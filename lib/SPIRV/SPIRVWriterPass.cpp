//===- SPIRVWriterPass.cpp - SPIRV writing pass -----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// SPIRVWriterPass implementation.
//
//===----------------------------------------------------------------------===//

#include "SPIRVWriterPass.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"
#include "SPIRV.h"
using namespace llvm;

PreservedAnalyses SPIRVWriterPass::run(Module &M) {
  // FIXME: at the moment LLVM/SPIR-V translation errors are ignored.
  std::string err;
  WriteSPIRV(&M, OS, err);
  return PreservedAnalyses::all();
}

namespace {
  class WriteSPIRVPass : public ModulePass {
    raw_ostream &OS; // raw_ostream to print on
  public:
    static char ID; // Pass identification, replacement for typeid
    explicit WriteSPIRVPass(raw_ostream &o)
      : ModulePass(ID), OS(o) {}

    const char *getPassName() const override { return "SPIRV Writer"; }

    bool runOnModule(Module &M) override {
      // FIXME: at the moment LLVM/SPIR-V translation errors are ignored.
      std::string err;
      WriteSPIRV(&M, OS, err);
      return false;
    }
  };
}

char WriteSPIRVPass::ID = 0;

ModulePass *llvm::createSPIRVWriterPass(raw_ostream &Str) {
  return new WriteSPIRVPass(Str);
}
