//===- LLVMSPRVWriter.cpp – Converts LLVM to SPIR-V -------------*- C++ -*-===//
//
//                     The LLVM/SPIRV Translator
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
/// This file implements conversion of LLVM intermediate language to SPIRV
/// binary.
///
//===----------------------------------------------------------------------===//

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/Triple.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Transforms/IPO.h"

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

#include <iostream>
#include <list>
#include <memory>
#include <set>
#include <sstream>
#include <vector>

using namespace llvm;
using namespace SPRV;

namespace SPRV{

bool SPRVDbgSaveRegularizedModule = false;

static int
getMDOperandAsInt(MDNode* N, unsigned I) {
  auto *C = dyn_cast_or_null<ConstantAsMetadata>(N->getOperand(I));
  return C->getValue()->getUniqueInteger().getZExtValue();
}

static std::string
getMDOperandAsString(MDNode* N, unsigned I) {
  Metadata* Op = N->getOperand(I);
  if (!Op)
    return "";
  if (MDString* Str = dyn_cast<MDString>(Op)) {
    return Str->getString().str();
  } else
    return "";
}

static Type*
getMDOperandAsType(MDNode* N, unsigned I) {
  return dyn_cast<ValueAsMetadata>(N->getOperand(I))->getType();
}

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
void dumpUsers(Value* V) {
  SPRVDBG(dbgs() << "Users of " << *V << " :\n");
  for (auto UI = V->use_begin(), UE = V->use_end();
      UI != UE; ++UI)
    SPRVDBG(dbgs() << "  " << **UI << '\n');
}

/// Lower SPIR2 blocks to function calls.
///
/// SPIR2 representation of blocks:
///
/// block = spir_block_bind(bitcast(block_func), context_len, context_align,
///   context)
/// block_func_ptr = bitcast(spir_get_block_invoke(block))
/// context_ptr = spir_get_block_context(block)
/// ret = block_func_ptr(context_ptr, args)
///
/// Propagates block_func to each spir_get_block_invoke through def-use chain of
/// spir_block_bind, so that
/// ret = block_func(context, args)
class OCLLowerBlocks {
public:
  OCLLowerBlocks(Module *Module):M(Module){}

  void run() {
    lowerBlockBind();
    lowerGetBlockInvoke();
    lowerGetBlockContext();
    std::vector<std::string> FN;
    FN.push_back(SPIR_INTRINSIC_GET_BLOCK_INVOKE);
    FN.push_back(SPIR_INTRINSIC_GET_BLOCK_CONTEXT);
    FN.push_back(SPIR_INTRINSIC_BLOCK_BIND);
    eraseFunctions(FN);
    SPRVDBG(dbgs() << "------- After OCLLowerBlocks ------------\n" << *M);
  }
private:
  const static int MaxIter = 1000;
  Module *M;

  void
  lowerBlockBind() {
    auto F = M->getFunction(SPIR_INTRINSIC_BLOCK_BIND);
    if (!F)
      return;
    int Iter = MaxIter;
    while(lowerBlockBind(F) && Iter > 0){
      Iter--;
      SPRVDBG(dbgs() << "-------------- after iteration " << MaxIter - Iter <<
          " --------------\n" << *M << '\n');
    }
    assert(Iter > 0 && "Too many iterations");
  }

  void
  lowerGetBlockInvoke() {
    if (auto F = M->getFunction(SPIR_INTRINSIC_GET_BLOCK_INVOKE)) {
      for (auto UI = F->use_begin(), UE = F->use_end(); UI != UE;) {
        auto CI = dyn_cast<CallInst>(*UI);
        assert(CI && "Invalid usage of spir_get_block_invoke");
        lowerGetBlockInvoke(CI);
        ++UI;
      }
    }
  }
  void
  lowerGetBlockContext() {
    if (auto F = M->getFunction(SPIR_INTRINSIC_GET_BLOCK_CONTEXT)) {
      for (auto UI = F->use_begin(), UE = F->use_end(); UI != UE;) {
        auto CI = dyn_cast<CallInst>(*UI);
        assert(CI && "Invalid usage of spir_get_block_context");
        lowerGetBlockContext(CI);
        ++UI;
      }
    }
  }
  /// Lower calls of spir_block_bind.
  /// Return true if the Module is changed.
  bool
  lowerBlockBind(Function *BlockBindFunc) {
    bool changed = false;
    for (auto I = BlockBindFunc->user_begin(), E = BlockBindFunc->user_end();
        I != E;) {
      SPRVDBG(dbgs() << "[lowerBlockBind] " << **I << '\n');
      // Handle spir_block_bind(bitcast(block_func), context_len,
      // context_align, context)
      auto CallBlkBind = dyn_cast<CallInst>(*I);
      assert(CallBlkBind);
      ++I;
      Function *InvF = nullptr;
      Value *Ctx = nullptr;
      getBlockInvokeFuncAndContext(CallBlkBind, &InvF, &Ctx);
      for (auto II = CallBlkBind->user_begin(), EE = CallBlkBind->user_end();
          II != EE;) {
        auto BlkUser = *II;
        ++II;
        SPRVDBG(dbgs() << "  Block user: " << *BlkUser << '\n');
        if (auto Ret = dyn_cast<ReturnInst>(BlkUser)) {
          bool Inlined = false;
          changed |= lowerReturnBlock(Ret, CallBlkBind, Inlined);
          if (Inlined)
            return true;
        } else if (auto CI = dyn_cast<CallInst>(BlkUser)){
          auto CallBindF = CI->getCalledFunction();
          auto Name = CallBindF->getName();
          std::string DemangledName;
          if (Name == SPIR_INTRINSIC_GET_BLOCK_INVOKE) {
            assert(CI->getArgOperand(0) == CallBlkBind);
            changed |= lowerGetBlockInvoke(CI, cast<Function>(InvF));
          } else if (Name == SPIR_INTRINSIC_GET_BLOCK_CONTEXT) {
            assert(CI->getArgOperand(0) == CallBlkBind);
            // Handle context_ptr = spir_get_block_context(block)
            lowerGetBlockContext(CI, Ctx);
            changed = true;
          } else if (oclIsBuiltin(Name, &DemangledName)) {
            lowerBlockBuiltin(CI, InvF, Ctx, DemangledName);
            changed = true;
          }
          else {
            assert(0);
          }
        }
      }
      erase(CallBlkBind);
    }
    return changed;
  }

