//===- SPRVRegularizeOCL20.cpp - Regularize OCL20 builtins-------*- C++ -*-===//
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
#define DEBUG_TYPE "spvcl20"

#include "SPRVInternal.h"
#include "OCLUtil.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Pass.h"
#include "llvm/PassSupport.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace SPRV;
using namespace OCLUtil;

namespace SPRV {
static size_t
getOCLCpp11AtomicMaxNumOps(StringRef Name) {
  return StringSwitch<size_t>(Name)
      .Cases("load", "flag_test_and_set", "flag_clear", 3)
      .Cases("store", "exchange",  4)
      .StartsWith("compare_exchange", 6)
      .StartsWith("fetch", 4)
      .Default(0);
}

class SPRVRegularizeOCL20: public ModulePass,
  public InstVisitor<SPRVRegularizeOCL20> {
public:
  SPRVRegularizeOCL20():ModulePass(ID), M(nullptr), Ctx(nullptr) {
    initializeSPRVRegularizeOCL20Pass(*PassRegistry::getPassRegistry());
  }
  virtual void getAnalysisUsage(AnalysisUsage &AU);
  virtual bool runOnModule(Module &M);
  virtual void visitCallInst(CallInst &CI);

  /// Transform atomic_work_item_fence/mem_fence to __spirv_MemoryBarrier.
  /// func(flag, order, scope) =>
  ///   __spirv_MemoryBarrier(map(scope), map(flag)|map(order))
  void transMemoryBarrier(CallInst *CI, AtomicWorkItemFenceLiterals);

  /// Transform atomic_* to __spirv_Atomic*.
  /// atomic_x(ptr_arg, args, order, scope) =>
  ///   __spirv_AtomicY(ptr_arg, map(order), map(scope), args)
  void transAtomicBuiltin(CallInst *CI, OCLBuiltinTransInfo &Info);

  /// Transform atomic_work_item_fence to __spirv_MemoryBarrier.
  /// atomic_work_item_fence(flag, order, scope) =>
  ///   __spirv_MemoryBarrier(map(scope), map(flag)|map(order))
  void visitCallAtomicWorkItemFence(CallInst *CI);

  /// Transform atom_cmpxchg/atomic_cmpxchg to atomic_compare_exchange.
  /// In atom_cmpxchg/atomic_cmpxchg, the expected value parameter is a value.
  /// However in atomic_compare_exchange it is a pointer. The transformation
  /// adds an alloca instruction, store the expected value in the pointer, and
  /// pass the pointer as argument.
  /// \returns the call instruction of atomic_compare_exchange_strong.
  CallInst *visitCallAtomicCmpXchg(CallInst *CI, const std::string &DemangledName);

  /// Transform atomic_init.
  /// atomic_init(p, x) => store p, x
  void visitCallAtomicInit(CallInst *CI);

  /// Transform legacy OCL 1.x atomic builtins to SPIR-V builtins for extensions
  ///   cl_khr_int64_base_atomics
  ///   cl_khr_int64_extended_atomics
  /// Do nothing if the called function is not a legacy atomic builtin.
  void visitCallAtomicLegacy(CallInst *CI, StringRef MangledName,
    const std::string &DemangledName);

  /// Transform OCL 2.0 C++11 atomic builtins to SPIR-V builtins.
  /// Do nothing if the called function is not a C++11 atomic builtin.
  void visitCallAtomicCpp11(CallInst *CI, StringRef MangledName,
    const std::string &DemangledName);

  /// Transform get_image_{width|height|depth|dim}.
  /// get_image_xxx(...) =>
  ///   dimension = __spirv_ImageQuerySizeLod(...);
  ///   return dimension.{x|y|z};
  void visitCallGetImageSize(CallInst *CI, StringRef MangledName,
    const std::string &DemangledName);

  /// Transform mem_fence to __spirv_MemoryBarrier.
  /// mem_fence(flag) => __spirv_MemoryBarrier(Workgroup, map(flag))
  void visitCallMemFence(CallInst *CI);

  void visitCallNDRange(CallInst *CI, const std::string &DemangledName);

  /// Transform read_image with sampler arguments.
  /// read_image(image, sampler, ...) =>
  ///   sampled_image = __spirv_SampledImage__(image, sampler);
  ///   return __spirv_ImageSampleExplicitLod__(sampled_image, ...);
  void visitCallReadImage(CallInst *CI, StringRef MangledName,
      const std::string &DemangledName);

  void visitDbgInfoIntrinsic(DbgInfoIntrinsic &I){
    I.dropAllReferences();
    I.eraseFromParent();
  }
  static char ID;
private:
  Module *M;
  LLVMContext *Ctx;

  ConstantInt *addInt32(int I) {
    return getInt32(M, I);
  }

};

char SPRVRegularizeOCL20::ID = 0;

void
SPRVRegularizeOCL20::getAnalysisUsage(AnalysisUsage& AU) {
}

bool
SPRVRegularizeOCL20::runOnModule(Module& Module) {
  M = &Module;
  Ctx = &M->getContext();
  visit(*M);

  DEBUG(dbgs() << "After RegularizeOCL20:\n" << *M);

  std::string Err;
  raw_string_ostream ErrorOS(Err);
  if (verifyModule(*M, &ErrorOS)){
    DEBUG(errs() << "Fails to verify module: " << ErrorOS.str());
  }
  return true;
}

void
SPRVRegularizeOCL20::visitCallInst(CallInst& CI) {
  DEBUG(dbgs() << "[visistCallInst] " << CI << '\n');
  auto F = CI.getCalledFunction();
  if (!F)
    return;

  auto MangledName = F->getName();
  std::string DemangledName;
  if (!oclIsBuiltin(MangledName, 20, &DemangledName))
    return;
  DEBUG(dbgs() << "DemangledName == " << DemangledName.c_str() << '\n');
  if (DemangledName.find(kOCLBuiltinName::NDRangePrefix) == 0) {
    visitCallNDRange(&CI, DemangledName);
    return;
  }
  if (DemangledName.find(kOCLBuiltinName::AtomicPrefix) == 0 ||
      DemangledName.find(kOCLBuiltinName::AtomPrefix) == 0) {
    auto PCI = &CI;
    if (DemangledName == kOCLBuiltinName::AtomicInit) {
      visitCallAtomicInit(PCI);
      return;
    }
    if (DemangledName == kOCLBuiltinName::AtomicWorkItemFence) {
      visitCallAtomicWorkItemFence(PCI);
      return;
    }
    if (DemangledName == kOCLBuiltinName::AtomCmpXchg ||
        DemangledName == kOCLBuiltinName::AtomicCmpXchg) {
      PCI = visitCallAtomicCmpXchg(PCI, DemangledName);
    }
    visitCallAtomicLegacy(PCI, MangledName, DemangledName);
    visitCallAtomicCpp11(PCI, MangledName, DemangledName);
    return;
  }
  if (DemangledName.find(kOCLBuiltinName::ReadImage) == 0) {
    visitCallReadImage(&CI, MangledName, DemangledName);
    return;
  }
  if (DemangledName == kOCLBuiltinName::GetImageWidth ||
      DemangledName == kOCLBuiltinName::GetImageHeight ||
      DemangledName == kOCLBuiltinName::GetImageDepth ||
      DemangledName == kOCLBuiltinName::GetImageDim) {
    visitCallGetImageSize(&CI, MangledName, DemangledName);
    return;
  }
  if (DemangledName == kOCLBuiltinName::MemFence) {
    visitCallMemFence(&CI);
    return;
  }
}


void
SPRVRegularizeOCL20::visitCallNDRange(CallInst *CI,
    const std::string &DemangledName) {
  assert(DemangledName.find(kOCLBuiltinName::NDRangePrefix) == 0);
  auto Len = atoi(DemangledName.substr(8, 1).c_str());
  assert (Len >= 1 && Len <= 3);
  // SPIR-V ndrange structure requires 3 members in the following order:
  //   global work offset
  //   global work size
  //   local work size
  // The arguments need to add missing members.
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInst(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    for (size_t I = 1, E = Args.size(); I != E; ++I)
      Args[I] = getScalarOrArray(Args[I], Len, CI);
    switch (Args.size()) {
    case 2: {
      // Has global work size.
      auto T = Args[1]->getType();
      Args.push_back(getScalarOrArrayConstantInt(CI, T, Len, 1));
      Args.insert(Args.begin() + 1, getScalarOrArrayConstantInt(CI, T, Len, 0));
    }
      break;
    case 3: {
      // Has global and local work size.
      auto T = Args[1]->getType();
      Args.insert(Args.begin() + 1, getScalarOrArrayConstantInt(CI, T, Len, 0));
    }
      break;
    case 4: {
      // Do nothing
    }
      break;
    default:
      assert(0 && "Invalid number of arguments");
    }
    return DemangledName;
  }, true, &Attrs);
}

