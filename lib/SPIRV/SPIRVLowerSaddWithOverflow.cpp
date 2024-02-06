//===- SPIRVLowerSaddWithOverflow.cpp - Lower llvm-intrinsics -----===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2022 The Khronos Group Inc.
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
// This file implements lowering of:
//   llvm.sadd.with.overflow.*
//   llvm.bitreverse.*
// into basic LLVM operations.
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "spv-lower-llvm_intrinsic"

#include "SPIRVLowerSaddWithOverflow.h"
#include "LLVMSaddWithOverflow.h"
#include "LLVMBitreverse.h"

#include "LLVMSPIRVLib.h"
#include "SPIRVError.h"
#include "libSPIRV/SPIRVDebug.h"

#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Linker/Linker.h"
#include "llvm/Support/SourceMgr.h"

using namespace llvm;
using namespace SPIRV;

namespace SPIRV {

namespace {
typedef struct llvm_intrinsic_map_entry_type {
  const Intrinsic::ID  ID;
  const ExtensionID    SupportingExtension;
  const char          *LLVMFuncName;
  const char          *SPIRVFuncName;
  const char          *ModuleText;
} LLVMIntrinsicMapEntryType;

#define NO_SUPPORTING_EXTENSION ExtensionID::Last

const LLVMIntrinsicMapEntryType LLVMIntrinsicMapEntries[] = {
  {Intrinsic::bitreverse,         ExtensionID::SPV_KHR_bit_instructions, "llvm.bitreverse.i16",         "llvm_bitreverse_i16",         LLVMBitreverse},
  {Intrinsic::bitreverse,         ExtensionID::SPV_KHR_bit_instructions, "llvm.bitreverse.i32",         "llvm_bitreverse_i32",         LLVMBitreverse},
  {Intrinsic::bitreverse,         ExtensionID::SPV_KHR_bit_instructions, "llvm.bitreverse.i64",         "llvm_bitreverse_i64",         LLVMBitreverse},
  {Intrinsic::sadd_with_overflow, NO_SUPPORTING_EXTENSION,               "llvm.sadd.with.overflow.i16", "llvm_sadd_with_overflow_i16", LLVMSaddWithOverflow},
  {Intrinsic::sadd_with_overflow, NO_SUPPORTING_EXTENSION,               "llvm.sadd.with.overflow.i32", "llvm_sadd_with_overflow_i32", LLVMSaddWithOverflow},
  {Intrinsic::sadd_with_overflow, NO_SUPPORTING_EXTENSION,               "llvm.sadd.with.overflow.i64", "llvm_sadd_with_overflow_i64", LLVMSaddWithOverflow},
};

} // namespace

void SPIRVLowerLLVMIntrinsicBase::visitIntrinsicInst(CallInst &I) {
  IntrinsicInst *II = dyn_cast<IntrinsicInst>(&I);

  std::string FuncName;
  const char *ModuleText{nullptr};

  if (!II) return;

  Function *IntrinsicFunc = I.getCalledFunction();
  assert(IntrinsicFunc && "Missing function");
  StringRef IntrinsicName = IntrinsicFunc->getName();

  for (const LLVMIntrinsicMapEntryType &LLVMIntrinsicMapEntry : LLVMIntrinsicMapEntries) {
    if (II->getIntrinsicID() == LLVMIntrinsicMapEntry.ID &&
        IntrinsicName == LLVMIntrinsicMapEntry.LLVMFuncName &&
        // Intrinsic is not supported by an extension
        !Opts.isAllowedToUseExtension(LLVMIntrinsicMapEntry.SupportingExtension)) {
      // emulation is needed
      FuncName   = LLVMIntrinsicMapEntry.SPIRVFuncName;
      ModuleText = LLVMIntrinsicMapEntry.ModuleText;
    }
  }

  if (!ModuleText) return;

  // Redirect @llvm.* call to the function we have in
  // the loaded module in ModuleText
  Function *F = Mod->getFunction(FuncName);
  if (F) { // This function is already linked in.
    I.setCalledFunction(F);
    return;
  }
  FunctionCallee FC = Mod->getOrInsertFunction(FuncName, I.getFunctionType());
  I.setCalledFunction(FC);

  // Read LLVM IR with the intrinsic's implementation
  SMDiagnostic Err;
  auto MB = MemoryBuffer::getMemBuffer(ModuleText);
  auto EmulationModule =
      parseIR(MB->getMemBufferRef(), Err, *Context,
              ParserCallbacks([&](StringRef, StringRef) {
                return Mod->getDataLayoutStr();
              }));
  if (!EmulationModule) {
    std::string ErrMsg;
    raw_string_ostream ErrStream(ErrMsg);
    Err.print("", ErrStream);
    SPIRVErrorLog EL;
    EL.checkError(false, SPIRVEC_InvalidLlvmModule, ErrMsg);
    return;
  }

  // Link in the intrinsic's implementation.
  if (!Linker::linkModules(*Mod, std::move(EmulationModule),
                           Linker::LinkOnlyNeeded))
    TheModuleIsModified = true;
}

bool SPIRVLowerLLVMIntrinsicBase::runLowerLLVMIntrinsic(Module &M) {
  Context = &M.getContext();
  Mod = &M;
  visit(M);

  verifyRegularizationPass(M, "SPIRVLowerLLVMIntrinsic");
  return TheModuleIsModified;
}

SPIRVLowerLLVMIntrinsicPass::SPIRVLowerLLVMIntrinsicPass(const SPIRV::TranslatorOpts &Opts) : SPIRVLowerLLVMIntrinsicBase(Opts) {
}

llvm::PreservedAnalyses
SPIRVLowerLLVMIntrinsicPass::run(llvm::Module &M,
                                    llvm::ModuleAnalysisManager &MAM) {
  return runLowerLLVMIntrinsic(M) ? llvm::PreservedAnalyses::none()
                                  : llvm::PreservedAnalyses::all();
}

SPIRVLowerLLVMIntrinsicLegacy::SPIRVLowerLLVMIntrinsicLegacy(const SPIRV::TranslatorOpts &Opts)
  : ModulePass(ID), SPIRVLowerLLVMIntrinsicBase(Opts) {
  initializeSPIRVLowerLLVMIntrinsicLegacyPass(
      *PassRegistry::getPassRegistry());
}

bool SPIRVLowerLLVMIntrinsicLegacy::runOnModule(Module &M) {
  return runLowerLLVMIntrinsic(M);
}

char SPIRVLowerLLVMIntrinsicLegacy::ID = 0;

} // namespace SPIRV

INITIALIZE_PASS(SPIRVLowerLLVMIntrinsicLegacy,
                "spv-lower-llvm-intrinsic",
                "Lower llvm intrinsics", false, false)

ModulePass *llvm::createSPIRVLowerLLVMIntrinsicLegacy(const SPIRV::TranslatorOpts &Opts) {
  return new SPIRVLowerLLVMIntrinsicLegacy(Opts);
}
