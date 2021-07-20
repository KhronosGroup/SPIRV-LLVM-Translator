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
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"

#include <stack>
#include <utility>

using namespace llvm;

namespace {

class SPIRVLowerBitCastToNonStandardTypeBase {
public:
  SPIRVLowerBitCastToNonStandardTypeBase() {}

  bool runLowerBitCastToNonStandardType(Module &Module) {
    // This pass doesn't cover all possible uses of non-standard types, only
    // known
    auto *M = &Module;
    bool Changed = false;

    std::vector<std::pair<Instruction *, VectorType *>> BCastsToNonStdVec;
    std::stack<Instruction *> InstsToErase;
    for (auto &F : M->functions())
      for (auto &BB : F)
        for (auto &I : BB)
          if (BitCastInst *BC = dyn_cast<BitCastInst>(&I)) {
            auto *DestTy = BC->getDestTy();
            if (auto *ElemTy = dyn_cast<PointerType>(DestTy))
              DestTy = ElemTy->getElementType();
            if (auto *DestVecTy = dyn_cast<VectorType>(DestTy)) {
              uint64_t NumElemsInDestVec =
                  DestVecTy->getElementCount().getValue();
              if (NumElemsInDestVec != 2 && NumElemsInDestVec != 3 &&
                  NumElemsInDestVec != 4 && NumElemsInDestVec != 8 &&
                  NumElemsInDestVec != 16)
                BCastsToNonStdVec.push_back(std::make_pair(&I, DestVecTy));
            }
          }

    for (auto &I : BCastsToNonStdVec)
      Changed |= lowerBitCastToNonStdVec(I, InstsToErase);

    while (!InstsToErase.empty()) {
      InstsToErase.top()->eraseFromParent();
      InstsToErase.pop();
    }

    verifyRegularizationPass(*M, "SPIRVLowerBitCastToNonStandardType");
    return Changed;
  }

  bool lowerBitCastToNonStdVec(std::pair<Instruction *, VectorType *> &Inst,
                               std::stack<Instruction *> &InstsToErase) {
    bool Changed = false;
    std::vector<Instruction *> InstsToInsert;
    Instruction *I = Inst.first;
    VectorType *DestVecTy = Inst.second;
    uint64_t NumElemsInDestVec = DestVecTy->getElementCount().getValue();
    InstsToErase.push(I);
    AddrSpaceCastInst *Src{nullptr};
    auto *II = I;
    while ((II = II->getNextNode())) {
      if (auto *ASCI = dyn_cast<AddrSpaceCastInst>(II)) {
        unsigned DestAddrSpace = ASCI->getDestAddressSpace();
        auto *SrcPointer = cast<CastInst>(I)->getSrcTy();
        auto *SrcTy = cast<PointerType>(SrcPointer)->getElementType();
        SrcPointer = SrcTy->getPointerTo(DestAddrSpace);
        if (ASCI->getOperand(0) == cast<Value>(I)) {
          Src = new AddrSpaceCastInst(I->getOperand(0), SrcPointer);
          InstsToInsert.push_back(Src);
          InstsToErase.push(II);
          break;
        }
      }
    }
    if (!II)
      II = I;
    auto *SrcTy =
        cast<PointerType>(cast<Value>(Src)->getType())->getElementType();
    LoadInst *Load =
        Src ? new LoadInst(SrcTy, Src, "", false, Align())
            : new LoadInst(SrcTy, I->getOperand(0), "", false, Align());
    InstsToInsert.push_back(Load);
    auto *III = II;
    while ((III = III->getNextNode())) {
      if (LoadInst *LI = dyn_cast<LoadInst>(III))
        if (LI->getOperand(0) == II) {
          InstsToErase.push(III);
          break;
        }
    }
    if (!III)
      III = II;
    uint64_t NumElemsInSrcVec =
        cast<VectorType>(SrcTy)->getElementCount().getValue();
    int ElemIdx = 0;
    Instruction *IIII{nullptr};
    while ((II = II->getNextNode())) {
      if (auto *EEI = dyn_cast<ExtractElementInst>(II)) {
        if (EEI->getOperand(0) == cast<Value>(III)) {
          ElemIdx = cast<ConstantInt>(EEI->getIndexOperand())->getSExtValue() /
                    (NumElemsInDestVec / NumElemsInSrcVec);
          IIII = II;
          InstsToErase.push(IIII);
          break;
        }
      }
    }
    auto *ExtractElement = ExtractElementInst::Create(
        Load, ConstantInt::get(Type::getInt64Ty(I->getContext()), ElemIdx));
    InstsToInsert.push_back(ExtractElement);
    auto *Trunc = new TruncInst(ExtractElement, DestVecTy->getElementType());
    InstsToInsert.push_back(Trunc);
    InstsToInsert[0]->insertBefore(I);
    for (size_t It = 1; It < InstsToInsert.size(); It++)
      InstsToInsert[It]->insertAfter(InstsToInsert[It - 1]);
    IIII->replaceAllUsesWith(Trunc);
    if (InstsToInsert.size())
      Changed = true;
    return Changed;
  }
};

class SPIRVLowerBitCastToNonStandardTypePass
    : public llvm::PassInfoMixin<SPIRVLowerBitCastToNonStandardTypePass>,
      public SPIRVLowerBitCastToNonStandardTypeBase {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &MAM) {
    return runLowerBitCastToNonStandardType(M) ? llvm::PreservedAnalyses::none()
                                               : llvm::PreservedAnalyses::all();
  }
};

class SPIRVLowerBitCastToNonStandardTypeLegacy
    : public ModulePass,
      public SPIRVLowerBitCastToNonStandardTypeBase {
public:
  SPIRVLowerBitCastToNonStandardTypeLegacy() : ModulePass(ID) {}

  bool runOnModule(Module &M) override {
    return runLowerBitCastToNonStandardType(M);
  }

  StringRef getPassName() const override { return "Lower nonstandard type"; }

  static char ID;
};

char SPIRVLowerBitCastToNonStandardTypeLegacy::ID = 0;

} // namespace

INITIALIZE_PASS(SPIRVLowerBitCastToNonStandardTypeLegacy,
                "spv-lower-bitcast-to-nonstandard-type",
                "Remove bitcast to nonstandard types", false, false)

llvm::ModulePass *llvm::createSPIRVLowerBitCastToNonStandardTypeLegacy() {
  return new SPIRVLowerBitCastToNonStandardTypeLegacy();
}
