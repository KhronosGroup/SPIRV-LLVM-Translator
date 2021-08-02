//===============- SPIRVLowerBitCastToNonStandardType.cpp -================//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2021 Intel Corporation. All rights reserved.
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
// Neither the names of Intel Corporation, nor the names of its
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
// This file implements lowering of BitCast to nonstandard types. LLVM
// transformations bitcast some vector types to scalar types, which are not
// universally supported across all targets. We need ensure that "optimized"
// LLVM IR doesn't have primitive types other than supported by the
// SPIR target (i.e. "scalar 8/16/32/64-bit integer and 16/32/64-bit floating
// point types, 2/3/4/8/16-element vector of scalar types").
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "spv-lower-bitcast-to-nonstandard-type"

#include "SPIRVInternal.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/PassManager.h"

#include <utility>

using namespace llvm;

namespace SPIRV {

static VectorType *getVectorType(Type *Ty) {
  if (!Ty)
    return nullptr;
  if (auto *ElemTy = dyn_cast<PointerType>(Ty))
    Ty = ElemTy->getElementType();
  return dyn_cast<VectorType>(Ty);
}

/// Since SPIR-V does not support non-standard vector types, instructions using
/// these types should be replaced in a special way to avoid using of
/// unsupported types.
/// lowerBitCastToNonStdVec function is designed to avoid using of bitcast to
/// unsupported vector types instructions and should be called if similar
/// instructions have been encountered in input LLVM IR.
bool lowerBitCastToNonStdVec(Instruction *Inst,
                             std::vector<Instruction *> &InstsToErase) {
  Instruction *OldInstIter(Inst);
  IRBuilder<> Builder(OldInstIter);
  Value *NewValue = OldInstIter->getOperand(0);
  VectorType *NewVecTy = getVectorType(NewValue->getType());
  InstsToErase.push_back(OldInstIter);
  // Handle addrspacecast instruction after bitcast if present
  for (auto *U : OldInstIter->users()) {
    if (auto *ASCastInst = dyn_cast<AddrSpaceCastInst>(U)) {
      unsigned DestAS = ASCastInst->getDestAddressSpace();
      auto *NewVecPtrTy = NewVecTy->getPointerTo(DestAS);
      // AddrSpaceCast is created explicitly instead of using method
      // IRBuilder<>.CreateAddrSpaceCast because IRBuilder doesn't create
      // separate instruction for constant values. Whereas SPIR-V translator
      // doesn't like several nested instructions in one.
      NewValue = new AddrSpaceCastInst(NewValue, NewVecPtrTy);
      Builder.Insert(NewValue);
      OldInstIter = ASCastInst;
      InstsToErase.push_back(OldInstIter);
      break;
    }
  }
  // Handle load instruction which is following the bitcast in the pattern
  for (auto *U : OldInstIter->users()) {
    if (auto *LI = dyn_cast<LoadInst>(U)) {
      NewValue = Builder.CreateLoad(NewVecTy, NewValue);
      OldInstIter = LI;
      InstsToErase.push_back(OldInstIter);
      break;
    }
  }
  // Handle extractelement instruction which is following the load
  for (auto *U : OldInstIter->users()) {
    if (auto *EEI = dyn_cast<ExtractElementInst>(U)) {
      VectorType *OldVecTy = getVectorType(Inst->getType());
      uint64_t NumElemsInOldVec = OldVecTy->getElementCount().getValue();
      uint64_t NumElemsInNewVec = NewVecTy->getElementCount().getValue();
      uint64_t ElemIdx =
          cast<ConstantInt>(EEI->getIndexOperand())->getSExtValue() /
          (NumElemsInOldVec / NumElemsInNewVec);
      NewValue = Builder.CreateExtractElement(NewValue, ElemIdx);
      NewValue = Builder.CreateTrunc(NewValue, OldVecTy->getElementType());
      OldInstIter = EEI;
      InstsToErase.push_back(OldInstIter);
      break;
    }
  }
  OldInstIter->replaceAllUsesWith(NewValue);
  return true;
}

class SPIRVLowerBitCastToNonStandardTypePass {
public:
  SPIRVLowerBitCastToNonStandardTypePass() {}

  PreservedAnalyses
  runLowerBitCastToNonStandardType(Function &F, FunctionAnalysisManager &FAM) {
    // This pass doesn't cover all possible uses of non-standard types, only
    // known. We assume that bad type won't be passed to a function as
    // parameter, since it added by an optimization.
    bool Changed = false;

    std::vector<Instruction *> BCastsToNonStdVec;
    std::vector<Instruction *> InstsToErase;
    for (auto &BB : F)
      for (auto &I : BB) {
        auto *BC = dyn_cast<BitCastInst>(&I);
        if (!BC)
          continue;
        auto *SrcTy = BC->getSrcTy();
        if (auto *SrcElemTy = dyn_cast<PointerType>(SrcTy))
          SrcTy = SrcElemTy->getElementType();
        if (auto *SrcVecTy = dyn_cast<VectorType>(SrcTy)) {
          uint64_t NumElemsInSrcVec = SrcVecTy->getElementCount().getValue();
          // assert(isValidVectorSize(NumElemsInSrcVec) &&
          //  ("Unsupported vector type with the size of: " +
          //   NumElemsInSrcVec));
          if (!isValidVectorSize(NumElemsInSrcVec))
            report_fatal_error("Unsupported vector type with the size of: " +
                                  NumElemsInSrcVec,
                              false);
        }
        VectorType *DestVecTy = getVectorType(BC->getDestTy());
        if (DestVecTy) {
          uint64_t NumElemsInDestVec = DestVecTy->getElementCount().getValue();
          if (!isValidVectorSize(NumElemsInDestVec))
            BCastsToNonStdVec.push_back(&I);
        }
      }

    for (auto &I : BCastsToNonStdVec)
      Changed |= lowerBitCastToNonStdVec(I, InstsToErase);

    for (int I = InstsToErase.size() - 1; I >= 0; I--)
      InstsToErase[I]->eraseFromParent();

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

class SPIRVLowerBitCastToNonStandardTypeLegacy
    : public FunctionPass,
      public SPIRVLowerBitCastToNonStandardTypePass {
public:
  static char ID;
  SPIRVLowerBitCastToNonStandardTypeLegacy() : FunctionPass(ID) {}

  bool runOnFunction(Function &F) override {
    FunctionAnalysisManager FAM;
    auto PA = Impl.runLowerBitCastToNonStandardType(F, FAM);
    return !PA.areAllPreserved();
  }

  bool doFinalization(Module &M) override {
    verifyRegularizationPass(M, "SPIRVLowerBitCastToNonStandardType");
    return false;
  }

  StringRef getPassName() const override { return "Lower nonstandard type"; }

private:
  SPIRVLowerBitCastToNonStandardTypePass Impl;
};

char SPIRVLowerBitCastToNonStandardTypeLegacy::ID = 0;

} // namespace SPIRV

INITIALIZE_PASS(SPIRVLowerBitCastToNonStandardTypeLegacy,
                "spv-lower-bitcast-to-nonstandard-type",
                "Remove bitcast to nonstandard types", false, false)

llvm::FunctionPass *llvm::createSPIRVLowerBitCastToNonStandardTypeLegacy() {
  return new SPIRVLowerBitCastToNonStandardTypeLegacy();
}