CallInst *
SPRVRegularizeOCL20::visitCallAtomicCmpXchg(CallInst* CI,
    const std::string& DemangledName) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  Value *Alloca = nullptr;
  CallInst *NewCI = nullptr;
  mutateCallInst(M, CI, [&](CallInst *, std::vector<Value *> &Args,
      Type *&RetTy){
    auto &CmpVal = Args[1];
    Alloca = new AllocaInst(CmpVal->getType(), "",
        CI->getParent()->getParent()->getEntryBlock().getFirstInsertionPt());
    auto Store = new StoreInst(CmpVal, Alloca, CI);
    CmpVal = Alloca;
    RetTy = Type::getInt1Ty(*Ctx);
    return "atomic_compare_exchange_strong";
  },
  [&](CallInst *NCI)->Instruction * {
    NewCI = NCI;
    return new LoadInst(Alloca, "", false, NCI->getNextNode());
  },
  true, &Attrs);
  return NewCI;
}

void
SPRVRegularizeOCL20::visitCallAtomicInit(CallInst* CI) {
  auto ST = new StoreInst(CI->getArgOperand(1), CI->getArgOperand(0), CI);
  ST->takeName(CI);
  CI->dropAllReferences();
  CI->eraseFromParent();
}

void
SPRVRegularizeOCL20::visitCallAtomicWorkItemFence(CallInst* CI) {
  transMemoryBarrier(CI, getAtomicWorkItemFenceLiterals(CI));
}

