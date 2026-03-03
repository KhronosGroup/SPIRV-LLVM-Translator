//===- SPIRVLowerPtrToAddrDiff.cpp - Lower ptrtoaddr diff patterns --------===//
//
//                     The LLVM/SPIR-V Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2026 The Khronos Group Inc.
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
// Neither the names of The Khronos Group, nor the names of its
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
// This file implements lowering of ptrtoaddr/sub patterns to __spirv_PtrDiff
// calls. The pattern:
//   %a = ptrtoaddr ptr %p1 to iN
//   %b = ptrtoaddr ptr %p2 to iN
//   %diff = sub iN %a, %b
// is transformed to:
//   %diff = call spir_func iN @_Z...__spirv_PtrDiff(ptr %p1, ptr %p2)
//
//===----------------------------------------------------------------------===//

#include "SPIRVLowerPtrToAddrDiff.h"
#include "SPIRVInternal.h"
#include "libSPIRV/SPIRVDebug.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"

#define DEBUG_TYPE "spvptrtoadddiff"

using namespace llvm;
using namespace SPIRV;

namespace SPIRV {

bool SPIRVLowerPtrToAddrDiffPass::lowerPtrToAddrDiffPattern(Function &F) {
  bool Changed = false;

  // Collect candidate sub instructions.
  SmallVector<BinaryOperator *, 8> Candidates;

  for (auto &I : instructions(F)) {
    auto *Sub = dyn_cast<BinaryOperator>(&I);
    if (!Sub || Sub->getOpcode() != Instruction::Sub)
      continue;

    // Check if both operands are ptrtoaddr instructions.
    auto *PtrToAddr1 = dyn_cast<PtrToAddrInst>(Sub->getOperand(0));
    auto *PtrToAddr2 = dyn_cast<PtrToAddrInst>(Sub->getOperand(1));
    if (!PtrToAddr1 || !PtrToAddr2)
      continue;

    Candidates.push_back(Sub);
  }

  for (auto *Sub : Candidates) {
    auto *PtrToAddr1 = cast<PtrToAddrInst>(Sub->getOperand(0));
    auto *PtrToAddr2 = cast<PtrToAddrInst>(Sub->getOperand(1));

    Value *Ptr1 = PtrToAddr1->getPointerOperand();
    Value *Ptr2 = PtrToAddr2->getPointerOperand();

    // Create mangled __spirv_PtrDiff function call.
    Type *ResultTy = Sub->getType();
    Type *PtrTy = Ptr1->getType();
    BuiltinFuncMangleInfo MangleInfo;
    std::string FuncName =
        mangleBuiltin("__spirv_PtrDiff", {PtrTy, PtrTy}, &MangleInfo);

    FunctionCallee PtrDiffFunc = Mod->getOrInsertFunction(
        FuncName, FunctionType::get(ResultTy, {PtrTy, PtrTy}, false));

    if (auto *Func = dyn_cast<Function>(PtrDiffFunc.getCallee()))
      Func->setCallingConv(CallingConv::SPIR_FUNC);

    IRBuilder<> Builder(Sub);
    CallInst *Call = Builder.CreateCall(PtrDiffFunc, {Ptr1, Ptr2});
    Call->setCallingConv(CallingConv::SPIR_FUNC);
    Call->takeName(Sub);

    Sub->replaceAllUsesWith(Call);
    Sub->eraseFromParent();

    if (PtrToAddr1->use_empty())
      PtrToAddr1->eraseFromParent();
    if (PtrToAddr2 != PtrToAddr1 && PtrToAddr2->use_empty())
      PtrToAddr2->eraseFromParent();

    Changed = true;
  }

  return Changed;
}

bool SPIRVLowerPtrToAddrDiffPass::runLowerPtrToAddrDiff(Module &M) {
  Mod = &M;
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    Changed |= lowerPtrToAddrDiffPattern(F);
  }

  verifyRegularizationPass(M, "SPIRVLowerPtrToAddrDiff");
  return Changed;
}

llvm::PreservedAnalyses
SPIRVLowerPtrToAddrDiffPass::run(llvm::Module &M,
                                 llvm::ModuleAnalysisManager &MAM) {
  return runLowerPtrToAddrDiff(M) ? llvm::PreservedAnalyses::none()
                                  : llvm::PreservedAnalyses::all();
}

} // namespace SPIRV