  void
  lowerGetBlockContext(CallInst *CallGetBlkCtx, Value *Ctx = nullptr) {
    if (!Ctx)
      getBlockInvokeFuncAndContext(CallGetBlkCtx->getArgOperand(0), nullptr,
          &Ctx);
    CallGetBlkCtx->replaceAllUsesWith(Ctx);
    SPRVDBG(dbgs() << "  [lowerGetBlockContext] " << *CallGetBlkCtx << " => " <<
        *Ctx << "\n\n");
    erase(CallGetBlkCtx);
  }

  bool
  lowerGetBlockInvoke(CallInst *CallGetBlkInvoke,
      Function *InvokeF = nullptr) {
    bool changed = false;
    for (auto UI = CallGetBlkInvoke->use_begin(),
        UE = CallGetBlkInvoke->use_end();
        UI != UE;) {
      // Handle block_func_ptr = bitcast(spir_get_block_invoke(block))
      auto CallInv =dyn_cast<Instruction>(*UI);
      ++UI;
      assert(CallInv);
      auto Cast = dyn_cast<BitCastInst>(CallInv);
      if (Cast)
        CallInv = dyn_cast<Instruction>(*CallInv->use_begin());
      SPRVDBG(dbgs() << "[lowerGetBlockInvoke]  " << *CallInv);
      // Handle ret = block_func_ptr(context_ptr, args)
      auto CI = dyn_cast<CallInst>(CallInv);
      assert(CI);
      auto F = CI->getCalledValue();
      if (InvokeF == nullptr) {
        getBlockInvokeFuncAndContext(CallGetBlkInvoke->getArgOperand(0),
            &InvokeF, nullptr);
        assert(InvokeF);
      }
      assert(F->getType() == InvokeF->getType());
      CI->replaceUsesOfWith(F, InvokeF);
      SPRVDBG(dbgs() << " => " << *CI << "\n\n");
      erase(Cast);
      erase(CallInv);
      changed = true;
    }
    erase(CallGetBlkInvoke);
    return changed;
  }

  void
  lowerBlockBuiltin(CallInst *CI, Function *InvF, Value *Ctx,
      const std::string& DemangledName) {
    mutateCallInst (M, CI, [=](CallInst *CI, std::vector<Value *> &Args) {
    auto ALoc = Args.begin();
    for (auto E = Args.end(); ALoc != E; ++ALoc) {
      if (isPointerToOpaqueStructType((*ALoc)->getType(),
          SPIR_TYPE_NAME_BLOCK_T)) {
        break;
      }
    }
    assert (ALoc != Args.end());
    *ALoc = InvF;
    if (DemangledName == OCL_BUILTIN_ENQUEUE_KERNEL)
      Args.insert(ALoc + 1, Ctx);

      return addSPRVPrefix(DemangledName);
    });
  }
  /// Transform return of a block.
  /// The function returning a block is inlined since the context cannot be
  /// passed to another function.
  /// Returns true of module is changed.
  bool
  lowerReturnBlock(ReturnInst *Ret, Value *CallBlkBind, bool &Inlined) {
    auto F = Ret->getParent()->getParent();
    auto changed = false;
    auto needInline = false;
    for (auto UI = F->user_begin(), UE = F->user_end(); UI != UE;) {
      auto U = *UI;
      ++UI;
      dumpUsers(U);
      auto Inst = dyn_cast<Instruction>(U);
      if (Inst && Inst->use_empty()) {
        erase(Inst);
        changed = true;
        continue;
      }
      auto CI = dyn_cast<CallInst>(U);
      if(!CI || CI->getCalledFunction() != F)
        continue;
      needInline = true;
    }
    if (!needInline)
      return changed;
    SPRVDBG(dbgs() << "[lowerReturnBlock] inline " << F->getName() << '\n');
    F->addFnAttr(Attribute::AlwaysInline);
    legacy::PassManager PassMgr;
    PassMgr.add(createAlwaysInlinerPass(/*InsertLifetime=*/ false));
    PassMgr.run(*M);
    Inlined = true;
    return true;
  }

