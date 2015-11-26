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
// This file implements regularization of LLVM moduel for SPIR-V.
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "spv-lower-const-expr"

#include "SPIRVInternal.h"
#include "OCLUtil.h"
#include "SPIRVMDBuilder.h"
#include "SPIRVMDWalker.h"

#include "llvm/ADT/StringSwitch.h"
#include "llvm/ADT/Triple.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Pass.h"
#include "llvm/PassSupport.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

#include <list>
#include <set>

using namespace llvm;
using namespace SPIRV;
using namespace OCLUtil;

namespace SPIRV {

cl::opt<bool> SPIRVLowerConst("spirv-lower-const-expr", cl::init(true),
    cl::desc("LLVM/SPIR-V translation enalbe lowering constant expression"));

class SPIRVLowerConstExpr: public ModulePass {
public:
  SPIRVLowerConstExpr():ModulePass(ID), M(nullptr), Ctx(nullptr) {
    initializeSPIRVLowerConstExprPass(*PassRegistry::getPassRegistry());
  }

  virtual bool runOnModule(Module &M);
  void visit(Module *M);

  static char ID;
private:
  Module *M;
  LLVMContext *Ctx;
};

char SPIRVLowerConstExpr::ID = 0;

bool
SPIRVLowerConstExpr::runOnModule(Module& Module) {
  if (!SPIRVLowerConst)
    return false;

  M = &Module;
  Ctx = &M->getContext();

  DEBUG(dbgs() << "Enter SPIRVLowerConstExpr:\n");
  visit(M);

  DEBUG(dbgs() << "After SPIRVLowerConstExpr:\n" << *M);
  std::string Err;
  raw_string_ostream ErrorOS(Err);
  if (verifyModule(*M, &ErrorOS)){
    DEBUG(errs() << "Fails to verify module: " << ErrorOS.str());
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

void
SPIRVLowerConstExpr::visit(Module *M) {
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
            SPIRVDBG(dbgs() << "[lowerConstantExpressions] " << *CE;)
            auto ReplInst = CE->getAsInstruction();
            ReplInst->insertBefore(FBegin->begin());
            SPIRVDBG(dbgs() << " -> " << *ReplInst << '\n';)
            WorkList.push_front(ReplInst);
            std::vector<Instruction *> Users;
            // Do not replace use during iteration of use. Do it in another loop.
            for (auto U:CE->users()){
              SPIRVDBG(dbgs() << "[lowerConstantExpressions] Use: " <<
                  *U << '\n';)
              if (auto InstUser = dyn_cast<Instruction>(U)) {
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
}

}

INITIALIZE_PASS(SPIRVLowerConstExpr, "spv-lower-const-expr",
    "Regularize LLVM for SPIR-V", false, false)

ModulePass *llvm::createSPIRVLowerConstExpr() {
  return new SPIRVLowerConstExpr();
}
