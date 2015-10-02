//===- SPRVWriter.cpp – Converts LLVM to SPIR-V -----------------*- C++ -*-===//
//
//                     The LLVM/SPIR-V Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2014 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal with the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimers.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimers in the documentation
// and/or other materials provided with the distribution.
// Neither the names of Advanced Micro Devices, Inc., nor the names of its
// contributors may be used to endorse or promote products derived from this
// Software without specific prior written permission.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH
// THE SOFTWARE.
//
//===----------------------------------------------------------------------===//
/// \file
///
/// This file implements conversion of LLVM intermediate language to SPIR-V
/// binary.
///
//===----------------------------------------------------------------------===//

#include "SPRVModule.h"
#include "SPRVEnum.h"
#include "SPRVEntry.h"
#include "SPRVType.h"
#include "SPRVValue.h"
#include "SPRVFunction.h"
#include "SPRVBasicBlock.h"
#include "SPRVInstruction.h"
#include "SPRVExtInst.h"
#include "SPRVUtil.h"
#include "SPRVInternal.h"
#include "OCLUtil.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/ADT/Triple.h"
#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DebugInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Verifier.h"
#include "llvm/PassManager.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Transforms/IPO.h"

#include <iostream>
#include <list>
#include <memory>
#include <set>
#include <sstream>
#include <vector>
#include <functional>

#define DEBUG_TYPE "spirv"

using namespace llvm;
using namespace SPRV;
using namespace OCLUtil;

namespace llvm {
  FunctionPass *createPromoteMemoryToRegisterPass();
}

namespace SPRV{

bool SPRVDbgSaveRegularizedModule = false;


static void
decodeMDNode(MDNode* N, unsigned& X, unsigned& Y, unsigned& Z) {
  if (N == NULL)
    return;
  X = getMDOperandAsInt(N, 1);
  Y = getMDOperandAsInt(N, 2);
  Z = getMDOperandAsInt(N, 3);
}

static std::string
decodeVecTypeHintMDNode(MDNode* Node, Type *&HintType) {
  HintType = getMDOperandAsType(Node, 1);
  int Signed = getMDOperandAsInt(Node, 2);
  return mapLLVMTypeToOpenCLType(HintType, Signed);
}

static std::string
getNamedMDAsString(Module *M, const std::string &MDName) {
  NamedMDNode *NamedMD = M->getNamedMetadata(MDName);
  if (!NamedMD)
    return "";
  assert(NamedMD->getNumOperands() == 1 && "Invalid SPIR");
  MDNode *MD = NamedMD->getOperand(0);
  if (!MD || MD->getNumOperands() == 0)
    return "";
  return getMDOperandAsString(MD, 0);
}

static void
foreachKernelArgMD(MDNode *MD, SPRVFunction *BF,
    std::function<void(const std::string& Str,
        SPRVFunctionParameter *BA)>Func) {
  for (unsigned I = 1, E = MD->getNumOperands(); I != E; ++I) {
    SPRVFunctionParameter *BA = BF->getArgument(I-1);
    Func(getMDOperandAsString(MD, I), BA);
  }
}

/// Information for translating OCL builtin.
struct OCLBuiltinSPRVTransInfo {
  std::string UniqName;
  /// Postprocessor of operands
  std::function<void(std::vector<SPRVWord>&)> PostProc;
  OCLBuiltinSPRVTransInfo(){
    PostProc = [](std::vector<SPRVWord>&){};
  }
};

class LLVMToSPRVDbgTran {
public:
  LLVMToSPRVDbgTran(Module *TM, SPRVModule *TBM)
  :BM(TBM), M(TM){
  }

  void transDbgInfo(Value *V, SPRVValue *BV) {
    if (auto I = dyn_cast<Instruction>(V)) {
      auto DL = I->getDebugLoc();
      if (!DL.isUnknown()) {
        DILocation DIL(DL.getAsMDNode());
        auto File = BM->getString(DIL.getFilename().str());
        // ToDo: SPIR-V rev.31 cannot add debug info for instructions without ids.
        // This limitation needs to be addressed.
        if (!BV->hasId())
          return;
        BM->addLine(BV, File, DIL.getLineNumber(), DIL.getColumnNumber());
      }
    } else if (auto F = dyn_cast<Function>(V)) {
      if (auto DIS = getDISubprogram(F)) {
        auto File = BM->getString(DIS.getFilename().str());
        BM->addLine(BV, File, DIS.getLineNumber(), 0);
      }
    }
  }

private:
  SPRVModule *BM;
  Module *M;
};

class LLVMToSPRV {
public:
  LLVMToSPRV(Module *LLVMModule, SPRVModule *TheSPRVModule)
      : M(LLVMModule),
        Ctx(&M->getContext()),
        BM(TheSPRVModule),
        BuiltinSetId(SPRVID_INVALID),
        SrcLangVer(0),
        DbgTran(M, BM){
    RegularizedModuleTmpFile = "regularized.bc";
  }
  SPRVType *transType(Type *T);

  SPRVValue *getTranslatedValue(Value *);

  // Lower functions
  bool regularize();
  bool transOCLBuiltinsToVariables();
  bool lowerConstantExpressions();

  // Translation functions

  bool transAddressingMode();
  bool transAlign(Value *V, SPRVValue *BV);
  std::vector<SPRVValue *> transArguments(CallInst *, SPRVBasicBlock *);
  bool transCompileFlag();
  bool transSourceLanguage();
  bool transSourceExtension();
  bool transBuiltinSet();
  SPRVValue *transCallInst(CallInst *Call, SPRVBasicBlock *BB);
  bool transDecoration(Value *V, SPRVValue *BV);
  SPRVWord transFunctionControlMask(CallInst *);
  SPRVWord transFunctionControlMask(Function *);
  SPRVFunction *transFunction(Function *F);
  bool transGlobalVariables();

  Op transBoolOpCode(SPRVValue *Opn, Op OC);
  // Translate LLVM module to SPIR-V module.
  // Returns true if succeeds.
  bool translate();
  bool transFPContractMetadata();
  SPRVValue *transConstant(Value *V);
  SPRVValue *transValue(Value *V, SPRVBasicBlock *BB,
      bool CreateForward = true);
  SPRVValue *transValueWithoutDecoration(Value *V, SPRVBasicBlock *BB,
      bool CreateForward = true);

  typedef DenseMap<Type *, SPRVType *> LLVMToSPRVTypeMap;
  typedef DenseMap<Value *, SPRVValue *> LLVMToSPRVValueMap;
  typedef DenseMap<GlobalVariable *, SPRVBuiltinVariableKind> BuiltinVarMap;
private:
  Module *M;
  LLVMContext *Ctx;
  SPRVModule *BM;
  BuiltinVarMap BuiltinGVMap;
  LLVMToSPRVTypeMap TypeMap;
  LLVMToSPRVValueMap ValueMap;
  //ToDo: support multiple builtin sets. Currently assume one builtin set.
  SPRVId BuiltinSetId;
  SPRVWord SrcLangVer;
  std::string RegularizedModuleTmpFile;
  LLVMToSPRVDbgTran DbgTran;

  SPRVType *mapType(Type *T, SPRVType *BT) {
    TypeMap[T] = BT;
    return BT;
  }

  SPRVValue *mapValue(Value *V, SPRVValue *BV) {
    auto Loc = ValueMap.find(V);
    if (Loc != ValueMap.end()) {
      if (Loc->second == BV)
        return BV;
      assert (Loc->second->isForward() &&
          "LLVM Value is mapped to different SPIRV Values");
      auto Forward = static_cast<SPRVForward *>(Loc->second);
      BV->setId(Forward->getId());
      BM->replaceForward(Forward, BV);
    }
    ValueMap[V] = BV;
    SPRVDBG(dbgs() << "[mapValue] " << *V << " => ";
      bildbgs() << *BV << "\n");
    return BV;
  }

  SPRVType *getSPRVType(Type *T) {
      return TypeMap[T];
  }

  SPRVValue *getSPRVValue(Value *V) {
      return ValueMap[V];
  }

  SPRVErrorLog &getErrorLog() {
    return BM->getErrorLog();
  }

  llvm::IntegerType* getSizetType();
  std::vector<SPRVValue*> transValue(const std::vector<Value *> &Values,
      SPRVBasicBlock* BB);

  bool isFuncParamSigned(const std::string& MangledName);
  void eraseSubstitutionFromMangledName(std::string& MangledName);
  SPRVInstruction* transBinaryInst(BinaryOperator* B, SPRVBasicBlock* BB);
  SPRVInstruction* transCmpInst(CmpInst* Cmp, SPRVBasicBlock* BB);
  void mutateFunctionType(const std::map<unsigned, Type*>& ChangedType,
      llvm::FunctionType* &FT);

  void dumpUsers(Value *V);

  MDNode *oclGetArgBaseTypeMetadata(Function *);
  MDNode *oclGetArgAccessQualifierMetadata(Function *);
  MDNode *oclGetArgMetadata(Function *, const std::string& MDName);
  template<class ExtInstKind>
  bool oclGetExtInstIndex(const std::string &MangledName,
      const std::string& DemangledName, SPRVWord* EntryPoint);
  MDNode *oclGetKernelMetadata(Function *F);
  void oclGetMutatedArgumentTypesByArgBaseTypeMetadata(llvm::FunctionType* FT,
      std::map<unsigned, Type*>& ChangedType, Function* F);
  void oclGetMutatedArgumentTypesByBuiltin(llvm::FunctionType* FT,
      std::map<unsigned, Type*>& ChangedType, Function* F);
  FunctionType *oclGetRegularizedFunctionType(Function *);
  SPRVWord oclGetVectorLoadWidth(const std::string& DemangledName);

  bool oclIsBuiltinTransToInst(Function *F);
  bool oclIsBuiltinTransToExtInst(Function *F,
      SPRVExtInstSetKind *BuiltinSet = nullptr,
      SPRVWord *EntryPoint = nullptr);
  bool oclIsKernel(Function *F);

  bool transOCLKernelMetadata();
  SPRVValue *transOCLAsyncGroupCopy(CallInst *Call,
      const std::string &MangledName,
      const std::string &DeMangledName, SPRVBasicBlock *BB);

  bool getOCLImageBuiltinTransInfo(OCLBuiltinSPRVTransInfo &Info, CallInst *CI,
      const std::string &DeMangledName);

  SPRVValue *oclTransBarrier(CallInst *Call,
      const std::string &DeMangledName, SPRVBasicBlock *BB);
  SPRVValue *oclTransWorkGroupBarrier(CallInst *Call,
      const std::string &DeMangledName, SPRVBasicBlock *BB);
  SPRVValue *transOCLBuiltinToInst(CallInst *Call,
      const std::string &MangledName,
      const std::string &DemangledName, SPRVBasicBlock *BB);
  SPRVValue *transOCLConvert(CallInst *Call, const std::string &MangledName,
      const std::string &DeMangledName, SPRVBasicBlock *BB);
  SPRVValue *transOCLGroupBuiltins(CallInst *Call,
      const std::string &MangledName,
      const std::string &DeMangledName, SPRVBasicBlock *BB);
  SPRVValue *transOCLVectorLoadStore(CallInst *Call,
      const std::string &MangledName, const std::string &DeMangledName,
      SPRVBasicBlock *BB);
  void transOCLVectorLoadStoreName(std::string &DemangledName);
  void transOCLVectorLoadStoreName(std::string& DemangledName,
      const std::string& Stem, bool AlwaysN);
  SPRVInstruction *transOCLBuiltinToInstByMap(const std::string& DemangledName,
      const std::string &MangledName, CallInst* CI, SPRVBasicBlock* BB);
  void mutateFuncArgType(const std::map<unsigned, Type*>& ChangedType,
      Function* F);
  bool oclIsSamplerType(llvm::Type* RT);

