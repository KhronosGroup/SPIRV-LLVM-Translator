//===- OCL20ToSPIRV.cpp - Transform OCL20 to SPIR-V builtins -----*- C++ -*-===//
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
// This file implements translation of OCL20 builtin functions.
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "cl20tospv"

#include "SPIRVInternal.h"
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

#include <set>

using namespace llvm;
using namespace SPIRV;
using namespace OCLUtil;

namespace SPIRV {
static size_t
getOCLCpp11AtomicMaxNumOps(StringRef Name) {
  return StringSwitch<size_t>(Name)
      .Cases("load", "flag_test_and_set", "flag_clear", 3)
      .Cases("store", "exchange",  4)
      .StartsWith("compare_exchange", 6)
      .StartsWith("fetch", 4)
      .Default(0);
}

class OCL20ToSPIRV: public ModulePass,
  public InstVisitor<OCL20ToSPIRV> {
public:
  OCL20ToSPIRV():ModulePass(ID), M(nullptr), Ctx(nullptr), CLVer(0) {
    initializeOCL20ToSPIRVPass(*PassRegistry::getPassRegistry());
  }
  virtual bool runOnModule(Module &M);
  virtual void visitCallInst(CallInst &CI);

  /// Transform barrier/work_group_barrier to __spirv_ControlBarrier.
  /// barrier(flag) =>
  ///   __spirv_ControlBarrier(workgroup, workgroup, map(flag))
  /// workgroup_barrier(scope, flag) =>
  ///   __spirv_ControlBarrier(workgroup, map(scope), map(flag))
  void visitCallWorkGroupBarrier(CallInst *CI);

  /// Erase useless convert functions.
  /// \return true if the call instruction is erased.
  bool eraseUselessConvert(CallInst *Call, const std::string &MangledName,
      const std::string &DeMangledName);

  /// Transform convert_ to
  ///   __spirv_{CastOpName}_R{TargeTyName}{_sat}{_rt[p|n|z|e]}
  void visitCallConvert(CallInst *CI, StringRef MangledName,
    const std::string &DemangledName);

  /// Transform async_work_group{_strided}_copy.
  /// async_work_group_copy(dst, src, n, event)
  ///   => async_work_group_strided_copy(dst, src, n, 1, event)
  /// async_work_group_strided_copy(dst, src, n, stride, event)
  ///   => __spirv_AsyncGroupCopy(ScopeWorkGroup, dst, src, n, stride, event)
  void visitCallAsyncWorkGroupCopy(CallInst *CI,
      const std::string &DemangledName);

  /// Transform OCL builtin function to SPIR-V builtin function.
  void transBuiltin(CallInst *CI, OCLBuiltinTransInfo &Info);

  /// Transform OCL work item builtin functions to SPIR-V builtin variables.
  void transWorkItemBuiltinsToVariables();

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
  CallInst *visitCallAtomicCmpXchg(CallInst *CI,
      const std::string &DemangledName);

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

  /// Transform OCL builtin function to SPIR-V builtin function.
  /// Assuming there is a simple name mapping without argument changes.
  /// Should be called at last.
  void visitCallBuiltinSimple(CallInst *CI, StringRef MangledName,
    const std::string &DemangledName);

  /// Transform get_image_{width|height|depth|dim}.
  /// get_image_xxx(...) =>
  ///   dimension = __spirv_ImageQuerySizeLod_R{ReturnType}(...);
  ///   return dimension.{x|y|z};
  void visitCallGetImageSize(CallInst *CI, StringRef MangledName,
    const std::string &DemangledName);

  /// Transform {work|sub}_group_x =>
  ///   __spirv_{OpName}
  ///
  /// Special handling of work_group_broadcast.
  ///   work_group_broadcast(a, x, y, z)
  ///     =>
  ///   __spirv_GroupBroadcast(a, vec3(x, y, z))

  void visitCallGroupBuiltin(CallInst *CI, StringRef MangledName,
    const std::string &DemangledName);

  /// Transform mem_fence to __spirv_MemoryBarrier.
  /// mem_fence(flag) => __spirv_MemoryBarrier(Workgroup, map(flag))
  void visitCallMemFence(CallInst *CI);

  void visitCallNDRange(CallInst *CI, const std::string &DemangledName);

  /// Transform OCL pipe builtin function to SPIR-V pipe builtin function.
  void visitCallPipeBuiltin(CallInst *CI, StringRef MangledName,
    const std::string &DemangledName);

  /// Transform read_image with sampler arguments.
  /// read_image(image, sampler, ...) =>
  ///   sampled_image = __spirv_SampledImage(image, sampler);
  ///   return __spirv_ImageSampleExplicitLod_R{ReturnType}(sampled_image, ...);
  void visitCallReadImageWithSampler(CallInst *CI, StringRef MangledName,
      const std::string &DemangledName);

  /// Transform {read|write}_image without sampler arguments.
  void visitCallReadWriteImage(CallInst *CI, StringRef MangledName,
      const std::string &DemangledName);

  /// Transform to_{global|local|private}.
  ///
  /// T* a = ...;
  /// addr T* b = to_addr(a);
  ///   =>
  /// i8* x = cast<i8*>(a);
  /// addr i8* y = __spirv_GenericCastToPtr_ToAddr(x);
  /// addr T* b = cast<addr T*>(y);
  void visitCallToAddr(CallInst *CI, StringRef MangledName,
      const std::string &DemangledName);

  /// Transform vector load/store functions to SPIR-V extended builtin
  ///   functions
  /// {vload|vstore{a}}{_half}{n}{_rte|_rtz|_rtp|_rtn} =>
  ///   __spirv_ocl_{ExtendedInstructionOpCodeName}__R{ReturnType}
  void visitCallVecLoadStore(CallInst *CI, StringRef MangledName,
      const std::string &DemangledName);

  /// Transforms OpDot instructions with a scalar type to a fmul instruction
  void visitCallDot(CallInst *CI);
  
    void visitCallForUnaryIntAsBool(CallInst *CI, StringRef MangledName,
      const std::string &DemangledName);
  
  void visitDbgInfoIntrinsic(DbgInfoIntrinsic &I){
    I.dropAllReferences();
    I.eraseFromParent();
  }
  static char ID;
private:
  Module *M;
  LLVMContext *Ctx;
  unsigned CLVer;                   /// OpenCL version as major*10+minor
  std::set<Value *> ValuesToDelete;

  ConstantInt *addInt32(int I) {
    return getInt32(M, I);
  }
  ConstantInt *addSizet(uint64_t I) {
    return getSizet(M, I);
  }

  /// Get vector width from OpenCL vload* function name.
  SPIRVWord getVecLoadWidth(const std::string& DemangledName) {
    SPIRVWord Width = 0;
    if (DemangledName == "vloada_half")
      Width = 1;
    else {
      unsigned Loc = 5;
      if (DemangledName.find("vload_half") == 0)
        Loc = 10;
      else if (DemangledName.find("vloada_half") == 0)
        Loc = 11;

      std::stringstream SS(DemangledName.substr(Loc));
      SS >> Width;
    }
    return Width;
  }

  /// Transform OpenCL vload/vstore function name.
  void transVecLoadStoreName(std::string& DemangledName,
      const std::string &Stem, bool AlwaysN) {
    auto HalfStem = Stem + "_half";
    auto HalfStemR = HalfStem + "_r";
    if (!AlwaysN && DemangledName == HalfStem)
      return;
    if (!AlwaysN && DemangledName.find(HalfStemR) == 0) {
      DemangledName = HalfStemR;
      return;
    }
    if (DemangledName.find(HalfStem) == 0) {
      auto OldName = DemangledName;
      DemangledName = HalfStem + "n";
      if (OldName.find("_r") != std::string::npos)
        DemangledName += "_r";
      return;
    }
    if (DemangledName.find(Stem) == 0) {
      DemangledName = Stem + "n";
      return;
    }
  }

};

char OCL20ToSPIRV::ID = 0;

bool
OCL20ToSPIRV::runOnModule(Module& Module) {
  M = &Module;
  Ctx = &M->getContext();
  auto Src = getSPIRVSource(&Module);
  if (std::get<0>(Src) != spv::SourceLanguageOpenCL_C)
    return false;

  CLVer = std::get<1>(Src);
  if (CLVer > kOCLVer::CL20)
    return false;

  DEBUG(dbgs() << "Enter OCL20ToSPIRV:\n");

  transWorkItemBuiltinsToVariables();

  visit(*M);

  for (auto &I:ValuesToDelete)
    if (auto Inst = dyn_cast<Instruction>(I))
      Inst->eraseFromParent();
  for (auto &I:ValuesToDelete)
    if (auto GV = dyn_cast<GlobalValue>(I))
      GV->eraseFromParent();

  DEBUG(dbgs() << "After OCL20ToSPIRV:\n" << *M);

  std::string Err;
  raw_string_ostream ErrorOS(Err);
  if (verifyModule(*M, &ErrorOS)){
    DEBUG(errs() << "Fails to verify module: " << ErrorOS.str());
  }
  return true;
}

// The order of handling OCL builtin functions is important.
// Workgroup functions need to be handled before pipe functions since
// there are functions fall into both categories.
void
OCL20ToSPIRV::visitCallInst(CallInst& CI) {
  DEBUG(dbgs() << "[visistCallInst] " << CI << '\n');
  auto F = CI.getCalledFunction();
  if (!F)
    return;

  auto MangledName = F->getName();
  std::string DemangledName;
  if (!oclIsBuiltin(MangledName, 20, &DemangledName))
    return;
  DEBUG(dbgs() << "DemangledName: " << DemangledName << '\n');
  if (DemangledName.find(kOCLBuiltinName::NDRangePrefix) == 0) {
    visitCallNDRange(&CI, DemangledName);
    return;
  }
  if (DemangledName.find(kOCLBuiltinName::AsyncWorkGroupCopy) == 0 ||
      DemangledName.find(kOCLBuiltinName::AsyncWorkGroupStridedCopy) == 0) {
    visitCallAsyncWorkGroupCopy(&CI, DemangledName);
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
  if (DemangledName.find(kOCLBuiltinName::ConvertPrefix) == 0) {
    visitCallConvert(&CI, MangledName, DemangledName);
    return;
  }
  if (DemangledName == kOCLBuiltinName::GetImageWidth ||
      DemangledName == kOCLBuiltinName::GetImageHeight ||
      DemangledName == kOCLBuiltinName::GetImageDepth ||
      DemangledName == kOCLBuiltinName::GetImageDim   ||
      DemangledName == kOCLBuiltinName::GetImageArraySize) {
    visitCallGetImageSize(&CI, MangledName, DemangledName);
    return;
  }
  if ((DemangledName.find(kOCLBuiltinName::WorkGroupPrefix) == 0 &&
      DemangledName != kOCLBuiltinName::WorkGroupBarrier) ||
      DemangledName == kOCLBuiltinName::WaitGroupEvent ||
      DemangledName.find(kOCLBuiltinName::SubGroupPrefix) == 0) {
    visitCallGroupBuiltin(&CI, MangledName, DemangledName);
    return;
  }
  if (DemangledName.find(kOCLBuiltinName::Pipe) != std::string::npos) {
    visitCallPipeBuiltin(&CI, MangledName, DemangledName);
    return;
  }
  if (DemangledName == kOCLBuiltinName::MemFence) {
    visitCallMemFence(&CI);
    return;
  }
  if (DemangledName.find(kOCLBuiltinName::ReadImage) == 0 &&
      MangledName.find(kMangledName::Sampler) != StringRef::npos) {
    visitCallReadImageWithSampler(&CI, MangledName, DemangledName);
    return;
  }
  if (DemangledName.find(kOCLBuiltinName::ReadImage) == 0 ||
      DemangledName.find(kOCLBuiltinName::WriteImage) == 0) {
    visitCallReadWriteImage(&CI, MangledName, DemangledName);
    return;
  }
  if (DemangledName == kOCLBuiltinName::ToGlobal ||
      DemangledName == kOCLBuiltinName::ToLocal ||
      DemangledName == kOCLBuiltinName::ToPrivate) {
    visitCallToAddr(&CI, MangledName, DemangledName);
    return;
  }
  if (DemangledName.find(kOCLBuiltinName::VLoadPrefix) == 0 ||
      DemangledName.find(kOCLBuiltinName::VStorePrefix) == 0) {
    visitCallVecLoadStore(&CI, MangledName, DemangledName);
    return;
  }
  if (DemangledName == kOCLBuiltinName::WorkGroupBarrier ||
      DemangledName == kOCLBuiltinName::Barrier) {
    visitCallWorkGroupBarrier(&CI);
    return;
  }
  if (DemangledName == kOCLBuiltinName::Dot &&
      !isa<VectorType>(CI.getOperand(0)->getType())){
      visitCallDot(&CI);
      return;
  }
   if (DemangledName == kOCLBuiltinName::IsFinite ||
      DemangledName == kOCLBuiltinName::IsInf ||
      DemangledName == kOCLBuiltinName::IsNan ||
      DemangledName == kOCLBuiltinName::IsNormal )
  {
    visitCallForUnaryIntAsBool(&CI, MangledName, DemangledName);
    return;
  }
  
  visitCallBuiltinSimple(&CI, MangledName, DemangledName);
}


void
OCL20ToSPIRV::visitCallNDRange(CallInst *CI,
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
  mutateCallInstSPIRV(M, CI, [=](CallInst *, std::vector<Value *> &Args){
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
    return getSPIRVFuncName(OpBuildNDRange);
  }, &Attrs);
}

void
OCL20ToSPIRV::visitCallAsyncWorkGroupCopy(CallInst* CI,
    const std::string &DemangledName) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstSPIRV(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    if (DemangledName == OCLUtil::kOCLBuiltinName::AsyncWorkGroupCopy) {
      Args.insert(Args.begin()+3, addSizet(1));
    }
    Args.insert(Args.begin(), addInt32(ScopeWorkgroup));
    return getSPIRVFuncName(OpGroupAsyncCopy);
  }, &Attrs);
}

