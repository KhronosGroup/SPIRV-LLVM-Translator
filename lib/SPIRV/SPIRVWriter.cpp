//===- SPIRVWriter.cpp - Converts LLVM to SPIR-V ----------------*- C++ -*-===//
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

#include "SPIRVModule.h"
#include "SPIRVEnum.h"
#include "SPIRVEntry.h"
#include "SPIRVType.h"
#include "SPIRVValue.h"
#include "SPIRVFunction.h"
#include "SPIRVBasicBlock.h"
#include "SPIRVInstruction.h"
#include "SPIRVExtInst.h"
#include "SPIRVUtil.h"
#include "SPIRVInternal.h"
#include "SPIRVMDWalker.h"
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
#include "llvm/Pass.h"
#include "llvm/PassSupport.h"
#include "llvm/PassManager.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/CommandLine.h"
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
using namespace SPIRV;
using namespace OCLUtil;

namespace llvm {
  FunctionPass *createPromoteMemoryToRegisterPass();
}

namespace SPIRV{

cl::opt<bool> SPIRVMemToReg("spirv-mem2reg", cl::init(true),
    cl::desc("LLVM/SPIR-V translation enable mem2reg"));


static void
foreachKernelArgMD(MDNode *MD, SPIRVFunction *BF,
    std::function<void(const std::string& Str,
        SPIRVFunctionParameter *BA)>Func) {
  for (unsigned I = 1, E = MD->getNumOperands(); I != E; ++I) {
    SPIRVFunctionParameter *BA = BF->getArgument(I-1);
    Func(getMDOperandAsString(MD, I), BA);
  }
}

/// Information for translating OCL builtin.
struct OCLBuiltinSPIRVTransInfo {
  std::string UniqName;
  /// Postprocessor of operands
  std::function<void(std::vector<SPIRVWord>&)> PostProc;
  OCLBuiltinSPIRVTransInfo(){
    PostProc = [](std::vector<SPIRVWord>&){};
  }
};

class LLVMToSPIRVDbgTran {
public:
  LLVMToSPIRVDbgTran(Module *TM = nullptr, SPIRVModule *TBM = nullptr)
  :BM(TBM), M(TM){
  }

  void setModule(Module *Mod) { M = Mod;}
  void setSPIRVModule(SPIRVModule *SMod) { BM = SMod;}

  void transDbgInfo(Value *V, SPIRVValue *BV) {
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
  SPIRVModule *BM;
  Module *M;
};

class LLVMToSPIRV: public ModulePass {
public:
  LLVMToSPIRV(SPIRVModule *SMod = nullptr)
      : ModulePass(ID),
        M(nullptr),
        Ctx(nullptr),
        BM(SMod),
        ExtSetId(SPIRVID_INVALID),
        SrcLang(0),
        SrcLangVer(0),
        DbgTran(nullptr, SMod){
  }

  bool runOnModule(Module &Mod) override {
    M = &Mod;
    Ctx = &M->getContext();
    DbgTran.setModule(M);
    assert(BM && "SPIR-V module not initialized");
    translate();
    return true;
  }

  static char ID;

  SPIRVType *transType(Type *T);

  SPIRVValue *getTranslatedValue(Value *);

  // Translation functions
  bool transAddressingMode();
  bool transAlign(Value *V, SPIRVValue *BV);
  std::vector<SPIRVValue *> transArguments(CallInst *, SPIRVBasicBlock *);
  std::vector<SPIRVWord> transArguments(CallInst *, SPIRVBasicBlock *,
      SPIRVEntry *);
  bool transSourceLanguage();
  bool transExtension();
  bool transBuiltinSet();
  SPIRVValue *transCallInst(CallInst *Call, SPIRVBasicBlock *BB);
  bool transDecoration(Value *V, SPIRVValue *BV);
  SPIRVWord transFunctionControlMask(CallInst *);
  SPIRVWord transFunctionControlMask(Function *);
  SPIRVFunction *transFunctionDecl(Function *F);
  bool transGlobalVariables();

  Op transBoolOpCode(SPIRVValue *Opn, Op OC);
  // Translate LLVM module to SPIR-V module.
  // Returns true if succeeds.
  bool translate();
  bool transExecutionMode();
  SPIRVValue *transConstant(Value *V);
  SPIRVValue *transValue(Value *V, SPIRVBasicBlock *BB,
      bool CreateForward = true);
  SPIRVValue *transValueWithoutDecoration(Value *V, SPIRVBasicBlock *BB,
      bool CreateForward = true);

  typedef DenseMap<Type *, SPIRVType *> LLVMToSPIRVTypeMap;
  typedef DenseMap<Value *, SPIRVValue *> LLVMToSPIRVValueMap;
private:
  Module *M;
  LLVMContext *Ctx;
  SPIRVModule *BM;
  LLVMToSPIRVTypeMap TypeMap;
  LLVMToSPIRVValueMap ValueMap;
  //ToDo: support multiple builtin sets. Currently assume one builtin set.
  SPIRVId ExtSetId;
  SPIRVWord SrcLang;
  SPIRVWord SrcLangVer;
  LLVMToSPIRVDbgTran DbgTran;

  SPIRVType *mapType(Type *T, SPIRVType *BT) {
    TypeMap[T] = BT;
    return BT;
  }

  SPIRVValue *mapValue(Value *V, SPIRVValue *BV) {
    auto Loc = ValueMap.find(V);
    if (Loc != ValueMap.end()) {
      if (Loc->second == BV)
        return BV;
      assert (Loc->second->isForward() &&
          "LLVM Value is mapped to different SPIRV Values");
      auto Forward = static_cast<SPIRVForward *>(Loc->second);
      BV->setId(Forward->getId());
      BM->replaceForward(Forward, BV);
    }
    ValueMap[V] = BV;
    SPIRVDBG(dbgs() << "[mapValue] " << *V << " => ";
      spvdbgs() << *BV << "\n");
    return BV;
  }

  SPIRVType *getSPIRVType(Type *T) {
      return TypeMap[T];
  }

  SPIRVValue *getSPIRVValue(Value *V) {
      return ValueMap[V];
  }

  SPIRVErrorLog &getErrorLog() {
    return BM->getErrorLog();
  }

