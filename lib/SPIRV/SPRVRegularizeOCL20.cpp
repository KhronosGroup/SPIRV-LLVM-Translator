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
#define DEBUG_TYPE "regocl20"

#include "SPRVInternal.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Pass.h"
#include "llvm/PassSupport.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace SPRV;

namespace SPRV {
class RegularizeOCL20: public ModulePass, public InstVisitor<RegularizeOCL20> {
public:
  RegularizeOCL20():ModulePass(ID) {
    initializeRegularizeOCL20Pass(*PassRegistry::getPassRegistry());
  }
  virtual void getAnalysisUsage(AnalysisUsage &AU);
  virtual bool runOnModule(Module &M);
  virtual void visitCallInst(CallInst &CI);
  static char ID;
};

char RegularizeOCL20::ID = 0;

void
RegularizeOCL20::getAnalysisUsage(AnalysisUsage& AU) {
}

bool
RegularizeOCL20::runOnModule(Module& M) {
  visit(M);
  return true;
}

void
RegularizeOCL20::visitCallInst(CallInst& CI) {
  DEBUG(dbgs() << "[visistCallInst] " << CI << '\n');
  auto F = CI.getCalledFunction();
  if (!F)
    return;

  std::string DemangledName;
  if (!oclIsBuiltin(F->getName(), 20, &DemangledName))
    return;
}

}

INITIALIZE_PASS(RegularizeOCL20, "regocl20", "Regularize OCL 2.0 module",
    false, false)

ModulePass *llvm::createRegularizeOCL20() {
  return new RegularizeOCL20();
}