CallInst *
OCL20ToSPIRV::visitCallAtomicCmpXchg(CallInst* CI,
    const std::string& DemangledName) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  Value *Alloca = nullptr;
  CallInst *NewCI = nullptr;
  mutateCallInstOCL(M, CI, [&](CallInst *, std::vector<Value *> &Args,
      Type *&RetTy){
    auto &CmpVal = Args[1];
    Alloca = new AllocaInst(CmpVal->getType(), "",
        CI->getParent()->getParent()->getEntryBlock().getFirstInsertionPt());
    auto Store = new StoreInst(CmpVal, Alloca, CI);
    CmpVal = Alloca;
    RetTy = Type::getInt1Ty(*Ctx);
    return kOCLBuiltinName::AtomicCmpXchgStrong;
  },
  [&](CallInst *NCI)->Instruction * {
    NewCI = NCI;
    return new LoadInst(Alloca, "", false, NCI->getNextNode());
  },
  &Attrs);
  return NewCI;
}

void
OCL20ToSPIRV::visitCallAtomicInit(CallInst* CI) {
  auto ST = new StoreInst(CI->getArgOperand(1), CI->getArgOperand(0), CI);
  ST->takeName(CI);
  CI->dropAllReferences();
  CI->eraseFromParent();
}

void
OCL20ToSPIRV::visitCallAtomicWorkItemFence(CallInst* CI) {
  transMemoryBarrier(CI, getAtomicWorkItemFenceLiterals(CI));
}

