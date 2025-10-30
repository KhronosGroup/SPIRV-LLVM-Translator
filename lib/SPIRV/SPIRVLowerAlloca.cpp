//===- SPIRVLowerAlloca.cpp - Hoist allocas to entry block ----------------===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2025 The Khronos Group Inc.
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
// This file implements moving alloca instructions to the entry block and
// inserting appropriate lifetime intrinsics to satisfy SPIR-V requirements
// that all OpVariable instructions must be in the first block of a function.
//
//===----------------------------------------------------------------------===//

#include "SPIRVLowerAlloca.h"
#include "SPIRVInternal.h"
#include "libSPIRV/SPIRVDebug.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/PassManager.h"

#define DEBUG_TYPE "spvalloca"

using namespace llvm;
using namespace SPIRV;

namespace SPIRV {

// Check if there's already a lifetime.start intrinsic for the given alloca.
static bool hasLifetimeStart(AllocaInst *AI) {
  for (User *U : AI->users()) {
    if (auto *II = dyn_cast<IntrinsicInst>(U)) {
      if (II->getIntrinsicID() == Intrinsic::lifetime_start)
        return true;
    }
  }
  return false;
}

// Find all basic blocks that use the alloca (directly or through
// bitcasts/GEPs).
static void findAllocaUsers(Value *V, SmallPtrSetImpl<BasicBlock *> &UserBlocks,
                            SmallPtrSetImpl<Value *> &Visited) {
  if (!Visited.insert(V).second)
    return;

  for (User *U : V->users()) {
    if (auto *Inst = dyn_cast<Instruction>(U)) {
      UserBlocks.insert(Inst->getParent());

      // Follow through bitcasts, GEPs, etc.
      if (isa<BitCastInst>(Inst) || isa<GetElementPtrInst>(Inst) ||
          isa<AddrSpaceCastInst>(Inst)) {
        findAllocaUsers(Inst, UserBlocks, Visited);
      }
    }
  }
}

// Find the best location to insert lifetime.end.
// This should be a block that post-dominates all uses of the alloca.
static BasicBlock *findLifetimeEndLocation(AllocaInst *AI, BasicBlock *AllocaBB,
                                           Function &F) {
  SmallPtrSet<BasicBlock *, 8> UserBlocks;
  SmallPtrSet<Value *, 8> Visited;

  findAllocaUsers(AI, UserBlocks, Visited);

  // If the alloca is only used in its original block, end lifetime there.
  if (UserBlocks.size() == 1 && UserBlocks.count(AllocaBB)) {
    return AllocaBB;
  }

  // Otherwise, we need to find a common post-dominator of all user blocks.
  // For simplicity, we'll use the function exit block(s).
  // A more sophisticated approach would use post-dominator analysis.

  // Find all return blocks.
  SmallVector<BasicBlock *, 4> ReturnBlocks;
  for (BasicBlock &BB : F) {
    if (isa<ReturnInst>(BB.getTerminator()) ||
        isa<UnreachableInst>(BB.getTerminator())) {
      ReturnBlocks.push_back(&BB);
    }
  }

  // If there's a single return block, use it.
  if (ReturnBlocks.size() == 1) {
    return ReturnBlocks[0];
  }

  // For multiple returns or complex control flow, we'll insert lifetime.end
  // at the beginning of each return block.
  // Return nullptr to signal we need multiple insertions.
  return nullptr;
}

static bool processFunction(Function &F, LLVMContext *Context) {
  if (F.isDeclaration())
    return false;

  BasicBlock &EntryBB = F.getEntryBlock();
  SmallVector<AllocaInst *, 8> AllocasToMove;

  // Find all allocas not in the entry block.
  for (BasicBlock &BB : F) {
    if (&BB == &EntryBB)
      continue;

    for (Instruction &I : BB) {
      if (auto *AI = dyn_cast<AllocaInst>(&I)) {
        // Skip VLA.
        if (isa<ConstantInt>(AI->getArraySize()))
          AllocasToMove.push_back(AI);
      }
    }
  }

  if (AllocasToMove.empty())
    return false;

  bool Changed = false;
  IRBuilder<> Builder(*Context);

  // Find the insertion point in the entry block.
  // Place after existing allocas.
  Instruction *InsertPoint = &*EntryBB.getFirstInsertionPt();
  for (Instruction &I : EntryBB) {
    if (isa<AllocaInst>(&I))
      InsertPoint = I.getNextNode();
    else
      break;
  }

  for (AllocaInst *AI : AllocasToMove) {
    BasicBlock *OriginalBB = AI->getParent();

    // Move the alloca to the entry block.
    AI->removeFromParent();
    AI->insertBefore(*InsertPoint->getParent(), InsertPoint->getIterator());
    Changed = true;

    // Check if there's already a lifetime.start.
    bool HasLifetimeStart = hasLifetimeStart(AI);

    if (!HasLifetimeStart) {
      // Insert lifetime.start at the original location.
      Builder.SetInsertPoint(OriginalBB, OriginalBB->getFirstInsertionPt());

      // Calculate size for lifetime intrinsic.
      const DataLayout &DL = F.getParent()->getDataLayout();
      Type *AllocatedType = AI->getAllocatedType();
      uint64_t Size = 0;
      if (AllocatedType->isSized()) {
        Size = DL.getTypeAllocSize(AllocatedType);
        if (AI->isArrayAllocation()) {
          if (auto *CI = dyn_cast<ConstantInt>(AI->getArraySize())) {
            Size *= CI->getZExtValue();
          } else {
            // For dynamic arrays, use -1 (unknown size).
            Size = -1ULL;
          }
        }
      } else {
        Size = -1ULL;
      }

      Builder.CreateLifetimeStart(AI);
    }

    // Insert lifetime.end.
    BasicBlock *EndBB = findLifetimeEndLocation(AI, OriginalBB, F);

    if (EndBB) {
      // Single end location.
      Builder.SetInsertPoint(EndBB->getTerminator());

      const DataLayout &DL = F.getParent()->getDataLayout();
      Type *AllocatedType = AI->getAllocatedType();
      uint64_t Size = 0;
      if (AllocatedType->isSized()) {
        Size = DL.getTypeAllocSize(AllocatedType);
        if (AI->isArrayAllocation()) {
          if (auto *CI = dyn_cast<ConstantInt>(AI->getArraySize())) {
            Size *= CI->getZExtValue();
          } else {
            Size = -1ULL;
          }
        }
      } else {
        Size = -1ULL;
      }

      Builder.CreateLifetimeEnd(AI);
    } else {
      // Multiple return blocks - insert before each return.
      const DataLayout &DL = F.getParent()->getDataLayout();
      Type *AllocatedType = AI->getAllocatedType();
      uint64_t Size = 0;
      if (AllocatedType->isSized()) {
        Size = DL.getTypeAllocSize(AllocatedType);
        if (AI->isArrayAllocation()) {
          if (auto *CI = dyn_cast<ConstantInt>(AI->getArraySize())) {
            Size *= CI->getZExtValue();
          } else {
            Size = -1ULL;
          }
        }
      } else {
        Size = -1ULL;
      }

      for (BasicBlock &BB : F) {
        Instruction *Term = BB.getTerminator();
        if (isa<ReturnInst>(Term) || isa<UnreachableInst>(Term)) {
          Builder.SetInsertPoint(Term);
          Builder.CreateLifetimeEnd(AI);
        }
      }
    }
  }

  return Changed;
}

bool SPIRVLowerAllocaBase::runLowerAlloca(Module &M) {
  Context = &M.getContext();
  bool Changed = false;

  for (Function &F : M) {
    Changed |= processFunction(F, Context);
  }

  verifyRegularizationPass(M, "SPIRVLowerAlloca");
  return Changed;
}

PreservedAnalyses SPIRVLowerAllocaPass::run(Module &M,
                                            ModuleAnalysisManager &MAM) {
  return runLowerAlloca(M) ? PreservedAnalyses::none()
                           : PreservedAnalyses::all();
}

SPIRVLowerAllocaLegacy::SPIRVLowerAllocaLegacy() : ModulePass(ID) {}

bool SPIRVLowerAllocaLegacy::runOnModule(Module &M) {
  return runLowerAlloca(M);
}

char SPIRVLowerAllocaLegacy::ID = 0;

} // namespace SPIRV

using namespace SPIRV;

INITIALIZE_PASS(SPIRVLowerAllocaLegacy, "spvalloca",
                "Hoist allocas to entry block with lifetime intrinsics", false,
                false)

ModulePass *llvm::createSPIRVLowerAllocaLegacy() {
  return new SPIRVLowerAllocaLegacy();
}
