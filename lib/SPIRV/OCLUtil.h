//===- OCLUtil.h - OCL Utilities declarations -------------------*- C++ -*-===//
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
// This file declares OCL utility functions.
//
//===----------------------------------------------------------------------===//
#include "SPRVInternal.h"

#include <utility>
#include <tuple>
#include <functional>
using namespace SPRV;
using namespace llvm;

namespace OCLUtil {

typedef std::tuple<unsigned, OCLMemOrderKind, OCLMemScopeKind>
  AtomicWorkItemFenceLiterals;

/// Information for translating OCL builtin.
struct OCLBuiltinTransInfo {
  std::string UniqName;
  /// Postprocessor of operands
  std::function<void(std::vector<Value *>&)> PostProc;
  OCLBuiltinTransInfo(){
    PostProc = [](std::vector<Value *>&){};
  }
};

/// OCL 1.x atomic memory order when translated to 2.0 atomics.
const OCLMemOrderKind OCLLegacyAtomicMemOrder = OCLMO_seq_cst;

/// OCL 1.x atomic memory scope when translated to 2.0 atomics.
const OCLMemScopeKind OCLLegacyAtomicMemScope = OCLMS_device;

/// Get literal arguments of call of atomic_work_item_fence.
AtomicWorkItemFenceLiterals getAtomicWorkItemFenceLiterals(CallInst* CI);

/// Get number of memory order arguments for atomic builtin function.
size_t getAtomicBuiltinNumMemoryOrderArgs(StringRef Name);

/// Get metadata operand as int.
int getMDOperandAsInt(MDNode* N, unsigned I);

/// Get metadata operand as string.
std::string getMDOperandAsString(MDNode* N, unsigned I);

/// Get metadata operand as type.
Type* getMDOperandAsType(MDNode* N, unsigned I);

/// Get OCL version from metadata opencl.ocl.version.
/// \return 20 for OCL 2.0, 12 for OCL 1.2.
unsigned getOCLVersion(Module *M);

SPIRAddressSpace getOCLOpaqueTypeAddrSpace(Op OpCode);

}