  void getOCLBuiltinSPRVTransInfo(OCLBuiltinSPRVTransInfo &Info, CallInst *CI,
      const std::string &MangledName, const std::string &DemangledName);
  // Transform OpenCL group builtin function names from work_group_
  // and sub_group_ to group_.
  bool getOCLGroupBuiltinTransInfo(OCLBuiltinSPRVTransInfo &Info, CallInst *CI,
      const std::string &DemangledName);
  // Transform OpenCL read_pipe/write_pipe builtin function names
  // with reserve_id argument to reserved_read_pipe/reserved_write_pipe.
  bool getOCLPipeBuiltinTransInfo(OCLBuiltinSPRVTransInfo &Info, CallInst *CI,
      const std::string &DemangledName);
  SPRVValue *transSpcvCast(CallInst* CI, SPRVBasicBlock *BB);
  SPRVValue *oclTransSpvcCastSampler(CallInst* CI, SPRVBasicBlock *BB);

  bool oclRegularizeConvert(CallInst *Call, const std::string &MangledName,
      const std::string &DeMangledName,
      std::set<Value *>& ValuesForDeleting);
  void oclRegularize();
  void eraseFunctions(const std::vector<std::string> &L);
  SPRV::SPRVInstruction* transUnaryInst(UnaryInstruction* U,
      SPRVBasicBlock* BB);

  /// Add a 32 bit integer constant.
  /// \return Id of the constant.
  SPRVId addInt32(int);
};

SPRVValue *
LLVMToSPRV::getTranslatedValue(Value *V) {
  LLVMToSPRVValueMap::iterator Loc = ValueMap.find(V);
  if (Loc != ValueMap.end())
    return Loc->second;
  return nullptr;
}

bool
LLVMToSPRV::oclIsKernel(Function *F) {
  if (F->getCallingConv() == CallingConv::SPIR_KERNEL)
    return true;
#if  SPCV_RELAX_KERNEL_CALLING_CONV
  if (oclGetKernelMetadata(F)) {
    F->setCallingConv(CallingConv::SPIR_KERNEL);
    return true;
  }
#endif
  return false;
}

bool
LLVMToSPRV::oclIsBuiltinTransToInst(Function *F) {
  std::string DemangledName;
  if (!oclIsBuiltin(F->getName(), SrcLangVer, &DemangledName) &&
      !isSPRVFunction(F, &DemangledName))
    return false;
  SPRVDBG(bildbgs() << "CallInst: demangled name: " << DemangledName << '\n');
  SourceLanguage SourceLang = BM->getSourceLanguage(nullptr);
  if (SourceLang == SourceLanguageOpenCL) {
    return DemangledName == "barrier" ||
        DemangledName == "dot" ||
        DemangledName.find("convert_") == 0 ||
        DemangledName.find("atomic_") == 0 ||
        DemangledName.find("async_work_group") == 0 ||
        DemangledName == "wait_group_events" ||
        DemangledName.find("work_group_") == 0 ||
        DemangledName.find("sub_group_") == 0 ||
        getSPRVFuncOC(DemangledName) != OpNop ||
        OCLSPRVBuiltinMap::find(DemangledName);
  }
  llvm_unreachable("not supported");
  return false;
}

void LLVMToSPRV::transOCLVectorLoadStoreName(std::string& DemangledName,
    const std::string &Stem, bool AlwaysN) {
  auto HalfStem = Stem + "_half";
  auto HalfStemR = HalfStem + "_r";
  if (!AlwaysN && DemangledName == HalfStem)
    return;
  if (!AlwaysN && DemangledName.find(HalfStemR) == 0) {
    DemangledName = HalfStemR;
    return;
  }
  if (DemangledName.find(HalfStem) == 0) {
    auto OldName = DemangledName;
    DemangledName = HalfStem + "n";
    if (OldName.find("_r") != std::string::npos)
      DemangledName += "_r";
    return;
  }
  if (DemangledName.find(Stem) == 0) {
    DemangledName = Stem + "n";
    return;
  }
}

void
LLVMToSPRV::transOCLVectorLoadStoreName(std::string &DemangledName) {
  if (DemangledName.find("vloada") == 0)
    transOCLVectorLoadStoreName(DemangledName, "vloada", true);
  else
    transOCLVectorLoadStoreName(DemangledName, "vload", false);

  if (DemangledName.find("vstorea") == 0)
    transOCLVectorLoadStoreName(DemangledName, "vstorea", true);
  else
    transOCLVectorLoadStoreName(DemangledName, "vstore", false);
}

template<class SPRVExtInstKind>
bool LLVMToSPRV::oclGetExtInstIndex(const std::string &MangledName,
    const std::string& DemangledName, SPRVWord* EntryPoint) {
  SPRVExtInstKind ExtInst = static_cast<SPRVExtInstKind>(0);
  bool Found = getNameMap(ExtInst).rfind(DemangledName, &ExtInst);
  if (!Found) {
    std::string Prefix = isFuncParamSigned(MangledName) ? "s_" : "u_";
    Found = getNameMap(ExtInst).rfind(Prefix + DemangledName, &ExtInst);
  }

  if (Found && EntryPoint)
    *EntryPoint = ExtInst;
  return Found;
}

bool
LLVMToSPRV::oclIsBuiltinTransToExtInst(Function *F,
    SPRVExtInstSetKind *BuiltinSet,
    SPRVWord *EntryPoint) {
  std::string OrigName = F->getName();
  std::string DemangledName;
  if (OrigName != "printf" &&
      !oclIsBuiltin(OrigName, SrcLangVer, &DemangledName))
    return false;
  if (OrigName == "printf")
    DemangledName = OrigName;
  else {
    SPRVDBG(bildbgs() << "CallInst: demangled name: " << DemangledName << '\n');
    transOCLVectorLoadStoreName(DemangledName);
  }
  SPRVDBG(bildbgs() << "CallInst: modified demangled name: " << DemangledName
                    << '\n');
  SPRVExtInstSetKind BSK = SPRVEIS_Count;
  BSK = BM->getBuiltinSet(BuiltinSetId);
  bool Found = false;
  switch (BSK) {
  case SPRVEIS_OpenCL:
    Found = oclGetExtInstIndex<OCLExtOpKind>(OrigName, DemangledName,
        EntryPoint);
    break;
  default:
    llvm_unreachable("not supported");
  }
  assert(Found && "Invalid builtin function");
  if (Found && BuiltinSet)
    *BuiltinSet = BSK;
  return Found;
}

/// Translates OCL work-item builtin functions to SPIRV builtin variables.
/// Function like get_global_id(i) -> x = load GlobalInvocationId; extract x, i
/// Function like get_work_dim() -> load WorkDim
bool
LLVMToSPRV::transOCLBuiltinsToVariables() {
  std::vector<Function *> WorkList;
  for (auto I = M->begin(), E = M->end(); I != E; ++I) {
    std::string DemangledName;
    if (!oclIsBuiltin(I->getName(), SrcLangVer, &DemangledName))
      continue;
    SPRVDBG(bildbgs() << "Function: demangled name: " << DemangledName <<
        '\n');
    std::string BuiltinVarName;
    SPRVBuiltinVariableKind BVKind = SPRVBI_Count;
    if (!SPIRSPRVBuiltinVariableMap::find(DemangledName, &BVKind))
      continue;
    BuiltinVarName = std::string(kSPRVName::Prefix) +
        SPRVBuiltinVariableNameMap::map(BVKind);
    SPRVDBG(bildbgs() << "builtin variable name: " << BuiltinVarName << '\n');
    bool IsVec = I->getFunctionType()->getNumParams() > 0;
    Type *GVType = IsVec ? VectorType::get(I->getReturnType(),3) :
        I->getReturnType();
    auto BV = new GlobalVariable(*M, GVType,
        true,
        GlobalValue::InternalLinkage,
        nullptr, BuiltinVarName,
        0,
        GlobalVariable::NotThreadLocal,
        SPIRAS_Constant);
    BuiltinGVMap[BV] = BVKind;
    std::vector<Instruction *> InstList;
    for (auto UI = I->user_begin(), UE = I->user_end(); UI != UE; ++UI) {
      auto CI = dyn_cast<CallInst>(*UI);
      assert(CI && "invalid instruction");
      Value * NewValue = new LoadInst(BV, "", CI);
      if (IsVec)
        NewValue = ExtractElementInst::Create(NewValue,
          CI->getArgOperand(0),
          "", CI);
      NewValue->takeName(CI);
      SPRVDBG(dbgs() << "Replace: " << *CI << " <- " << *NewValue << '\n');
      CI->replaceAllUsesWith(NewValue);
      InstList.push_back(CI);
    }
    for (auto &Inst:InstList) {
      Inst->dropAllReferences();
      Inst->removeFromParent();
    }
    WorkList.push_back(I);
  }
  for (auto &I:WorkList) {
    I->dropAllReferences();
    I->removeFromParent();
  }
  return true;
}

/// Since SPIR-V cannot represent constant expression, constant expressions
/// in LLVM needs to be lowered to instructions.
/// For each function, the constant expressions used by instructions of the
/// function are replaced by instructions placed in the entry block since it
/// dominates all other BB's. Each constant expression only needs to be lowered
/// once in each function and all uses of it by instructions in that function
/// is replaced by one instruction.
/// ToDo: remove redundant instructions for common subexpression
bool
LLVMToSPRV::lowerConstantExpressions() {
  for (auto I = M->begin(), E = M->end(); I != E; ++I) {
    std::map<ConstantExpr*, Instruction *> CMap;
    std::list<Instruction *> WorkList;
    auto FBegin = I->begin();
    for (auto BI = FBegin, BE = I->end(); BI != BE; ++BI) {
      for (auto II = BI->begin(), IE = BI->end(); II != IE; ++II) {
        WorkList.push_back(II);
      }
    }
    while (!WorkList.empty()) {
      auto II = WorkList.front();
      WorkList.pop_front();
      for (unsigned OI = 0, OE = II->getNumOperands(); OI != OE; ++OI) {
        auto Op = II->getOperand(OI);

        if (auto CE = dyn_cast<ConstantExpr>(Op)) {
          SPRVDBG(dbgs() << "[lowerConstantExpressions] " << *CE;)
          auto ReplInst = CE->getAsInstruction();
          ReplInst->insertBefore(FBegin->begin());
          SPRVDBG(dbgs() << " -> " << *ReplInst << '\n';)
          WorkList.push_front(ReplInst);
          std::vector<Instruction *> Users;
          // Do not replace use during iteration of use. Do it in another loop.
          for (auto UI = CE->user_begin(), UE = CE->user_end(); UI != UE;
              ++UI){
            SPRVDBG(dbgs() << "[lowerConstantExpressions] Use: " <<
                **UI << '\n';)
            if (auto InstUser = dyn_cast<Instruction>(*UI)) {
              if (InstUser->getParent()->getParent() != I)
                continue;
              Users.push_back(InstUser);
            }
          }
          for (auto &User:Users)
            User->replaceUsesOfWith(CE, ReplInst);
        }
      }
    }
  }
  return true;
}

SPRVType *
LLVMToSPRV::transType(Type *T) {
  LLVMToSPRVTypeMap::iterator Loc = TypeMap.find(T);
  if (Loc != TypeMap.end())
    return Loc->second;

  SPRVDBG(dbgs() << "[transType] " << *T << '\n');
  if (T->isVoidTy())
    return mapType(T, BM->addVoidType());

  if (T->isIntegerTy(1))
    return mapType(T, BM->addBoolType());

  if (T->isIntegerTy())
    return mapType(T, BM->addIntegerType(T->getIntegerBitWidth()));

  if (T->isFloatingPointTy())
    return mapType(T, BM->addFloatType(T->getPrimitiveSizeInBits()));

  // A pointer to image or pipe type in LLVM is translated to a SPRV
  // sampler or pipe type.
  if (T->isPointerTy()) {
    auto ET = T->getPointerElementType();
    auto ST = dyn_cast<StructType>(ET);
    auto AddrSpc = T->getPointerAddressSpace();
    if (ST && !ST->isSized()) {
      Op OpCode;
      StringRef STName = ST->getName();
      // Workaround for non-conformant SPIR binary
      if (STName == "struct._event_t") {
        STName = kSPR2TypeName::Event;
        ST->setName(STName);
      }
      if (STName.find(SPIR_TYPE_NAME_PIPE_T) == 0) {
        assert(AddrSpc == SPIRAS_Global);
        SmallVector<StringRef, 4> SubStrs;
        const char Delims[] = {kSPR2TypeName::Delimiter, 0};
        STName.split(SubStrs, Delims);
        std::string Acc = kAccessQualName::ReadOnly;
        if (SubStrs.size() > 2) {
          Acc = SubStrs[2];
        }
        auto PipeT = BM->addPipeType();
        PipeT->setPipeAcessQualifier(SPIRSPRVAccessQualifierMap::map(Acc));
        return mapType(T, PipeT);
      } else if (STName.find(kSPR2TypeName::ImagePrefix) == 0) {
        assert(AddrSpc == SPIRAS_Global);
        SmallVector<StringRef, 4> SubStrs;
        const char Delims[] = {kSPR2TypeName::Delimiter, 0};
        STName.split(SubStrs, Delims);
        std::string Acc = kAccessQualName::ReadOnly;
        if (SubStrs.size() > 2) {
          Acc = SubStrs[2];
        }
        auto Desc = map<SPRVTypeImageDescriptor>(SubStrs[1].str());
        DEBUG(dbgs() << "[trans image type] " << SubStrs[1] << " => " <<
            "(" << (unsigned)Desc.Dim << ", " <<
                   Desc.Depth << ", " <<
                   Desc.Arrayed << ", " <<
                   Desc.MS << ", " <<
                   Desc.Sampled << ", " <<
                   Desc.Format << ")\n");
        auto VoidT = transType(Type::getVoidTy(*Ctx));
        return mapType(T, BM->addImageType(VoidT, Desc,
          SPIRSPRVAccessQualifierMap::map(Acc)));
      } else if (STName == kSPR2TypeName::Sampler) {
        assert(AddrSpc == SPIRAS_Global);
        return mapType(T, BM->addSamplerType());
      } else if (STName.find(kSPRVTypeName::SampledImg) == 0) {
        SmallVector<StringRef, 4> SubStrs;
        const char Delims[] = {kSPR2TypeName::Delimiter, 0};
        STName.split(SubStrs, Delims);
        std::string ImgTyName = kSPR2TypeName::OCLPrefix;
        ImgTyName += SubStrs[2];
        if (SubStrs.size() > 3) {
          ImgTyName += kSPR2TypeName::Delimiter;
          ImgTyName += SubStrs[3].str();
        }
        return mapType(T, BM->addSampledImageType(
            static_cast<SPRVTypeImage *>(
                transType(getOrCreateOpaquePtrType(M, ImgTyName)))));
      }
      else if (BuiltinOpaqueGenericTypeOpCodeMap::find(STName, &OpCode)) {
        if (OpCode == OpTypePipe) {
          return mapType(T, BM->addPipeType());
        }
        return mapType(T, BM->addOpaqueGenericType(OpCode));
      }
      else if (isPointerToOpaqueStructType(T)) {
        return mapType(T, BM->addPointerType(SPIRSPRVAddrSpaceMap::map(
          static_cast<SPIRAddressSpace>(AddrSpc)),
          transType(ET)));
      }
    } else  {
      return mapType(T, BM->addPointerType(SPIRSPRVAddrSpaceMap::map(
        static_cast<SPIRAddressSpace>(AddrSpc)),
        transType(ET)));
    }
  }

  if (T->isVectorTy())
    return mapType(T, BM->addVectorType(transType(T->getVectorElementType()),
        T->getVectorNumElements()));

  if (T->isArrayTy())
    return mapType(T, BM->addArrayType(transType(T->getArrayElementType()),
        static_cast<SPRVConstant*>(transValue(ConstantInt::get(getSizetType(),
            T->getArrayNumElements(), false), nullptr))));

  if (T->isStructTy() && !T->isSized()) {
    auto ST = dyn_cast<StructType>(T);
    assert(!ST->getName().startswith(SPIR_TYPE_NAME_PIPE_T));
    assert(!ST->getName().startswith(kSPR2TypeName::ImagePrefix));
    return mapType(T, BM->addOpaqueType(T->getStructName()));
  }

  if (auto ST = dyn_cast<StructType>(T)) {
    assert(ST->isSized());
    std::vector<SPRVType *> MT;
    for (unsigned I = 0, E = T->getStructNumElements(); I != E; ++I)
      MT.push_back(transType(ST->getElementType(I)));
    std::string Name;
    if (ST->hasName())
      Name = ST->getName();
    return mapType(T, BM->addStructType(MT, Name, ST->isPacked()));
  }

  if (FunctionType *FT = dyn_cast<FunctionType>(T)) {
    SPRVType *RT = transType(FT->getReturnType());
    std::vector<SPRVType *> PT;
    for (FunctionType::param_iterator I = FT->param_begin(),
        E = FT->param_end(); I != E; ++I)
      PT.push_back(transType(*I));
    return mapType(T, BM->addFunctionType(RT, PT));
  }

  llvm_unreachable("Not implemented!");
  return 0;
}

SPRVFunction *
LLVMToSPRV::transFunction(Function *F) {
  if (auto BF= getTranslatedValue(F))
    return static_cast<SPRVFunction *>(BF);

  SPRVTypeFunction *BFT = static_cast<SPRVTypeFunction *>(transType(
      oclGetRegularizedFunctionType(F)));
  SPRVFunction *BF = static_cast<SPRVFunction *>(mapValue(F,
      BM->addFunction(BFT)));
  BF->setFunctionControlMask(transFunctionControlMask(F));
  if (F->hasName())
    BM->setName(BF, F->getName());
  if (oclIsKernel(F))
    BM->addEntryPoint(SPRVEMDL_Kernel, BF->getId());
  else if (F->getLinkage() != GlobalValue::InternalLinkage &&
           F->getLinkage() != GlobalValue::LinkOnceODRLinkage)
    BF->setLinkageType(SPIRSPRVLinkageTypeMap::map(F->getLinkage()));
  auto Attrs = F->getAttributes();
  for (Function::arg_iterator I = F->arg_begin(), E = F->arg_end(); I != E;
      ++I) {
    auto ArgNo = I->getArgNo();
    SPRVFunctionParameter *BA = BF->getArgument(ArgNo);
    if (I->hasName())
      BM->setName(BA, I->getName());
    if (I->hasByValAttr())
      BA->addAttr(SPRVFPA_ByVal);
    if (I->hasNoAliasAttr())
      BA->addAttr(SPRVFPA_NoAlias);
    if (I->hasNoCaptureAttr())
      BA->addAttr(SPRVFPA_NoCapture);
    if (I->hasStructRetAttr())
      BA->addAttr(SPRVFPA_Sret);
    if (Attrs.hasAttribute(ArgNo + 1, Attribute::ZExt))
      BA->addAttr(SPRVFPA_Zext);
    if (Attrs.hasAttribute(ArgNo + 1, Attribute::SExt))
      BA->addAttr(SPRVFPA_Sext);
  }
  if (Attrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::ZExt))
    BF->addDecorate(DecorationFuncParamAttr, SPRVFPA_Zext);
  if (Attrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::SExt))
    BF->addDecorate(DecorationFuncParamAttr, SPRVFPA_Sext);
  DbgTran.transDbgInfo(F, BF);
  SPRVDBG(dbgs() << "[transFunction] " << *F << " => ";
    bildbgs() << *BF << '\n';)
  return BF;
}

