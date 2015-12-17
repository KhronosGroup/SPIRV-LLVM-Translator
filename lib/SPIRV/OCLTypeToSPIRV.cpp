//===- OCLTypeToSPIRV.cpp - Adapt types from OCL for SPIRV ------*- C++ -*-===//
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
// This file implements adaptation of OCL types for SPIRV.
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "cltytospv"

#include "OCLTypeToSPIRV.h"
#include "SPIRVInternal.h"
#include "OCLUtil.h"

#include "llvm/Pass.h"
#include "llvm/PassSupport.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

#include <set>
#include <iterator>

using namespace llvm;
using namespace SPIRV;
using namespace OCLUtil;

namespace SPIRV {

char OCLTypeToSPIRV::ID = 0;

OCLTypeToSPIRV::OCLTypeToSPIRV()
  :ModulePass(ID), M(nullptr), Ctx(nullptr), CLVer(0) {
  initializeOCLTypeToSPIRVPass(*PassRegistry::getPassRegistry());
}

void
OCLTypeToSPIRV::getAnalysisUsage(AnalysisUsage& AU) const {
  AU.setPreservesAll();
}

bool
OCLTypeToSPIRV::runOnModule(Module& Module) {
  DEBUG(dbgs() << "Enter OCLTypeToSPIRV:\n");
  M = &Module;
  Ctx = &M->getContext();
  auto Src = getSPIRVSource(&Module);
  if (std::get<0>(Src) != spv::SourceLanguageOpenCL_C)
    return false;

  for (auto &F:Module.functions())
    adaptArgumentsByMetadata(&F);

  while (!WorkSet.empty()) {
    Function *F = *WorkSet.begin();
    WorkSet.erase(WorkSet.begin());

    adaptFunction(F);
   }

  return false;
}

void
OCLTypeToSPIRV::addAdaptedType(Value *V, Type *T) {
  DEBUG(dbgs() << "[add adapted type] ";
    V->printAsOperand(dbgs(), true, M);
    dbgs() << " => " << *T << '\n');
  AdaptedTy[V] = T;
}

void
OCLTypeToSPIRV::addWork(Function *F) {
  DEBUG(dbgs() << "[add work] ";
    F->printAsOperand(dbgs(), true, M);
    dbgs() << '\n');
  WorkSet.insert(F);
}

/// Find index of \param V as argument of function call \param CI.
static unsigned
getArgIndex(CallInst *CI, Value *V) {
  for (unsigned AI = 0, AE = CI->getNumArgOperands(); AI != AE; ++AI) {
    if (CI->getArgOperand(AI) == V)
      return AI;
  }
  llvm_unreachable("Not argument of function call");
}

/// Get i-th argument of a function.
static Argument*
getArg(Function *F, unsigned I) {
  auto AI = F->arg_begin();
  std::advance(AI, I);
  return AI;
}

/// Create a new function type if \param F has arguments in AdaptedTy, and
/// propagates the adapted arguments to functions called by \param F.
void
OCLTypeToSPIRV::adaptFunction(Function *F) {
  DEBUG(dbgs() << "\n[work on function] ";
    F->printAsOperand(dbgs(), true, M);
    dbgs() << '\n');
  assert (AdaptedTy.count(F) == 0);

  std::vector<Type*> ArgTys;
  bool Changed = false;
  for (auto &I:F->args()) {
    auto Loc = AdaptedTy.find(&I);
    auto Found = (Loc != AdaptedTy.end());
    Changed |= Found;
    ArgTys.push_back (Found ? Loc->second : I.getType());

    if (Found) {
      for (auto U:I.users()) {
        if (auto CI = dyn_cast<CallInst>(U)) {
          auto ArgIndex = getArgIndex(CI, &I);
          auto CF = CI->getCalledFunction();
          if (AdaptedTy.count(CF) == 0) {
            addAdaptedType(getArg(CF, ArgIndex), Loc->second);
            addWork(CF);
          }
        }
      }
    }
  }

  if (!Changed)
    return;

  auto FT = F->getFunctionType();
  FT = FunctionType::get(FT->getReturnType(), ArgTys, FT->isVarArg());
  addAdaptedType(F, FT);
}

MDNode *
OCLTypeToSPIRV::getArgAccessQualifierMetadata(Function *F) {
  return getArgMetadata(F, SPIR_MD_KERNEL_ARG_ACCESS_QUAL);
}

MDNode *
OCLTypeToSPIRV::getKernelMetadata(Function *F) {
  NamedMDNode *KernelMDs = M->getNamedMetadata(SPIR_MD_KERNELS);
  if (!KernelMDs)
    return nullptr;

  for (unsigned I = 0, E = KernelMDs->getNumOperands(); I < E; ++I) {
    MDNode *KernelMD = KernelMDs->getOperand(I);
    if (KernelMD->getNumOperands() == 0)
      continue;
    Function *Kernel = mdconst::dyn_extract<Function>(KernelMD->getOperand(0));

    if (Kernel == F)
      return KernelMD;
  }
  return nullptr;
}

MDNode *
OCLTypeToSPIRV::getArgMetadata(Function *F, const std::string &MDName) {
  auto KernelMD = getKernelMetadata(F);
  if (!KernelMD)
    return nullptr;

  for (unsigned MI = 1, ME = KernelMD->getNumOperands(); MI < ME; ++MI) {
    MDNode *MD = dyn_cast<MDNode>(KernelMD->getOperand(MI));
    if (!MD)
      continue;
    MDString *NameMD = dyn_cast<MDString>(MD->getOperand(0));
    if (!NameMD)
      continue;
    StringRef Name = NameMD->getString();
    if (Name == MDName) {
      return MD;
    }
  }
  return nullptr;
}


MDNode *
OCLTypeToSPIRV::getArgBaseTypeMetadata(Function *F) {
  return getArgMetadata(F, SPIR_MD_KERNEL_ARG_BASE_TYPE);
}

void
OCLTypeToSPIRV::adaptArgumentsByMetadata(Function* F) {
  auto TypeMD = getArgBaseTypeMetadata(F);
  if (!TypeMD)
    return;
  bool Changed = false;
  auto FT = F->getFunctionType();
  auto PI = FT->param_begin();
  auto Arg = F->arg_begin();
  for (unsigned I = 1, E = TypeMD->getNumOperands(); I != E;
      ++I, ++PI, ++ Arg) {
    auto OCLTyStr = getMDOperandAsString(TypeMD, I);
    auto NewTy = *PI;
    if (OCLTyStr == OCL_TYPE_NAME_SAMPLER_T && !NewTy->isStructTy()) {
      addAdaptedType(Arg, getOrCreateOpaquePtrType(M, kSPR2TypeName::Sampler));
      Changed = true;
    } else if (isPointerToOpaqueStructType(NewTy)) {
      auto STName = NewTy->getPointerElementType()->getStructName();
      if (STName.startswith(kSPR2TypeName::ImagePrefix)) {
        auto Ty = STName.str();
        auto AccMD = getArgAccessQualifierMetadata(F);
        auto AccStr = getMDOperandAsString(AccMD, I);
        addAdaptedType(Arg, getOrCreateOpaquePtrType(M,
            Ty + kSPR2TypeName::Delimiter + AccStr));
        Changed = true;
      } else if (STName == SPIR_TYPE_NAME_PIPE_T) {
        auto Ty = STName.str();
        auto AccMD = getArgAccessQualifierMetadata(F);
        auto AccStr = getMDOperandAsString(AccMD, I);
        addAdaptedType(Arg, getOrCreateOpaquePtrType(M,
            Ty + kSPR2TypeName::Delimiter + AccStr));
        Changed = true;
      }
    }
  }
  if (Changed)
    addWork(F);
}


// OCL sampler, image and pipe type need to be regularized before converting
// to SPIRV types.
//
// OCL sampler type is represented as i32 in LLVM, however in SPIRV it is
// represented as OpTypeSampler. Also LLVM uses the same pipe type to
// represent pipe types with different underlying data types, however
// in SPIRV they are different types. OCL image and pipie types do not
// encode access qualifier, which is part of SPIRV types for image and pipe.
//
// The function types in LLVM need to be regularized before translating
// to SPIRV function types:
//
// sampler type as i32 -> opencl.sampler_t opaque type
// opencl.pipe_t opaque type with underlying opencl type x and access
//   qualifier y -> opencl.pipe_t.x.y opaque type
// opencl.image_x opaque type with access qualifier y ->
//   opencl.image_x.y opaque type
//
// The converter relies on kernel_arg_base_type to identify the sampler
// type, the underlying data type of pipe type, and access qualifier for
// image and pipe types. The FE is responsible to generate the correct
// kernel_arg_base_type metadata.
//
// Alternatively,the FE may choose to use opencl.sampler_t to represent
// sampler type, use opencl.pipe_t.x.y to represent pipe type with underlying
// opencl data type x and access qualifier y, and use opencl.image_x.y to
// represent image_x type with access qualifier y.
//
FunctionType *
OCLTypeToSPIRV::getAdaptedFunctionType(Function *F) {
  auto Loc = AdaptedTy.find(F);
  if (Loc != AdaptedTy.end())
    return cast<FunctionType>(Loc->second);

  return F->getFunctionType();
}

}

INITIALIZE_PASS(OCLTypeToSPIRV, "cltytospv", "Adapt OCL types for SPIR-V",
    false, true)

ModulePass *llvm::createOCLTypeToSPIRV() {
  return new OCLTypeToSPIRV();
}