  Value *
  removeCast(Value *V) {
    auto Cast = dyn_cast<ConstantExpr>(V);
    if (Cast && Cast->isCast()) {
      return Cast->getOperand(0);
    }
    return V;
  }

  void
  getBlockInvokeFuncAndContext(Value *Blk, Function **PInvF, Value **PCtx){
    Function *InvF = nullptr;
    Value *Ctx = nullptr;
    if (auto CallBlkBind = dyn_cast<CallInst>(Blk)) {
      assert(CallBlkBind->getCalledFunction()->getName() ==
          SPIR_INTRINSIC_BLOCK_BIND && "Invalid block");
      InvF = dyn_cast<Function>(removeCast(CallBlkBind->getArgOperand(0)));
      Ctx = CallBlkBind->getArgOperand(3);
    } else if (auto F = dyn_cast<Function>(removeCast(Blk))) {
      InvF = F;
      Ctx = Constant::getNullValue(IntegerType::getInt8PtrTy(M->getContext()));
    } else {
      assert(0 && "Invalid block");
    }
    SPRVDBG(dbgs() << "  Block invocation func: " << InvF->getName() << '\n' <<
        "  Block context: " << *Ctx << '\n');
    assert(InvF && Ctx && "Invalid block");
    if (PInvF)
      *PInvF = InvF;
    if (PCtx)
      *PCtx = Ctx;
  }
  void
  erase(Instruction *I) {
    if (!I)
      return;
    if (I->use_empty()) {
      I->dropAllReferences();
      I->removeFromParent();
    } else
      dumpUsers(I);
  }
  void
  erase(ConstantExpr *I) {
    if (!I)
      return;
    if (I->use_empty()) {
      I->dropAllReferences();
      I->destroyConstant();
    } else
      dumpUsers(I);
  }
  void
  erase(Function *F) {
    if (!F)
      return;
    if (!F->use_empty()) {
      dumpUsers(F);
      return;
    }
    F->dropAllReferences();
    F->removeFromParent();
  }
  void
  eraseFunctions(std::vector<std::string> &L) {
    for (auto &I : L) {
      erase(M->getFunction(I));
    }
  }
};

class LLVMToSPRV {
public:
  LLVMToSPRV(Module *LLVMModule, SPRVModule *TheSPRVModule)
    :M(LLVMModule), BM(TheSPRVModule), BuiltinSetId(SPRVID_INVALID){
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
  SPRVModule *BM;
  BuiltinVarMap BuiltinGVMap;
  LLVMToSPRVTypeMap TypeMap;
  LLVMToSPRVValueMap ValueMap;
  //ToDo: support multiple builtin sets. Currently assume one builtin set.
  SPRVId BuiltinSetId;
  std::string RegularizedModuleTmpFile;

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
  bool isMangledTypeUnsigned(char Mangled);
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
  SPRVValue *transOCLAtomic(CallInst *Call, const std::string &MangledName,
      const std::string &DeMangledName, SPRVBasicBlock *BB);
  SPRVValue *oclTransBarrier(CallInst *Call,
      const std::string &DeMangledName, SPRVBasicBlock *BB);
  SPRVValue *oclTransMemFence(CallInst *Call,
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
      CallInst* CI, SPRVBasicBlock* BB);
  void mutateFuncArgType(const std::map<unsigned, Type*>& ChangedType,
      Function* F);
  bool oclIsSamplerType(llvm::Type* RT);
  SPRVValue *transSpcvCast(CallInst* CI, SPRVBasicBlock *BB);
  SPRVValue *oclTransSpvcCastSampler(CallInst* CI, SPRVBasicBlock *BB);

  bool oclRegularizeConvert(CallInst *Call, const std::string &MangledName,
      const std::string &DeMangledName,
      std::set<Value *>& ValuesForDeleting);
  void oclRegularize();
  void eraseFunctions(const std::vector<std::string> &L);
  SPRV::SPRVInstruction* transUnaryInst(UnaryInstruction* U,
      SPRVBasicBlock* BB);
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
  if (!oclIsBuiltin(F->getName(), &DemangledName))
    return false;
  SPRVDBG(bildbgs() << "CallInst: demangled name: " << DemangledName <<
      '\n');
  SPRVWord Ver = 0;
  if (BM->getSourceLanguage(&Ver) ==  SPRVSL_OpenCL)
    return DemangledName == "barrier" ||
        DemangledName == "mem_fence" ||
        DemangledName == "dot" ||
        DemangledName.find("convert_") == 0 ||
        DemangledName.find("atomic_") == 0 ||
        DemangledName.find("async_work_group") == 0 ||
        DemangledName == "wait_group_events" ||
        SPIRSPRVBuiltinInstMap::find(DemangledName);
  assert(0 && "not supported");
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
  if (OrigName != "printf" && !oclIsBuiltin(OrigName, &DemangledName))
    return false;
  if (OrigName == "printf")
    DemangledName = OrigName;
  else {
    SPRVDBG(bildbgs() << "CallInst: demangled name: " << DemangledName <<
        '\n');
    transOCLVectorLoadStoreName(DemangledName);
  }
  SPRVDBG(bildbgs() << "CallInst: modified demangled name: " << DemangledName <<
      '\n');
  SPRVExtInstSetKind BSK = SPRVBIS_Count;
  SPRVWord EP = SPRVWORD_MAX;
  BSK = BM->getBuiltinSet(BuiltinSetId);
  bool Found = false;
  switch (BSK) {
  case SPRVBIS_OpenCL12:
    Found = oclGetExtInstIndex<SPRVBuiltinOCL12Kind>(OrigName, DemangledName,
        EntryPoint);
    break;
  case SPRVBIS_OpenCL20:
    Found = oclGetExtInstIndex<SPRVBuiltinOCL20Kind>(OrigName, DemangledName,
        EntryPoint);
    break;
  case SPRVBIS_OpenCL21:
    Found = oclGetExtInstIndex<SPRVBuiltinOCL21Kind>(OrigName, DemangledName,
                                                     EntryPoint);
    break;
  default:
    assert(0 && "not supported");
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
    if (!oclIsBuiltin(I->getName(), &DemangledName))
      continue;
    SPRVDBG(bildbgs() << "Function: demangled name: " << DemangledName <<
        '\n');
    std::string BuiltinVarName;
    SPRVBuiltinVariableKind BVKind = SPRVBI_Count;
    if (!SPIRSPRVBuiltinVariableMap::find(DemangledName, &BVKind))
      continue;
    BuiltinVarName = std::string(SPRV_BUILTIN_PREFIX) +
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
    if (ST && !ST->isSized()) {
      SPRVOpCode OpCode;
      StringRef STName = ST->getName();
      // Workaround for non-conformant SPIR binary
      if (STName == "struct._event_t") {
        STName = SPIR_TYPE_NAME_EVENT_T;
        ST->setName(STName);
      }
      if (STName.find(SPIR_TYPE_NAME_PREFIX_IMAGE_T) == 0) {
        auto FirstDotPos = STName.find_first_of(SPIR_TYPE_NAME_DELIMITER, 0);
        assert (FirstDotPos != std::string::npos);
        auto SecondDotPos = STName.find_first_of(SPIR_TYPE_NAME_DELIMITER,
            FirstDotPos + 1);
        if (SecondDotPos != std::string::npos) {
          auto BaseTy = STName.substr(0, SecondDotPos);
          auto Acc = STName.substr(SecondDotPos + 1, STName.size() -
              SecondDotPos - 1);
          SPRVTypeSamplerDescriptor SamplerDesc(0, 0, 0, 0, 0);
          SPIRSPRVImageSamplerTypeMap::find(BaseTy, &SamplerDesc);
          return mapType(T, BM->addSamplerType(nullptr, SamplerDesc,
            SPIRSPRVAccessQualifierMap::map(Acc)));
        } else {
          SPRVTypeSamplerDescriptor SamplerDesc(0, 0, 0, 0, 0);
          SPIRSPRVImageSamplerTypeMap::find(STName, &SamplerDesc);
          return mapType(T, BM->addSamplerType(nullptr, SamplerDesc));
        }
      } else if (STName == SPIR_TYPE_NAME_SAMPLER_T) {
        SPRVTypeSamplerDescriptor SamplerDesc(0, 0, 0, 0, 0);
        SPIRSPRVImageSamplerTypeMap::find(STName, &SamplerDesc);
        return mapType(T, BM->addSamplerType(nullptr, SamplerDesc));
      } else if (BuiltinOpaqueGenericTypeOpCodeMap::find(STName, &OpCode)) {
        if (OpCode == SPRVOC_OpTypePipe)
          return mapType(T, BM->addPipeType());
        return mapType(T, BM->addOpaqueGenericType(OpCode));
      }
    } else 
      return mapType(T, BM->addPointerType(SPIRSPRVAddrSpaceMap::map(
        static_cast<SPIRAddressSpace>(T->getPointerAddressSpace())),
        transType(ET)));
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
    SPRVTypeSamplerDescriptor SamplerDesc(0, 0, 0, 0, 0);
    assert(!ST->getName().startswith(SPIR_TYPE_NAME_PIPE_T));
    assert(!SPIRSPRVImageSamplerTypeMap::find(ST->getName(), &SamplerDesc));
    return mapType(T, BM->addOpaqueType(T->getStructName()));
  }

  if (auto ST = dyn_cast<StructType>(T)) {
    assert(ST->isSized());
    std::vector<SPRVType *> MT;
    for (unsigned I = 0, E = T->getStructNumElements(); I != E; ++I)
      MT.push_back(transType(ST->getElementType(I)));
    return mapType(T, BM->addStructType(MT, ST->getName(), ST->isPacked()));
  }

  if (FunctionType *FT = dyn_cast<FunctionType>(T)) {
    SPRVType *RT = transType(FT->getReturnType());
    std::vector<SPRVType *> PT;
    for (FunctionType::param_iterator I = FT->param_begin(),
        E = FT->param_end(); I != E; ++I)
      PT.push_back(transType(*I));
    return mapType(T, BM->addFunctionType(RT, PT));
  }

  assert(0 && "Not implemented!");
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
  else if (F->getLinkage() != GlobalValue::InternalLinkage)
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
    BF->addDecorate(SPRVDEC_FuncParamAttr, SPRVFPA_Zext);
  if (Attrs.hasAttribute(AttributeSet::ReturnIndex, Attribute::SExt))
    BF->addDecorate(SPRVDEC_FuncParamAttr, SPRVFPA_Sext);
  SPRVDBG(dbgs() << "[transFunction] " << *F << " => ";
    bildbgs() << *BF << '\n';)
  return BF;
}

#define _SPRV_OPL(x) SPRVOC_OpLogical##x

#define _SPRV_OPB(x) SPRVOC_OpBitwise##x

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