  llvm::IntegerType* getSizetType();
  std::vector<SPIRVValue*> transValue(const std::vector<Value *> &Values,
      SPIRVBasicBlock* BB);
  std::vector<SPIRVWord> transValue(const std::vector<Value *> &Values,
      SPIRVBasicBlock* BB, SPIRVEntry *Entry);

  SPIRVInstruction* transBinaryInst(BinaryOperator* B, SPIRVBasicBlock* BB);
  SPIRVInstruction* transCmpInst(CmpInst* Cmp, SPIRVBasicBlock* BB);
  void mutateFunctionType(const std::map<unsigned, Type*>& ChangedType,
      llvm::FunctionType* &FT);

  void dumpUsers(Value *V);

  MDNode *oclGetArgBaseTypeMetadata(Function *);
  MDNode *oclGetArgAccessQualifierMetadata(Function *);
  MDNode *oclGetArgMetadata(Function *, const std::string& MDName);
  template<class ExtInstKind>
  bool oclGetExtInstIndex(const std::string &MangledName,
      const std::string& DemangledName, SPIRVWord* EntryPoint);
  MDNode *oclGetKernelMetadata(Function *F);
  void oclGetMutatedArgumentTypesByArgBaseTypeMetadata(llvm::FunctionType* FT,
      std::map<unsigned, Type*>& ChangedType, Function* F);
  void oclGetMutatedArgumentTypesByBuiltin(llvm::FunctionType* FT,
      std::map<unsigned, Type*>& ChangedType, Function* F);
  FunctionType *oclGetRegularizedFunctionType(Function *);

  bool isBuiltinTransToInst(Function *F);
  bool isBuiltinTransToExtInst(Function *F,
      SPIRVExtInstSetKind *BuiltinSet = nullptr,
      SPIRVWord *EntryPoint = nullptr,
      SmallVectorImpl<std::string> *Dec = nullptr);
  bool oclIsKernel(Function *F);

  bool transOCLKernelMetadata();

  SPIRVInstruction *transBuiltinToInst(const std::string& DemangledName,
      const std::string &MangledName, CallInst* CI, SPIRVBasicBlock* BB);
  SPIRVInstruction *transBuiltinToInstWithoutDecoration(Op OC,
      CallInst* CI, SPIRVBasicBlock* BB);
  void mutateFuncArgType(const std::map<unsigned, Type*>& ChangedType,
      Function* F);
  bool oclIsSamplerType(llvm::Type* RT);

  SPIRVValue *transSpcvCast(CallInst* CI, SPIRVBasicBlock *BB);
  SPIRVValue *oclTransSpvcCastSampler(CallInst* CI, SPIRVBasicBlock *BB);

  SPIRV::SPIRVInstruction* transUnaryInst(UnaryInstruction* U,
      SPIRVBasicBlock* BB);