void
SPRVRegularizeOCL20::visitCallMemFence(CallInst* CI) {
  transMemoryBarrier(CI, std::make_tuple(
      cast<ConstantInt>(CI->getArgOperand(0))->getZExtValue(),
      OCLMO_relaxed,
      OCLMS_work_group));
}

void SPRVRegularizeOCL20::transMemoryBarrier(CallInst* CI,
    AtomicWorkItemFenceLiterals Lit) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInst(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    Args.resize(2);
    Args[0] = addInt32(map<Scope>(std::get<2>(Lit)));
    Args[1] = addInt32(mapOCLMemSemanticToSPRV(std::get<0>(Lit),
        std::get<1>(Lit)));
    return getSPRVFuncName(OpMemoryBarrier);
  }, true, &Attrs);
}

void
SPRVRegularizeOCL20::visitCallAtomicLegacy(CallInst* CI,
    StringRef MangledName, const std::string& DemangledName) {
  StringRef Stem = DemangledName;
  if (Stem.startswith("atom_"))
    Stem = Stem.drop_front(strlen("atom_"));
  else if (Stem.startswith("atomic_"))
    Stem = Stem.drop_front(strlen("atomic_"));
  else
    return;

  std::string Sign;
  std::string Postfix;
  std::string Prefix;
  if (Stem == "add" ||
      Stem == "sub" ||
      Stem == "and" ||
      Stem == "or" ||
      Stem == "xor" ||
      Stem == "min" ||
      Stem == "max") {
    if ((Stem == "min" || Stem == "max") &&
         isMangledTypeUnsigned(MangledName.back()))
      Sign = 'u';
    Prefix = "fetch_";
    Postfix = "_explicit";
  } else if (Stem == "xchg") {
    Stem = "exchange";
    Postfix = "_explicit";
  }
  else if (Stem == "cmpxchg") {
    Stem = "compare_exchange_strong";
    Postfix = "_explicit";
  }
  else if (Stem == "inc" ||
           Stem == "dec") {
    // do nothing
  } else
    return;

  OCLBuiltinTransInfo Info;
  Info.UniqName = "atomic_" + Prefix + Sign + Stem.str() + Postfix;
  std::vector<int> PostOps;
  PostOps.push_back(OCLLegacyAtomicMemOrder);
  if (Stem.startswith("compare_exchange"))
    PostOps.push_back(OCLLegacyAtomicMemOrder);
  PostOps.push_back(OCLLegacyAtomicMemScope);

  Info.PostProc = [=](std::vector<Value *> &Ops){
    for (auto &I:PostOps){
      Ops.push_back(addInt32(I));
    }
  };
  transAtomicBuiltin(CI, Info);
}