#define _SPRV_OPL(x) OpLogical##x

#define _SPRV_OPB(x) OpBitwise##x

SPRVValue *
LLVMToSPRV::transConstant(Value *V) {
  if (auto CPNull = dyn_cast<ConstantPointerNull>(V))
    return BM->addNullConstant(bcast<SPRVTypePointer>(transType(
        CPNull->getType())));

  if (auto CAZero = dyn_cast<ConstantAggregateZero>(V))
    return BM->addNullConstant(transType(CAZero->getType()));

  if (auto ConstI = dyn_cast<ConstantInt>(V)) {
    SPRVTypeInt *BT = static_cast<SPRVTypeInt *>(transType(V->getType()));
    return BM->addIntegerConstant(BT, ConstI->getZExtValue());
  }

  if (auto ConstFP = dyn_cast<ConstantFP>(V)) {
    auto BT = static_cast<SPRVType *>(transType(V->getType()));
    return BM->addConstant(BT,
        ConstFP->getValueAPF().bitcastToAPInt().getZExtValue());
  }

  if (auto ConstDA = dyn_cast<ConstantDataArray>(V)) {
    std::vector<SPRVValue *> BV;
    for (unsigned I = 0, E = ConstDA->getNumElements(); I != E; ++I)
      BV.push_back(transValue(ConstDA->getElementAsConstant(I), nullptr));
    return BM->addCompositeConstant(transType(V->getType()), BV);
  }

  if (auto ConstA = dyn_cast<ConstantArray>(V)) {
    std::vector<SPRVValue *> BV;
    for (auto I = ConstA->op_begin(), E = ConstA->op_end(); I != E; ++I)
      BV.push_back(transValue(*I, nullptr));
    return BM->addCompositeConstant(transType(V->getType()), BV);
  }

  if (auto ConstDV = dyn_cast<ConstantDataVector>(V)) {
    std::vector<SPRVValue *> BV;
    for (unsigned I = 0, E = ConstDV->getNumElements(); I != E; ++I)
      BV.push_back(transValue(ConstDV->getElementAsConstant(I), nullptr));
    return BM->addCompositeConstant(transType(V->getType()), BV);
  }

  if (auto ConstV = dyn_cast<ConstantVector>(V)) {
    std::vector<SPRVValue *> BV;
    for (auto I = ConstV->op_begin(), E = ConstV->op_end(); I != E; ++I)
      BV.push_back(transValue(*I, nullptr));
    return BM->addCompositeConstant(transType(V->getType()), BV);
  }

  if (auto ConstV = dyn_cast<ConstantStruct>(V)) {
    std::vector<SPRVValue *> BV;
    for (auto I = ConstV->op_begin(), E = ConstV->op_end(); I != E; ++I)
      BV.push_back(transValue(*I, nullptr));
    return BM->addCompositeConstant(transType(V->getType()), BV);
  }

  if (auto ConstUE = dyn_cast<ConstantExpr>(V)) {
    auto Inst = ConstUE->getAsInstruction();
    SPRVDBG(dbgs() << "ConstantExpr: " << *ConstUE << '\n';
      dbgs() << "Instruction: " << *Inst << '\n';)
    auto BI = transValue(Inst, nullptr, false);
    Inst->dropAllReferences();
    return BI;
  }

  if (isa<UndefValue>(V)) {
    return BM->addUndef(transType(V->getType()));
  }

  return nullptr;
}

