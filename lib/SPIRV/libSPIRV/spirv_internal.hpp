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
  IOpAliasDomainDeclINTEL = 5911,
  IOpAliasScopeDeclINTEL = 5912,
  IOpAliasScopeListDeclINTEL = 5913,
  IOpConvertFToBF16INTEL = 6116,
  IOpConvertBF16ToFINTEL = 6117,
  IOpRoundFToTF32INTEL = 6426,
  IOpMaskedGatherINTEL = 6428,
  IOpMaskedScatterINTEL = 6429,
  IOpPrev = OpMax - 2,
  IOpForward
};

enum InternalDecoration {
  IDecAliasScopeINTEL = 5914,
  IDecNoAliasINTEL = 5915,
  IDecHostAccessINTEL = 6147,
  IDecInitModeINTEL = 6148,
  IDecImplementInCSRINTEL = 6149,
};

enum InternalCapability {
  ICapMemoryAccessAliasingINTEL = 5910,
  ICapDebugInfoModuleINTEL = 6114,
  ICapBfloat16ConversionINTEL = 6115,
  ICapabilityTensorFloat32RoundingINTEL = 6425,
  ICapabilityMaskedGatherScatterINTEL = 6427,
  ICapabilityHWThreadQueryINTEL = 6134,
  ICapGlobalVariableDecorationsINTEL = 6146
};

enum InternalMemoryAccessMask {
  IMemAccessAliasScopeINTELMask = 0x10000,
  IMemAccessNoAliasINTELMask = 0x20000
};

constexpr LinkageType LinkageTypeInternal =
    static_cast<LinkageType>(ILTInternal);

#define _SPIRV_OP(x, y) constexpr x x##y = static_cast<x>(I##x##y);
_SPIRV_OP(Capability, MaskedGatherScatterINTEL)
_SPIRV_OP(Op, MaskedGatherINTEL)
_SPIRV_OP(Op, MaskedScatterINTEL)

_SPIRV_OP(Capability, TensorFloat32RoundingINTEL)
_SPIRV_OP(Op, RoundFToTF32INTEL)

enum InternalBuiltIn {
  IBuiltInSubDeviceIDINTEL = 6135,
  IBuiltInGlobalHWThreadIDINTEL = 6136,
};

#define _SPIRV_OP(x, y) constexpr x x##y = static_cast<x>(I##x##y);
_SPIRV_OP(Capability, HWThreadQueryINTEL)
_SPIRV_OP(BuiltIn, SubDeviceIDINTEL)
_SPIRV_OP(BuiltIn, GlobalHWThreadIDINTEL)
#undef _SPIRV_OP

constexpr Op OpForward = static_cast<Op>(IOpForward);
constexpr Op OpAliasDomainDeclINTEL = static_cast<Op>(IOpAliasDomainDeclINTEL);
constexpr Op OpAliasScopeDeclINTEL = static_cast<Op>(IOpAliasScopeDeclINTEL);
constexpr Op OpAliasScopeListDeclINTEL =
    static_cast<Op>(IOpAliasScopeListDeclINTEL);
constexpr Op OpConvertFToBF16INTEL = static_cast<Op>(IOpConvertFToBF16INTEL);
constexpr Op OpConvertBF16ToFINTEL = static_cast<Op>(IOpConvertBF16ToFINTEL);

constexpr Decoration DecorationAliasScopeINTEL =
    static_cast<Decoration>(IDecAliasScopeINTEL );
constexpr Decoration DecorationNoAliasINTEL =
    static_cast<Decoration>(IDecNoAliasINTEL);
constexpr Decoration DecorationHostAccessINTEL =
    static_cast<Decoration>(IDecHostAccessINTEL);
constexpr Decoration DecorationInitModeINTEL =
    static_cast<Decoration>(IDecInitModeINTEL);
constexpr Decoration DecorationImplementInCSRINTEL =
    static_cast<Decoration>(IDecImplementInCSRINTEL);

constexpr Capability CapabilityGlobalVariableDecorationsINTEL =
    static_cast<Capability>(ICapGlobalVariableDecorationsINTEL);

constexpr Capability CapabilityMemoryAccessAliasingINTEL =
    static_cast<Capability>(ICapMemoryAccessAliasingINTEL);
constexpr Capability CapabilityDebugInfoModuleINTEL =
    static_cast<Capability>(ICapDebugInfoModuleINTEL);

constexpr Capability CapabilityBfloat16ConversionINTEL =
    static_cast<Capability>(ICapBfloat16ConversionINTEL);

constexpr MemoryAccessMask MemoryAccessAliasScopeINTELMask =
    static_cast<MemoryAccessMask>(IMemAccessAliasScopeINTELMask);
constexpr MemoryAccessMask MemoryAccessNoAliasINTELMask =
    static_cast<MemoryAccessMask>(IMemAccessNoAliasINTELMask);

} // namespace internal
} // namespace spv

#endif // #ifndef spirv_internal_HPP
