// Copyright (c) 2020 The Khronos Group Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and/or associated documentation files (the "Materials"),
// to deal in the Materials without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Materials, and to permit persons to whom the
// Materials are furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Materials.
//
// THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM,OUT OF OR IN CONNECTION WITH THE MATERIALS OR THE USE OR OTHER DEALINGS
// IN THE MATERIALS.

// The header is for SPIR-V to LLVM IR internal definitions, that are not a part
// of Khronos SPIR-V specification.

#include "spirv.hpp"

#ifndef spirv_internal_HPP
#define spirv_internal_HPP

namespace spv {
namespace internal {

enum InternalLinkageType {
  ILTPrev = LinkageTypeMax - 2,
  ILTInternal
};

enum InternalOp {
  IOpAtomicFMinEXT = 5614,
  IOpAtomicFMaxEXT = 5615,
  IOpAssumeTrueINTEL = 5630,
  IOpExpectINTEL = 5631,
  IOpPrev = OpMax - 2,
  IOpForward
};

enum InternalCapability {
  ICapAtomicFloat32MinMaxEXT = 5612,
  ICapAtomicFloat64MinMaxEXT = 5613,
  ICapAtomicFloat16MinMaxEXT = 5616,
  ICapOptimizationHintsINTEL = 5629
};

constexpr LinkageType LinkageTypeInternal =
    static_cast<LinkageType>(ILTInternal);

constexpr Op OpForward = static_cast<Op>(IOpForward);
constexpr Op OpAtomicFMinEXT = static_cast<Op>(IOpAtomicFMinEXT);
constexpr Op OpAtomicFMaxEXT = static_cast<Op>(IOpAtomicFMaxEXT);
constexpr Op OpAssumeTrueINTEL = static_cast<Op>(IOpAssumeTrueINTEL);
constexpr Op OpExpectINTEL = static_cast<Op>(IOpExpectINTEL);

constexpr Capability CapabilityAtomicFloat32MinMaxEXT =
    static_cast<Capability>(ICapAtomicFloat32MinMaxEXT);
constexpr Capability CapabilityAtomicFloat64MinMaxEXT =
    static_cast<Capability>(ICapAtomicFloat64MinMaxEXT);
constexpr Capability CapabilityAtomicFloat16MinMaxEXT =
    static_cast<Capability>(ICapAtomicFloat16MinMaxEXT);
constexpr Capability CapabilityOptimizationHintsINTEL =
    static_cast<Capability>(ICapOptimizationHintsINTEL);

} // namespace internal
} // namespace spv

#endif // #ifndef spirv_internal_HPP