SPRVValue *
LLVMToSPRV::transValue(Value *V, SPRVBasicBlock *BB, bool CreateForward) {
  LLVMToSPRVValueMap::iterator Loc = ValueMap.find(V);
  if (Loc != ValueMap.end() && (!Loc->second->isForward() || CreateForward))
    return Loc->second;

  SPRVDBG(dbgs() << "[transValue] " << *V << '\n');
  assert ((!isa<Instruction>(V) || isa<GetElementPtrInst>(V) ||
      isa<CastInst>(V) || BB) &&
      "Invalid SPIRV BB");

  auto BV = transValueWithoutDecoration(V, BB, CreateForward);
  BM->setName(BV, V->getName());
  if(!transDecoration(V, BV))
    return nullptr;
  return BV;
}

SPRVInstruction*
LLVMToSPRV::transBinaryInst(BinaryOperator* B, SPRVBasicBlock* BB) {
  unsigned LLVMOC = B->getOpcode();
  auto Op0 = transValue(B->getOperand(0), BB);
  SPRVInstruction* BI = BM->addBinaryInst(
      transBoolOpCode(Op0, OpCodeMap::map(LLVMOC)),
      transType(B->getType()), Op0, transValue(B->getOperand(1), BB), BB);
  return BI;
}

SPRVInstruction*
LLVMToSPRV::transCmpInst(CmpInst* Cmp, SPRVBasicBlock* BB) {
  auto Op0 = transValue(Cmp->getOperand(0), BB);
  SPRVInstruction* BI = BM->addCmpInst(
      transBoolOpCode(Op0, CmpMap::map(Cmp->getPredicate())),
      transType(Cmp->getType()), Op0,
      transValue(Cmp->getOperand(1), BB), BB);
  return BI;
}

bool
LLVMToSPRV::getOCLPipeBuiltinTransInfo(OCLBuiltinSPRVTransInfo &Info,
    CallInst *CI, const std::string &DemangledName) {
  std::string NewName = DemangledName;
  if (DemangledName.find(kOCLBuiltinName::ReadPipe) != 0 &&
      DemangledName.find(kOCLBuiltinName::WritePipe) != 0)
    return false;

  if (CI->getNumArgOperands() > 4 &&
      DemangledName.find(kSPRVName::ReservedPrefix) != 0)
    NewName = std::string(kSPRVName::ReservedPrefix) + DemangledName;
  Info.UniqName = NewName;
  return true;
}

// ToDo: Handle unsigned integer texel type
bool
LLVMToSPRV::getOCLImageBuiltinTransInfo(OCLBuiltinSPRVTransInfo &Info,
    CallInst *CI, const std::string &DemangledName) {
  std::string NewName = DemangledName;
  if (DemangledName.find(kOCLBuiltinName::ReadImage) == 0) {
    Info.UniqName = kOCLBuiltinName::ReadImage;
    return true;
  }

  if (DemangledName.find(kOCLBuiltinName::WriteImage) == 0) {
    Info.UniqName = kOCLBuiltinName::WriteImage;
    return true;
  }
  return false;
}

bool
LLVMToSPRV::getOCLGroupBuiltinTransInfo(OCLBuiltinSPRVTransInfo &Info,
    CallInst *CI, const std::string &OrigDemangledName) {
  auto F = CI->getCalledFunction();
  std::vector<SPRVWord> PreOps;
  std::string DemangledName = OrigDemangledName;
  if (DemangledName == kOCLBuiltinName::WorkGroupBarrier)
    return false;
  if (DemangledName.find(kOCLBuiltinName::WorkGroupPrefix) == 0) {
    DemangledName.erase(0, strlen(kOCLBuiltinName::WorkPrefix));
    PreOps.push_back(ScopeWorkgroup);
  } else if (DemangledName.find(kOCLBuiltinName::SubGroupPrefix) == 0) {
    DemangledName.erase(0, strlen(kOCLBuiltinName::SubPrefix));
    PreOps.push_back(ScopeSubgroup);
  } else
    return false;

  StringRef GroupOp = DemangledName;
  GroupOp = GroupOp.drop_front(strlen(kSPRVName::GroupPrefix));
  SPIRSPRVGroupOperationMap::foreach_conditional([&](const std::string &S,
      SPRVGroupOperationKind G){
    if (!GroupOp.startswith(S))
      return true; // continue
    PreOps.push_back(G);
    StringRef Op = GroupOp.drop_front(S.size() + 1);
    assert(!Op.empty() && "Invalid OpenCL group builtin function");
    char OpTyC = 0;
    auto NeedSign = Op == "max" || Op == "min";
    auto OpTy = F->getReturnType();
    if (OpTy->isFloatingPointTy())
      OpTyC = 'f';
    else if (OpTy->isIntegerTy()) {
      if (!NeedSign)
        OpTyC = 'i';
      else {
        if (isFuncParamSigned(F->getName()))
          OpTyC = 's';
        else
          OpTyC = 'u';
      }
    } else
      llvm_unreachable("Invalid OpenCL group builtin argument type");

    DemangledName = std::string(kSPRVName::GroupPrefix) + OpTyC + Op.str();
    return false; // break out of loop
  });
  Info.UniqName = DemangledName;
  Info.PostProc = [=](std::vector<SPRVWord> &Ops){
    Ops.insert(Ops.begin(), PreOps.begin(), PreOps.end());
  };
  return true;
}

void LLVMToSPRV::getOCLBuiltinSPRVTransInfo(OCLBuiltinSPRVTransInfo &Info,
    CallInst *CI, const std::string & MangledName,
    const std::string &DemangledName) {
  if (getOCLGroupBuiltinTransInfo(Info, CI, DemangledName))
    return;
  if (getOCLPipeBuiltinTransInfo(Info, CI, DemangledName))
    return;
  if (getOCLImageBuiltinTransInfo(Info, CI, DemangledName))
    return;
  Info.UniqName = DemangledName;
  return;
}

SPRV::SPRVInstruction *LLVMToSPRV::transUnaryInst(UnaryInstruction *U,
                                                  SPRVBasicBlock *BB) {
  Op BOC = OpNop;
  if (auto Cast = dyn_cast<AddrSpaceCastInst>(U)) {
    if (Cast->getDestTy()->getPointerAddressSpace() == SPIRAS_Generic) {
      assert(Cast->getSrcTy()->getPointerAddressSpace() != SPIRAS_Constant &&
             "Casts from constant address space to generic are illegal");
      BOC = OpPtrCastToGeneric;
    } else {
      assert(Cast->getDestTy()->getPointerAddressSpace() != SPIRAS_Constant &&
             "Casts from generic address space to constant are illegal");
      assert(Cast->getSrcTy()->getPointerAddressSpace() == SPIRAS_Generic);
      BOC = OpGenericCastToPtr;
    }
  } else {
    auto OpCode = U->getOpcode();
    BOC = OpCodeMap::map(OpCode);
  }
  auto Op = transValue(U->getOperand(0), BB);
  return BM->addUnaryInst(transBoolOpCode(Op, BOC),
      transType(U->getType()), Op, BB);
}

