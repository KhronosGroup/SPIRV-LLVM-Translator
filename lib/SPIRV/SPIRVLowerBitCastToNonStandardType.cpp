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

class SPIRVLowerBitCastToNonStandardTypePass {
public:
  SPIRVLowerBitCastToNonStandardTypePass() {}

  PreservedAnalyses
  runLowerBitCastToNonStandardType(Function &F, FunctionAnalysisManager &FAM) {
    // This pass doesn't cover all possible uses of non-standard types, only
    // known. We assume that bad type won't be passed to a function as
    // parameter, since it added by an optimization.
    bool Changed = false;

    std::vector<std::pair<Instruction *, VectorType *>> BCastsToNonStdVec;
    std::vector<Instruction *> InstsToErase;
    for (auto &BB : F)
      for (auto &I : BB) {
        auto *BC = dyn_cast<BitCastInst>(&I);
        if (!BC)
          continue;
        auto *DestTy = BC->getDestTy();
        if (auto *ElemTy = dyn_cast<PointerType>(DestTy))
          DestTy = ElemTy->getElementType();
        if (auto *DestVecTy = dyn_cast<VectorType>(DestTy)) {
          uint64_t NumElemsInDestVec = DestVecTy->getElementCount().getValue();
          if (!isValidVectorSize(NumElemsInDestVec))
            BCastsToNonStdVec.push_back(std::make_pair(&I, DestVecTy));
        }
      }

    for (auto &I : BCastsToNonStdVec)
      Changed |= lowerBitCastToNonStdVec(I, InstsToErase);

    for (int I = InstsToErase.size() - 1; I >= 0; I--)
      InstsToErase[I]->eraseFromParent();

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }

  bool lowerBitCastToNonStdVec(std::pair<Instruction *, VectorType *> &Inst,
                               std::vector<Instruction *> &InstsToErase) {
    bool Changed = false;
    Instruction *I = Inst.first;
    VectorType *DestVecTy = Inst.second;
    uint64_t NumElemsInDestVec = DestVecTy->getElementCount().getValue();
    InstsToErase.push_back(I);
    auto *ASCastInstIter = I;
    IRBuilder<> Builder(I);
    Value *Src = nullptr;
    // It is assumed that the function can contain addrspacecast after handled
    // bitcast instruction, so addrspacecast should also be handled
    for (auto *U : I->users()) {
      if (auto *ASCastInst = dyn_cast<AddrSpaceCastInst>(U)) {
        unsigned DestAddrSpace = ASCastInst->getDestAddressSpace();
        auto *SrcPointer = cast<CastInst>(I)->getSrcTy();
        auto *SrcTy = cast<PointerType>(SrcPointer)->getElementType();
        SrcPointer = SrcTy->getPointerTo(DestAddrSpace);
        if (ASCastInst->getOperand(0) == cast<Value>(I)) {
          Src = new AddrSpaceCastInst(I->getOperand(0), SrcPointer);
          Builder.Insert(Src);
          ASCastInstIter = cast<Instruction>(U);
          InstsToErase.push_back(ASCastInstIter);
          break;
        }
      }
    }
    auto *SrcTy = cast<PointerType>((Src)->getType())->getElementType();
    auto *Load = Src ? Builder.CreateLoad(SrcTy, Src)
                     : Builder.CreateLoad(SrcTy, I->getOperand(0));
    // In the already known pattern, the bitcast is followed by load instruction
    auto *LoadInstIter = ASCastInstIter;
    for (auto *U : ASCastInstIter->users()) {
      if (auto *LI = dyn_cast<LoadInst>(U))
        if (LI->getOperand(0) == ASCastInstIter) {
          LoadInstIter = cast<Instruction>(U);
          InstsToErase.push_back(LoadInstIter);
          break;
        }
    }
    // The bitcast is followed by extractelement instruction
    uint64_t NumElemsInSrcVec =
        cast<VectorType>(SrcTy)->getElementCount().getValue();
    int ElemIdx = 0;
    Instruction *ExtrElInstIter = LoadInstIter;
    for (auto *U : LoadInstIter->users()) {
      if (auto *EEI = dyn_cast<ExtractElementInst>(U)) {
        if (EEI->getOperand(0) == cast<Value>(LoadInstIter)) {
          ElemIdx = cast<ConstantInt>(EEI->getIndexOperand())->getSExtValue() /
                    (NumElemsInDestVec / NumElemsInSrcVec);
          ExtrElInstIter = cast<Instruction>(U);
          InstsToErase.push_back(ExtrElInstIter);
          break;
        }
      }
    }
    auto *ExtractElement = Builder.CreateExtractElement(
        Load, ConstantInt::get(Type::getInt64Ty(I->getContext()), ElemIdx));
    auto *Trunc =
        Builder.CreateTrunc(ExtractElement, DestVecTy->getElementType());
    ExtrElInstIter->replaceAllUsesWith(Trunc);
    if (InstsToErase.size())
      Changed = true;
    return Changed;
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
