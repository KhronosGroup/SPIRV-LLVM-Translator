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
  M = &Module;
  Ctx = &M->getContext();
  auto Src = getSPIRVSource(&Module);
  if (std::get<0>(Src) != spv::SourceLanguageOpenCL_C)
    return false;

  CLVer = std::get<1>(Src);
  if (CLVer > kOCLVer::CL20)
    return false;

  DEBUG(dbgs() << "Enter OCLTypeToSPIRV:\n");

  return false;
}

void
OCLTypeToSPIRV::adaptFunctionType(const std::map<unsigned, Type*>& ChangedType,
    llvm::FunctionType* &FT) {
  if (ChangedType.empty())
    return;
  std::vector<Type*> ArgTys;
  getFunctionTypeParameterTypes(FT, ArgTys);
  for (auto& I : ChangedType)
    ArgTys[I.first] = I.second;
  FT = FunctionType::get(FT->getReturnType(), ArgTys, FT->isVarArg());
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
OCLTypeToSPIRV::getAdaptedArgumentTypesByArgBaseTypeMetadata(
    llvm::FunctionType* FT,
    std::map<unsigned, Type*>& ChangedType, Function* F) {
  auto TypeMD = getArgBaseTypeMetadata(F);
  if (!TypeMD)
    return;
  auto PI = FT->param_begin();
  for (unsigned I = 1, E = TypeMD->getNumOperands(); I != E; ++I, ++PI) {
    auto OCLTyStr = getMDOperandAsString(TypeMD, I);
    auto NewTy = *PI;
    if (OCLTyStr == OCL_TYPE_NAME_SAMPLER_T && !NewTy->isStructTy()) {
      ChangedType[I - 1] = getOrCreateOpaquePtrType(M,
          kSPR2TypeName::Sampler);
    } else if (isPointerToOpaqueStructType(NewTy)) {
      auto STName = NewTy->getPointerElementType()->getStructName();
      if (STName.startswith(kSPR2TypeName::ImagePrefix)) {
        auto Ty = STName.str();
        auto AccMD = getArgAccessQualifierMetadata(F);
        auto AccStr = getMDOperandAsString(AccMD, I);
        ChangedType[I - 1] = getOrCreateOpaquePtrType(M,
            Ty + kSPR2TypeName::Delimiter + AccStr);
      } else if (STName == SPIR_TYPE_NAME_PIPE_T) {
        auto Ty = STName.str();
        auto AccMD = getArgAccessQualifierMetadata(F);
        auto AccStr = getMDOperandAsString(AccMD, I);
        ChangedType[I - 1] = getOrCreateOpaquePtrType(M,
            Ty + kSPR2TypeName::Delimiter + AccStr);
      }
    }
  }
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
  auto FT = F->getFunctionType();
  std::map<unsigned, Type *> ChangedType;
  getAdaptedArgumentTypesByArgBaseTypeMetadata(FT, ChangedType, F);
  adaptFunctionType(ChangedType, FT);
  return FT;
}

}

INITIALIZE_PASS(OCLTypeToSPIRV, "cltytospv", "Adapt OCL types for SPIR-V",
    false, true)

ModulePass *llvm::createOCLTypeToSPIRV() {
  return new OCLTypeToSPIRV();
}