/// An instruction may use an instruction from another BB which has not been
/// translated. SPRVForward should be created as place holder for these
/// instructions and replaced later by the real instructions.
/// Use CreateForward = true to indicate such situation.
SPRVValue *
LLVMToSPRV::transValueWithoutDecoration(Value *V, SPRVBasicBlock *BB,
    bool CreateForward) {
  if (auto LBB = dyn_cast<BasicBlock>(V)) {
    auto BF = static_cast<SPRVFunction *>(getTranslatedValue(LBB->getParent()));
    assert (BF && "Function not translated");
    BB = static_cast<SPRVBasicBlock *>(mapValue(V, BM->addBasicBlock(BF)));
    BM->setName(BB, LBB->getName());
    return BB;
  }

  if (auto F = dyn_cast<Function>(V))
    return transFunction(F);

  if (auto GV = dyn_cast<GlobalVariable>(V)) {
    auto BVar = static_cast<SPRVVariable *>(BM->addVariable(
        transType(GV->getType()), GV->isConstant(),
        SPIRSPRVLinkageTypeMap::map(GV->getLinkage()),
        GV->hasInitializer()?transValue(GV->getInitializer(), nullptr):nullptr,
        GV->getName(),
        SPIRSPRVAddrSpaceMap::map(static_cast<SPIRAddressSpace>(
            GV->getType()->getAddressSpace())),
        nullptr
        ));
    mapValue(V, BVar);
    auto Loc = BuiltinGVMap.find(GV);
    if (Loc == BuiltinGVMap.end())
      return BVar;
    BVar->setBuiltin(Loc->second);
    return BVar;
  }

  if (isa<Constant>(V)) {
    auto BV = transConstant(V);
    assert(BV);
    return mapValue(V, BV);
  }

  if (auto Arg = dyn_cast<Argument>(V)) {
    unsigned ArgNo = Arg->getArgNo();
    SPRVFunction *BF = BB->getParent();
    //assert(BF->existArgument(ArgNo));
    return mapValue(V, BF->getArgument(ArgNo));
  }

  if (CreateForward)
    return mapValue(V, BM->addForward(transType(V->getType())));

  if (StoreInst *ST = dyn_cast<StoreInst>(V)) {
    std::vector<SPRVWord> MemoryAccess;
    if (ST->isVolatile())
      MemoryAccess.push_back(SPRVMA_Volatile);
    MemoryAccess.push_back(SPRVMA_Aligned);
    MemoryAccess.push_back(ST->getAlignment());
    return mapValue(V, BM->addStoreInst(
        transValue(ST->getPointerOperand(), BB),
        transValue(ST->getValueOperand(), BB),
        MemoryAccess, BB));
  }

  if (LoadInst *LD = dyn_cast<LoadInst>(V)) {
    std::vector<SPRVWord> MemoryAccess;
    if (LD->isVolatile())
      MemoryAccess.push_back(SPRVMA_Volatile);
    MemoryAccess.push_back(SPRVMA_Aligned);
    MemoryAccess.push_back(LD->getAlignment());
    return mapValue(V, BM->addLoadInst(
        transValue(LD->getPointerOperand(), BB),
        MemoryAccess, BB));
  }

  if (BinaryOperator *B = dyn_cast<BinaryOperator>(V)) {
    SPRVInstruction* BI = transBinaryInst(B, BB);
    return mapValue(V, BI);
  }

  if (auto RI = dyn_cast<ReturnInst>(V)) {
    if (auto RV = RI->getReturnValue())
      return mapValue(V, BM->addReturnValueInst(
          transValue(RV, BB), BB));
    return mapValue(V, BM->addReturnInst(BB));
  }

  if (CmpInst *Cmp = dyn_cast<CmpInst>(V)) {
    SPRVInstruction* BI = transCmpInst(Cmp, BB);
    return mapValue(V, BI);
  }

  if (SelectInst *Sel = dyn_cast<SelectInst>(V))
    return mapValue(V, BM->addSelectInst(
        transValue(Sel->getCondition(), BB),
        transValue(Sel->getTrueValue(), BB),
        transValue(Sel->getFalseValue(), BB),BB));

  if (AllocaInst *Alc = dyn_cast<AllocaInst>(V))
    return mapValue(V, BM->addVariable(
      transType(Alc->getType()), false,
      SPIRSPRVLinkageTypeMap::map(GlobalValue::InternalLinkage),
      nullptr, Alc->getName(),
      SPRVSC_Function, BB));

  if (auto *Switch = dyn_cast<SwitchInst>(V)) {
    std::vector<std::pair<SPRVWord, SPRVBasicBlock *>> Pairs;
    for (auto I = Switch->case_begin(), E = Switch->case_end(); I != E; ++I)
      Pairs.push_back(std::make_pair(I.getCaseValue()->getZExtValue(),
          static_cast<SPRVBasicBlock*>(transValue(I.getCaseSuccessor(),
              nullptr))));
    return mapValue(V, BM->addSwitchInst(
        transValue(Switch->getCondition(), BB),
        static_cast<SPRVBasicBlock*>(transValue(Switch->getDefaultDest(),
            nullptr)), Pairs, BB));
  }

  if (auto Branch = dyn_cast<BranchInst>(V)) {
    if (Branch->isUnconditional())
      return mapValue(V, BM->addBranchInst(
          static_cast<SPRVLabel*>(transValue(Branch->getSuccessor(0), BB)),
          BB));
    return mapValue(V, BM->addBranchConditionalInst(
        transValue(Branch->getCondition(), BB),
        static_cast<SPRVLabel*>(transValue(Branch->getSuccessor(0), BB)),
        static_cast<SPRVLabel*>(transValue(Branch->getSuccessor(1), BB)),
        BB));
  }

  if (auto Phi = dyn_cast<PHINode>(V)) {
    std::vector<SPRVValue *> IncomingPairs;
    for (size_t I = 0, E = Phi->getNumIncomingValues(); I != E; ++I) {
      IncomingPairs.push_back(transValue(Phi->getIncomingValue(I), BB));
      IncomingPairs.push_back(transValue(Phi->getIncomingBlock(I), nullptr));
    }
    return mapValue(V, BM->addPhiInst(transType(Phi->getType()), IncomingPairs,
        BB));
  }

  if (UnaryInstruction *U = dyn_cast<UnaryInstruction>(V)) {
    return mapValue(V, transUnaryInst(U, BB));
  }

  if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(V)) {
    std::vector<SPRVValue *> Indices;
    for (unsigned i = 0, e = GEP->getNumIndices(); i != e; ++i)
      Indices.push_back(transValue(GEP->getOperand(i+1), BB));
    return mapValue(V, BM->addPtrAccessChainInst(
        transType(GEP->getType()),
        transValue(GEP->getPointerOperand(), BB),
        Indices, BB, GEP->isInBounds()));
  }

  if (auto Ext = dyn_cast<ExtractElementInst>(V)) {
    auto Index = Ext->getIndexOperand();
    if (auto Const = dyn_cast<ConstantInt>(Index))
      return mapValue(V, BM->addCompositeExtractInst(
        transType(Ext->getType()),
        transValue(Ext->getVectorOperand(), BB),
        std::vector<SPRVWord>(1, Const->getZExtValue()),
        BB));
    else
      return mapValue(V, BM->addVectorExtractDynamicInst(
          transValue(Ext->getVectorOperand(), BB),
          transValue(Index, BB),
          BB));
  }

  if (auto Ins = dyn_cast<InsertElementInst>(V)) {
    auto Index = Ins->getOperand(2);
    if (auto Const = dyn_cast<ConstantInt>(Index))
      return mapValue(V, BM->addCompositeInsertInst(
      transValue(Ins->getOperand(1), BB),
      transValue(Ins->getOperand(0), BB),
      std::vector<SPRVWord>(1, Const->getZExtValue()),
      BB));
    else
      return mapValue(V, BM->addVectorInsertDynamicInst(
      transValue(Ins->getOperand(0), BB),
      transValue(Ins->getOperand(1), BB),
      transValue(Index, BB),
      BB));
  }

  if (auto SF = dyn_cast<ShuffleVectorInst>(V)) {
    std::vector<SPRVWord> Comp;
    for (auto &I:SF->getShuffleMask())
      Comp.push_back(I);
    return mapValue(V, BM->addVectorShuffleInst(
        transType(SF->getType()),
        transValue(SF->getOperand(0), BB),
        transValue(SF->getOperand(1), BB),
        Comp,
        BB));
  }

  if (CallInst *CI = dyn_cast<CallInst>(V))
    return mapValue(V, transCallInst(CI, BB));

  llvm_unreachable("Not implemented");
  return nullptr;
}

bool
LLVMToSPRV::transDecoration(Value *V, SPRVValue *BV) {
  if (!transAlign(V, BV))
    return false;
  if ((isa<AtomicCmpXchgInst>(V) &&
      cast<AtomicCmpXchgInst>(V)->isVolatile()) ||
      (isa<AtomicRMWInst>(V) && cast<AtomicRMWInst>(V)->isVolatile()))
    BV->setVolatile(true);
  DbgTran.transDbgInfo(V, BV);
  return true;
}

bool
LLVMToSPRV::transAlign(Value *V, SPRVValue *BV) {
  if (auto AL = dyn_cast<AllocaInst>(V)) {
    BM->setAlignment(BV, AL->getAlignment());
    return true;
  }
  if (auto GV = dyn_cast<GlobalVariable>(V)) {
    BM->setAlignment(BV, GV->getAlignment());
    return true;
  }
  return true;
}

/// Do this after source language is set.
bool
LLVMToSPRV::transBuiltinSet() {
  SPRVWord Ver = 0;
  SourceLanguage Kind = BM->getSourceLanguage(&Ver);
  assert(Kind == SourceLanguageOpenCL && "not supported");
  std::stringstream SS;
  SS << "OpenCL.std";
  return BM->importBuiltinSet(SS.str(), &BuiltinSetId);
}

bool
LLVMToSPRV::transCompileFlag() {
  BM->getCompileFlag() = getNamedMDAsString(M, SPIR_MD_COMPILER_OPTIONS);
  return true;
}

bool
LLVMToSPRV::oclIsSamplerType(llvm::Type* T) {
  auto PT = dyn_cast<PointerType>(T);
  if (!PT)
    return false;
  auto ST = dyn_cast<StructType>(PT->getElementType());
  if (!ST)
    return false;
  bool isSampler =
      ST->isOpaque() && ST->getStructName() == kSPR2TypeName::Sampler;
  return isSampler;
}

/// Transform sampler* spcv.cast(i32 arg)
/// Only two cases are possible:
///   arg = ConstantInt x -> SPRVConstantSampler
///   arg = i32 argument -> transValue(arg)
SPRVValue *
LLVMToSPRV::oclTransSpvcCastSampler(CallInst* CI, SPRVBasicBlock *BB) {
  llvm::Function* F = CI->getCalledFunction();
  auto FT = F->getFunctionType();
  auto RT = FT->getReturnType();
  assert(FT->getNumParams() == 1);
  auto ArgT = FT->getParamType(0);
  bool isSampler = oclIsSamplerType(RT);
  assert(isSampler && ArgT->isIntegerTy());
  auto Arg = CI->getArgOperand(0);
  auto Const = dyn_cast<ConstantInt>(Arg);
  if (Const) {
    auto Lit = Const->getZExtValue();
    auto AddrMode = (Lit & 0xE) >> 1;
    auto Param = Lit & 0x1;
    auto Filter = ((Lit & 0x30) >> 4) - 1;
    auto BV = BM->addSamplerConstant(transType(RT), AddrMode, Param, Filter);
    return BV;
  }
  auto BV = transValue(Arg, BB);
  assert(BV && BV->getType() == transType(RT));
  return BV;
}

SPRVValue *
LLVMToSPRV::transSpcvCast(CallInst* CI, SPRVBasicBlock *BB) {
  return oclTransSpvcCastSampler(CI, BB);
}

SPRVValue *
LLVMToSPRV::transCallInst(CallInst *CI, SPRVBasicBlock *BB) {
  SPRVExtInstSetKind BSK = SPRVEIS_Count;
  SPRVWord EntryPoint = SPRVWORD_MAX;
  llvm::Function* F = CI->getCalledFunction();
  auto MangledName = F->getName();
  std::string DemangledName;

  if (MangledName.startswith(SPCV_CAST))
    return transSpcvCast(CI, BB);

  if (MangledName.startswith("llvm.memcpy")) {
    std::vector<SPRVWord> MemoryAccess;

    if (isa<ConstantInt>(CI->getOperand(4)) &&
      dyn_cast<ConstantInt>(CI->getOperand(4))
      ->getZExtValue() == 1)
      MemoryAccess.push_back(SPRVMA_Volatile);
    if (isa<ConstantInt>(CI->getOperand(3))) {
        MemoryAccess.push_back(SPRVMA_Aligned);
        MemoryAccess.push_back(dyn_cast<ConstantInt>(CI->getOperand(3))
          ->getZExtValue());
    }

    return BM->addCopyMemorySizedInst(
      transValue(CI->getOperand(0), BB),
      transValue(CI->getOperand(1), BB),
      transValue(CI->getOperand(2), BB),
      MemoryAccess,
      BB);
  }

  if (oclIsBuiltin(MangledName, SrcLangVer, &DemangledName) ||
      isSPRVFunction(F, &DemangledName))
    if (auto BV = transOCLBuiltinToInst(CI, MangledName, DemangledName, BB))
      return BV;

  if (oclIsBuiltinTransToExtInst(CI->getCalledFunction(), &BSK, &EntryPoint))
    return BM->addExtInst(
        transType(CI->getType()),
        BuiltinSetId,
        EntryPoint,
        transArguments(CI, BB),
        BB);
  return BM->addCallInst(
      transFunction(CI->getCalledFunction()),
      transArguments(CI, BB),
      BB);
}