void
OCL20ToSPIRV::visitCallMemFence(CallInst* CI) {
  transMemoryBarrier(CI, std::make_tuple(
      cast<ConstantInt>(CI->getArgOperand(0))->getZExtValue(),
      OCLMO_relaxed,
      OCLMS_work_group));
}

void OCL20ToSPIRV::transMemoryBarrier(CallInst* CI,
    AtomicWorkItemFenceLiterals Lit) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstSPIRV(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    Args.resize(2);
    Args[0] = addInt32(map<Scope>(std::get<2>(Lit)));
    Args[1] = addInt32(mapOCLMemSemanticToSPIRV(std::get<0>(Lit),
        std::get<1>(Lit)));
    return getSPIRVFuncName(OpMemoryBarrier);
  }, &Attrs);
}

void
OCL20ToSPIRV::visitCallAtomicLegacy(CallInst* CI,
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
OCL20ToSPIRV::visitCallAtomicCpp11(CallInst* CI,
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
OCL20ToSPIRV::transAtomicBuiltin(CallInst* CI,
    OCLBuiltinTransInfo& Info) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstSPIRV(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    Info.PostProc(Args);
    auto NumOrder = getAtomicBuiltinNumMemoryOrderArgs(Info.UniqName);
    auto ScopeIdx = Args.size() - 1;
    auto OrderIdx = Args.size() - NumOrder - 1;
    Args[ScopeIdx] = mapUInt(M, cast<ConstantInt>(Args[ScopeIdx]),
        [](unsigned I){
      return map<Scope>(static_cast<OCLScopeKind>(I));
    });
    for (size_t I = 0; I < NumOrder; ++I)
      Args[OrderIdx + I] = mapUInt(M, cast<ConstantInt>(Args[OrderIdx + I]),
          [](unsigned Ord) {
      return mapOCLMemSemanticToSPIRV(0, static_cast<OCLMemOrderKind>(Ord));
    });
    move(Args, OrderIdx, Args.size(), findFirstPtr(Args) + 1);
    return getSPIRVFuncName(OCLSPIRVBuiltinMap::map(Info.UniqName));
  }, &Attrs);
}

