//===- TransOCLMD.cpp - Transform OCL metadata to SPIR-V metadata - C++ -*-===//
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
// This file implements translation of OCL metadata to SPIR-V metadata.
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "clmdtospv"

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

#include <set>

using namespace llvm;
using namespace SPIRV;
using namespace OCLUtil;

namespace SPIRV {

cl::opt<bool> EraseOCLMD("spirv-erase-cl-md", cl::init(true),
    cl::desc("Erase OpenCL metadata"));

class TransOCLMD: public ModulePass {
public:
  TransOCLMD():ModulePass(ID), M(nullptr), Ctx(nullptr), CLVer(0) {
    initializeTransOCLMDPass(*PassRegistry::getPassRegistry());
  }

  virtual bool runOnModule(Module &M);
  void visit(Module *M);

  static char ID;
private:
  Module *M;
  LLVMContext *Ctx;
  unsigned CLVer;                   /// OpenCL version as major*10+minor
};

char TransOCLMD::ID = 0;

bool
TransOCLMD::runOnModule(Module& Module) {
  M = &Module;
  Ctx = &M->getContext();
  CLVer = getOCLVersion(M);
  if (CLVer == 0)
    return false;

  DEBUG(dbgs() << "Enter TransOCLMD:\n");
  visit(M);

  DEBUG(dbgs() << "After TransOCLMD:\n" << *M);
  std::string Err;
  raw_string_ostream ErrorOS(Err);
  if (verifyModule(*M, &ErrorOS)){
    DEBUG(errs() << "Fails to verify module: " << ErrorOS.str());
  }
  return true;
}

void
TransOCLMD::visit(Module *M) {
  SPIRVMDBuilder B(*M);
  SPIRVMDWalker W(*M);
  B.addNamedMD(kSPIRVMD::Source)
      .addOp()
        .add(CLVer < kOCLVer::CL21 ? spv::SourceLanguageOpenCL_C
            : spv::SourceLanguageOpenCL_CPP)
        .add(CLVer)
        .done();
  if (EraseOCLMD)
    B.eraseNamedMD(kSPIR2MD::OCLVer)
     .eraseNamedMD(kSPIR2MD::SPIRVer);

  Triple TT(M->getTargetTriple());
  auto Arch = TT.getArch();
  assert((Arch == Triple::spir || Arch == Triple::spir64) && "Invalid triple");
  B.addNamedMD(kSPIRVMD::MemoryModel)
      .addOp()
        .add(Arch == Triple::spir ? spv::AddressingModelPhysical32 :
            AddressingModelPhysical64)
        .add(spv::MemoryModelOpenCL)
        .done();

  // Add extensions
  std::string OCLExtensions = getNamedMDAsString(M, kSPIR2MD::Extensions);
  std::string OCLOptionalCoreFeatures = getNamedMDAsString(M,
      kSPIR2MD::OptFeatures);
  auto S = concat(OCLOptionalCoreFeatures, OCLExtensions);
  SmallVector<StringRef, 10> Exts;
  StringRef(S).split(Exts, " ", -1, false);
  if (!Exts.empty()) {
    auto N = B.addNamedMD(kSPIRVMD::Extension);
    for (auto &I:Exts)
      N.addOp()
         .add(I)
         .done();
  }
  if (EraseOCLMD)
    B.eraseNamedMD(kSPIR2MD::Extensions)
     .eraseNamedMD(kSPIR2MD::OptFeatures);

  bool HasFPContract = W.getNamedMD(kSPIR2MD::FPContract);
  if (EraseOCLMD)
    B.eraseNamedMD(kSPIR2MD::FPContract);

  // Add entry points
  auto EP = B.addNamedMD(kSPIRVMD::EntryPoint);
  auto EM = B.addNamedMD(kSPIRVMD::ExecutionMode);

  // Add execution mode
  NamedMDNode *KernelMDs = M->getNamedMetadata(SPIR_MD_KERNELS);
  if (!KernelMDs)
    return;

  for (unsigned I = 0, E = KernelMDs->getNumOperands(); I < E; ++I) {
    MDNode *KernelMD = KernelMDs->getOperand(I);
    if (KernelMD->getNumOperands() == 0)
      continue;
    Function *Kernel = mdconst::dyn_extract<Function>(KernelMD->getOperand(0));

    // Workaround for OCL 2.0 producer not using SPIR_KERNEL calling convention
#if  SPCV_RELAX_KERNEL_CALLING_CONV
    Kernel->setCallingConv(CallingConv::SPIR_KERNEL);
#endif

    MDNode *EPNode;
    EP.addOp()
        .add(spv::ExecutionModelKernel)
        .add(Kernel)
        .add(Kernel->getName())
        .done(&EPNode);

    if (!HasFPContract)
      EM.addOp()
        .addOp(EPNode)
        .add(spv::ExecutionModeContractionOff)
        .done();

    for (unsigned MI = 1, ME = KernelMD->getNumOperands(); MI < ME; ++MI) {
      MDNode *MD = dyn_cast<MDNode>(KernelMD->getOperand(MI));
      if (!MD)
        continue;
      MDString *NameMD = dyn_cast<MDString>(MD->getOperand(0));
      if (!NameMD)
        continue;
      StringRef Name = NameMD->getString();
      if (Name == kSPIR2MD::WGSizeHint) {
        unsigned X, Y, Z;
        decodeMDNode(MD, X, Y, Z);
        EM.addOp()
            .addOp(EPNode)
            .add(spv::ExecutionModeLocalSizeHint)
            .add(X).add(Y).add(Z)
            .done();
      } else if (Name == kSPIR2MD::WGSize) {
        unsigned X, Y, Z;
        decodeMDNode(MD, X, Y, Z);
        EM.addOp()
            .addOp(EPNode)
            .add(spv::ExecutionModeLocalSize)
            .add(X).add(Y).add(Z)
            .done();
      } else if (Name == kSPIR2MD::VecTyHint) {
        EM.addOp()
            .addOp(EPNode)
            .add(spv::ExecutionModeVecTypeHint)
            .add(transVecTypeHint(MD))
            .done();
      }
    }
  }
}

}

INITIALIZE_PASS(TransOCLMD, "clmdtospv", "Transform OCL metadata to SPIR-V",
    false, false)

ModulePass *llvm::createTransOCLMD() {
  return new TransOCLMD();
}