/// Remove entities not representable by SPIR-V
bool
LLVMToSPRV::regularize() {
  LLVMContext *Context = &M->getContext();

  oclRegularize();
  lowerConstantExpressions();

  std::set<Value *> ValuesForDeleting;
  for (auto I = M->begin(), E = M->end(); I != E;) {
    Function *F = I++;
    if (F->isDeclaration() && F->use_empty()) {
      F->eraseFromParent();
      continue;
    }

    for (auto BI = F->begin(), BE = F->end(); BI != BE; ++BI) {
      for (auto II = BI->begin(), IE = BI->end(); II != IE; ++II) {
        if (auto Call = dyn_cast<CallInst>(II)) {
          Call->setTailCall(false);
          if (Call->getCalledFunction()->isIntrinsic())
            removeFnAttr(Context, Call, Attribute::NoUnwind);

          // Remove useless convert function
          std::string DemangledName;
          auto MangledName = Call->getCalledFunction()->getName();
          if (oclIsBuiltin(MangledName, SrcLangVer, &DemangledName)) {
            if (DemangledName.find("convert_") == 0)
              if (!oclRegularizeConvert(Call, MangledName, DemangledName,
                  ValuesForDeleting))
                return false;
          }
        }
        // Remove optimization info not supported by SPRV
        if (auto BO = dyn_cast<BinaryOperator>(II)) {
          if (isa<OverflowingBinaryOperator>(BO)) {
            if (BO->hasNoUnsignedWrap())
              BO->setHasNoUnsignedWrap(false);
            if (BO->hasNoSignedWrap())
              BO->setHasNoSignedWrap(false);
          }
          if (isa<PossiblyExactOperator>(BO) && BO->isExact())
            BO->setIsExact(false);
        }
        // Remove metadata not supported by SPRV
        static const char *MDs[] = {
            "fpmath",
            "tbaa",
            "range",
        };
        for (auto &MDName:MDs) {
          if (II->getMetadata(MDName)) {
            II->setMetadata(MDName, nullptr);
          }
        }
      }
    }
  }

  for (auto &I:ValuesForDeleting)
    if (auto Inst = dyn_cast<Instruction>(I)) {
      Inst->dropAllReferences();
      Inst->removeFromParent();
    }
  for (auto &I : ValuesForDeleting)
    if (auto GV = dyn_cast<GlobalValue>(I)) {
      GV->dropAllReferences();
      GV->removeFromParent();
    }

  std::string Err;
  raw_string_ostream ErrorOS(Err);
  if (verifyModule(*M, &ErrorOS)){
    SPRVDBG(errs() << "Fails to verify module: " << ErrorOS.str();)
    return false;
  }

  if (SPRVDbgSaveRegularizedModule)
    saveLLVMModule(M, RegularizedModuleTmpFile);
  return true;
}

/// Remove trivial conversion functions
bool
LLVMToSPRV::oclRegularizeConvert(CallInst *CI, const std::string &MangledName,
    const std::string &DemangledName,
    std::set<Value *>& ValuesForDeleting) {
  auto TargetTy = CI->getType();
  auto SrcTy = CI->getArgOperand(0)->getType();
  if (isa<VectorType>(TargetTy))
    TargetTy = TargetTy->getVectorElementType();
  if (isa<VectorType>(SrcTy))
    SrcTy = SrcTy->getVectorElementType();
  if (TargetTy == SrcTy) {
    if (isa<IntegerType>(TargetTy) &&
        DemangledName.find("_sat") != std::string::npos &&
        isFuncParamSigned(MangledName) != (DemangledName[8] != 'u'))
      return true;
    CI->getArgOperand(0)->takeName(CI);
    SPRVDBG(dbgs() << "[regularizeOCLConvert] " << *CI << " <- " <<
        *CI->getArgOperand(0) << '\n');
    CI->replaceAllUsesWith(CI->getArgOperand(0));
    ValuesForDeleting.insert(CI);
    ValuesForDeleting.insert(CI->getCalledFunction());
  }
  return true;
}

MDNode *
LLVMToSPRV::oclGetArgBaseTypeMetadata(Function *F) {
  return oclGetArgMetadata(F, SPIR_MD_KERNEL_ARG_BASE_TYPE);
}

MDNode *
LLVMToSPRV::oclGetArgAccessQualifierMetadata(Function *F) {
  return oclGetArgMetadata(F, SPIR_MD_KERNEL_ARG_ACCESS_QUAL);
}

MDNode *
LLVMToSPRV::oclGetKernelMetadata(Function *F) {
  NamedMDNode *KernelMDs = M->getNamedMetadata(SPIR_MD_KERNELS);
  if (!KernelMDs)
    return nullptr;

  for (unsigned I = 0, E = KernelMDs->getNumOperands(); I < E; ++I) {
    MDNode *KernelMD = KernelMDs->getOperand(I);
    if (KernelMD->getNumOperands() == 0)
      continue;
    Function *Kernel = mdconst::dyn_extract<Function>(KernelMD->getOperand(0)); 

    if (Kernel == F)
      return KernelMD;
  }
  return nullptr;
}

MDNode *
LLVMToSPRV::oclGetArgMetadata(Function *F, const std::string &MDName) {
  auto KernelMD = oclGetKernelMetadata(F);
  if (!KernelMD)
    return nullptr;

  for (unsigned MI = 1, ME = KernelMD->getNumOperands(); MI < ME; ++MI) {
    MDNode *MD = dyn_cast<MDNode>(KernelMD->getOperand(MI));
    if (!MD)
      continue;
    MDString *NameMD = dyn_cast<MDString>(MD->getOperand(0));
    if (!NameMD)
      continue;
    StringRef Name = NameMD->getString();
    if (Name == MDName) {
      return MD;
    }
  }
  return nullptr;
}


void
LLVMToSPRV::oclGetMutatedArgumentTypesByArgBaseTypeMetadata(
    llvm::FunctionType* FT,
    std::map<unsigned, Type*>& ChangedType, Function* F) {
  auto TypeMD = oclGetArgBaseTypeMetadata(F);
  if (!TypeMD)
    return;
  auto PI = FT->param_begin();
  for (unsigned I = 1, E = TypeMD->getNumOperands(); I != E; ++I, ++PI) {
    auto OCLTyStr = getMDOperandAsString(TypeMD, I);
    auto NewTy = *PI;
    if (OCLTyStr == OCL_TYPE_NAME_SAMPLER_T && !NewTy->isStructTy()) {
      ChangedType[I - 1] = getOrCreateOpaquePtrType(M,
          kSPR2TypeName::Sampler);
    } else if (isPointerToOpaqueStructType(NewTy)) {
      auto STName = NewTy->getPointerElementType()->getStructName();
      if (STName.startswith(kSPR2TypeName::ImagePrefix)) {
        auto Ty = STName.str();
        auto AccMD = oclGetArgAccessQualifierMetadata(F);
        auto AccStr = getMDOperandAsString(AccMD, I);
        ChangedType[I - 1] = getOrCreateOpaquePtrType(M,
            Ty + kSPR2TypeName::Delimiter + AccStr);
      } else if (STName == SPIR_TYPE_NAME_PIPE_T) {
        auto Ty = STName.str();
        auto AccMD = oclGetArgAccessQualifierMetadata(F);
        auto AccStr = getMDOperandAsString(AccMD, I);
        ChangedType[I - 1] = getOrCreateOpaquePtrType(M,
            Ty + kSPR2TypeName::Delimiter + AccStr);
      }
    }
  }
}


void
LLVMToSPRV::mutateFunctionType(const std::map<unsigned, Type*>& ChangedType,
    llvm::FunctionType* &FT) {
  if (ChangedType.empty())
    return;
  std::vector<Type*> ArgTys;
  getFunctionTypeParameterTypes(FT, ArgTys);
  for (auto& I : ChangedType)
    ArgTys[I.first] = I.second;
  FT = FunctionType::get(FT->getReturnType(), ArgTys, FT->isVarArg());
}

// OCL sampler, image and pipe type need to be regularized before converting
// to SPIRV types.
//
// OCL sampler type is represented as i32 in LLVM, however in SPIRV it is
// represented as OpTypeSampler. Also LLVM uses the same pipe type to
// represent pipe types with different underlying data types, however
// in SPIRV they are different types. OCL image and pipie types do not
// encode access qualifier, which is part of SPIRV types for image and pipe.
//
// The function types in LLVM need to be regularized before translating
// to SPIRV function types:
//
// sampler type as i32 -> opencl.sampler_t opaque type
// opencl.pipe_t opaque type with underlying opencl type x and access
//   qualifier y -> opencl.pipe_t.x.y opaque type
// opencl.image_x opaque type with access qualifier y ->
//     opencl.image_x.y opaque type
//
// The converter relies on kernel_arg_base_type to identify the sampler
// type, the underlying data type of pipe type, and access qualifier for
// image and pipe types. The FE is responsible to generate the correct
// kernel_arg_base_type metadata.
//
// Alternatively,the FE may choose to use opencl.sampler_t to represent
// sampler type, use opencl.pipe_t.x.y to represent pipe type with underlying
// opencl data type x and access qualifier y, and use opencl.image_x.y to
// represent image_x type with access qualifier y.
//
FunctionType *
LLVMToSPRV::oclGetRegularizedFunctionType(Function *F) {
  auto FT = F->getFunctionType();
  std::map<unsigned, Type *> ChangedType;
  oclGetMutatedArgumentTypesByArgBaseTypeMetadata(FT, ChangedType, F);
  mutateFunctionType(ChangedType, FT);
  return FT;
}

bool
LLVMToSPRV::transAddressingMode() {
  Triple TargetTriple(M->getTargetTriple());
  Triple::ArchType Arch = TargetTriple.getArch();

  SPRVCKRT(Arch == Triple::spir || Arch == Triple::spir64,
      InvalidTargetTriple,
      "Actual target triple is " + M->getTargetTriple());

  if (Arch == Triple::spir)
    BM->setAddressingModel(SPRVAM_Physical32);
  else
    BM->setAddressingModel(SPRVAM_Physical64);
  return true;
}

std::vector<SPRVValue*>
LLVMToSPRV::transValue(const std::vector<Value *> &Args, SPRVBasicBlock* BB) {
  std::vector<SPRVValue*> BArgs;
  for (auto &I: Args)
    BArgs.push_back(transValue(I, BB));
  return BArgs;
}

std::vector<SPRVValue*>
LLVMToSPRV::transArguments(CallInst *CI, SPRVBasicBlock *BB) {
  return transValue(getArguments(CI), BB);
}

SPRVWord
LLVMToSPRV::transFunctionControlMask(CallInst *CI) {
  SPRVWord FCM = 0;
  SPIRSPRVFuncCtlMaskMap::foreach([&](Attribute::AttrKind Attr,
      SPRVFunctionControlMaskKind Mask){
    if (CI->hasFnAttr(Attr))
      FCM |= Mask;
  });
  return FCM;
}

SPRVWord
LLVMToSPRV::transFunctionControlMask(Function *F) {
  SPRVWord FCM = 0;
  SPIRSPRVFuncCtlMaskMap::foreach([&](Attribute::AttrKind Attr,
      SPRVFunctionControlMaskKind Mask){
    if (F->hasFnAttribute(Attr))
      FCM |= Mask;
  });
  return FCM;
}