void
OCL20ToSPIRV::visitCallWorkGroupBarrier(CallInst* CI) {
  auto Lit = getWorkGroupBarrierLiterals(CI);
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstSPIRV(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    Args.resize(3);
    Args[0] = addInt32(map<Scope>(std::get<2>(Lit)));
    Args[1] = addInt32(map<Scope>(std::get<1>(Lit)));
    Args[2] = addInt32(mapOCLMemFenceFlagToSPIRV(std::get<0>(Lit)));
    return getSPIRVFuncName(OpControlBarrier);
  }, &Attrs);
}

void OCL20ToSPIRV::visitCallConvert(CallInst* CI,
    StringRef MangledName, const std::string& DemangledName) {
  if (eraseUselessConvert(CI, MangledName, DemangledName))
    return;
  Op OC = OpNop;
  auto TargetTy = CI->getType();
  auto SrcTy = CI->getArgOperand(0)->getType();
  if (isa<VectorType>(TargetTy))
    TargetTy = TargetTy->getVectorElementType();
  if (isa<VectorType>(SrcTy))
    SrcTy = SrcTy->getVectorElementType();
  auto IsTargetInt = isa<IntegerType>(TargetTy);

  std::string TargetTyName = DemangledName.substr(
      strlen(kOCLBuiltinName::ConvertPrefix));
  auto FirstUnderscoreLoc = TargetTyName.find('_');
  if (FirstUnderscoreLoc != std::string::npos)
    TargetTyName = TargetTyName.substr(0, FirstUnderscoreLoc);
  TargetTyName = std::string("_R") + TargetTyName;

  std::string Sat = DemangledName.find("_sat") != std::string::npos ?
      "_sat" : "";
  auto TargetSigned = DemangledName[8] != 'u';
  if (isa<IntegerType>(SrcTy)) {
    bool Signed = isLastFuncParamSigned(MangledName);
    if (IsTargetInt) {
      if (!Sat.empty() && TargetSigned != Signed) {
        OC = Signed ? OpSatConvertSToU : OpSatConvertUToS;
        Sat = "";
      }
      else
        OC = Signed ? OpSConvert : OpUConvert;
    }
    else
      OC = Signed ? OpConvertSToF : OpConvertUToF;
  } else {
    if (IsTargetInt) {
      OC = TargetSigned ? OpConvertFToS : OpConvertFToU;
    } else
      OC = OpFConvert;
  }
  auto Loc = DemangledName.find("_rt");
  std::string Rounding;
  if (Loc != std::string::npos &&
      !(isa<IntegerType>(SrcTy) && IsTargetInt)) {
    Rounding = DemangledName.substr(Loc, 4);
  }
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstSPIRV(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    return getSPIRVFuncName(OC, TargetTyName + Sat + Rounding);
  }, &Attrs);
}