  /// Add a 32 bit integer constant.
  /// \return Id of the constant.
  SPIRVId addInt32(int);
  void transFunction(Function *I);
};


SPIRVValue *
LLVMToSPIRV::getTranslatedValue(Value *V) {
  LLVMToSPIRVValueMap::iterator Loc = ValueMap.find(V);
  if (Loc != ValueMap.end())
    return Loc->second;
  return nullptr;
}

bool
LLVMToSPIRV::oclIsKernel(Function *F) {
  if (F->getCallingConv() == CallingConv::SPIR_KERNEL)
    return true;
  return false;
}

bool
LLVMToSPIRV::isBuiltinTransToInst(Function *F) {
  std::string DemangledName;
  if (!oclIsBuiltin(F->getName(), SrcLangVer, &DemangledName) &&
      !isDecoratedSPIRVFunc(F, &DemangledName))
    return false;
  SPIRVDBG(spvdbgs() << "CallInst: demangled name: " << DemangledName << '\n');
  return getSPIRVFuncOC(DemangledName) != OpNop;
}

bool
LLVMToSPIRV::isBuiltinTransToExtInst(Function *F,
    SPIRVExtInstSetKind *ExtSet,
    SPIRVWord *ExtOp,
    SmallVectorImpl<std::string> *Dec) {
  std::string OrigName = F->getName();
  std::string DemangledName;
  if (!oclIsBuiltin(OrigName, SrcLangVer, &DemangledName))
    return false;
  DEBUG(dbgs() << "[oclIsBuiltinTransToExtInst] CallInst: demangled name: "
      << DemangledName << '\n');
  StringRef S = DemangledName;
  if (!S.startswith(kSPIRVName::Prefix))
    return false;
  S = S.drop_front(strlen(kSPIRVName::Prefix));
  auto Loc = S.find(kSPIRVPostfix::Divider);
  auto ExtSetName = S.substr(0, Loc);
  SPIRVExtInstSetKind Set = SPIRVEIS_Count;
  if (!SPIRVExtSetShortNameMap::rfind(ExtSetName, &Set))
    return false;
  assert(Set == BM->getBuiltinSet(ExtSetId) &&
      "Invalid extended instruction set");
  assert(Set == SPIRVEIS_OpenCL && "Unsupported extended instruction set");

  auto ExtOpName = S.substr(Loc + 1);
  auto Splited = ExtOpName.split(kSPIRVPostfix::ExtDivider);
  OCLExtOpKind EOC;
  if (!OCLExtOpMap::rfind(Splited.first, &EOC))
    return false;

  if (ExtSet)
    *ExtSet = Set;
  if (ExtOp)
    *ExtOp = EOC;
  if (Dec) {
    SmallVector<StringRef, 2> P;
    Splited.second.split(P, kSPIRVPostfix::Divider);
    for (auto &I:P)
      Dec->push_back(I.str());
  }
  return true;
}


SPIRVType *
LLVMToSPIRV::transType(Type *T) {
  LLVMToSPIRVTypeMap::iterator Loc = TypeMap.find(T);
  if (Loc != TypeMap.end())
    return Loc->second;

  SPIRVDBG(dbgs() << "[transType] " << *T << '\n');
  if (T->isVoidTy())
    return mapType(T, BM->addVoidType());

  if (T->isIntegerTy(1))
    return mapType(T, BM->addBoolType());

  if (T->isIntegerTy())
    return mapType(T, BM->addIntegerType(T->getIntegerBitWidth()));

  if (T->isFloatingPointTy())
    return mapType(T, BM->addFloatType(T->getPrimitiveSizeInBits()));

  // A pointer to image or pipe type in LLVM is translated to a SPIRV
  // sampler or pipe type.
  if (T->isPointerTy()) {
    auto ET = T->getPointerElementType();
    assert(!ET->isFunctionTy() && "Function pointer type is not allowed");
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
        PipeT->setPipeAcessQualifier(SPIRSPIRVAccessQualifierMap::map(Acc));
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
        auto Desc = map<SPIRVTypeImageDescriptor>(SubStrs[1].str());
        DEBUG(dbgs() << "[trans image type] " << SubStrs[1] << " => " <<
            "(" << (unsigned)Desc.Dim << ", " <<
                   Desc.Depth << ", " <<
                   Desc.Arrayed << ", " <<
                   Desc.MS << ", " <<
                   Desc.Sampled << ", " <<
                   Desc.Format << ")\n");
        auto VoidT = transType(Type::getVoidTy(*Ctx));
        return mapType(T, BM->addImageType(VoidT, Desc,
          SPIRSPIRVAccessQualifierMap::map(Acc)));
      } else if (STName == kSPR2TypeName::Sampler) {
        assert(AddrSpc == SPIRAS_Global);
        return mapType(T, BM->addSamplerType());
      } else if (STName.find(kSPIRVTypeName::SampledImg) == 0) {
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
            static_cast<SPIRVTypeImage *>(
                transType(getOrCreateOpaquePtrType(M, ImgTyName)))));
      }
      else if (BuiltinOpaqueGenericTypeOpCodeMap::find(STName, &OpCode)) {
        if (OpCode == OpTypePipe) {
          return mapType(T, BM->addPipeType());
        }
        return mapType(T, BM->addOpaqueGenericType(OpCode));
      }
      else if (isPointerToOpaqueStructType(T)) {
        return mapType(T, BM->addPointerType(SPIRSPIRVAddrSpaceMap::map(
          static_cast<SPIRAddressSpace>(AddrSpc)),
          transType(ET)));
      }
    } else  {
      return mapType(T, BM->addPointerType(SPIRSPIRVAddrSpaceMap::map(
        static_cast<SPIRAddressSpace>(AddrSpc)),
        transType(ET)));
    }
  }

  if (T->isVectorTy())
    return mapType(T, BM->addVectorType(transType(T->getVectorElementType()),
        T->getVectorNumElements()));

  if (T->isArrayTy())
    return mapType(T, BM->addArrayType(transType(T->getArrayElementType()),
        static_cast<SPIRVConstant*>(transValue(ConstantInt::get(getSizetType(),
            T->getArrayNumElements(), false), nullptr))));

  if (T->isStructTy() && !T->isSized()) {
    auto ST = dyn_cast<StructType>(T);
    assert(!ST->getName().startswith(SPIR_TYPE_NAME_PIPE_T));
    assert(!ST->getName().startswith(kSPR2TypeName::ImagePrefix));
    return mapType(T, BM->addOpaqueType(T->getStructName()));
  }

  if (auto ST = dyn_cast<StructType>(T)) {
    assert(ST->isSized());
    std::vector<SPIRVType *> MT;
    for (unsigned I = 0, E = T->getStructNumElements(); I != E; ++I)
      MT.push_back(transType(ST->getElementType(I)));
    std::string Name;
    if (ST->hasName())
      Name = ST->getName();
    return mapType(T, BM->addStructType(MT, Name, ST->isPacked()));
  }

  if (FunctionType *FT = dyn_cast<FunctionType>(T)) {
    SPIRVType *RT = transType(FT->getReturnType());
    std::vector<SPIRVType *> PT;
    for (FunctionType::param_iterator I = FT->param_begin(),
        E = FT->param_end(); I != E; ++I)
      PT.push_back(transType(*I));
    return mapType(T, BM->addFunctionType(RT, PT));
  }

  llvm_unreachable("Not implemented!");
  return 0;
}

SPIRVFunction *
LLVMToSPIRV::transFunctionDecl(Function *F) {
  if (auto BF= getTranslatedValue(F))
    return static_cast<SPIRVFunction *>(BF);

  SPIRVTypeFunction *BFT = static_cast<SPIRVTypeFunction *>(transType(
      oclGetRegularizedFunctionType(F)));
  SPIRVFunction *BF = static_cast<SPIRVFunction *>(mapValue(F,
      BM->addFunction(BFT)));
  BF->setFunctionControlMask(transFunctionControlMask(F));
  if (F->hasName())
    BM->setName(BF, F->getName());
  if (oclIsKernel(F))
    BM->addEntryPoint(ExecutionModelKernel, BF->getId());
  else if (F->getLinkage() != GlobalValue::InternalLinkage &&
           F->getLinkage() != GlobalValue::LinkOnceODRLinkage)
    BF->setLinkageType(SPIRSPIRVLinkageTypeMap::map(F->getLinkage()));
  auto Attrs = F->getAttributes();
  for (Function::arg_iterator I = F->arg_begin(), E = F->arg_end(); I != E;
      ++I) {
    auto ArgNo = I->getArgNo();
    SPIRVFunctionParameter *BA = BF->getArgument(ArgNo);
    if (I->hasName())
      BM->setName(BA, I->getName());
    if (I->hasByValAttr())
      BA->addAttr(FunctionParameterAttributeByVal);
    if (I->hasNoAliasAttr())
      BA->addAttr(FunctionParameterAttributeNoAlias);
    if (I->hasNoCaptureAttr())
      BA->addAttr(FunctionParameterAttributeNoCapture);
    if (I->hasStructRetAttr())
      BA->addAttr(FunctionParameterAttributeSret);
    if (Attrs.hasAttribute(ArgNo + 1, Attribute::ZExt))
      BA->addAttr(FunctionParameterAttributeZext);
    if (Attrs.hasAttribute(ArgNo + 1, Attribute::SExt))
      BA->addAttr(FunctionParameterAttributeSext);
  }
  if (Attrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::ZExt))
    BF->addDecorate(DecorationFuncParamAttr, FunctionParameterAttributeZext);
  if (Attrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::SExt))
    BF->addDecorate(DecorationFuncParamAttr, FunctionParameterAttributeSext);
  DbgTran.transDbgInfo(F, BF);
  SPIRVDBG(dbgs() << "[transFunction] " << *F << " => ";
    spvdbgs() << *BF << '\n';)
  return BF;
}

