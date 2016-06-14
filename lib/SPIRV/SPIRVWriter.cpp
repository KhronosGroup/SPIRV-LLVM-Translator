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
#include "OCLTypeToSPIRV.h"
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
#include <cstdlib>

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

  void getAnalysisUsage(AnalysisUsage &AU) const {
    AU.addRequired<OCLTypeToSPIRV>();
  }

  static char ID;

  SPIRVType *transType(Type *T);
  SPIRVType *transSPIRVOpaqueType(Type *T);

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
    SPIRVDBG(dbgs() << "[mapType] " << *T << " => ";
             spvdbgs() << *BT << '\n');
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

  void dumpUsers(Value *V);

  template<class ExtInstKind>
  bool oclGetExtInstIndex(const std::string &MangledName,
      const std::string& DemangledName, SPIRVWord* EntryPoint);
  void oclGetMutatedArgumentTypesByBuiltin(llvm::FunctionType* FT,
      std::map<unsigned, Type*>& ChangedType, Function* F);

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

  SPIRVValue *transSpcvCast(CallInst* CI, SPIRVBasicBlock *BB);
  SPIRVValue *oclTransSpvcCastSampler(CallInst* CI, SPIRVBasicBlock *BB);

  SPIRV::SPIRVInstruction* transUnaryInst(UnaryInstruction* U,
      SPIRVBasicBlock* BB);

  /// Add a 32 bit integer constant.
  /// \return Id of the constant.
  SPIRVId addInt32(int);
  void transFunction(Function *I);
  SPIRV::SPIRVLinkageTypeKind transLinkageType(const GlobalValue* GV);
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
  if (!oclIsBuiltin(F->getName(), &DemangledName) &&
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
  if (!oclIsBuiltin(OrigName, &DemangledName))
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

/// Decode SPIR-V type name in the format spirv.{TypeName}._{Postfixes}
/// where Postfixes are strings separated by underscores.
/// \return TypeName.
/// \param Ops contains the integers decoded from postfixes.
static std::string
 decodeSPIRVTypeName(StringRef Name,
    SmallVectorImpl<std::string>& Strs) {
  SmallVector<StringRef, 4> SubStrs;
  const char Delim[] = { kSPIRVTypeName::Delimiter, 0 };
  Name.split(SubStrs, Delim, -1, true);
  assert(SubStrs.size() >= 2 && "Invalid SPIRV type name");
  assert(SubStrs[0] == kSPIRVTypeName::Prefix && "Invalid prefix");
  assert((SubStrs.size() == 2 || !SubStrs[2].empty()) && "Invalid postfix");

  if (SubStrs.size() > 2) {
    const char PostDelim[] = { kSPIRVTypeName::PostfixDelim, 0 };
    SmallVector<StringRef, 4> Postfixes;
    SubStrs[2].split(Postfixes, PostDelim, -1, true);
    assert(Postfixes.size() > 1 && Postfixes[0].empty() && "Invalid postfix");
    for (unsigned I = 1, E = Postfixes.size(); I != E; ++I)
      Strs.push_back(std::string(Postfixes[I]).c_str());
  }
  return SubStrs[1].str();
}

static bool recursiveType(const StructType *ST, const Type *Ty) {
  SmallPtrSet<const StructType *, 4> Seen;

  std::function<bool(const Type *Ty)> Run = [&](const Type *Ty) {
    if (!isa<CompositeType>(Ty))
      return false;

    if (auto *StructTy = dyn_cast<StructType>(Ty)) {
      if (StructTy == ST)
        return true;

      if (Seen.count(StructTy))
        return false;

      Seen.insert(StructTy);

      return find_if(StructTy->subtype_begin(), StructTy->subtype_end(), Run) !=
             StructTy->subtype_end();
    }

    if (auto *PtrTy = dyn_cast<PointerType>(Ty))
      return Run(PtrTy->getPointerElementType());

    if (auto *ArrayTy = dyn_cast<ArrayType>(Ty))
      return Run(ArrayTy->getArrayElementType());

    return false;
  };

  return Run(Ty);
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
      assert (!STName.startswith(kSPR2TypeName::Pipe) &&
              "OpenCL type names should be translated to SPIR-V type names");
      // ToDo: For SPIR1.2/2.0 there may still be load/store or bitcast
      // instructions using opencl.* type names. We need to handle these
      // type names until they are all mapped or FE generates SPIR-V type
      // names.
      if (STName.find(kSPR2TypeName::Pipe) == 0) {
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
        auto SPIRVImageTy = getSPIRVImageTypeFromOCL(M, T);
        return mapType(T, transSPIRVOpaqueType(SPIRVImageTy));
      } else if (STName.startswith(kSPIRVTypeName::PrefixAndDelim))
        return transSPIRVOpaqueType(T);
      else if (OCLOpaqueTypeOpCodeMap::find(STName, &OpCode)) {
        switch (OpCode) {
        default:
          return mapType(T, BM->addOpaqueGenericType(OpCode));
        case OpTypePipe:
          return mapType(T, BM->addPipeType());
        case OpTypeDeviceEvent:
          return mapType(T, BM->addDeviceEventType());
        case OpTypeQueue:
          return mapType(T, BM->addQueueType());
        }
      } else if (isPointerToOpaqueStructType(T)) {
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
    assert(!ST->getName().startswith(kSPR2TypeName::Pipe));
    assert(!ST->getName().startswith(kSPR2TypeName::ImagePrefix));
    return mapType(T, BM->addOpaqueType(T->getStructName()));
  }

  if (auto ST = dyn_cast<StructType>(T)) {
    assert(ST->isSized());

    std::string Name;
    if (ST->hasName())
      Name = ST->getName();

    if(Name == getSPIRVTypeName(kSPIRVTypeName::ConstantSampler))
      return transType(getSamplerType(M));
    if (Name == getSPIRVTypeName(kSPIRVTypeName::ConstantPipeStorage))
      return transType(getPipeStorageType(M));

    auto *Struct = BM->openStructType(T->getStructNumElements(), Name);
    mapType(T, Struct);

    SmallVector<unsigned, 4> ForwardRefs;

    for (unsigned I = 0, E = T->getStructNumElements(); I != E; ++I) {
      auto *ElemTy = ST->getElementType(I);
      if (isa<CompositeType>(ElemTy) && recursiveType(ST, ElemTy))
        ForwardRefs.push_back(I);
      else
        Struct->setMemberType(I, transType(ST->getElementType(I)));
    }

    BM->closeStructType(Struct, ST->isPacked());

    for (auto I : ForwardRefs)
      Struct->setMemberType(I, transType(ST->getElementType(I)));

    return Struct;
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

SPIRVType *
LLVMToSPIRV::transSPIRVOpaqueType(Type *T) {
  auto ET = T->getPointerElementType();
  auto ST = cast<StructType>(ET);
  auto AddrSpc = T->getPointerAddressSpace();
  auto STName = ST->getStructName();
  assert (STName.startswith(kSPIRVTypeName::PrefixAndDelim) &&
    "Invalid SPIR-V opaque type name");
  SmallVector<std::string, 8> Postfixes;
  auto TN = decodeSPIRVTypeName(STName, Postfixes);
  if (TN == kSPIRVTypeName::Pipe) {
    assert(AddrSpc == SPIRAS_Global);
    assert(Postfixes.size() == 1 && "Invalid pipe type ops");
    auto PipeT = BM->addPipeType();
    PipeT->setPipeAcessQualifier(static_cast<spv::AccessQualifier>(
      atoi(Postfixes[0].c_str())));
    return mapType(T, PipeT);
  } else if (TN == kSPIRVTypeName::Image) {
    assert(AddrSpc == SPIRAS_Global);
    // The sampled type needs to be translated through LLVM type to guarantee
    // uniqueness.
    auto SampledT = transType(getLLVMTypeForSPIRVImageSampledTypePostfix(
      Postfixes[0], *Ctx));
    SmallVector<int, 7> Ops;
    for (unsigned I = 1; I < 8; ++I)
      Ops.push_back(atoi(Postfixes[I].c_str()));
    SPIRVTypeImageDescriptor Desc(static_cast<SPIRVImageDimKind>(Ops[0]),
        Ops[1], Ops[2], Ops[3], Ops[4], Ops[5]);
    return mapType(T, BM->addImageType(SampledT, Desc,
                   static_cast<spv::AccessQualifier>(Ops[6])));
  } else if (TN == kSPIRVTypeName::SampledImg) {
    return mapType(T, BM->addSampledImageType(
        static_cast<SPIRVTypeImage *>(
            transType(getSPIRVTypeByChangeBaseTypeName(M,
                T, kSPIRVTypeName::SampledImg,
                kSPIRVTypeName::Image)))));
  } else if(TN == kSPIRVTypeName::Sampler)
    return mapType(T, BM->addSamplerType());
  else if (TN == kSPIRVTypeName::DeviceEvent)
    return mapType(T, BM->addDeviceEventType());
  else if (TN == kSPIRVTypeName::Queue)
    return mapType(T, BM->addQueueType());
  else if (TN == kSPIRVTypeName::PipeStorage)
    return mapType(T, BM->addPipeStorageType());
  else
    return mapType(T, BM->addOpaqueGenericType(
      SPIRVOpaqueTypeOpCodeMap::map(TN)));
}

SPIRVFunction *
LLVMToSPIRV::transFunctionDecl(Function *F) {
  if (auto BF= getTranslatedValue(F))
    return static_cast<SPIRVFunction *>(BF);

  SPIRVTypeFunction *BFT = static_cast<SPIRVTypeFunction *>(transType(
      getAnalysis<OCLTypeToSPIRV>().getAdaptedType(F)));
  SPIRVFunction *BF = static_cast<SPIRVFunction *>(mapValue(F,
      BM->addFunction(BFT)));
  BF->setFunctionControlMask(transFunctionControlMask(F));
  if (F->hasName())
    BM->setName(BF, F->getName());
  if (oclIsKernel(F))
    BM->addEntryPoint(ExecutionModelKernel, BF->getId());
  else if (F->getLinkage() != GlobalValue::InternalLinkage)
    BF->setLinkageType(transLinkageType(F));
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
    if (Attrs.hasAttribute(ArgNo + 1, Attribute::Dereferenceable))
      BA->addDecorate(DecorationMaxByteOffset,
                      Attrs.getAttribute(ArgNo + 1, Attribute::Dereferenceable)
                        .getDereferenceableBytes());
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

  if (auto CAZero = dyn_cast<ConstantAggregateZero>(V)) {
    Type *AggType = CAZero->getType();
    if (const StructType* ST = dyn_cast<StructType>(AggType))
      if (ST->getName() == getSPIRVTypeName(kSPIRVTypeName::ConstantSampler))
        return BM->addSamplerConstant(transType(AggType), 0,0,0);

    return BM->addNullConstant(transType(AggType));
  }

  if (auto ConstI = dyn_cast<ConstantInt>(V))
    return BM->addConstant(transType(V->getType()), ConstI->getZExtValue());

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
    if (ConstV->getType()->getName() ==
        getSPIRVTypeName(kSPIRVTypeName::ConstantSampler)) {
      assert(ConstV->getNumOperands() == 3);
      SPIRVWord
        AddrMode   = ConstV->getOperand(0)->getUniqueInteger().getZExtValue(),
        Normalized = ConstV->getOperand(1)->getUniqueInteger().getZExtValue(),
        FilterMode = ConstV->getOperand(2)->getUniqueInteger().getZExtValue();
      assert(AddrMode < 5 && "Invalid addressing mode");
      assert(Normalized < 2 && "Invalid value of normalized coords");
      assert(FilterMode < 2 && "Invalid filter mode");
      SPIRVType* SamplerTy = transType(ConstV->getType());
      return BM->addSamplerConstant(SamplerTy,
                                    AddrMode, Normalized, FilterMode);
    }
    if (ConstV->getType()->getName() ==
      getSPIRVTypeName(kSPIRVTypeName::ConstantPipeStorage)) {
      assert(ConstV->getNumOperands() == 3);
      SPIRVWord
        PacketSize = ConstV->getOperand(0)->getUniqueInteger().getZExtValue(),
        PacketAlign = ConstV->getOperand(1)->getUniqueInteger().getZExtValue(),
        Capacity = ConstV->getOperand(2)->getUniqueInteger().getZExtValue();
      assert(PacketAlign >= 1 && "Invalid packet alignment");
      assert(PacketSize >= PacketAlign && PacketSize % PacketAlign == 0 &&
        "Invalid packet size and/or alignment.");
      SPIRVType* PipeStorageTy = transType(ConstV->getType());
      return BM->addPipeStorageConstant(PipeStorageTy, PacketSize, PacketAlign,
                                        Capacity);
    }
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
  std::string name = V->getName();
  if (!name.empty()) // Don't erase the name, which BM might already have
    BM->setName(BV, name);
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
    llvm::PointerType * Ty = GV->getType();
    // Though variables with common linkage type are initialized by 0,
    // they can be represented in SPIR-V as uninitialized variables with
    // 'Export' linkage type, just as tentative definitions look in C
    llvm::Value *Init = GV->hasInitializer() && !GV->hasCommonLinkage() ?
      GV->getInitializer() : nullptr;
    StructType *ST = Init ? dyn_cast<StructType>(Init->getType()) : nullptr;
    if (ST && ST->hasName() && isSPIRVConstantName(ST->getName())) {
      auto BV = transConstant(Init);
      assert(BV);
      return mapValue(V, BV);
    } else if (ConstantExpr *ConstUE = dyn_cast_or_null<ConstantExpr>(Init)) {
      Instruction * Inst = ConstUE->getAsInstruction();
      if (isSpecialTypeInitializer(Inst)) {
        Init = Inst->getOperand(0);
        Ty = static_cast<PointerType*>(Init->getType());
      }
      Inst->dropAllReferences();
    }
    auto BVar = static_cast<SPIRVVariable *>(BM->addVariable(
      transType(Ty), GV->isConstant(),
      transLinkageType(GV),
      Init ? transValue(Init, nullptr) : nullptr,
      GV->getName(),
      SPIRSPIRVAddrSpaceMap::map(
        static_cast<SPIRAddressSpace>(Ty->getAddressSpace())),
      nullptr
      ));
    mapValue(V, BVar);
    spv::BuiltIn Builtin = spv::BuiltInPosition;
    if (!GV->hasName() || !getSPIRVBuiltin(GV->getName().str(), Builtin))
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
    std::vector<SPIRVWord> MemoryAccess(1,0);
    if (ST->isVolatile())
      MemoryAccess[0] |= MemoryAccessVolatileMask;
    if (ST->getAlignment()) {
      MemoryAccess[0] |= MemoryAccessAlignedMask;
      MemoryAccess.push_back(ST->getAlignment());
    }
    if (ST->getMetadata(LLVMContext::MD_nontemporal))
      MemoryAccess[0] |= MemoryAccessNontemporalMask;
    if (MemoryAccess.front() == 0)
      MemoryAccess.clear();
    return mapValue(V, BM->addStoreInst(
        transValue(ST->getPointerOperand(), BB),
        transValue(ST->getValueOperand(), BB),
        MemoryAccess, BB));
  }

  if (LoadInst *LD = dyn_cast<LoadInst>(V)) {
    std::vector<SPIRVWord> MemoryAccess(1,0);
    if (LD->isVolatile())
      MemoryAccess[0] |= MemoryAccessVolatileMask;
    if (LD->getAlignment()) {
      MemoryAccess[0] |= MemoryAccessAlignedMask;
      MemoryAccess.push_back(LD->getAlignment());
    }
    if (LD->getMetadata(LLVMContext::MD_nontemporal))
      MemoryAccess[0] |= MemoryAccessNontemporalMask;
    if (MemoryAccess.front() == 0)
      MemoryAccess.clear();
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
      SPIRVLinkageTypeKind::LinkageTypeInternal,
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

  if (auto Ext = dyn_cast<ExtractValueInst>(V)) {
    return mapValue(V, BM->addCompositeExtractInst(
        transType(Ext->getType()),
        transValue(Ext->getAggregateOperand(), BB),
        Ext->getIndices(), BB));
  }

  if (auto Ins = dyn_cast<InsertValueInst>(V)) {
    return mapValue(V, BM->addCompositeInsertInst(
        transValue(Ins->getInsertedValueOperand(), BB),
        transValue(Ins->getAggregateOperand(), BB),
        Ins->getIndices(), BB));
  }

  if (UnaryInstruction *U = dyn_cast<UnaryInstruction>(V)) {
    if (isSpecialTypeInitializer(U))
      return mapValue(V, transValue(U->getOperand(0), BB));
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

/// Transform sampler* spcv.cast(i32 arg)
/// Only two cases are possible:
///   arg = ConstantInt x -> SPIRVConstantSampler
///   arg = i32 argument -> transValue(arg)
///   arg = load from sampler -> look through load
SPIRVValue *
LLVMToSPIRV::oclTransSpvcCastSampler(CallInst* CI, SPIRVBasicBlock *BB) {
  llvm::Function* F = CI->getCalledFunction();
  auto FT = F->getFunctionType();
  auto RT = FT->getReturnType();
  assert(FT->getNumParams() == 1);
  assert(isSPIRVType(RT, kSPIRVTypeName::Sampler) &&
    FT->getParamType(0)->isIntegerTy() && "Invalid sampler type");
  auto Arg = CI->getArgOperand(0);

  auto GetSamplerConstant = [&](uint64_t SamplerValue) {
    auto AddrMode = (SamplerValue & 0xE) >> 1;
    auto Param = SamplerValue & 0x1;
    auto Filter = ((SamplerValue & 0x30) >> 4) - 1;
    auto BV = BM->addSamplerConstant(transType(RT), AddrMode, Param, Filter);
    return BV;
  };

  if (auto Const = dyn_cast<ConstantInt>(Arg)) {
    // Sampler is declared as a kernel scope constant
    return GetSamplerConstant(Const->getZExtValue());
  } else if (auto Load = dyn_cast<LoadInst>(Arg)) {
    // If value of the sampler is loaded from a global constant, use its
    // initializer for initialization of the sampler.
    auto Op = Load->getPointerOperand();
    assert(isa<GlobalVariable>(Op) && "Unknown sampler pattern!");
    auto GV = cast<GlobalVariable>(Op);
    assert(GV->isConstant() ||
      GV->getType()->getPointerAddressSpace() == SPIRAS_Constant);
    auto Initializer = GV->getInitializer();
    assert(isa<ConstantInt>(Initializer) && "sampler not constant int?");
    return GetSamplerConstant(cast<ConstantInt>(Initializer)->getZExtValue());
  }
  // Sampler is a function argument
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

  if (oclIsBuiltin(MangledName, &DemangledName) ||
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
  // Physical addressing model requires Addresses capability
  BM->addCapability(CapabilityAddresses);
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
  BM->resolveUnknownStructFields();
  BM->createForwardPointers();
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
  if (!oclIsBuiltin(Name, &Demangled))
    return;
  if (Demangled.find(kSPIRVName::SampledImage) == std::string::npos)
    return;
  if (FT->getParamType(1)->isIntegerTy())
    ChangedType[1] = getSamplerType(F->getParent());
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
      Function *F = nullptr;
      auto N = NMD.nextOp(); /* execution mode MDNode */
      N.get(F).get(EMode);

      SPIRVFunction *BF = static_cast<SPIRVFunction *>(getTranslatedValue(F));
      assert(BF && "Invalid kernel function");
      if (!BF)
        return false;

      switch (EMode) {
      case spv::ExecutionModeContractionOff:
      case spv::ExecutionModeInitializer:
      case spv::ExecutionModeFinalizer:
        BF->addExecutionMode(new SPIRVExecutionMode(BF,
            static_cast<ExecutionMode>(EMode)));
        break;
      case spv::ExecutionModeLocalSize:
      case spv::ExecutionModeLocalSizeHint: {
        unsigned X, Y, Z;
        N.get(X).get(Y).get(Z);
        BF->addExecutionMode(new SPIRVExecutionMode(BF,
            static_cast<ExecutionMode>(EMode), X, Y, Z));
      }
      break;
      case spv::ExecutionModeVecTypeHint:
      case spv::ExecutionModeSubgroupSize:
      case spv::ExecutionModeSubgroupsPerWorkgroup: {
        unsigned X;
        N.get(X);
        BF->addExecutionMode(new SPIRVExecutionMode(BF,
            static_cast<ExecutionMode>(EMode), X));
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
  if (isGroupOpCode(OC))
    BM->addCapability(CapabilityGroups);
  switch (OC) {
  case OpControlBarrier: {
    auto BArgs = transValue(getArguments(CI), BB);
    return BM->addControlBarrierInst(
      BArgs[0], BArgs[1], BArgs[2], BB);
    }
    break;
  case OpGroupAsyncCopy: {
    auto BArgs = transValue(getArguments(CI), BB);
    return BM->addAsyncGroupCopy(BArgs[0], BArgs[1], BArgs[2], BArgs[3],
                                 BArgs[4], BArgs[5], BB);
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
      auto BBT = transType(BoolTy);
      auto Cmp = BM->addCmpInst(OC, BBT,
        transValue(CI->getArgOperand(0), BB),
        transValue(CI->getArgOperand(1), BB), BB);
      auto Zero = transValue(Constant::getNullValue(ResultTy), BB);
      auto One = transValue(
          IsVector ? Constant::getAllOnesValue(ResultTy) : getInt32(M, 1), BB);
      return BM->addSelectInst(Cmp, One, Zero, BB);
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

SPIRV::SPIRVLinkageTypeKind
LLVMToSPIRV::transLinkageType(const GlobalValue* GV) {
  if(GV->isDeclarationForLinker())
    return SPIRVLinkageTypeKind::LinkageTypeImport;
  if(GV->hasInternalLinkage() || GV->hasPrivateLinkage())
    return SPIRVLinkageTypeKind::LinkageTypeInternal;
  return SPIRVLinkageTypeKind::LinkageTypeExport;
}
} // end of SPIRV namespace

char LLVMToSPIRV::ID = 0;

INITIALIZE_PASS_BEGIN(LLVMToSPIRV, "llvmtospv", "Translate LLVM to SPIR-V",
    false, false)
INITIALIZE_PASS_DEPENDENCY(OCLTypeToSPIRV)
INITIALIZE_PASS_END(LLVMToSPIRV, "llvmtospv", "Translate LLVM to SPIR-V",
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
  PassMgr.add(createOCLTypeToSPIRV());
  PassMgr.add(createOCL20ToSPIRV());
  PassMgr.add(createSPIRVRegularizeLLVM());
  PassMgr.add(createSPIRVLowerConstExpr());
  PassMgr.add(createSPIRVLowerBool());
}

bool
llvm::WriteSPIRV(Module *M, llvm::raw_ostream &OS, std::string &ErrMsg) {
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