void
SPRVRegularizeOCL20::visitCallAtomicCpp11(CallInst* CI,
    StringRef MangledName, const std::string& DemangledName) {
  StringRef Stem = DemangledName;
  if (Stem.startswith("atomic_"))
    Stem = Stem.drop_front(strlen("atomic_"));
  else
    return;

  std::string NewStem = Stem;
  std::vector<int> PostOps;
  if (Stem.startswith("store") ||
      Stem.startswith("load") ||
      Stem.startswith("exchange") ||
      Stem.startswith("compare_exchange") ||
      Stem.startswith("fetch") ||
      Stem.startswith("flag")) {
    if ((Stem.startswith("fetch_min") ||
        Stem.startswith("fetch_max")) &&
        containsUnsignedAtomicType(MangledName))
      NewStem.insert(NewStem.begin() + strlen("fetch_"), 'u');

    if (!Stem.endswith("_explicit")) {
      NewStem = NewStem + "_explicit";
      PostOps.push_back(OCLMO_seq_cst);
      if (Stem.startswith("compare_exchange"))
        PostOps.push_back(OCLMO_seq_cst);
      PostOps.push_back(OCLMS_device);
    } else {
      auto MaxOps = getOCLCpp11AtomicMaxNumOps(
          Stem.drop_back(strlen("_explicit")));
      if (CI->getNumArgOperands() < MaxOps)
        PostOps.push_back(OCLMS_device);
    }
  } else if (Stem == "work_item_fence") {
    // do nothing
  } else
    return;

  OCLBuiltinTransInfo Info;
  Info.UniqName = std::string("atomic_") + NewStem;
  Info.PostProc = [=](std::vector<Value *> &Ops){
    for (auto &I:PostOps){
      Ops.push_back(addInt32(I));
    }
  };

  transAtomicBuiltin(CI, Info);
}

void
SPRVRegularizeOCL20::transAtomicBuiltin(CallInst* CI,
    OCLBuiltinTransInfo& Info) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInst(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    Info.PostProc(Args);
    auto NumOrder = getAtomicBuiltinNumMemoryOrderArgs(Info.UniqName);
    auto ScopeIdx = Args.size() - 1;
    auto OrderIdx = Args.size() - NumOrder - 1;
    Args[ScopeIdx] = mapUInt(M, cast<ConstantInt>(Args[ScopeIdx]),
        [](unsigned I){
      return map<Scope>(static_cast<OCLMemScopeKind>(I));
    });
    for (size_t I = 0; I < NumOrder; ++I)
      Args[OrderIdx + I] = mapUInt(M, cast<ConstantInt>(Args[OrderIdx + I]),
          [](unsigned Ord) {
      return mapOCLMemSemanticToSPRV(0, static_cast<OCLMemOrderKind>(Ord));
    });
    move(Args, OrderIdx, Args.size(), findFirstPtr(Args) + 1);
    return getSPRVFuncName(OCLSPRVBuiltinMap::map(Info.UniqName));
  }, true, &Attrs);
}