#define _SPIRV_OPL(x) OpLogical##x

#define _SPIRV_OPB(x) OpBitwise##x

SPIRVValue *
LLVMToSPIRV::transConstant(Value *V) {
  if (auto CPNull = dyn_cast<ConstantPointerNull>(V))
    return BM->addNullConstant(bcast<SPIRVTypePointer>(transType(
        CPNull->getType())));

  if (auto CAZero = dyn_cast<ConstantAggregateZero>(V))
    return BM->addNullConstant(transType(CAZero->getType()));

  if (auto ConstI = dyn_cast<ConstantInt>(V)) {
    SPIRVTypeInt *BT = static_cast<SPIRVTypeInt *>(transType(V->getType()));
    return BM->addIntegerConstant(BT, ConstI->getZExtValue());
  }

  if (auto ConstFP = dyn_cast<ConstantFP>(V)) {
    auto BT = static_cast<SPIRVType *>(transType(V->getType()));
    return BM->addConstant(BT,
        ConstFP->getValueAPF().bitcastToAPInt().getZExtValue());
  }

  if (auto ConstDA = dyn_cast<ConstantDataArray>(V)) {
    std::vector<SPIRVValue *> BV;
    for (unsigned I = 0, E = ConstDA->getNumElements(); I != E; ++I)
      BV.push_back(transValue(ConstDA->getElementAsConstant(I), nullptr));
    return BM->addCompositeConstant(transType(V->getType()), BV);
  }

  if (auto ConstA = dyn_cast<ConstantArray>(V)) {
    std::vector<SPIRVValue *> BV;
    for (auto I = ConstA->op_begin(), E = ConstA->op_end(); I != E; ++I)
      BV.push_back(transValue(*I, nullptr));
    return BM->addCompositeConstant(transType(V->getType()), BV);
  }

  if (auto ConstDV = dyn_cast<ConstantDataVector>(V)) {
    std::vector<SPIRVValue *> BV;
    for (unsigned I = 0, E = ConstDV->getNumElements(); I != E; ++I)
      BV.push_back(transValue(ConstDV->getElementAsConstant(I), nullptr));
    return BM->addCompositeConstant(transType(V->getType()), BV);
  }

  if (auto ConstV = dyn_cast<ConstantVector>(V)) {
    std::vector<SPIRVValue *> BV;
    for (auto I = ConstV->op_begin(), E = ConstV->op_end(); I != E; ++I)
      BV.push_back(transValue(*I, nullptr));
    return BM->addCompositeConstant(transType(V->getType()), BV);
  }

  if (auto ConstV = dyn_cast<ConstantStruct>(V)) {
    std::vector<SPIRVValue *> BV;
    for (auto I = ConstV->op_begin(), E = ConstV->op_end(); I != E; ++I)
      BV.push_back(transValue(*I, nullptr));
    return BM->addCompositeConstant(transType(V->getType()), BV);
  }

  if (auto ConstUE = dyn_cast<ConstantExpr>(V)) {
    auto Inst = ConstUE->getAsInstruction();
    SPIRVDBG(dbgs() << "ConstantExpr: " << *ConstUE << '\n';
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

SPIRVValue *
LLVMToSPIRV::transValue(Value *V, SPIRVBasicBlock *BB, bool CreateForward) {
  LLVMToSPIRVValueMap::iterator Loc = ValueMap.find(V);
  if (Loc != ValueMap.end() && (!Loc->second->isForward() || CreateForward))
    return Loc->second;

  SPIRVDBG(dbgs() << "[transValue] " << *V << '\n');
  assert ((!isa<Instruction>(V) || isa<GetElementPtrInst>(V) ||
      isa<CastInst>(V) || BB) &&
      "Invalid SPIRV BB");

  auto BV = transValueWithoutDecoration(V, BB, CreateForward);
  BM->setName(BV, V->getName());
  if(!transDecoration(V, BV))
    return nullptr;
  return BV;
}

SPIRVInstruction*
LLVMToSPIRV::transBinaryInst(BinaryOperator* B, SPIRVBasicBlock* BB) {
  unsigned LLVMOC = B->getOpcode();
  auto Op0 = transValue(B->getOperand(0), BB);
  SPIRVInstruction* BI = BM->addBinaryInst(
      transBoolOpCode(Op0, OpCodeMap::map(LLVMOC)),
      transType(B->getType()), Op0, transValue(B->getOperand(1), BB), BB);
  return BI;
}

SPIRVInstruction*
LLVMToSPIRV::transCmpInst(CmpInst* Cmp, SPIRVBasicBlock* BB) {
  auto Op0 = transValue(Cmp->getOperand(0), BB);
  SPIRVInstruction* BI = BM->addCmpInst(
      transBoolOpCode(Op0, CmpMap::map(Cmp->getPredicate())),
      transType(Cmp->getType()), Op0,
      transValue(Cmp->getOperand(1), BB), BB);
  return BI;
}

SPIRV::SPIRVInstruction *LLVMToSPIRV::transUnaryInst(UnaryInstruction *U,
                                                  SPIRVBasicBlock *BB) {
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
/// translated. SPIRVForward should be created as place holder for these
/// instructions and replaced later by the real instructions.
/// Use CreateForward = true to indicate such situation.
SPIRVValue *
LLVMToSPIRV::transValueWithoutDecoration(Value *V, SPIRVBasicBlock *BB,
    bool CreateForward) {
  if (auto LBB = dyn_cast<BasicBlock>(V)) {
    auto BF = static_cast<SPIRVFunction *>(getTranslatedValue(LBB->getParent()));
    assert (BF && "Function not translated");
    BB = static_cast<SPIRVBasicBlock *>(mapValue(V, BM->addBasicBlock(BF)));
    BM->setName(BB, LBB->getName());
    return BB;
  }

  if (auto F = dyn_cast<Function>(V))
    return transFunctionDecl(F);

  if (auto GV = dyn_cast<GlobalVariable>(V)) {
    auto BVar = static_cast<SPIRVVariable *>(BM->addVariable(
        transType(GV->getType()), GV->isConstant(),
        SPIRSPIRVLinkageTypeMap::map(GV->getLinkage()),
        GV->hasInitializer()?transValue(GV->getInitializer(), nullptr):nullptr,
        GV->getName(),
        SPIRSPIRVAddrSpaceMap::map(static_cast<SPIRAddressSpace>(
            GV->getType()->getAddressSpace())),
        nullptr
        ));
    mapValue(V, BVar);
    auto Builtin = spv::BuiltInCount;
    if (GV->hasName())
      Builtin = getSPIRVBuiltin(GV->getName().str());
    if (Builtin == spv::BuiltInCount)
      return BVar;
    BVar->setBuiltin(Builtin);
    return BVar;
  }

  if (isa<Constant>(V)) {
    auto BV = transConstant(V);
    assert(BV);
    return mapValue(V, BV);
  }

  if (auto Arg = dyn_cast<Argument>(V)) {
    unsigned ArgNo = Arg->getArgNo();
    SPIRVFunction *BF = BB->getParent();
    //assert(BF->existArgument(ArgNo));
    return mapValue(V, BF->getArgument(ArgNo));
  }

  if (CreateForward)
    return mapValue(V, BM->addForward(transType(V->getType())));

  if (StoreInst *ST = dyn_cast<StoreInst>(V)) {
    std::vector<SPIRVWord> MemoryAccess;
    if (ST->isVolatile())
      MemoryAccess.push_back(MemoryAccessVolatileMask);
    MemoryAccess.push_back(MemoryAccessAlignedMask);
    MemoryAccess.push_back(ST->getAlignment());
    return mapValue(V, BM->addStoreInst(
        transValue(ST->getPointerOperand(), BB),
        transValue(ST->getValueOperand(), BB),
        MemoryAccess, BB));
  }

  if (LoadInst *LD = dyn_cast<LoadInst>(V)) {
    std::vector<SPIRVWord> MemoryAccess;
    if (LD->isVolatile())
      MemoryAccess.push_back(MemoryAccessVolatileMask);
    MemoryAccess.push_back(MemoryAccessAlignedMask);
    MemoryAccess.push_back(LD->getAlignment());
    return mapValue(V, BM->addLoadInst(
        transValue(LD->getPointerOperand(), BB),
        MemoryAccess, BB));
  }

  if (BinaryOperator *B = dyn_cast<BinaryOperator>(V)) {
    SPIRVInstruction* BI = transBinaryInst(B, BB);
    return mapValue(V, BI);
  }

  if (auto RI = dyn_cast<ReturnInst>(V)) {
    if (auto RV = RI->getReturnValue())
      return mapValue(V, BM->addReturnValueInst(
          transValue(RV, BB), BB));
    return mapValue(V, BM->addReturnInst(BB));
  }

  if (CmpInst *Cmp = dyn_cast<CmpInst>(V)) {
    SPIRVInstruction* BI = transCmpInst(Cmp, BB);
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
      SPIRSPIRVLinkageTypeMap::map(GlobalValue::InternalLinkage),
      nullptr, Alc->getName(),
      StorageClassFunction, BB));

  if (auto *Switch = dyn_cast<SwitchInst>(V)) {
    std::vector<std::pair<SPIRVWord, SPIRVBasicBlock *>> Pairs;
    for (auto I = Switch->case_begin(), E = Switch->case_end(); I != E; ++I)
      Pairs.push_back(std::make_pair(I.getCaseValue()->getZExtValue(),
          static_cast<SPIRVBasicBlock*>(transValue(I.getCaseSuccessor(),
              nullptr))));
    return mapValue(V, BM->addSwitchInst(
        transValue(Switch->getCondition(), BB),
        static_cast<SPIRVBasicBlock*>(transValue(Switch->getDefaultDest(),
            nullptr)), Pairs, BB));
  }

  if (auto Branch = dyn_cast<BranchInst>(V)) {
    if (Branch->isUnconditional())
      return mapValue(V, BM->addBranchInst(
          static_cast<SPIRVLabel*>(transValue(Branch->getSuccessor(0), BB)),
          BB));
    return mapValue(V, BM->addBranchConditionalInst(
        transValue(Branch->getCondition(), BB),
        static_cast<SPIRVLabel*>(transValue(Branch->getSuccessor(0), BB)),
        static_cast<SPIRVLabel*>(transValue(Branch->getSuccessor(1), BB)),
        BB));
  }

  if (auto Phi = dyn_cast<PHINode>(V)) {
    std::vector<SPIRVValue *> IncomingPairs;
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
    std::vector<SPIRVValue *> Indices;
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
        std::vector<SPIRVWord>(1, Const->getZExtValue()),
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
      std::vector<SPIRVWord>(1, Const->getZExtValue()),
      BB));
    else
      return mapValue(V, BM->addVectorInsertDynamicInst(
      transValue(Ins->getOperand(0), BB),
      transValue(Ins->getOperand(1), BB),
      transValue(Index, BB),
      BB));
  }

  if (auto SF = dyn_cast<ShuffleVectorInst>(V)) {
    std::vector<SPIRVWord> Comp;
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
LLVMToSPIRV::transDecoration(Value *V, SPIRVValue *BV) {
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
LLVMToSPIRV::transAlign(Value *V, SPIRVValue *BV) {
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
LLVMToSPIRV::transBuiltinSet() {
  SPIRVWord Ver = 0;
  SourceLanguage Kind = BM->getSourceLanguage(&Ver);
  assert((Kind == SourceLanguageOpenCL_C ||
      Kind == SourceLanguageOpenCL_CPP ) && "not supported");
  std::stringstream SS;
  SS << "OpenCL.std";
  return BM->importBuiltinSet(SS.str(), &ExtSetId);
}

bool
LLVMToSPIRV::oclIsSamplerType(llvm::Type* T) {
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
///   arg = ConstantInt x -> SPIRVConstantSampler
///   arg = i32 argument -> transValue(arg)
SPIRVValue *
LLVMToSPIRV::oclTransSpvcCastSampler(CallInst* CI, SPIRVBasicBlock *BB) {
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

SPIRVValue *
LLVMToSPIRV::transSpcvCast(CallInst* CI, SPIRVBasicBlock *BB) {
  return oclTransSpvcCastSampler(CI, BB);
}

SPIRVValue *
LLVMToSPIRV::transCallInst(CallInst *CI, SPIRVBasicBlock *BB) {
  SPIRVExtInstSetKind ExtSetKind = SPIRVEIS_Count;
  SPIRVWord ExtOp = SPIRVWORD_MAX;
  llvm::Function* F = CI->getCalledFunction();
  auto MangledName = F->getName();
  std::string DemangledName;

  if (MangledName.startswith(SPCV_CAST))
    return transSpcvCast(CI, BB);

  if (MangledName.startswith("llvm.memcpy")) {
    std::vector<SPIRVWord> MemoryAccess;

    if (isa<ConstantInt>(CI->getOperand(4)) &&
      dyn_cast<ConstantInt>(CI->getOperand(4))
      ->getZExtValue() == 1)
      MemoryAccess.push_back(MemoryAccessVolatileMask);
    if (isa<ConstantInt>(CI->getOperand(3))) {
        MemoryAccess.push_back(MemoryAccessAlignedMask);
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
      isDecoratedSPIRVFunc(F, &DemangledName))
    if (auto BV = transBuiltinToInst(DemangledName, MangledName, CI, BB))
      return BV;

  SmallVector<std::string, 2> Dec;
  if (isBuiltinTransToExtInst(CI->getCalledFunction(), &ExtSetKind,
      &ExtOp, &Dec))
    return addDecorations(BM->addExtInst(
      transType(CI->getType()),
      ExtSetId,
      ExtOp,
      transArguments(CI, BB, SPIRVEntry::create_unique(ExtSetKind, ExtOp).get()),
      BB), Dec);

  return BM->addCallInst(
    transFunctionDecl(CI->getCalledFunction()),
    transArguments(CI, BB, SPIRVEntry::create_unique(OpFunctionCall).get()),
    BB);
}



MDNode *
LLVMToSPIRV::oclGetArgBaseTypeMetadata(Function *F) {
  return oclGetArgMetadata(F, SPIR_MD_KERNEL_ARG_BASE_TYPE);
}

MDNode *
LLVMToSPIRV::oclGetArgAccessQualifierMetadata(Function *F) {
  return oclGetArgMetadata(F, SPIR_MD_KERNEL_ARG_ACCESS_QUAL);
}

MDNode *
LLVMToSPIRV::oclGetKernelMetadata(Function *F) {
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
LLVMToSPIRV::oclGetArgMetadata(Function *F, const std::string &MDName) {
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
LLVMToSPIRV::oclGetMutatedArgumentTypesByArgBaseTypeMetadata(
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
LLVMToSPIRV::mutateFunctionType(const std::map<unsigned, Type*>& ChangedType,
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
//   opencl.image_x.y opaque type
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
LLVMToSPIRV::oclGetRegularizedFunctionType(Function *F) {
  auto FT = F->getFunctionType();
  std::map<unsigned, Type *> ChangedType;
  oclGetMutatedArgumentTypesByArgBaseTypeMetadata(FT, ChangedType, F);
  mutateFunctionType(ChangedType, FT);
  return FT;
}

bool
LLVMToSPIRV::transAddressingMode() {
  Triple TargetTriple(M->getTargetTriple());
  Triple::ArchType Arch = TargetTriple.getArch();

  SPIRVCKRT(Arch == Triple::spir || Arch == Triple::spir64,
      InvalidTargetTriple,
      "Actual target triple is " + M->getTargetTriple());

  if (Arch == Triple::spir)
    BM->setAddressingModel(AddressingModelPhysical32);
  else
    BM->setAddressingModel(AddressingModelPhysical64);
  return true;
}
std::vector<SPIRVValue*>
LLVMToSPIRV::transValue(const std::vector<Value *> &Args, SPIRVBasicBlock* BB) {
  std::vector<SPIRVValue*> BArgs;
  for (auto &I: Args)
    BArgs.push_back(transValue(I, BB));
  return BArgs;
}

std::vector<SPIRVValue*>
LLVMToSPIRV::transArguments(CallInst *CI, SPIRVBasicBlock *BB) {
  return transValue(getArguments(CI), BB);
}

std::vector<SPIRVWord>
LLVMToSPIRV::transValue(const std::vector<Value *> &Args, SPIRVBasicBlock* BB,
    SPIRVEntry *Entry) {
  std::vector<SPIRVWord> Operands;
  for (size_t I = 0, E = Args.size(); I != E; ++I) {
    Operands.push_back(Entry->isOperandLiteral(I) ?
        cast<ConstantInt>(Args[I])->getZExtValue() :
        transValue(Args[I], BB)->getId());
  }
  return Operands;
}

std::vector<SPIRVWord>
LLVMToSPIRV::transArguments(CallInst *CI, SPIRVBasicBlock *BB, SPIRVEntry *Entry) {
  return transValue(getArguments(CI), BB, Entry);
}

SPIRVWord
LLVMToSPIRV::transFunctionControlMask(CallInst *CI) {
  SPIRVWord FCM = 0;
  SPIRSPIRVFuncCtlMaskMap::foreach([&](Attribute::AttrKind Attr,
      SPIRVFunctionControlMaskKind Mask){
    if (CI->hasFnAttr(Attr))
      FCM |= Mask;
  });
  return FCM;
}

SPIRVWord
LLVMToSPIRV::transFunctionControlMask(Function *F) {
  SPIRVWord FCM = 0;
  SPIRSPIRVFuncCtlMaskMap::foreach([&](Attribute::AttrKind Attr,
      SPIRVFunctionControlMaskKind Mask){
    if (F->hasFnAttribute(Attr))
      FCM |= Mask;
  });
  return FCM;
}

bool
LLVMToSPIRV::transGlobalVariables() {
  for (auto I = M->global_begin(),
            E = M->global_end(); I != E; ++I) {
    if (!transValue(I, nullptr))
      return false;
  }
  return true;
}

void
LLVMToSPIRV::mutateFuncArgType(const std::map<unsigned, Type*>& ChangedType,
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
      SPIRVDBG(dbgs() << "[mutate arg type] " << *Call << ", " << *Arg << '\n');
      auto CastF = M->getOrInsertFunction(SPCV_CAST, I.second, OrigTy, nullptr);
      std::vector<Value *> Args;
      Args.push_back(Arg);
      auto Cast = CallInst::Create(CastF, Args, "", Call);
      Call->replaceUsesOfWith(Arg, Cast);
      SPIRVDBG(dbgs() << "[mutate arg type] -> " << *Cast << '\n');
    }
  }
}

void
LLVMToSPIRV::transFunction(Function *I) {
  transFunctionDecl(I);
  // Creating all basic blocks before creating any instruction.
  for (Function::iterator FI = I->begin(), FE = I->end(); FI != FE; ++FI) {
    transValue(FI, nullptr);
  }
  for (Function::iterator FI = I->begin(), FE = I->end(); FI != FE; ++FI) {
    SPIRVBasicBlock* BB = static_cast<SPIRVBasicBlock*>(transValue(FI, nullptr));
    for (BasicBlock::iterator BI = FI->begin(), BE = FI->end(); BI != BE;
        ++BI) {
      transValue(BI, BB, false);
    }
  }
}

bool
LLVMToSPIRV::translate() {
  BM->setGeneratorVer(kTranslatorVer);

  if (!transSourceLanguage())
    return false;
  if (!transExtension())
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

  // SPIR-V logical layout requires all function declarations go before
  // function definitions.
  std::vector<Function *> Decls, Defs;
  for (Module::iterator I = M->begin(), E = M->end(); I != E; ++I) {
    if (isBuiltinTransToInst(I) || isBuiltinTransToExtInst(I)
        || I->getName().startswith(SPCV_CAST) ||
        I->getName().startswith(LLVM_MEMCPY))
      continue;
    if (I->isDeclaration())
      Decls.push_back(I);
    else
      Defs.push_back(I);
  }
  for (auto I:Decls)
    transFunctionDecl(I);
  for (auto I:Defs)
    transFunction(I);

  if (!transOCLKernelMetadata())
    return false;
  if (!transExecutionMode())
    return false;

  BM->optimizeDecorates();
  return true;
}

llvm::IntegerType* LLVMToSPIRV::getSizetType() {
  return IntegerType::getIntNTy(M->getContext(),
    M->getDataLayout()->getPointerSizeInBits());
}

void
LLVMToSPIRV::oclGetMutatedArgumentTypesByBuiltin(
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

SPIRVInstruction *
LLVMToSPIRV::transBuiltinToInst(const std::string& DemangledName,
    const std::string &MangledName, CallInst* CI, SPIRVBasicBlock* BB) {
  SmallVector<std::string, 2> Dec;
  auto OC = getSPIRVFuncOC(DemangledName, &Dec);

  if (OC == OpNop)
    return nullptr;

  auto Inst = transBuiltinToInstWithoutDecoration(OC, CI, BB);
  addDecorations(Inst, Dec);
  return Inst;
}

bool
LLVMToSPIRV::transExecutionMode() {
  if (auto NMD = SPIRVMDWalker(*M).getNamedMD(kSPIRVMD::ExecutionMode)) {
    while (!NMD.atEnd()) {
      unsigned EMode = ~0U;
      unsigned EModel = ~0U;
      Function *F = nullptr;
      auto N = NMD.nextOp(); /* execution mode MDNode */
      N.nextOp() /* entry point MDNode */
          .get(EModel)
          .get(F)
          .done()
       .get(EMode);
      assert (EModel == spv::ExecutionModelKernel &&
          "Unsupported execution model");
      SPIRVFunction *BF = static_cast<SPIRVFunction *>(getTranslatedValue(F));
      assert(BF && "Invalid kernel function");
      switch(EMode) {
      case spv::ExecutionModeContractionOff:
        BF->addExecutionMode(new SPIRVExecutionMode(BF,
            ExecutionModeContractionOff));
        break;
      case spv::ExecutionModeLocalSize: {
        unsigned X, Y, Z;
        N.get(X).get(Y).get(Z);
        BF->addExecutionMode(new SPIRVExecutionMode(BF,
            ExecutionModeLocalSize, X, Y, Z));
      }
      break;
      case spv::ExecutionModeLocalSizeHint: {
        unsigned X, Y, Z;
        N.get(X).get(Y).get(Z);
        BF->addExecutionMode(new SPIRVExecutionMode(BF,
            ExecutionModeLocalSizeHint, X, Y, Z));
      }
      break;
      case spv::ExecutionModeVecTypeHint: {
        unsigned X;
        N.get(X);
        BF->addExecutionMode(new SPIRVExecutionMode(BF,
            ExecutionModeVecTypeHint, X));
      }
      break;
      default:
        llvm_unreachable("invalid execution mode");
      }
    }
  }
  return true;
}

bool
LLVMToSPIRV::transOCLKernelMetadata() {
  NamedMDNode *KernelMDs = M->getNamedMetadata(SPIR_MD_KERNELS);
  std::vector<std::string> argAccessQual;
  if (!KernelMDs)
    return true;

  for (unsigned I = 0, E = KernelMDs->getNumOperands(); I < E; ++I) {
    MDNode *KernelMD = KernelMDs->getOperand(I);
    if (KernelMD->getNumOperands() == 0)
      continue;
    Function *Kernel = mdconst::dyn_extract<Function>(KernelMD->getOperand(0));

    SPIRVFunction *BF = static_cast<SPIRVFunction *>(getTranslatedValue(Kernel));
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
      if (Name == SPIR_MD_KERNEL_ARG_TYPE_QUAL) {
        foreachKernelArgMD(MD, BF,
            [](const std::string &Str, SPIRVFunctionParameter *BA){
          if (Str.find("volatile") != std::string::npos)
            BA->addDecorate(new SPIRVDecorate(DecorationVolatile, BA));
          if (Str.find("restrict") != std::string::npos)
            BA->addDecorate(new SPIRVDecorate(DecorationFuncParamAttr,
                BA, FunctionParameterAttributeNoAlias));
          if (Str.find("const") != std::string::npos)
            BA->addDecorate(new SPIRVDecorate(DecorationFuncParamAttr,
                BA, FunctionParameterAttributeNoWrite));
          });
      } else if (Name == SPIR_MD_KERNEL_ARG_NAME) {
        foreachKernelArgMD(MD, BF,
            [=](const std::string &Str, SPIRVFunctionParameter *BA){
            BM->setName(BA, Str);
          });
      }
    }
  }
  return true;
}

bool
LLVMToSPIRV::transSourceLanguage() {
  auto Src = getSPIRVSource(M);
  SrcLang = std::get<0>(Src);
  SrcLangVer = std::get<1>(Src);
  BM->setSourceLanguage(static_cast<SourceLanguage>(SrcLang), SrcLangVer);
  return true;
}

bool
LLVMToSPIRV::transExtension() {
  if (auto N = SPIRVMDWalker(*M).getNamedMD(kSPIRVMD::Extension)) {
    while (!N.atEnd()) {
      std::string S;
      N.nextOp().get(S);
      assert(!S.empty() && "Invalid extension");
      BM->getExtension().insert(S);
    }
  }
  if (auto N = SPIRVMDWalker(*M).getNamedMD(kSPIRVMD::SourceExtension)) {
    while (!N.atEnd()) {
      std::string S;
      N.nextOp().get(S);
      assert(!S.empty() && "Invalid extension");
      BM->getSourceExtension().insert(S);
    }
  }
  for (auto &I:map<SPIRVCapabilityKind>(rmap<OclExt::Kind>(BM->getExtension())))
    BM->addCapability(I);

  return true;
}

void
LLVMToSPIRV::dumpUsers(Value* V) {
  SPIRVDBG(dbgs() << "Users of " << *V << " :\n");
  for (auto UI = V->user_begin(), UE = V->user_end();
      UI != UE; ++UI)
    SPIRVDBG(dbgs() << "  " << **UI << '\n');
}

Op
LLVMToSPIRV::transBoolOpCode(SPIRVValue* Opn, Op OC) {
  if (!Opn->getType()->isTypeVectorOrScalarBool())
    return OC;
  IntBoolOpMap::find(OC, &OC);
  return OC;
}

SPIRVInstruction *
LLVMToSPIRV::transBuiltinToInstWithoutDecoration(Op OC,
    CallInst* CI, SPIRVBasicBlock* BB) {
  switch (OC) {
  case OpControlBarrier:
    return BM->addControlBarrierInst(
        getArgAsScope(CI, 0),
        getArgAsScope(CI, 1),
        getArgAsInt(CI, 2), BB);
    break;
  case OpGroupAsyncCopy: {
    auto Args = getArguments(CI, 1);
    auto BArgs = transValue(Args, BB);
    return BM->addAsyncGroupCopy(
        getArgAsScope(CI, 0),
        BArgs[0], BArgs[1], BArgs[2],
        BArgs[3], BArgs[4], BB);
    }
    break;
  default: {
    if (isCvtOpCode(OC) && OC != OpGenericCastToPtrExplicit) {
      return BM->addUnaryInst(OC, transType(CI->getType()),
        transValue(CI->getArgOperand(0), BB), BB);
    } else if (isCmpOpCode(OC)) {
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
        !hasExecScope(OC) &&
        !isAtomicOpCode(OC)) {
      return BM->addUnaryInst(OC, transType(CI->getType()),
        transValue(CI->getArgOperand(0), BB), BB);
    } else {
      auto Args = getArguments(CI);
      SPIRVType *SPRetTy = nullptr;
      Type *RetTy = CI->getType();
      auto F = CI->getCalledFunction();
      if (!RetTy->isVoidTy()) {
        SPRetTy = transType(RetTy);
      } else if (Args.size() > 0 && F->arg_begin()->hasStructRetAttr()) {
        SPRetTy = transType(F->arg_begin()->getType()->getPointerElementType());
        Args.erase(Args.begin());
      }
      auto SPI = BM->addInstTemplate(OC, BB, SPRetTy);
      std::vector<SPIRVWord> SPArgs;
      for (size_t I = 0, E = Args.size(); I != E; ++I) {
        assert((!isFunctionPointerType(Args[I]->getType()) ||
               isa<Function>(Args[I])) &&
               "Invalid function pointer argument");
        SPArgs.push_back(SPI->isOperandLiteral(I) ?
            cast<ConstantInt>(Args[I])->getZExtValue() :
            transValue(Args[I], BB)->getId());
      }
      SPI->setOpWordsAndValidate(SPArgs);
      if (!SPRetTy || !SPRetTy->isTypeStruct())
        return SPI;
      std::vector<SPIRVWord> Mem;
      SPIRVDBG(spvdbgs() << *SPI << '\n');
      return BM->addStoreInst(transValue(CI->getArgOperand(0), BB), SPI,
          Mem, BB);
    }
  }
  }
  return nullptr;
}


SPIRVId
LLVMToSPIRV::addInt32(int I) {
  return transValue(getInt32(M, I), nullptr, false)->getId();
}

}

char LLVMToSPIRV::ID = 0;

INITIALIZE_PASS(LLVMToSPIRV, "llvmtospv", "Translate LLVM to SPIR-V",
    false, false)

ModulePass *llvm::createLLVMToSPIRV(SPIRVModule *SMod) {
  return new LLVMToSPIRV(SMod);
}

void
addPassesForSPIRV(PassManager &PassMgr) {
  if (SPIRVMemToReg)
    PassMgr.add(createPromoteMemoryToRegisterPass());
  PassMgr.add(createTransOCLMD());
  PassMgr.add(createOCL21ToSPIRV());
  PassMgr.add(createSPIRVLowerOCLBlocks());
  PassMgr.add(createSPIRVLowerBool());
  PassMgr.add(createOCL20ToSPIRV());
  PassMgr.add(createSPIRVRegularizeLLVM());
  PassMgr.add(createSPIRVLowerConstExpr());
}

bool
llvm::WriteSPIRV(Module *M, std::ostream &OS, std::string &ErrMsg) {
  std::unique_ptr<SPIRVModule> BM(SPIRVModule::createSPIRVModule());
  PassManager PassMgr;
  addPassesForSPIRV(PassMgr);
  PassMgr.add(createLLVMToSPIRV(BM.get()));
  PassMgr.run(*M);

  if (BM->getError(ErrMsg) != SPIRVEC_Success)
    return false;
  OS << *BM;
  return true;
}

bool
llvm::RegularizeLLVMForSPIRV(Module *M, std::string &ErrMsg) {
  std::unique_ptr<SPIRVModule> BM(SPIRVModule::createSPIRVModule());
  PassManager PassMgr;
  addPassesForSPIRV(PassMgr);
  PassMgr.run(*M);
  return true;
}


