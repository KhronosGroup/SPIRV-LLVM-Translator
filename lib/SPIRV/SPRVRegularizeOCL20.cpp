//===- LLVMSPRVRegularizeOCL20.cpp – Regularize OCL20 builtins---*- C++ -*-===//
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
//
// This file implements regularization of OCL20 builtin functions.
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "spvcl20"

#include "SPRVInternal.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Pass.h"
#include "llvm/PassSupport.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace SPRV;

namespace SPRV {
class SPRVRegularizeOCL20: public ModulePass,
  public InstVisitor<SPRVRegularizeOCL20> {
public:
  SPRVRegularizeOCL20():ModulePass(ID) {
    initializeSPRVRegularizeOCL20Pass(*PassRegistry::getPassRegistry());
  }
  virtual void getAnalysisUsage(AnalysisUsage &AU);
  virtual bool runOnModule(Module &M);
  virtual void visitCallInst(CallInst &CI);
  void visitCallGetFence(CallInst *CI,
      const std::string &DemangledName);
  void visitCallNDRange(Module *M, CallInst *CI,
      const std::string &DemangledName);

  /// Transform atom_cmpxchg/atomic_cmpxchg to atomic_compare_exchange.
  /// In atom_cmpxchg/atomic_cmpxchg, the expected value parameter is a value.
  /// However in atomic_compare_exchange it is a pointer. The transformation
  /// adds an alloca instruction, store the expected value in the pointer, and
  /// pass the pointer as argument.
  void visitCallAtomic(Module *M, CallInst *CI,
      const std::string &DemangledName);
  static char ID;
};

char SPRVRegularizeOCL20::ID = 0;

void
SPRVRegularizeOCL20::getAnalysisUsage(AnalysisUsage& AU) {
}

bool
SPRVRegularizeOCL20::runOnModule(Module& M) {
  visit(M);

  DEBUG(dbgs() << "After RegularizeOCL20:\n" << M);

  std::string Err;
  raw_string_ostream ErrorOS(Err);
  if (verifyModule(M, &ErrorOS)){
    DEBUG(errs() << "Fails to verify module: " << Err);
  }
  return true;
}

void
SPRVRegularizeOCL20::visitCallInst(CallInst& CI) {
  DEBUG(dbgs() << "[visistCallInst] " << CI << '\n');
  auto M = CI.getParent()->getParent()->getParent();
  auto F = CI.getCalledFunction();
  if (!F)
    return;

  std::string DemangledName;
  if (!oclIsBuiltin(F->getName(), 20, &DemangledName))
    return;
  DEBUG(dbgs() << "DemangledName == " << DemangledName.c_str() << '\n');
  if (DemangledName == kOCLBuiltinName::GetFence){
    visitCallGetFence(&CI, DemangledName);
    return;
  }
  if (DemangledName.find(kOCLBuiltinName::NDRangePrefix) == 0) {
    visitCallNDRange(M, &CI, DemangledName);
    return;
  }
  if (DemangledName == "atom_cmpxchg" ||
      DemangledName == "atomic_cmpxchg") {
    visitCallAtomic(M, &CI, DemangledName);
    return;
  }
}

void
SPRVRegularizeOCL20::visitCallGetFence(CallInst *CI,
    const std::string &DemangledName) {
  assert(DemangledName == kOCLBuiltinName::GetFence);
  int fence = 0;
  Value *V = const_cast<Value *>(CI->getArgOperand(0));
  PointerType *SrcPtrTy = cast<PointerType>(V->getType());
  unsigned InAS = SrcPtrTy->getAddressSpace();
  switch (InAS) {
    case SPIRAS_Global:
      fence = SPIRMFF_Global; //SPIRV's Global MEM Fence
      break;
    case SPIRAS_Local:
      fence = SPIRMFF_Local; //SPIRV's Local MEM Fence
      break;
    case SPIRAS_Private:
    case SPIRAS_Generic:
    case SPIRAS_Constant:
    default:
      break;
  }
  CI->replaceAllUsesWith(ConstantInt::get(CI->getType(), fence, false));

  auto F = CI->getCalledFunction();
  CI->dropAllReferences();
  CI->removeFromParent();
  return;
}

void
SPRVRegularizeOCL20::visitCallNDRange(Module *M, CallInst *CI,
    const std::string &DemangledName) {
  assert(DemangledName.find(kOCLBuiltinName::NDRangePrefix) == 0);
  auto Len = atoi(DemangledName.substr(8, 1).c_str());
  assert (Len >= 1 && Len <= 3);
  // SPIR-V ndrange structure requires 3 members in the following order:
  //   global work offset
  //   global work size
  //   local work size
  // The arguments need to add missing members.
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInst(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    for (size_t I = 1, E = Args.size(); I != E; ++I)
      Args[I] = getScalarOrArray(Args[I], Len, CI);
    switch (Args.size()) {
    case 2: {
      // Has global work size.
      auto T = Args[1]->getType();
      Args.push_back(getScalarOrArrayConstantInt(CI, T, Len, 1));
      Args.insert(Args.begin() + 1, getScalarOrArrayConstantInt(CI, T, Len, 0));
    }
      break;
    case 3: {
      // Has global and local work size.
      auto T = Args[1]->getType();
      Args.insert(Args.begin() + 1, getScalarOrArrayConstantInt(CI, T, Len, 0));
    }
      break;
    case 4: {
      // Do nothing
    }
      break;
    default:
      assert(0 && "Invalid number of arguments");
    }
    return DemangledName;
  }, true, &Attrs);
}

void
SPRVRegularizeOCL20::visitCallAtomic(Module *M, CallInst* CI,
    const std::string& DemangledName) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInst(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    auto &CmpVal = Args[1];
    auto Alloca = new AllocaInst(CmpVal->getType(), "",
        CI->getParent()->getParent()->begin());
    auto Store = new StoreInst(CmpVal, Alloca, CI);
    CmpVal = Alloca;
    return "atomic_compare_exchange_strong";
  }, true, &Attrs);
}

}

INITIALIZE_PASS(SPRVRegularizeOCL20, "regocl20", "Regularize OCL 2.0 module",
    false, false)

ModulePass *llvm::createSPRVRegularizeOCL20() {
  return new SPRVRegularizeOCL20();
}