void
SPRVRegularizeOCL20::visitCallReadImage(CallInst* CI,
    StringRef MangledName, const std::string& DemangledName) {
  if (MangledName.find(kMangledName::Sampler) == StringRef::npos)
    return;
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInst(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    auto SampledImgTy = getSPRVSampledImageType(M, Args[0]->getType());
    Value *SampledImgArgs[] = {Args[0], Args[1]};
    auto SampledImg = addCallInst(M,
        decorateSPRVFunction(kSPRVName::SampledImage), SampledImgTy,
        SampledImgArgs, nullptr, CI, false, kSPRVName::TempSampledImage,
        false);

    Args[0] = SampledImg;
    Args.erase(Args.begin() + 1, Args.begin() + 2);
    return decorateSPRVFunction(kSPRVName::ImageSampleExplicitLod);
  }, false, &Attrs);
}

void
SPRVRegularizeOCL20::visitCallGetImageSize(CallInst* CI,
    StringRef MangledName, const std::string& DemangledName) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  SPRVTypeImageDescriptor Desc;
  unsigned Dim = 0;
  mutateCallInst(M, CI,
    [&](CallInst *, std::vector<Value *> &Args, Type *&Ret){
      assert(Args.size() == 1);
      StringRef TyName;
      auto IsImg = isOCLImageType(Args[0]->getType(), &TyName);
      assert(IsImg);
      Desc = map<SPRVTypeImageDescriptor>(TyName.str());
      Dim = getImageDimension(Desc.Dim) + Desc.Arrayed;
      Ret = Type::getInt32Ty(*Ctx);
      if (Dim > 1)
        Ret = VectorType::get(Ret, Dim);
      if (Desc.Dim == SPRV::SPRVDIM_Buffer)
        return getSPRVFuncName(OpImageQuerySize);
      else {
        Args.push_back(getInt32(M, 0));
        return getSPRVFuncName(OpImageQuerySizeLod);
      }
    },
    [&](CallInst *NCI)->Instruction * {
      if (Dim == 1)
        return NCI;
      if (DemangledName == kOCLBuiltinName::GetImageDim) {
        if (Desc.Dim != SPRV::SPRVDIM_3D)
          return NCI;
        else {
          auto ZeroVec = ConstantVector::getSplat(3,
            Constant::getNullValue(NCI->getType()->getVectorElementType()));
          Constant *Index[] = {getInt32(M, 0), getInt32(M, 1),
              getInt32(M, 2), getInt32(M, 3)};
          return new ShuffleVectorInst(NCI, ZeroVec,
             ConstantVector::get(Index), "", CI);
        }
      }
      auto I = StringSwitch<unsigned>(DemangledName)
          .Case(kOCLBuiltinName::GetImageWidth, 0)
          .Case(kOCLBuiltinName::GetImageHeight, 1)
          .Case(kOCLBuiltinName::GetImageDepth, 2)
          .Case(kOCLBuiltinName::GetImageArraySize, Dim - 1);
      return ExtractElementInst::Create(NCI, getInt32(M, I), "",
          NCI->getNextNode());
    },
  true, &Attrs);
}

}

INITIALIZE_PASS(SPRVRegularizeOCL20, "regocl20", "Regularize OCL 2.0 module",
    false, false)

ModulePass *llvm::createSPRVRegularizeOCL20() {
  return new SPRVRegularizeOCL20();
}
