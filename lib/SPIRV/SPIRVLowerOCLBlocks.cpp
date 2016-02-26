//===- SPIRVLowerOCLBlocks.cpp – Lower OpenCL blocks -------------*- C++ -*-===//
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
/// This file implements lowering of OpenCL blocks to functions.
///
//===----------------------------------------------------------------------===//

#ifndef OCLLOWERBLOCKS_H_
#define OCLLOWERBLOCKS_H_

#include "SPIRVInternal.h"
#include "OCLUtil.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/ADT/Triple.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/CallGraph.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Pass.h"
#include "llvm/PassSupport.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include <iostream>
#include <list>
#include <memory>
#include <set>
#include <sstream>
#include <vector>

#define DEBUG_TYPE "spvblocks"

using namespace llvm;
using namespace SPIRV;
using namespace OCLUtil;

namespace SPIRV{

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
class SPIRVLowerOCLBlocks: public ModulePass {
public:
  SPIRVLowerOCLBlocks():ModulePass(ID), M(nullptr){
    initializeSPIRVLowerOCLBlocksPass(*PassRegistry::getPassRegistry());
  }

  virtual void getAnalysisUsage(AnalysisUsage &AU) const {
    AU.addRequired<CallGraphWrapperPass>();
    AU.addRequired<AliasAnalysis>();
    AU.addRequired<AssumptionCacheTracker>();
  }

  virtual bool runOnModule(Module &Module) {
    M = &Module;
    if (!lowerBlockBind())
      return false;
    lowerGetBlockInvoke();
    lowerGetBlockContext();
    erase(M->getFunction(SPIR_INTRINSIC_GET_BLOCK_INVOKE));
    erase(M->getFunction(SPIR_INTRINSIC_GET_BLOCK_CONTEXT));
    erase(M->getFunction(SPIR_INTRINSIC_BLOCK_BIND));
    DEBUG(dbgs() << "------- After OCLLowerBlocks ------------\n" <<
                    *M << '\n');
    return true;
  }

  static char ID;
private:
  const static int MaxIter = 1000;
  Module *M;

  bool
  lowerBlockBind() {
    auto F = M->getFunction(SPIR_INTRINSIC_BLOCK_BIND);
    if (!F)
      return false;
    int Iter = MaxIter;
    while(lowerBlockBind(F) && Iter > 0){
      Iter--;
      DEBUG(dbgs() << "-------------- after iteration " << MaxIter - Iter <<
          " --------------\n" << *M << '\n');
    }
    assert(Iter > 0 && "Too many iterations");
    return true;
  }

  bool
  eraseUselessFunctions() {
    bool changed = false;
    for (auto I = M->begin(), E = M->end(); I != E;) {
      Function *F = I++;
      if (!GlobalValue::isInternalLinkage(F->getLinkage()) &&
          !F->isDeclaration())
        continue;

      dumpUsers(F, "[eraseUselessFunctions] ");
      for (auto UI = F->user_begin(), UE = F->user_end(); UI != UE;) {
        auto U = *UI++;
        if (auto CE = dyn_cast<ConstantExpr>(U)){
          if (CE->use_empty()) {
            CE->dropAllReferences();
            changed = true;
          }
        }
      }
      if (F->use_empty()) {
        erase(F);
        changed = true;
      }
    }
    return changed;
  }

  void
  lowerGetBlockInvoke() {
    if (auto F = M->getFunction(SPIR_INTRINSIC_GET_BLOCK_INVOKE)) {
      for (auto UI = F->user_begin(), UE = F->user_end(); UI != UE;) {
        auto CI = dyn_cast<CallInst>(*UI++);
        assert(CI && "Invalid usage of spir_get_block_invoke");
        lowerGetBlockInvoke(CI);
      }
    }
  }

  void
  lowerGetBlockContext() {
    if (auto F = M->getFunction(SPIR_INTRINSIC_GET_BLOCK_CONTEXT)) {
      for (auto UI = F->user_begin(), UE = F->user_end(); UI != UE;) {
        auto CI = dyn_cast<CallInst>(*UI++);
        assert(CI && "Invalid usage of spir_get_block_context");
        lowerGetBlockContext(CI);
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
      DEBUG(dbgs() << "[lowerBlockBind] " << **I << '\n');
      // Handle spir_block_bind(bitcast(block_func), context_len,
      // context_align, context)
      auto CallBlkBind = cast<CallInst>(*I++);
      Function *InvF = nullptr;
      Value *Ctx = nullptr;
      Value *CtxLen = nullptr;
      Value *CtxAlign = nullptr;
      getBlockInvokeFuncAndContext(CallBlkBind, &InvF, &Ctx, &CtxLen,
          &CtxAlign);
      for (auto II = CallBlkBind->user_begin(), EE = CallBlkBind->user_end();
          II != EE;) {
        auto BlkUser = *II++;
        SPIRVDBG(dbgs() << "  Block user: " << *BlkUser << '\n');
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
          } else if (oclIsBuiltin(Name, 20, &DemangledName)) {
            lowerBlockBuiltin(CI, InvF, Ctx, CtxLen, CtxAlign, DemangledName);
            changed = true;
          } else
            llvm_unreachable("Invalid block user");
        }
      }
      erase(CallBlkBind);
    }
    changed |= eraseUselessFunctions();
    return changed;
  }