void OCL20ToSPIRV::visitCallGroupBuiltin(CallInst* CI,
    StringRef MangledName, const std::string& OrigDemangledName) {
  auto F = CI->getCalledFunction();
  std::vector<int> PreOps;
  std::string DemangledName = OrigDemangledName;
  if (DemangledName == kOCLBuiltinName::WorkGroupBarrier)
    return;
  if (DemangledName == kOCLBuiltinName::WaitGroupEvent) {
    PreOps.push_back(ScopeWorkgroup);
  } else if (DemangledName.find(kOCLBuiltinName::WorkGroupPrefix) == 0) {
    DemangledName.erase(0, strlen(kOCLBuiltinName::WorkPrefix));
    PreOps.push_back(ScopeWorkgroup);
  } else if (DemangledName.find(kOCLBuiltinName::SubGroupPrefix) == 0) {
    DemangledName.erase(0, strlen(kOCLBuiltinName::SubPrefix));
    PreOps.push_back(ScopeSubgroup);
  } else
    return;

  if (DemangledName != kOCLBuiltinName::WaitGroupEvent) {
    StringRef GroupOp = DemangledName;
    GroupOp = GroupOp.drop_front(strlen(kSPIRVName::GroupPrefix));
    SPIRSPIRVGroupOperationMap::foreach_conditional([&](const std::string &S,
        SPIRVGroupOperationKind G){
      if (!GroupOp.startswith(S))
        return true; // continue
      PreOps.push_back(G);
      StringRef Op = GroupOp.drop_front(S.size() + 1);
      assert(!Op.empty() && "Invalid OpenCL group builtin function");
      char OpTyC = 0;
      auto NeedSign = Op == "max" || Op == "min";
      auto OpTy = F->getReturnType();
      if (OpTy->isFloatingPointTy())
        OpTyC = 'f';
      else if (OpTy->isIntegerTy()) {
        if (!NeedSign)
          OpTyC = 'i';
        else {
          if (isLastFuncParamSigned(F->getName()))
            OpTyC = 's';
          else
            OpTyC = 'u';
        }
      } else
        llvm_unreachable("Invalid OpenCL group builtin argument type");

      DemangledName = std::string(kSPIRVName::GroupPrefix) + OpTyC + Op.str();
      return false; // break out of loop
    });
  }
  auto Consts = getInt32(M, PreOps);
  OCLBuiltinTransInfo Info;
  Info.UniqName = DemangledName;
  Info.PostProc = [=](std::vector<Value *> &Ops){
    size_t E = Ops.size();
    if (DemangledName == "group_broadcast" && E > 2) {
      assert (E == 3 || E == 4);
      makeVector(CI, Ops, std::make_pair(Ops.begin() + 1, Ops.end()));
    }
    Ops.insert(Ops.begin(), Consts.begin(), Consts.end());
  };
  transBuiltin(CI, Info);
}

void
OCL20ToSPIRV::transBuiltin(CallInst* CI,
    OCLBuiltinTransInfo& Info) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  Op OC = OpNop;
  unsigned ExtOp = ~0U;
  if (OCLSPIRVBuiltinMap::find(Info.UniqName, &OC))
    Info.UniqName = getSPIRVFuncName(OC);
  else if ((ExtOp = getExtOp(Info.MangledName, Info.UniqName)) != ~0U)
    Info.UniqName = getSPIRVExtFuncName(SPIRVEIS_OpenCL, ExtOp);
  else
    return;
  if (!Info.RetTy)
    mutateCallInstSPIRV(M, CI, [=](CallInst *, std::vector<Value *> &Args){
      Info.PostProc(Args);
      return Info.UniqName + Info.Postfix;
    }, &Attrs);
  else
    mutateCallInstSPIRV(M, CI,
      [=](CallInst *, std::vector<Value *> &Args, Type *&RetTy){
        Info.PostProc(Args);
        RetTy = Info.RetTy;
        return Info.UniqName + Info.Postfix;
      },
      [=](CallInst *NewCI) -> Instruction * {
        return CastInst::CreatePointerBitCastOrAddrSpaceCast(NewCI,
            CI->getType(), "", CI);
      },
    &Attrs);
}