  if (auto ConstDV = dyn_cast<ConstantDataArray>(V)) {
    std::vector<SPRVValue *> BV;
    for (unsigned I = 0, E = ConstDV->getNumElements(); I != E; ++I)
      BV.push_back(transValue(ConstDV->getElementAsConstant(I), nullptr));
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

  if (auto ConstUE = dyn_cast<ConstantExpr>(V)) {
    auto Inst = ConstUE->getAsInstruction();
    SPRVDBG(dbgs() << "ConstantExpr: " << *ConstUE << '\n';
      dbgs() << "Instruction: " << *Inst << '\n';)
    auto BI = transValue(Inst, nullptr, false);
    Inst->dropAllReferences();
    return BI;
  }

  if (auto Undef = dyn_cast<UndefValue>(V)) {
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
  unsigned ThellvmOpCode = B->getOpcode();
  SPRVOpCode TheBilOpCode;
  switch (ThellvmOpCode) {
  case Instruction::And:
    TheBilOpCode =
        B->getOperand(0)->getType()->isIntegerTy(1) ?
            _SPRV_OPL(And) : _SPRV_OPB(And);
    break;
  case Instruction::Or:
    TheBilOpCode =
        B->getOperand(0)->getType()->isIntegerTy(1) ?
            _SPRV_OPL(Or) : _SPRV_OPB(Or);
    break;
  case Instruction::Xor:
    TheBilOpCode =
        B->getOperand(0)->getType()->isIntegerTy(1) ?
            _SPRV_OPL(Xor) : _SPRV_OPB(Xor);
    break;
  default:
    TheBilOpCode = OpCodeMap::map(ThellvmOpCode);
  }
  SPRVInstruction* BI = BM->addBinaryInst(TheBilOpCode, transType(B->getType()),
      transValue(B->getOperand(0), BB), transValue(B->getOperand(1), BB), BB);
  return BI;
}

SPRVInstruction*
LLVMToSPRV::transCmpInst(CmpInst* Cmp, SPRVBasicBlock* BB) {
  VectorType* llvmVecType = dyn_cast<VectorType>(Cmp->getOperand(0)->getType());
  Type* resTy;
  if (llvmVecType) {
    resTy = VectorType::get(Type::getInt1Ty(M->getContext()),
        llvmVecType->getNumElements());
  } else {
    resTy = Type::getInt1Ty(M->getContext());
  }
  SPRVInstruction* BI = BM->addCmpInst(CmpMap::map(Cmp->getPredicate()),
      transType(resTy), transValue(Cmp->getOperand(0), BB),
      transValue(Cmp->getOperand(1), BB), BB);
  return BI;
}

SPRV::SPRVInstruction* LLVMToSPRV::transUnaryInst(UnaryInstruction* U,
    SPRVBasicBlock* BB) {
  auto OpCode = U->getOpcode();
  SPRVOpCode BOC = SPRVOC_OpNop;
  if (OpCode == Instruction::AddrSpaceCast) {
    if (U->getType()->getPointerAddressSpace() == SPIRAS_Generic)
      BOC = SPRVOC_OpPtrCastToGeneric;
    else {
      assert(U->getOperand(0)->getType()->getPointerAddressSpace() ==
          SPIRAS_Generic);
      BOC = SPRVOC_OpGenericCastToPtr;
    }
  } else
    BOC = OpCodeMap::map(OpCode);
  return BM->addUnaryInst(BOC,
      transType(U->getType()), transValue(U->getOperand(0), BB), BB);
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

  if (auto BV = transConstant(V))
    return mapValue(V, BV);

  if (Argument *Arg = dyn_cast<Argument>(V)) {
    unsigned ArgNo = Arg->getArgNo();
    SPRVFunction *BF = BB->getParent();
    //assert(BF->existArgument(ArgNo));
    return mapValue(V, BF->getArgument(ArgNo));
  }

  if (GlobalVariable *GV = dyn_cast<GlobalVariable>(V)) {
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

  if (Function *F = dyn_cast<Function>(V))
    return transFunction(F);

  if (CreateForward)
    return mapValue(V, BM->addForward());

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

  if (AllocaInst *Alc = dyn_cast<AllocaInst>(V)) {
    if (Alc->isArrayAllocation())
      return mapValue(V, BM->addVariableArrayInst(
      transType(Alc->getType()), Alc->getName(),
      SPRVSC_Function, (dyn_cast<ConstantInt>(
      Alc->getArraySize())->getZExtValue()), BB));
    else
      return mapValue(V, BM->addVariable(
      transType(Alc->getType()), false,
      SPIRSPRVLinkageTypeMap::map(GlobalValue::InternalLinkage),
      nullptr, Alc->getName(),
      SPRVSC_Function, BB));
  }

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
    return mapValue(V, BM->addAccessChainInst(
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

  // Undef index is represented by -1 in LLVM.
  // SPIRV does not allow -1 as component.
  // However here we allow it.
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

  assert(0 && "Not implemented");
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
  SPRVSourceLanguageKind Kind = BM->getSourceLanguage(&Ver);
  assert(Kind == SPRVSL_OpenCL && "not supported");
  std::stringstream SS;
  SS << "OpenCL.std." << Ver;
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
      ST->isOpaque() && ST->getStructName() == SPIR_TYPE_NAME_SAMPLER_T;
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
  SPRVExtInstSetKind BSK = SPRVBIS_Count;
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

  if (oclIsBuiltin(MangledName, &DemangledName))
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
  for (auto I = M->begin(), E = M->end(); I != E; ++I) {
    for (auto BI = I->begin(), BE = I->end(); BI != BE; ++BI) {
      for (auto II = BI->begin(), IE = BI->end(); II != IE; ++II) {
        if (auto Call = dyn_cast<CallInst>(II)) {
          Call->setTailCall(false);
          if (Call->getCalledFunction()->isIntrinsic())
            removeFnAttr(Context, Call, Attribute::NoUnwind);

          // Remove useless convert function
          std::string DemangledName;
          auto MangledName = Call->getCalledFunction()->getName();
          if (oclIsBuiltin(MangledName, &DemangledName)) {
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
          if (auto MD = II->getMetadata(MDName)) {
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
    SPRVDBG(errs() << "Fails to verify module: " << Err;)
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
  SPRVOpCode OC = SPRVOC_OpNop;
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
    Function *Kernel = dyn_cast<Function>(dyn_cast<ValueAsMetadata>(KernelMD->getOperand(0))->getValue());
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
          SPIR_TYPE_NAME_SAMPLER_T);
    } else if (isPointerToOpaqueStructType(NewTy)) {
      auto STName = NewTy->getPointerElementType()->getStructName();
      if (STName.startswith(SPIR_TYPE_NAME_PREFIX_IMAGE_T)) {
        auto Ty = STName.str();
        auto AccMD = oclGetArgAccessQualifierMetadata(F);
        auto AccStr = getMDOperandAsString(AccMD, I);
        ChangedType[I - 1] = getOrCreateOpaquePtrType(M,
            Ty + SPIR_TYPE_NAME_DELIMITER + AccStr);
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
  if (!regularize())
    return false;
  if (!transOCLBuiltinsToVariables())
    return false;
  if (!transSourceLanguage())
    return false;
  if (!transSourceExtension())
    return false;
  if (!transCompileFlag())
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
        || I->getName().startswith(SPCV_CAST))
      continue;
    SPRVFunction *BF = transFunction(I);
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
    Args.insert(Args.begin()+3, ConstantInt::getAllOnesValue(getSizetType()));
  }
  auto BArgs = transValue(Args, BB);
  return BM->addAsyncGroupCopy(SPRVES_Workgroup, BArgs[0], BArgs[1], BArgs[2],
      BArgs[3], BArgs[4], BB);
}

SPRVValue *
LLVMToSPRV::transOCLGroupBuiltins(CallInst *CI, const std::string &MangledName,
    const std::string &DemangledName, SPRVBasicBlock *BB) {
  auto Args = getArguments(CI);
  auto BArgs = transValue(Args, BB);
  return BM->addGroupInst(SPIRSPRVBuiltinInstMap::map(DemangledName),
      transType(CI->getType()),
      SPRVES_Workgroup, BArgs, BB);
}

SPRVValue *
LLVMToSPRV::transOCLAtomic(CallInst *CI, const std::string &MangledName,
    const std::string &DemangledName, SPRVBasicBlock *BB) {
  std::string NewName = DemangledName;
  if (DemangledName == "atomic_min" || DemangledName == "atomic_max") {
    auto LastChar = MangledName.back();
    if (LastChar == 'j' || LastChar == 'm')
      NewName.insert(7, "u");
  }
  std::vector<SPRVValue *> Args;
  for (unsigned I = 0, E = CI->getNumArgOperands(); I != E; ++I)
    Args.push_back(transValue(CI->getArgOperand(I), BB));
  SPRVWord MemSema = SPRVWORD_MAX;
  switch (CI->getArgOperand(0)->getType()->getPointerAddressSpace()) {
  case SPIRAS_Global:
    MemSema = static_cast<SPRVWord>(SPRVMSM_WorkgroupGlobalMemory);
    break;
  case SPIRAS_Local:
    MemSema = static_cast<SPRVWord>(SPRVMSM_WorkgroupLocalMemory);
    break;
  default:
    assert(0 && "Invalid address space");
  }
  return BM->addAtomicInst(SPIRSPRVBuiltinInstMap::map(NewName),
      transType(CI->getType()), Args, SPRVES_Workgroup,
      MemSema, BB);
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

  SPRVExtInstSetKind BSK = SPRVBIS_Count;
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
  SPRVValue * CB = BM->addControlBarrierInst(SPRVES_Workgroup,
    mapBitMask<SPIRSPRVMemFenceFlagMap>(dyn_cast<ConstantInt>(
    MemFenceFlagVal)->getZExtValue()), BB);
  return CB;
}

SPRVValue *
LLVMToSPRV::oclTransMemFence(CallInst *CI,
    const std::string &DemangledName, SPRVBasicBlock *BB) {
  assert(CI->getNumArgOperands() == 1);
  auto MemFenceFlagVal = CI->getArgOperand(0);
  assert(isa<ConstantInt>(MemFenceFlagVal));
  auto MB = BM->addMemoryBarrierInst(SPRVES_Workgroup,
    mapBitMask<SPIRSPRVMemFenceFlagMap>(dyn_cast<ConstantInt>(
    MemFenceFlagVal)->getZExtValue()), BB);
  return MB;
}

void
LLVMToSPRV::oclGetMutatedArgumentTypesByBuiltin(
    llvm::FunctionType* FT, std::map<unsigned, Type*>& ChangedType,
    Function* F) {
  auto Name = F->getName();
  std::string Demangled;
  if (!oclIsBuiltin(Name, &Demangled))
    return;
  if (Demangled.find(OCL_BUILTIN_PREFIX_READ_IMAGE) != 0 ||
      Name.find(OCL_MANGLED_TYPE_NAME_SAMPLER) == std::string::npos)
    return;
  ChangedType[1] = getOrCreateOpaquePtrType(F->getParent(),
      SPIR_TYPE_NAME_SAMPLER_T);
}

SPRVInstruction *
LLVMToSPRV::transOCLBuiltinToInstByMap(const std::string& DemangledName,
    CallInst* CI, SPRVBasicBlock* BB) {
  auto OC = SPRVOC_OpNop;
  if (SPIRSPRVBuiltinInstMap::find(DemangledName, &OC)) {
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
      auto CastOC = IsVector ? SPRVOC_OpSConvert : SPRVOC_OpUConvert;
      return BM->addUnaryInst(CastOC, BT, Cmp, BB);
    } else if (isBinaryOpCode(OC)) {
      assert(CI && CI->getNumArgOperands() == 2 && "Invalid call inst");
      return BM->addBinaryInst(OC, transType(CI->getType()),
        transValue(CI->getArgOperand(0), BB),
        transValue(CI->getArgOperand(1), BB), BB);
    } else if (CI->getNumArgOperands() == 1 && !CI->getType()->isVoidTy()) {
      return BM->addUnaryInst(OC, transType(CI->getType()),
        transValue(CI->getArgOperand(0), BB), BB);
    } else {
      auto Args = getArguments(CI);
      SPRVType *SPRetTy = nullptr;
      Type *RetTy = CI->getType();
      auto F = CI->getCalledFunction();
      auto FT = F->getFunctionType();
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
      if (OC == SPRVOC_OpBuildNDRange) {
        switch (SPArgs.size()) {
        case 1: {
          auto SizetTy = transType(getSizetType());
          SPArgs.push_back(BM->addConstant(SizetTy, 1)->getId());
          SPArgs.push_back(BM->addConstant(SizetTy, 0)->getId());
        }
        break;
        case 2: {
          auto SizetTy = transType(getSizetType());
          SPArgs.push_back(BM->addConstant(SizetTy, 0)->getId());
        }
        break;
        case 3: {
          std::swap(SPArgs[0], SPArgs[2]);
          std::swap(SPArgs[0], SPArgs[1]);
        }
        break;
        default:
          assert (0 && "Invalid number of arguments");
        }
      }
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
  if (DemangledName.find("mem_fence") != std::string::npos)
    return oclTransMemFence(CI, DemangledName, BB);
  if (DemangledName.find("convert_") == 0)
    return transOCLConvert(CI, MangledName, DemangledName, BB);
  if (DemangledName.find("atom") == 0)
    return transOCLAtomic(CI, MangledName, DemangledName, BB);
  if (DemangledName.find("vload") == 0 ||
      DemangledName.find("vstore") == 0)
    return transOCLVectorLoadStore(CI, MangledName, DemangledName, BB);
  if (DemangledName.find("async_work_group") == 0)
    return transOCLAsyncGroupCopy(CI, MangledName, DemangledName, BB);
  if (DemangledName == "wait_group_events")
    return transOCLGroupBuiltins(CI, MangledName, DemangledName, BB);
  return transOCLBuiltinToInstByMap(DemangledName, CI, BB);
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
LLVMToSPRV::isMangledTypeUnsigned(char Mangled) {
  return Mangled == 'h' || Mangled == 't' || Mangled == 'j' || Mangled == 'm';
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
  SPRVOpCode OC = SPRVOC_OpNop;
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
        OC = Signed ? SPRVOC_OpSatConvertSToU : SPRVOC_OpSatConvertUToS;
      else
        OC = Signed ? SPRVOC_OpSConvert : SPRVOC_OpUConvert;
    }
    else
      OC = Signed ? SPRVOC_OpConvertSToF : SPRVOC_OpConvertUToF;
  } else {
    if (IsTargetInt) {
      OC = TargetSigned ? SPRVOC_OpConvertFToS : SPRVOC_OpConvertFToU;
    } else
      OC = SPRVOC_OpFConvert;
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

/// Creates an llvm type based on the "kernel_arg_type" MDString
Type* getLLVMTypeFromStr(LLVMContext *c, const std::string Str)
{
  int vecSize = 0;
  Type *ty = NULL;
  size_t pos = Str.find_first_of('*');
  assert(pos != std::string::npos && "Invalid argument type");
  std::string tyStr = Str.substr(0, pos - 1);
  pos = tyStr.find_last_of(' ');
  if (pos != std::string::npos)
    tyStr = tyStr.substr(pos + 1, Str.length());

  //check for vector type
  if ((pos = tyStr.find_first_of("0123456789")) != std::string::npos) {
    std::string vecstr = tyStr.substr(pos);
    sscanf(vecstr.data(), "%d", &vecSize);
    tyStr = tyStr.substr(0, pos);
  }

  if (tyStr == "int")
    ty = Type::getInt16Ty(*c);
  else if (tyStr == "float")
    ty = Type::getFloatTy(*c);
  else if (tyStr == "half")
    ty = Type::getHalfTy(*c);
  else if (tyStr == "double")
    ty = Type::getDoubleTy(*c);
  else
    assert("Incorrect KERNEL_ARG_TYPE metadata");

  if (vecSize)
    return PointerType::get(VectorType::get(ty, vecSize),
    SPIRSPRVAddrSpaceMap::map(SPIRAS_Global));

  return PointerType::get(ty, SPIRSPRVAddrSpaceMap::map(SPIRAS_Global));
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
    Function *Kernel = dyn_cast<Function>(dyn_cast<ValueAsMetadata>(KernelMD->getOperand(0))->getValue());
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
        foreachKernelArgMD(MD, BF,
            [this, MD, &argAccessQual](const std::string &Str,
                SPRVFunctionParameter *BA){
          if (BA->getType()->isTypePipe()) {
            Type *argDataType = getLLVMTypeFromStr(&MD->getContext(), Str);
            unsigned i = BA->getArgNo();
            SPRVTypePipe *BP = static_cast<SPRVTypePipe*>(BA->getType());
            if (!BP->getPipeType()) {
              BP->setPipeAcessQualifier(SPIRSPRVAccessQualifierMap::map(
                  argAccessQual[i]));
              BP->setPipeType(transType(argDataType));
            }
            else {
              // ToDo: Figure out a way to store different pipe types
              // (with different accessqualifer/pipedatatype) in the
              // TypeMap .Update BA type with the new pipe type
              SPRVTypePipe *BP = static_cast<SPRVTypePipe*>(
                  transType(llvm::StructType::create(M->getContext(),
                      "opencl.pipe_t")));
              BP->setPipeAcessQualifier(SPIRSPRVAccessQualifierMap::map(
                  argAccessQual[i]));
              BP->setPipeType(transType(argDataType));
            }
          }
        });
      } else if (Name == SPIR_MD_KERNEL_ARG_BASE_TYPE) {
        //Do nothing
      } else if (Name == SPIR_MD_KERNEL_ARG_TYPE_QUAL) {
        foreachKernelArgMD(MD, BF,
            [](const std::string &Str, SPRVFunctionParameter *BA){
          if (Str.find("volatile") != std::string::npos)
            BA->addDecorate(new SPRVDecorate(SPRVDEC_Volatile, BA));
          if (Str.find("restrict") != std::string::npos)
            BA->addDecorate(new SPRVDecorate(SPRVDEC_FuncParamAttr,
                BA, SPRVFPA_NoAlias));
          if (Str.find("const") != std::string::npos)
            BA->addDecorate(new SPRVDecorate(SPRVDEC_FuncParamAttr,
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
  NamedMDNode *NamedMD = M->getNamedMetadata(SPIR_MD_OCL_VERSION);
  assert (NamedMD && "Invalid SPIR");
  assert (NamedMD->getNumOperands() == 1 && "Invalid SPIR");
  MDNode *MD = NamedMD->getOperand(0);
  unsigned Major = getMDOperandAsInt(MD, 0);
  unsigned Minor = getMDOperandAsInt(MD, 1);
  BM->setSourceLanguage(SPRVSL_OpenCL, Major * 10 + Minor);
  return true;
}

/// SPIR-V does not separate OpenCL extensions with optional core features,
/// so put them together.
bool
LLVMToSPRV::transSourceExtension() {
  std::string OCLExtensions = getNamedMDAsString(M, SPIR_MD_USED_EXTENSIONS);
  std::string OCLOptionalCoreFeatures = getNamedMDAsString(M,
      SPIR_MD_USED_OPTIONAL_CORE_FEATURES);
  BM->setSourceExtension(OCLExtensions + OCLOptionalCoreFeatures);
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
  legacy::PassManager PassMgr;
  PassMgr.add(createRegularizeOCL20());
  PassMgr.run(*M);

  OCLLowerBlocks LowerBlocks(M);
  LowerBlocks.run();
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