  void
  lowerGetBlockContext(CallInst *CallGetBlkCtx, Value *Ctx = nullptr) {
    if (!Ctx)
      getBlockInvokeFuncAndContext(CallGetBlkCtx->getArgOperand(0), nullptr,
          &Ctx);
    CallGetBlkCtx->replaceAllUsesWith(Ctx);
    DEBUG(dbgs() << "  [lowerGetBlockContext] " << *CallGetBlkCtx << " => " <<
        *Ctx << "\n\n");
    erase(CallGetBlkCtx);
  }

  bool
  lowerGetBlockInvoke(CallInst *CallGetBlkInvoke,
      Function *InvokeF = nullptr) {
    bool changed = false;
    for (auto UI = CallGetBlkInvoke->user_begin(),
        UE = CallGetBlkInvoke->user_end();
        UI != UE;) {
      // Handle block_func_ptr = bitcast(spir_get_block_invoke(block))
      auto CallInv = cast<Instruction>(*UI++);
      auto Cast = dyn_cast<BitCastInst>(CallInv);
      if (Cast)
        CallInv = dyn_cast<Instruction>(*CallInv->user_begin());
      DEBUG(dbgs() << "[lowerGetBlockInvoke]  " << *CallInv);
      // Handle ret = block_func_ptr(context_ptr, args)
      auto CI = cast<CallInst>(CallInv);
      auto F = CI->getCalledValue();
      if (InvokeF == nullptr) {
        getBlockInvokeFuncAndContext(CallGetBlkInvoke->getArgOperand(0),
            &InvokeF, nullptr);
        assert(InvokeF);
      }
      assert(F->getType() == InvokeF->getType());
      CI->replaceUsesOfWith(F, InvokeF);
      DEBUG(dbgs() << " => " << *CI << "\n\n");
      erase(Cast);
      changed = true;
    }
    erase(CallGetBlkInvoke);
    return changed;
  }

