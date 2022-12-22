//===- SPIRVLowerSaddIntrinsics.cpp - Lower llvm.sadd.* -------------------===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2020 Intel Corporation. All rights reserved.
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
// This file implements lowering of llvm.sadd.* into basic LLVM
// operations. Probably, in the future this pass can be generalized for other
// function calls
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "spv-lower-llvm_sadd_intrinsics"

#include "SPIRVLowerSaddIntrinsics.h"
#include "LLVMSaddWithOverflow.h"

#include "LLVMSPIRVLib.h"
#include "SPIRVError.h"
#include "libSPIRV/SPIRVDebug.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Linker/Linker.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"

using namespace llvm;
using namespace SPIRV;

namespace SPIRV {

void SPIRVLowerSaddIntrinsicsBase::replaceSaddOverflow(Function &F) {
  assert(F.getIntrinsicID() == Intrinsic::sadd_with_overflow);

  StringRef IntrinsicName = F.getName();
  std::string FuncName = "llvm_sadd_with_overflow_i";
  if (IntrinsicName.endswith(".i16"))
    FuncName += "16";
  else if (IntrinsicName.endswith(".i32"))
    FuncName += "32";
  else if (IntrinsicName.endswith(".i64"))
    FuncName += "64";
  else {
    assert(false &&
           "Unsupported overloading of llvm.sadd.with.overflow intrinsic");
    return;
  }

  // Redirect @llvm.sadd.with.overflow.* call to the function we have in
  // the loaded module @llvm_sadd_with_overflow_*
  Function *ReplacementFunc = Mod->getFunction(FuncName);
  if (!ReplacementFunc) { // This function needs linking.
    Mod->getOrInsertFunction(FuncName, F.getFunctionType());
    // Read LLVM IR with the intrinsic's implementation
    SMDiagnostic Err;
    auto MB = MemoryBuffer::getMemBuffer(LLVMSaddWithOverflow);
    auto SaddWithOverflowModule =
        parseIR(MB->getMemBufferRef(), Err, *Context,
                [&](StringRef) { return Mod->getDataLayoutStr(); });
    if (!SaddWithOverflowModule) {
      std::string ErrMsg;
      raw_string_ostream ErrStream(ErrMsg);
      Err.print("", ErrStream);
      SPIRVErrorLog EL;
      EL.checkError(false, SPIRVEC_InvalidLlvmModule, ErrMsg);
      return;
    }

    // Link in the intrinsic's implementation.
    if (!Linker::linkModules(*Mod, std::move(SaddWithOverflowModule),
                             Linker::LinkOnlyNeeded))
      TheModuleIsModified = true;

    ReplacementFunc = Mod->getFunction(FuncName);
    assert(ReplacementFunc && "How did we not link in the necessary function?");
  }

  F.replaceAllUsesWith(ReplacementFunc);
}

void SPIRVLowerSaddIntrinsicsBase::replaceSaddSat(Function &F) {
  assert(F.getIntrinsicID() == Intrinsic::sadd_sat);

  SmallVector<IntrinsicInst *, 4> Intrinsics;
  for (User *U : F.users()) {
    if (auto *II = dyn_cast<IntrinsicInst>(U))
      Intrinsics.push_back(II);
  }

  // Get the corresponding sadd_with_overflow intrinsic for the sadd_sat.
  Type *IntTy = F.getFunctionType()->getReturnType();
  Function *SaddO =
      Intrinsic::getDeclaration(Mod, Intrinsic::sadd_with_overflow, IntTy);

  // Replace all uses of the intrinsic with equivalent code relying on
  // sadd_with_overflow
  IRBuilder<> Builder(F.getContext());
  unsigned BitWidth = IntTy->getIntegerBitWidth();
  Value *IntMin = Builder.getInt(APInt::getSignedMinValue(BitWidth));
  Value *ShiftWidth = Builder.getIntN(BitWidth, BitWidth - 1);

  for (IntrinsicInst *II : Intrinsics) {
    Builder.SetInsertPoint(II);
    // {res, overflow} = @llvm.sadd_with_overflow(a, b)
    // sadd_sat(a, b) => overflow ? (res >> bitwidth) ^ intmin : res;
    Value *StructRes =
        Builder.CreateCall(SaddO, {II->getArgOperand(0), II->getArgOperand(1)});
    Value *Sum = Builder.CreateExtractValue(StructRes, 0);
    Value *Overflow = Builder.CreateExtractValue(StructRes, 1);
    Value *OverflowedRes =
        Builder.CreateXor(Builder.CreateAShr(Sum, ShiftWidth), IntMin);
    Value *Result = Builder.CreateSelect(Overflow, OverflowedRes, Sum);
    II->replaceAllUsesWith(Result);
    II->eraseFromParent();
  }

  // Now replace the sadd_with_overflow intrinsic itself.
  replaceSaddOverflow(*SaddO);
}

// This function for a given @IntegerBitWidth generates the following IR:
// Lets define T as i{IntegerBitWidth} (for example, i8, i16, i32 or i64).
// define dso_local T @FuncName(T %a, T %b) {
//   %not = xor T %a, -1
//   %cmp = icmp ult T %not, %b
//   %add = add T %b, %a
//   %retval.0 = select i1 %cmp, T 0, T %add
//   ret T %retval.0
// }
//
// which is equivalent to the following C++ code:
// unsigned T uadd_sat(unsigned T a, unsigned T b) {
//   // ~a is equivalent to std::numeric_limits<unsigned T>::max() - a
//   if (~a < b)
//     return static_cast<unsigned T>(-1);
//   return a + b;
// }
static Function *GenerateUaddSatReplacement(Module *M,
                                            const std::string FuncName,
                                            int IntegerBitWidth) {
  Function *F;
  if ((F = M->getFunction(FuncName)))
    return F;

  Type *ReturnType = IntegerType::get(M->getContext(), IntegerBitWidth);
  SmallVector<Type *> ArgTypes = {ReturnType, ReturnType};
  FunctionType *FT = FunctionType::get(ReturnType, ArgTypes, false);
  F = Function::Create(FT, Function::InternalLinkage, FuncName, M);
  BasicBlock *BB = BasicBlock::Create(F->getContext(), "entry", F);
  IRBuilder<> IB(F->getContext());
  IB.SetInsertPoint(BB);

  Value *FirstArg = F->getArg(0);
  Value *SecondArg = F->getArg(1);
  Constant *Constant = ConstantInt::getSigned(ReturnType, -1);
  Value *Not =
      IB.CreateXor(FirstArg, Constant); // This is equivalent to ~FirstArg.
  Value *Cmp = IB.CreateICmpULT(Not, SecondArg);
  Value *Add = IB.CreateAdd(FirstArg, SecondArg);
  Value *RetVal = IB.CreateSelect(Cmp, Constant, Add);
  IB.CreateRet(RetVal);
  return F;
}

void SPIRVLowerSaddIntrinsicsBase::replaceUaddSat(Function &F) {
  SmallVector<IntrinsicInst *, 4> IntrinsicInsts;
  int IBW = F.getFunctionType()->getReturnType()->getIntegerBitWidth();
  assert((IBW == 8 || IBW == 16 || IBW == 32 || IBW == 64) &&
         "Unsupported bit width of llvm.uadd.sat.* intrinsic");
  for (User *U : F.users())
    if (auto *II = dyn_cast<IntrinsicInst>(U))
      IntrinsicInsts.push_back(II);

  if (IntrinsicInsts.empty())
    return;

  std::string FuncName = "llvm_uadd_sat_i" + std::to_string(IBW);
  Function *Replacement = GenerateUaddSatReplacement(Mod, FuncName, IBW);
  for (auto *II : IntrinsicInsts) {
    SmallVector<Value *, 2> Args = {II->getArgOperand(0), II->getArgOperand(1)};
    CallInst *CI = CallInst::Create(Replacement, Args, "replaced_intrinsic");
    II->replaceAllUsesWith(CI);
    ReplaceInstWithInst(II, CI);
  }
}

bool SPIRVLowerSaddIntrinsicsBase::runLowerSaddIntrinsics(Module &M) {
  Context = &M.getContext();
  Mod = &M;
  SmallVector<Function *, 4> FuncsToRemove;
  for (Function &F : M) {
    Intrinsic::ID IntrinId = F.getIntrinsicID();
    if (IntrinId == Intrinsic::sadd_with_overflow)
      replaceSaddOverflow(F);
    else if (IntrinId == Intrinsic::sadd_sat)
      replaceSaddSat(F);
    else if (IntrinId == Intrinsic::uadd_sat) {
      replaceUaddSat(F);
      FuncsToRemove.push_back(&F);
    }
  }

  for (auto *F : FuncsToRemove)
    F->eraseFromParent();

  verifyRegularizationPass(M, "SPIRVLowerSaddIntrinsics");
  return TheModuleIsModified;
}

llvm::PreservedAnalyses
SPIRVLowerSaddIntrinsicsPass::run(llvm::Module &M,
                                  llvm::ModuleAnalysisManager &MAM) {
  return runLowerSaddIntrinsics(M) ? llvm::PreservedAnalyses::none()
                                   : llvm::PreservedAnalyses::all();
}

SPIRVLowerSaddIntrinsicsLegacy::SPIRVLowerSaddIntrinsicsLegacy()
    : ModulePass(ID) {
  initializeSPIRVLowerSaddIntrinsicsLegacyPass(
      *PassRegistry::getPassRegistry());
}

bool SPIRVLowerSaddIntrinsicsLegacy::runOnModule(Module &M) {
  return runLowerSaddIntrinsics(M);
}

char SPIRVLowerSaddIntrinsicsLegacy::ID = 0;

} // namespace SPIRV

INITIALIZE_PASS(SPIRVLowerSaddIntrinsicsLegacy,
                "spv-lower-llvm_sadd_intrinsics",
                "Lower llvm.sadd.* intrinsics", false, false)

ModulePass *llvm::createSPIRVLowerSaddIntrinsicsLegacy() {
  return new SPIRVLowerSaddIntrinsicsLegacy();
}
