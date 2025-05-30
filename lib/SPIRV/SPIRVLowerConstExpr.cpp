//===- SPIRVLowerConstExpr.cpp - Regularize LLVM for SPIR-V ------- C++ -*-===//
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
// This file implements regularization of LLVM module for SPIR-V.
//
//===----------------------------------------------------------------------===//

#include "SPIRVLowerConstExpr.h"
#include "OCLUtil.h"
#include "SPIRVInternal.h"
#include "SPIRVMDBuilder.h"
#include "SPIRVMDWalker.h"
#include "libSPIRV/SPIRVDebug.h"

#include "llvm/ADT/StringSwitch.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/TargetParser/Triple.h"

#include <list>
#include <set>

#define DEBUG_TYPE "spv-lower-const-expr"

using namespace llvm;
using namespace SPIRV;
using namespace OCLUtil;

namespace SPIRV {

cl::opt<bool> SPIRVLowerConst(
    "spirv-lower-const-expr", cl::init(true),
    cl::desc("LLVM/SPIR-V translation enable lowering constant expression"));

class SPIRVLowerConstExprLegacy : public ModulePass,
                                  public SPIRVLowerConstExprBase {
public:
  SPIRVLowerConstExprLegacy() : ModulePass(ID) {
    initializeSPIRVLowerConstExprLegacyPass(*PassRegistry::getPassRegistry());
  }

  bool runOnModule(Module &M) override { return runLowerConstExpr(M); }

  static char ID;
};

char SPIRVLowerConstExprLegacy::ID = 0;

bool SPIRVLowerConstExprBase::runLowerConstExpr(Module &Module) {
  if (!SPIRVLowerConst)
    return false;

  M = &Module;
  Ctx = &M->getContext();

  LLVM_DEBUG(dbgs() << "Enter SPIRVLowerConstExpr:\n");
  bool Changed = visit(M);

  verifyRegularizationPass(*M, "SPIRVLowerConstExpr");

  return Changed;
}

/// Since SPIR-V cannot represent constant expression, constant expressions
/// in LLVM needs to be lowered to instructions.
/// For each function, the constant expressions used by instructions of the
/// function are replaced by instructions placed in the entry block since it
/// dominates all other BB's. Each constant expression only needs to be lowered
/// once in each function and all uses of it by instructions in that function
/// is replaced by one instruction.
/// ToDo: remove redundant instructions for common subexpression

bool SPIRVLowerConstExprBase::visit(Module *M) {
  bool Changed = false;
  for (auto &I : M->functions()) {
    std::list<Instruction *> WorkList;
    for (auto &BI : I) {
      for (auto &II : BI) {
        WorkList.push_back(&II);
      }
    }
    auto FBegin = I.begin();
    while (!WorkList.empty()) {
      auto *II = WorkList.front();

      auto LowerOp = [&II, &FBegin, &I, &Changed](Value *V) -> Value * {
        if (isa<Function>(V))
          return V;
        auto *CE = cast<ConstantExpr>(V);
        SPIRVDBG(dbgs() << "[lowerConstantExpressions] " << *CE;)
        auto *ReplInst = CE->getAsInstruction();
        auto InsPoint = II->getParent() == &*FBegin
                            ? II->getIterator()
                            : FBegin->back().getIterator();
        ReplInst->insertBefore(InsPoint);
        SPIRVDBG(dbgs() << " -> " << *ReplInst << '\n';)
        std::vector<Instruction *> Users;
        // Do not replace use during iteration of use. Do it in another loop
        for (auto *U : CE->users()) {
          SPIRVDBG(dbgs() << "[lowerConstantExpressions] Use: " << *U << '\n';)
          if (auto *InstUser = dyn_cast<Instruction>(U)) {
            // Only replace users in scope of current function
            if (InstUser->getParent()->getParent() == &I)
              Users.push_back(InstUser);
          }
        }
        for (auto &User : Users) {
          if (ReplInst->getParent() == User->getParent())
            if (User->comesBefore(ReplInst))
              ReplInst->moveBefore(User->getIterator());
          User->replaceUsesOfWith(CE, ReplInst);
        }
        Changed = true;
        return ReplInst;
      };

      WorkList.pop_front();

      for (unsigned OI = 0, OE = II->getNumOperands(); OI != OE; ++OI) {
        auto *Op = II->getOperand(OI);
        if (auto *CE = dyn_cast<ConstantExpr>(Op)) {
          WorkList.push_front(cast<Instruction>(LowerOp(CE)));
        } else if (auto *MDAsVal = dyn_cast<MetadataAsValue>(Op)) {
          Metadata *MD = MDAsVal->getMetadata();
          if (auto *ConstMD = dyn_cast<ConstantAsMetadata>(MD)) {
            Constant *C = ConstMD->getValue();
            Value *ReplInst = nullptr;
            if (auto *CE = dyn_cast<ConstantExpr>(C))
              ReplInst = LowerOp(CE);
            if (ReplInst) {
              Metadata *RepMD = ValueAsMetadata::get(ReplInst);
              Value *RepMDVal = MetadataAsValue::get(M->getContext(), RepMD);
              II->setOperand(OI, RepMDVal);
              WorkList.push_front(cast<Instruction>(ReplInst));
            }
          }
        }
      }
    }
  }
  return Changed;
}

} // namespace SPIRV

INITIALIZE_PASS(SPIRVLowerConstExprLegacy, "spv-lower-const-expr",
                "Regularize LLVM for SPIR-V", false, false)

ModulePass *llvm::createSPIRVLowerConstExprLegacy() {
  return new SPIRVLowerConstExprLegacy();
}