  void
  lowerBlockBuiltin(CallInst *CI, Function *InvF, Value *Ctx, Value *CtxLen,
      Value *CtxAlign, const std::string& DemangledName) {
    mutateCallInstSPIRV (M, CI, [=](CallInst *CI, std::vector<Value *> &Args) {
      size_t I = 0;
      size_t E = Args.size();
      for (; I != E; ++I) {
        if (isPointerToOpaqueStructType(Args[I]->getType(),
            SPIR_TYPE_NAME_BLOCK_T)) {
          break;
        }
      }
      assert (I < E);
      Args[I] = castToVoidFuncPtr(InvF);
      if (I + 1 == E) {
        Args.push_back(Ctx);
        Args.push_back(CtxLen);
        Args.push_back(CtxAlign);
      } else {
        Args.insert(Args.begin() + I + 1, CtxAlign);
        Args.insert(Args.begin() + I + 1, CtxLen);
        Args.insert(Args.begin() + I + 1, Ctx);
      }
      if (DemangledName == kOCLBuiltinName::EnqueueKernel) {
        // Insert event arguments if there are not.
        if (!isa<IntegerType>(Args[3]->getType())) {
          Args.insert(Args.begin() + 3, getInt32(M, 0));
          Args.insert(Args.begin() + 4, getOCLNullClkEventPtr());
        }
        if (!isOCLClkEventPtrType(Args[5]->getType()))
          Args.insert(Args.begin() + 5, getOCLNullClkEventPtr());
      }
      return getSPIRVFuncName(OCLSPIRVBuiltinMap::map(DemangledName));
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
    for (auto UI = F->user_begin(), UE = F->user_end(); UI != UE;) {
      auto U = *UI++;
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

      DEBUG(dbgs() << "[lowerReturnBlock] inline " << F->getName() << '\n');
      auto CG = &getAnalysis<CallGraphWrapperPass>().getCallGraph();
      auto ACT = &getAnalysis<AssumptionCacheTracker>();
      auto AA = &getAnalysis<AliasAnalysis>();
      InlineFunctionInfo IFI(CG, M->getDataLayout(), AA, ACT);
      InlineFunction(CI, IFI);
      Inlined = true;
    }
    return changed || Inlined;
  }

  void
  getBlockInvokeFuncAndContext(Value *Blk, Function **PInvF, Value **PCtx,
      Value **PCtxLen = nullptr, Value **PCtxAlign = nullptr){
    Function *InvF = nullptr;
    Value *Ctx = nullptr;
    Value *CtxLen = nullptr;
    Value *CtxAlign = nullptr;
    if (auto CallBlkBind = dyn_cast<CallInst>(Blk)) {
      assert(CallBlkBind->getCalledFunction()->getName() ==
          SPIR_INTRINSIC_BLOCK_BIND && "Invalid block");
      InvF = dyn_cast<Function>(
          CallBlkBind->getArgOperand(0)->stripPointerCasts());
      CtxLen = CallBlkBind->getArgOperand(1);
      CtxAlign = CallBlkBind->getArgOperand(2);
      Ctx = CallBlkBind->getArgOperand(3);
    } else if (auto F = dyn_cast<Function>(Blk->stripPointerCasts())) {
      InvF = F;
      Ctx = Constant::getNullValue(IntegerType::getInt8PtrTy(M->getContext()));
    } else if (auto Load = dyn_cast<LoadInst>(Blk)) {
      auto Op = Load->getPointerOperand();
      if (auto GV = dyn_cast<GlobalVariable>(Op)) {
        if (GV->isConstant()) {
          InvF = cast<Function>(GV->getInitializer()->stripPointerCasts());
          Ctx = Constant::getNullValue(IntegerType::getInt8PtrTy(M->getContext()));
        } else {
          llvm_unreachable("load non-constant block?");
        }
      } else {
        llvm_unreachable("Loading block from non global?");
      }
    } else {
      llvm_unreachable("Invalid block");
    }
    DEBUG(dbgs() << "  Block invocation func: " << InvF->getName() << '\n' <<
        "  Block context: " << *Ctx << '\n');
    assert(InvF && Ctx && "Invalid block");
    if (PInvF)
      *PInvF = InvF;
    if (PCtx)
      *PCtx = Ctx;
    if (PCtxLen)
      *PCtxLen = CtxLen;
    if (PCtxAlign)
      *PCtxAlign = CtxAlign;
  }
  void
  erase(Instruction *I) {
    if (!I)
      return;
    if (I->use_empty()) {
      I->dropAllReferences();
      I->eraseFromParent();
    }
    else
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
    auto &CG = getAnalysis<CallGraphWrapperPass>().getCallGraph();
    CG.removeFunctionFromModule(new CallGraphNode(F));
  }

  llvm::PointerType* getOCLClkEventType() {
    return getOrCreateOpaquePtrType(M, SPIR_TYPE_NAME_CLK_EVENT_T,
        SPIRAS_Global);
  }

  llvm::PointerType* getOCLClkEventPtrType() {
    return PointerType::get(getOCLClkEventType(), SPIRAS_Generic);
  }

  bool isOCLClkEventPtrType(Type *T) {
    if (auto PT = dyn_cast<PointerType>(T))
      return isPointerToOpaqueStructType(
        PT->getElementType(), SPIR_TYPE_NAME_CLK_EVENT_T);
    return false;
  }

  llvm::Constant* getOCLNullClkEventPtr() {
    return Constant::getNullValue(getOCLClkEventPtrType());
  }

  void dumpGetBlockInvokeUsers(StringRef Prompt) {
    DEBUG(dbgs() << Prompt);
    dumpUsers(M->getFunction(SPIR_INTRINSIC_GET_BLOCK_INVOKE));
  }
};

char SPIRVLowerOCLBlocks::ID = 0;
}

INITIALIZE_PASS_BEGIN(SPIRVLowerOCLBlocks, "spvblocks",
    "SPIR-V lower OCL blocks", false, false)
INITIALIZE_PASS_DEPENDENCY(CallGraphWrapperPass)
INITIALIZE_PASS_DEPENDENCY(AssumptionCacheTracker)
INITIALIZE_AG_DEPENDENCY(AliasAnalysis)
INITIALIZE_PASS_END(SPIRVLowerOCLBlocks, "spvblocks",
    "SPIR-V lower OCL blocks", false, false)

ModulePass *llvm::createSPIRVLowerOCLBlocks() {
  return new SPIRVLowerOCLBlocks();
}

#endif /* OCLLOWERBLOCKS_H_ */