bool
LLVMToSPRV::transGlobalVariables() {
  for (auto I = M->global_begin(),
            E = M->global_end(); I != E; ++I) {
    if (!transValue(I, nullptr))
      return false;
  }
  return true;
}

void
LLVMToSPRV::mutateFuncArgType(const std::map<unsigned, Type*>& ChangedType,
    Function* F) {
  for (auto &I : ChangedType) {
    for (auto UI = F->user_begin(), UE = F->user_end(); UI != UE; ++UI) {
      auto Call = dyn_cast<CallInst>(*UI);
      if (!Call)
        continue;
      auto Arg = Call->getArgOperand(I.first);
      auto OrigTy = Arg->getType();
      if (OrigTy == I.second)
        continue;
      SPRVDBG(dbgs() << "[mutate arg type] " << *Call << ", " << *Arg << '\n');
      auto CastF = M->getOrInsertFunction(SPCV_CAST, I.second, OrigTy, nullptr);
      std::vector<Value *> Args;
      Args.push_back(Arg);
      auto Cast = CallInst::Create(CastF, Args, "", Call);
      Call->replaceUsesOfWith(Arg, Cast);
      SPRVDBG(dbgs() << "[mutate arg type] -> " << *Cast << '\n');
    }
  }
}

bool
LLVMToSPRV::translate() {
  if (!transSourceLanguage())
    return false;
  if (!transSourceExtension())
    return false;
  if (!regularize())
    return false;
  if (!transCompileFlag())
    return false;
  if (!transOCLBuiltinsToVariables())
    return false;
  if (!transBuiltinSet())
    return false;
  if (!transAddressingMode())
    return false;
  if (!transGlobalVariables())
    return false;

  for (Module::iterator I = M->begin(), E = M->end(); I != E; ++I) {
    Function *F = I;
    auto FT = F->getFunctionType();
    std::map<unsigned, Type *> ChangedType;
    oclGetMutatedArgumentTypesByBuiltin(FT, ChangedType, F);
    mutateFuncArgType(ChangedType, F);
  }

  for (Module::iterator I = M->begin(), E = M->end(); I != E; ++I) {
    if (oclIsBuiltinTransToInst(I) || oclIsBuiltinTransToExtInst(I)
        || I->getName().startswith(SPCV_CAST) || I->getName().startswith(LLVM_MEMCPY))
      continue;
    transFunction(I);
    // Creating all basic blocks before creating any instruction.
    for (Function::iterator FI = I->begin(), FE = I->end(); FI != FE; ++FI) {
      transValue(FI, nullptr);
    }
    for (Function::iterator FI = I->begin(), FE = I->end(); FI != FE; ++FI) {
      SPRVBasicBlock *BB = static_cast<SPRVBasicBlock*>(
          transValue(FI, nullptr));
      for (BasicBlock::iterator BI = FI->begin(), BE = FI->end(); BI != BE;
          ++BI) {
        transValue(BI, BB, false);
      }
    }
  }
  if (!transOCLKernelMetadata())
    return false;
  if (!transFPContractMetadata())
    return false;

  BM->optimizeDecorates();
  return true;
}

llvm::IntegerType* LLVMToSPRV::getSizetType() {
  return IntegerType::getIntNTy(M->getContext(),
    M->getDataLayout()->getPointerSizeInBits());
}


SPRVValue *
LLVMToSPRV::transOCLAsyncGroupCopy(CallInst *CI, const std::string &MangledName,
    const std::string &DemangledName, SPRVBasicBlock *BB) {
  auto Args = getArguments(CI);
  if (DemangledName == "async_work_group_copy") {
    Args.insert(Args.begin()+3, ConstantInt::get(getSizetType(), 1));
  }
  auto BArgs = transValue(Args, BB);
  return BM->addAsyncGroupCopy(ScopeWorkgroup, BArgs[0], BArgs[1], BArgs[2],
      BArgs[3], BArgs[4], BB);
}

SPRVValue *
LLVMToSPRV::transOCLGroupBuiltins(CallInst *CI, const std::string &MangledName,
    const std::string &DemangledName, SPRVBasicBlock *BB) {
  auto Args = getArguments(CI);
  auto BArgs = transValue(Args, BB);
  auto Ty = CI->getType();
  return BM->addGroupInst(OCLSPRVBuiltinMap::map(DemangledName),
      Ty->isVoidTy() ? nullptr : transType(Ty),
      ScopeWorkgroup, BArgs, BB);
}

SPRVWord LLVMToSPRV::oclGetVectorLoadWidth(const std::string& DemangledName) {
  SPRVWord Width = 0;
  if (DemangledName == "vloada_half")
    Width = 1;
  else {
    unsigned Loc = 5;
    if (DemangledName.find("vload_half") == 0)
      Loc = 10;
    else if (DemangledName.find("vloada_half") == 0)
      Loc = 11;

    std::stringstream SS(DemangledName.substr(Loc));
    SS >> Width;
  }
  return Width;
}

SPRVValue *
LLVMToSPRV::transOCLVectorLoadStore(CallInst *CI,
    const std::string &MangledName,
    const std::string &DemangledName, SPRVBasicBlock *BB) {
  std::vector<SPRVWord> Args;
  for (unsigned I = 0, E = CI->getNumArgOperands(); I != E; ++I)
    Args.push_back(transValue(CI->getArgOperand(I), BB)->getId());
  if (DemangledName.find("vload") == 0 &&
      DemangledName != "vload_half") {
    SPRVWord Width = oclGetVectorLoadWidth(DemangledName);
    SPRVDBG(bildbgs() << "[transOCLVectorLoadStore] DemangledName: " <<
        DemangledName << " Width: " << Width << '\n');
    Args.push_back(Width);
  } else if (DemangledName.find("_r") != std::string::npos) {
    Args.push_back(SPIRSPRVFPRoundingModeMap::map(DemangledName.substr(
        DemangledName.find("_r") + 1, 3)));
  }

  SPRVExtInstSetKind BSK = SPRVEIS_Count;
  SPRVWord EntryPoint = SPRVWORD_MAX;
  bool Found = oclIsBuiltinTransToExtInst(CI->getCalledFunction(), &BSK,
      &EntryPoint);
  assert (Found);
  return BM->addExtInst(
      transType(CI->getType()),
      BuiltinSetId,
      EntryPoint,
      Args,
      BB);
}

SPRVValue *
LLVMToSPRV::oclTransBarrier(CallInst *CI,
    const std::string &DemangledName, SPRVBasicBlock *BB) {
  assert(CI->getNumArgOperands() == 1);
  auto MemFenceFlagVal = CI->getArgOperand(0);
  assert(isa<ConstantInt>(MemFenceFlagVal));
  SPRVValue * CB = BM->addControlBarrierInst(ScopeWorkgroup, ScopeWorkgroup,
    mapBitMask<OCLMemFenceMap>(dyn_cast<ConstantInt>(
    MemFenceFlagVal)->getZExtValue()), BB);
  return CB;
}

SPRVValue *
LLVMToSPRV::oclTransWorkGroupBarrier(CallInst *CI,
    const std::string &DemangledName, SPRVBasicBlock *BB) {
  assert(CI->getNumArgOperands() == 1 || CI->getNumArgOperands() == 3);
  Value *MemFenceFlagVal = CI->getArgOperand(0);
  assert(isa<ConstantInt>(MemFenceFlagVal));

  if (CI->getNumArgOperands() == 1){
    return BM->addControlBarrierInst(ScopeWorkgroup, ScopeWorkgroup,
      mapBitMask<OCLMemFenceMap>(dyn_cast<ConstantInt>
      (MemFenceFlagVal)->getZExtValue()), BB);
  }

  Value *MemScopeVal = CI->getArgOperand(1);
  assert(isa<ConstantInt>(MemScopeVal));
  assert(dyn_cast<ConstantInt>(MemScopeVal)->getZExtValue() <= OCLMS_sub_group);

  SPRVValue * CB = BM->addControlBarrierInst(ScopeWorkgroup,
    OCLMemScopeMap::map(static_cast<OCLMemScopeKind>(
    dyn_cast<ConstantInt>(MemScopeVal)->getZExtValue())),
    mapBitMask<OCLMemFenceMap>(dyn_cast<ConstantInt>
    (MemFenceFlagVal)->getZExtValue()), BB);
  return CB;
}

void
LLVMToSPRV::oclGetMutatedArgumentTypesByBuiltin(
    llvm::FunctionType* FT, std::map<unsigned, Type*>& ChangedType,
    Function* F) {
  auto Name = F->getName();
  std::string Demangled;
  if (!oclIsBuiltin(Name, SrcLangVer, &Demangled))
    return;
  if (Demangled.find(kOCLBuiltinName::ReadImage) != 0 ||
      Name.find(kMangledName::Sampler) == std::string::npos)
    return;
  ChangedType[1] = getOrCreateOpaquePtrType(F->getParent(),
      kSPR2TypeName::Sampler);
}

SPRVInstruction *
LLVMToSPRV::transOCLBuiltinToInstByMap(const std::string& DemangledName,
    const std::string &MangledName, CallInst* CI, SPRVBasicBlock* BB) {
  auto OC = getSPRVFuncOC(DemangledName);
  OCLBuiltinSPRVTransInfo Info;

  if (OC == OpNop) {
    getOCLBuiltinSPRVTransInfo(Info, CI, MangledName, DemangledName);
    OCLSPRVBuiltinMap::find(Info.UniqName, &OC);
  }

  if (OC != OpNop) {
    if (isCmpOpCode(OC)) {
      assert(CI && CI->getNumArgOperands() == 2 && "Invalid call inst");
      auto ResultTy = CI->getType();
      Type *BoolTy = IntegerType::getInt1Ty(M->getContext());
      auto IsVector = ResultTy->isVectorTy();
      if (IsVector)
        BoolTy = VectorType::get(BoolTy, ResultTy->getVectorNumElements());
      auto BT = transType(ResultTy);
      auto BBT = transType(BoolTy);
      auto Cmp = BM->addCmpInst(OC, BBT,
        transValue(CI->getArgOperand(0), BB),
        transValue(CI->getArgOperand(1), BB), BB);
      auto CastOC = IsVector ? OpSConvert : OpUConvert;
      return BM->addUnaryInst(CastOC, BT, Cmp, BB);
    } else if (isBinaryOpCode(OC)) {
      assert(CI && CI->getNumArgOperands() == 2 && "Invalid call inst");
      return BM->addBinaryInst(OC, transType(CI->getType()),
        transValue(CI->getArgOperand(0), BB),
        transValue(CI->getArgOperand(1), BB), BB);
    } else if (CI->getNumArgOperands() == 1 &&
        !CI->getType()->isVoidTy() &&
        Info.UniqName.find("group_") != 0 &&
        Info.UniqName.find("atomic_") != 0) {
      return BM->addUnaryInst(OC, transType(CI->getType()),
        transValue(CI->getArgOperand(0), BB), BB);
    } else {
      auto Args = getArguments(CI);
      SPRVType *SPRetTy = nullptr;
      Type *RetTy = CI->getType();
      auto F = CI->getCalledFunction();
      if (!RetTy->isVoidTy()) {
        SPRetTy = transType(RetTy);
      } else if (Args.size() > 0 && F->arg_begin()->hasStructRetAttr()) {
        SPRetTy = transType(F->arg_begin()->getType()->getPointerElementType());
        Args.erase(Args.begin());
      }
      std::vector<SPRVWord> SPArgs;
      for (auto I:Args) {
        SPArgs.push_back(transValue(I, BB)->getId());
      }
      Info.PostProc(SPArgs);
      auto SPI = BM->addInstTemplate(OC, SPArgs, BB, SPRetTy);
      if (!SPRetTy || !SPRetTy->isTypeStruct())
        return SPI;
      std::vector<SPRVWord> Mem;
      SPRVDBG(bildbgs() << *SPI << '\n');
      return BM->addStoreInst(transValue(CI->getArgOperand(0), BB), SPI,
          Mem, BB);
    }
  }

  return nullptr;
}