void
OCL20ToSPIRV::visitCallPipeBuiltin(CallInst* CI,
    StringRef MangledName, const std::string& DemangledName) {
  std::string NewName = DemangledName;
  // Transform OpenCL read_pipe/write_pipe builtin function names
  // with reserve_id argument to reserved_read_pipe/reserved_write_pipe.
  if ((DemangledName.find(kOCLBuiltinName::ReadPipe) == 0 ||
      DemangledName.find(kOCLBuiltinName::WritePipe) == 0)
      && CI->getNumArgOperands() > 4)
    NewName = std::string(kSPIRVName::ReservedPrefix) + DemangledName;
  OCLBuiltinTransInfo Info;
  Info.UniqName = NewName;
  transBuiltin(CI, Info);
}

void
OCL20ToSPIRV::visitCallReadImageWithSampler(CallInst* CI,
    StringRef MangledName, const std::string& DemangledName) {
  assert (MangledName.find(kMangledName::Sampler) != StringRef::npos);
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstSPIRV(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    auto SampledImgTy = getSPIRVSampledImageType(M, Args[0]->getType());
    Value *SampledImgArgs[] = {Args[0], Args[1]};
    auto SampledImg = addCallInstSPIRV(M,
        getSPIRVFuncName(OpSampledImage), SampledImgTy,
        SampledImgArgs, nullptr, CI, kSPIRVName::TempSampledImage);

    Args[0] = SampledImg;
    Args.erase(Args.begin() + 1, Args.begin() + 2);
    return getSPIRVFuncName(OpImageSampleExplicitLod,
      std::string(kSPIRVPostfix::ExtDivider) + getPostfixForReturnType(CI));
  }, &Attrs);
}

void
OCL20ToSPIRV::visitCallGetImageSize(CallInst* CI,
    StringRef MangledName, const std::string& DemangledName) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  SPIRVTypeImageDescriptor Desc;
  unsigned Dim = 0;
  mutateCallInstSPIRV(M, CI,
    [&](CallInst *, std::vector<Value *> &Args, Type *&Ret){
      assert(Args.size() == 1);
      StringRef TyName;
      auto IsImg = isOCLImageType(Args[0]->getType(), &TyName);
      assert(IsImg);
      Desc = map<SPIRVTypeImageDescriptor>(TyName.str());
      Dim = getImageDimension(Desc.Dim) + Desc.Arrayed;
      Ret = CI->getType()->isIntegerTy(64) ?
          Type::getInt64Ty(*Ctx) :
          Type::getInt32Ty(*Ctx);
      if (Dim > 1)
        Ret = VectorType::get(Ret, Dim);
      if (Desc.Dim == DimBuffer)
          return getSPIRVFuncName(OpImageQuerySize, CI->getType());
      else {
        Args.push_back(getInt32(M, 0));
        return getSPIRVFuncName(OpImageQuerySizeLod, CI->getType());
      }
    },
    [&](CallInst *NCI)->Instruction * {
      if (Dim == 1)
        return NCI;
      if (DemangledName == kOCLBuiltinName::GetImageDim) {
        if (Desc.Dim == Dim3D) {
          auto ZeroVec = ConstantVector::getSplat(3,
            Constant::getNullValue(NCI->getType()->getVectorElementType()));
          Constant *Index[] = {getInt32(M, 0), getInt32(M, 1),
              getInt32(M, 2), getInt32(M, 3)};
          return new ShuffleVectorInst(NCI, ZeroVec,
             ConstantVector::get(Index), "", CI);

        } else if (Desc.Dim == Dim2D && Desc.Arrayed) {
          Constant *Index[] = {getInt32(M, 0), getInt32(M, 1)};
          Constant *mask = ConstantVector::get(Index);
          return new ShuffleVectorInst(NCI, UndefValue::get(NCI->getType()),
                                       mask, NCI->getName(), CI);
        }
        return NCI;
      }
      auto I = StringSwitch<unsigned>(DemangledName)
          .Case(kOCLBuiltinName::GetImageWidth, 0)
          .Case(kOCLBuiltinName::GetImageHeight, 1)
          .Case(kOCLBuiltinName::GetImageDepth, 2)
          .Case(kOCLBuiltinName::GetImageArraySize, Dim - 1);
      return ExtractElementInst::Create(NCI, getInt32(M, I), "",
          NCI->getNextNode());
    },
  &Attrs);
}

