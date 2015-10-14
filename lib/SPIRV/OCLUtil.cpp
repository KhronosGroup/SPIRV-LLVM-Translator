//===- OCLUtil.cpp - OCL Utilities ----------------------------------------===//
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
// This file implements OCL utility functions.
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "oclutil"

#include "SPRVInternal.h"
#include "OCLUtil.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Pass.h"
#include "llvm/PassSupport.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace SPRV;

namespace OCLUtil {

cl::opt<enum SPIRAddressSpace>
ReservedIdAddrSpaceForOutput("spirv-reserved-id-addr-space",
    cl::desc("Addr space of reserved id for output"), cl::init(SPIRAS_Global));

///////////////////////////////////////////////////////////////////////////////
//
// Functions for getting builtin call info
//
///////////////////////////////////////////////////////////////////////////////
AtomicWorkItemFenceLiterals getAtomicWorkItemFenceLiterals(CallInst* CI) {
  return std::make_tuple(getArgInt(CI, 0),
    static_cast<OCLMemOrderKind>(getArgInt(CI, 1)),
    static_cast<OCLScopeKind>(getArgInt(CI, 2)));
}

size_t getAtomicBuiltinNumMemoryOrderArgs(StringRef Name) {
  if (Name.find("compare_exchange_strong") != StringRef::npos)
    return 2;
  return 1;
}

WorkGroupBarrierLiterals getWorkGroupBarrierLiterals(CallInst* CI){
  auto N = CI->getNumArgOperands();
  assert (N == 1 || N == 3);
  return std::make_tuple(getArgInt(CI, 0),
    N == 1 ? OCLMS_work_group : static_cast<OCLScopeKind>(getArgInt(CI, 1)),
    OCLMS_work_group);
}

///////////////////////////////////////////////////////////////////////////////
//
// Functions for getting metadata
//
///////////////////////////////////////////////////////////////////////////////
int
getMDOperandAsInt(MDNode* N, unsigned I) {
  return mdconst::dyn_extract<ConstantInt>(N->getOperand(I))->getZExtValue();
}

std::string
getMDOperandAsString(MDNode* N, unsigned I) {
  Metadata* Op = N->getOperand(I);

  if (!Op)
    return "";
  if (MDString* Str = dyn_cast<MDString>(Op)) {
    return Str->getString().str();
  }
  return "";
}

Type*
getMDOperandAsType(MDNode* N, unsigned I) {
  return cast<ValueAsMetadata>(N->getOperand(I))->getType();
}

///////////////////////////////////////////////////////////////////////////////
//
// Functions for getting module info
//
///////////////////////////////////////////////////////////////////////////////

unsigned getOCLVersion(Module *M) {
  NamedMDNode *NamedMD = M->getNamedMetadata(SPIR_MD_OCL_VERSION);
  assert (NamedMD && "Invalid SPIR");
  assert (NamedMD->getNumOperands() == 1 && "Invalid SPIR");
  MDNode *MD = NamedMD->getOperand(0);
  unsigned Major = getMDOperandAsInt(MD, 0);
  unsigned Minor = getMDOperandAsInt(MD, 1);
  return Major * 10 + Minor;
}

SPIRAddressSpace
getOCLOpaqueTypeAddrSpace(Op OpCode) {
  switch (OpCode) {
  case OpTypePipe:
  case OpTypeQueue:
  case OpTypeEvent:
  case OpTypeDeviceEvent:
  case OpTypeSampler:
    return SPIRAS_Global;
  case OpTypeReserveId:
    return ReservedIdAddrSpaceForOutput;
  default:
    return SPIRAS_Private;
  }
}


}