SPRVValue *
LLVMToSPRV::transOCLBuiltinToInst(CallInst *CI, const std::string &MangledName,
    const std::string &DemangledName, SPRVBasicBlock *BB) {
  if (DemangledName == "barrier")
    return oclTransBarrier(CI, DemangledName, BB);
  if (DemangledName == "work_group_barrier")
    return oclTransWorkGroupBarrier(CI, DemangledName, BB);
  if (DemangledName.find("convert_") == 0)
    return transOCLConvert(CI, MangledName, DemangledName, BB);
  if (DemangledName.find("vload") == 0 ||
      DemangledName.find("vstore") == 0)
    return transOCLVectorLoadStore(CI, MangledName, DemangledName, BB);
  if (DemangledName.find("async_work_group") == 0)
    return transOCLAsyncGroupCopy(CI, MangledName, DemangledName, BB);
  if (DemangledName == "wait_group_events")
    return transOCLGroupBuiltins(CI, MangledName, DemangledName, BB);
  return transOCLBuiltinToInstByMap(DemangledName, MangledName, CI, BB);
}

void
LLVMToSPRV::eraseSubstitutionFromMangledName(std::string& MangledName) {
  auto Len = MangledName.length();
  while (Len >= 2 && MangledName.substr(Len - 2, 2) == "S_") {
    Len -= 2;
    MangledName.erase(Len, 2);
  }
}

bool
LLVMToSPRV::isFuncParamSigned(const std::string& MangledName) {
  auto Copy = MangledName;
  eraseSubstitutionFromMangledName(Copy);
  char Mangled = Copy.back();
  bool Signed = true;
  if (isMangledTypeUnsigned(Mangled))
    Signed = false;
  return Signed;
}

SPRVValue *
LLVMToSPRV::transOCLConvert(CallInst *CI, const std::string &MangledName,
    const std::string &DemangledName, SPRVBasicBlock *BB) {
  Op OC = OpNop;
  auto TargetTy = CI->getType();
  auto SrcTy = CI->getArgOperand(0)->getType();
  if (isa<VectorType>(TargetTy))
    TargetTy = TargetTy->getVectorElementType();
  if (isa<VectorType>(SrcTy))
    SrcTy = SrcTy->getVectorElementType();
  auto IsTargetInt = isa<IntegerType>(TargetTy);
  auto IsSat = DemangledName.find("_sat") != std::string::npos;
  auto TargetSigned = DemangledName[8] != 'u';
  if (isa<IntegerType>(SrcTy)) {
    bool Signed = isFuncParamSigned(MangledName);
    if (IsTargetInt) {
      if (IsSat && TargetSigned != Signed)
        OC = Signed ? OpSatConvertSToU : OpSatConvertUToS;
      else
        OC = Signed ? OpSConvert : OpUConvert;
    }
    else
      OC = Signed ? OpConvertSToF : OpConvertUToF;
  } else {
    if (IsTargetInt) {
      OC = TargetSigned ? OpConvertFToS : OpConvertFToU;
    } else
      OC = OpFConvert;
  }
  auto V = BM->addUnaryInst(OC, transType(CI->getType()),
      transValue(CI->getArgOperand(0), BB), BB);
  auto Loc = DemangledName.find("_rt");
  if (Loc != std::string::npos) {
    auto Rounding = SPIRSPRVFPRoundingModeMap::map(
        DemangledName.substr(Loc + 1, 3));
    V->addFPRoundingMode(Rounding);
  }
  if (IsSat)
    V->setSaturatedConversion(true);
  return V;
}

bool
LLVMToSPRV::transFPContractMetadata() {
  NamedMDNode *KernelMDs = M->getNamedMetadata(SPIR_MD_ENABLE_FP_CONTRACT);
  if (KernelMDs)
    return true;
  for (auto I = M->begin(), E = M->end(); I != E; ++I) {
    if (!oclIsKernel(I))
      continue;
    SPRVFunction *BF = static_cast<SPRVFunction *>(getTranslatedValue(I));
    assert(BF && "Invalid kernel function");
    BF->addExecutionMode(new SPRVExecutionMode(BF, SPRVEM_ContractionOff));
  }
  return true;
}


bool
LLVMToSPRV::transOCLKernelMetadata() {
  NamedMDNode *KernelMDs = M->getNamedMetadata(SPIR_MD_KERNELS);
  std::vector<std::string> argAccessQual;
  if (!KernelMDs)
    return true;

  for (unsigned I = 0, E = KernelMDs->getNumOperands(); I < E; ++I) {
    MDNode *KernelMD = KernelMDs->getOperand(I);
    if (KernelMD->getNumOperands() == 0)
      continue;
    Function *Kernel = mdconst::dyn_extract<Function>(KernelMD->getOperand(0));

    SPRVFunction *BF = static_cast<SPRVFunction *>(getTranslatedValue(Kernel));
    assert(BF && "Kernel function should be translated first");
    assert(Kernel && oclIsKernel(Kernel)
            && "Invalid kernel calling convention or metadata");
    for (unsigned MI = 1, ME = KernelMD->getNumOperands(); MI < ME; ++MI) {
      MDNode *MD = dyn_cast<MDNode>(KernelMD->getOperand(MI));
      if (!MD)
        continue;
      MDString *NameMD = dyn_cast<MDString>(MD->getOperand(0));
      if (!NameMD)
        continue;
      StringRef Name = NameMD->getString();
      if (Name == SPIR_MD_WORK_GROUP_SIZE_HINT) {
        unsigned X, Y, Z;
        decodeMDNode(MD, X, Y, Z);
        BF->addExecutionMode(new SPRVExecutionMode(BF, SPRVEM_LocalSizeHint,
            X, Y, Z));
      } else if (Name == SPIR_MD_REQD_WORK_GROUP_SIZE) {
        unsigned X, Y, Z;
        decodeMDNode(MD, X, Y, Z);
        BF->addExecutionMode(new SPRVExecutionMode(BF, SPRVEM_LocalSize,
            X, Y, Z));
      } else if (Name == SPIR_MD_VEC_TYPE_HINT) {
        Type *HintTy = nullptr;
        std::string HintTyStr = decodeVecTypeHintMDNode(MD, HintTy);
        BF->addExecutionMode(new SPRVExecutionMode(BF, SPRVEM_VecTypeHint,
            transType(HintTy)->getId(), HintTyStr));
      } else if (Name == SPIR_MD_KERNEL_ARG_ADDR_SPACE) {
        // Do nothing
      } else if (Name == SPIR_MD_KERNEL_ARG_ACCESS_QUAL) {
        // Do nothing
      } else if (Name == SPIR_MD_KERNEL_ARG_TYPE) {
        // Do nothing
      } else if (Name == SPIR_MD_KERNEL_ARG_BASE_TYPE) {
        //Do nothing
      } else if (Name == SPIR_MD_KERNEL_ARG_TYPE_QUAL) {
        foreachKernelArgMD(MD, BF,
            [](const std::string &Str, SPRVFunctionParameter *BA){
          if (Str.find("volatile") != std::string::npos)
            BA->addDecorate(new SPRVDecorate(DecorationVolatile, BA));
          if (Str.find("restrict") != std::string::npos)
            BA->addDecorate(new SPRVDecorate(DecorationFuncParamAttr,
                BA, SPRVFPA_NoAlias));
          if (Str.find("const") != std::string::npos)
            BA->addDecorate(new SPRVDecorate(DecorationFuncParamAttr,
                BA, SPRVFPA_Const));
          });
      } else if (Name == SPIR_MD_KERNEL_ARG_NAME) {
        foreachKernelArgMD(MD, BF,
            [=](const std::string &Str, SPRVFunctionParameter *BA){
            BM->setName(BA, Str);
          });
      }
    }
  }
  return true;
}

bool
LLVMToSPRV::transSourceLanguage() {
  SrcLangVer = getOCLVersion(M);
  BM->setSourceLanguage(SourceLanguageOpenCL, SrcLangVer);
  return true;
}

/// SPIR-V does not separate OpenCL extensions with optional core features,
/// so put them together.
bool
LLVMToSPRV::transSourceExtension() {
  std::string OCLExtensions = getNamedMDAsString(M, SPIR_MD_USED_EXTENSIONS);
  std::string OCLOptionalCoreFeatures = getNamedMDAsString(M,
      SPIR_MD_USED_OPTIONAL_CORE_FEATURES);

  auto S = concat(OCLOptionalCoreFeatures, OCLExtensions);

  BM->setSourceExtension(S);
  for (auto &I:map<SPRVCapabilityKind>(rmap<OclExt::Kind>(getSet(S))))
    BM->addCapability(I);

  return true;
}

void
LLVMToSPRV::dumpUsers(Value* V) {
  SPRVDBG(dbgs() << "Users of " << *V << " :\n");
  for (auto UI = V->user_begin(), UE = V->user_end();
      UI != UE; ++UI)
    SPRVDBG(dbgs() << "  " << **UI << '\n');
}

void
LLVMToSPRV::oclRegularize() {
  PassManager PassMgr;
  PassMgr.add(createPromoteMemoryToRegisterPass());
  PassMgr.add(createSPRVRegularizeOCL20());
  PassMgr.add(createSPRVLowerOCLBlocks());
  PassMgr.add(createSPRVLowerBool());
  PassMgr.run(*M);
  eraseUselessFunctions(M);
}

Op
LLVMToSPRV::transBoolOpCode(SPRVValue* Opn, Op OC) {
  if (!Opn->getType()->isTypeVectorOrScalarBool())
    return OC;
  IntBoolOpMap::find(OC, &OC);
  return OC;
}

SPRVId LLVMToSPRV::addInt32(int I) {
  return transValue(getInt32(M, I), nullptr, false)->getId();
}

}

bool
llvm::WriteSPRV(Module *M, std::ostream &OS, std::string &ErrMsg) {
  std::unique_ptr<SPRVModule> BM(SPRVModule::createSPRVModule());
  LLVMToSPRV LTB(M, BM.get());
  if (!LTB.translate()) {
    BM->getError(ErrMsg);
    return false;
  }
  OS << *BM;
  return true;
}

bool
llvm::RegularizeLLVMForSPRV(Module *M, std::string &ErrMsg) {
  std::unique_ptr<SPRVModule> BM(SPRVModule::createSPRVModule());
  LLVMToSPRV LTB(M, BM.get());
  if (!LTB.regularize()) {
    BM->getError(ErrMsg);
    return false;
  }
  return true;
}