/// Remove trivial conversion functions
bool
OCL20ToSPIRV::eraseUselessConvert(CallInst *CI,
    const std::string &MangledName,
    const std::string &DemangledName) {
  auto TargetTy = CI->getType();
  auto SrcTy = CI->getArgOperand(0)->getType();
  if (isa<VectorType>(TargetTy))
    TargetTy = TargetTy->getVectorElementType();
  if (isa<VectorType>(SrcTy))
    SrcTy = SrcTy->getVectorElementType();
  if (TargetTy == SrcTy) {
    if (isa<IntegerType>(TargetTy) &&
        DemangledName.find("_sat") != std::string::npos &&
        isLastFuncParamSigned(MangledName) != (DemangledName[8] != 'u'))
      return false;
    CI->getArgOperand(0)->takeName(CI);
    SPIRVDBG(dbgs() << "[regularizeOCLConvert] " << *CI << " <- " <<
        *CI->getArgOperand(0) << '\n');
    CI->replaceAllUsesWith(CI->getArgOperand(0));
    ValuesToDelete.insert(CI);
    ValuesToDelete.insert(CI->getCalledFunction());
    return true;
  }
  return false;
}

void
OCL20ToSPIRV::visitCallBuiltinSimple(CallInst* CI,
    StringRef MangledName, const std::string& DemangledName) {
  OCLBuiltinTransInfo Info;
  Info.MangledName = MangledName.str();
  Info.UniqName = DemangledName;
  transBuiltin(CI, Info);
}

/// Translates OCL work-item builtin functions to SPIRV builtin variables.
/// Function like get_global_id(i) -> x = load GlobalInvocationId; extract x, i
/// Function like get_work_dim() -> load WorkDim
void OCL20ToSPIRV::transWorkItemBuiltinsToVariables() {
  DEBUG(dbgs() << "Enter transWorkItemBuiltinsToVariables\n");
  std::vector<Function *> WorkList;
  for (auto I = M->begin(), E = M->end(); I != E; ++I) {
    std::string DemangledName;
    if (!oclIsBuiltin(I->getName(), 20, &DemangledName))
      continue;
    DEBUG(dbgs() << "Function demangled name: " << DemangledName << '\n');
    std::string BuiltinVarName;
    SPIRVBuiltinVariableKind BVKind = BuiltInCount;
    if (!SPIRSPIRVBuiltinVariableMap::find(DemangledName, &BVKind))
      continue;
    BuiltinVarName = std::string(kSPIRVName::Prefix) +
        SPIRVBuiltinVariableNameMap::map(BVKind);
    DEBUG(dbgs() << "builtin variable name: " << BuiltinVarName << '\n');
    bool IsVec = I->getFunctionType()->getNumParams() > 0;
    Type *GVType = IsVec ? VectorType::get(I->getReturnType(),3) :
        I->getReturnType();
    auto BV = new GlobalVariable(*M, GVType,
        true,
        GlobalValue::ExternalLinkage,
        nullptr, BuiltinVarName,
        0,
        GlobalVariable::NotThreadLocal,
        SPIRAS_Constant);
    std::vector<Instruction *> InstList;
    for (auto UI = I->user_begin(), UE = I->user_end(); UI != UE; ++UI) {
      auto CI = dyn_cast<CallInst>(*UI);
      assert(CI && "invalid instruction");
      Value * NewValue = new LoadInst(BV, "", CI);
      DEBUG(dbgs() << "Transform: " << *CI << " => " << *NewValue << '\n');
      if (IsVec) {
        NewValue = ExtractElementInst::Create(NewValue,
          CI->getArgOperand(0),
          "", CI);
        DEBUG(dbgs() << *NewValue << '\n');
      }
      NewValue->takeName(CI);
      CI->replaceAllUsesWith(NewValue);
      InstList.push_back(CI);
    }
    for (auto &Inst:InstList) {
      Inst->dropAllReferences();
      Inst->removeFromParent();
    }
    WorkList.push_back(I);
  }
  for (auto &I:WorkList) {
    I->dropAllReferences();
    I->removeFromParent();
  }
}

void
OCL20ToSPIRV::visitCallReadWriteImage(CallInst* CI,
    StringRef MangledName, const std::string& DemangledName) {
  OCLBuiltinTransInfo Info;
  if (DemangledName.find(kOCLBuiltinName::ReadImage) == 0)
    Info.UniqName = kOCLBuiltinName::ReadImage;

  if (DemangledName.find(kOCLBuiltinName::WriteImage) == 0)
    Info.UniqName = kOCLBuiltinName::WriteImage;
  transBuiltin(CI, Info);
}

void
OCL20ToSPIRV::visitCallToAddr(CallInst* CI, StringRef MangledName,
    const std::string &DemangledName) {
  auto AddrSpace = static_cast<SPIRAddressSpace>(
      CI->getType()->getPointerAddressSpace());
  OCLBuiltinTransInfo Info;
  Info.UniqName = DemangledName;
  Info.Postfix = std::string(kSPIRVPostfix::Divider) + "To" +
      SPIRAddrSpaceCapitalizedNameMap::map(AddrSpace);
  auto StorageClass = addInt32(SPIRSPIRVAddrSpaceMap::map(AddrSpace));
  Info.RetTy = getInt8PtrTy(cast<PointerType>(CI->getType()));
  Info.PostProc = [=](std::vector<Value *> &Ops){
    auto P = Ops.back();
    Ops.pop_back();
    Ops.push_back(castToInt8Ptr(P, CI));
    Ops.push_back(StorageClass);
  };
  transBuiltin(CI, Info);
}

void
OCL20ToSPIRV::visitCallVecLoadStore(CallInst* CI,
    StringRef MangledName, const std::string& OrigDemangledName) {
  std::vector<int> PreOps;
  std::string DemangledName = OrigDemangledName;
  if (DemangledName.find(kOCLBuiltinName::VLoadPrefix) == 0 &&
      DemangledName != kOCLBuiltinName::VLoadHalf) {
    SPIRVWord Width = getVecLoadWidth(DemangledName);
    SPIRVDBG(spvdbgs() << "[visitCallVecLoadStore] DemangledName: " <<
        DemangledName << " Width: " << Width << '\n');
    PreOps.push_back(Width);
  } else if (DemangledName.find(kOCLBuiltinName::RoundingPrefix)
      != std::string::npos) {
    auto R = SPIRSPIRVFPRoundingModeMap::map(DemangledName.substr(
        DemangledName.find(kOCLBuiltinName::RoundingPrefix) + 1, 3));
    PreOps.push_back(R);
  }

  if (DemangledName.find(kOCLBuiltinName::VLoadAPrefix) == 0)
    transVecLoadStoreName(DemangledName, kOCLBuiltinName::VLoadAPrefix, true);
  else
    transVecLoadStoreName(DemangledName, kOCLBuiltinName::VLoadPrefix, false);

  if (DemangledName.find(kOCLBuiltinName::VStoreAPrefix) == 0)
    transVecLoadStoreName(DemangledName, kOCLBuiltinName::VStoreAPrefix, true);
  else
    transVecLoadStoreName(DemangledName, kOCLBuiltinName::VStorePrefix, false);


  auto Consts = getInt32(M, PreOps);
  OCLBuiltinTransInfo Info;
  Info.MangledName = MangledName;
  Info.UniqName = DemangledName;
  if (DemangledName.find(kOCLBuiltinName::VLoadPrefix) == 0)
    Info.Postfix = std::string(kSPIRVPostfix::ExtDivider) +
      getPostfixForReturnType(CI);
  Info.PostProc = [=](std::vector<Value *> &Ops){
    Ops.insert(Ops.end(), Consts.begin(), Consts.end());
  };
  transBuiltin(CI, Info);
}

void
OCL20ToSPIRV::visitCallDot(CallInst* CI){
    IRBuilder<> Builder(CI);
    Value *FMulVal = Builder.CreateFMul(CI->getOperand(0), CI->getOperand(1));
    CI->replaceAllUsesWith(FMulVal);
    CI->dropAllReferences();
    CI->removeFromParent();
}

void OCL20ToSPIRV::visitCallForUnaryIntAsBool(CallInst *CI, StringRef MangledName,
  const std::string &DemangledName) {

  std::vector<Type *> ArgTys;
  std::vector<Value*> Args;
  for (size_t I = 0, E = CI->getNumArgOperands(); I != E; ++I) {
    ArgTys.push_back(CI->getArgOperand(I)->getType());
    Args.push_back(CI->getArgOperand(I));
  }

  spv::Op OC = OpNop;
  
  if(DemangledName == kOCLBuiltinName::IsFinite) OC = OpIsFinite;
  if(DemangledName == kOCLBuiltinName::IsInf) OC = OpIsInf;
  if(DemangledName == kOCLBuiltinName::IsNan) OC = OpIsNan;
  if(DemangledName == kOCLBuiltinName::IsNormal) OC = OpIsNormal;

  assert( OC != OpNop && "Invalid OC in visitCallForUnaryIntAsBool");

  BuiltinFuncMangleInfo mangler;
  AttributeSet AS = CI->getCalledFunction()->getAttributes();

  CallInst* CallInst = 
    addCallInst(M, getSPIRVFuncName(OC), Type::getInt1Ty(M->getContext()), Args, 
    &AS, 
    CI, 
    &mangler);

  auto Ty = CI->getType();
  auto Zero = getScalarOrVectorConstantInt(Ty, 0, false);
  auto One = getScalarOrVectorConstantInt(Ty, 1, false);
  auto Sel = SelectInst::Create(CallInst, One, Zero, "");
    
  Sel->insertAfter(CallInst);
  CI->replaceAllUsesWith(Sel);
  CI->eraseFromParent();
}

}

INITIALIZE_PASS(OCL20ToSPIRV, "cl20tospv", "Transform OCL 2.0 to SPIR-V",
    false, false)

ModulePass *llvm::createOCL20ToSPIRV() {
  return new OCL20ToSPIRV();
}
