//===- SPIRVEnum.h - SPIR-V enums -------------------------------*- C++ -*-===//
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
/// \file
///
/// This file defines SPIR-V enums.
///
//===----------------------------------------------------------------------===//

#ifndef SPIRVENUM_HPP_
#define SPIRVENUM_HPP_

#include "spirv.hpp"
#include "SPIRVOpCode.h"
#include <cstdint>
using namespace spv;

namespace SPIRV{

typedef uint32_t SPIRVWord;
typedef uint32_t SPIRVId;
#define SPIRVID_MAX       ~0U
#define SPIRVID_INVALID   ~0U
#define SPIRVWORD_MAX     ~0U

inline bool
isValidId(SPIRVId Id) { return Id != SPIRVID_INVALID && Id != 0;}

inline SPIRVWord
mkWord(unsigned WordCount, Op OpCode) {
  return (WordCount << 16) | OpCode;
}

const static unsigned kSPIRVMemOrderSemanticMask = 0x1F;

enum SPIRVGeneratorKind {
  SPIRVGEN_KhronosLLVMSPIRVTranslator   = 6,
  SPIRVGEN_KhronosSPIRVAssembler        = 7,
};

enum SPIRVInstructionSchemaKind {
  SPIRVISCH_Default,
};

enum SPIRVExtInstSetKind {
  SPIRVEIS_OpenCL,
  SPIRVEIS_Count,
};

enum SPIRVSamplerAddressingModeKind {
  SPIRVSAM_None = 0,
  SPIRVSAM_ClampEdge = 2,
  SPIRVSAM_Clamp = 4,
  SPIRVSAM_Repeat = 6,
  SPIRVSAM_RepeatMirrored = 8,
  SPIRVSAM_Invalid = 255,
};

enum SPIRVSamplerFilterModeKind {
  SPIRVSFM_Nearest = 16,
  SPIRVSFM_Linear = 32,
  SPIRVSFM_Invalid = 255,
};

typedef spv::Capability SPIRVCapabilityKind;
typedef spv::ExecutionModel SPIRVExecutionModelKind;
typedef spv::ExecutionMode SPIRVExecutionModeKind;
typedef spv::AccessQualifier SPIRVAccessQualifierKind;
typedef spv::AddressingModel SPIRVAddressingModelKind;
typedef spv::LinkageType SPIRVLinkageTypeKind;
typedef spv::MemoryModel SPIRVMemoryModelKind;
typedef spv::StorageClass SPIRVStorageClassKind;
typedef spv::FunctionControlMask SPIRVFunctionControlMaskKind;
typedef spv::FPRoundingMode SPIRVFPRoundingModeKind;
typedef spv::FunctionParameterAttribute SPIRVFuncParamAttrKind;
typedef spv::BuiltIn SPIRVBuiltinVariableKind;
typedef spv::MemoryAccessMask SPIRVMemoryAccessKind;
typedef spv::GroupOperation SPIRVGroupOperationKind;
typedef spv::Dim SPIRVImageDimKind;
typedef std::vector<SPIRVCapabilityKind> SPIRVCapVec;

template<> inline void
SPIRVMap<SPIRVExtInstSetKind, std::string>::init() {
  add(SPIRVEIS_OpenCL, "OpenCL.std");
}
typedef SPIRVMap<SPIRVExtInstSetKind, std::string> SPIRVBuiltinSetNameMap;

template<typename K>
SPIRVCapVec
getCapability(K Key) {
  SPIRVCapVec V;
  SPIRVMap<K, SPIRVCapVec>::find(Key, &V);
  return std::move(V);
}

template<> inline void
SPIRVMap<SPIRVCapabilityKind, SPIRVCapVec>::init() {
  add(CapabilityShader, { CapabilityMatrix });
  add(CapabilityGeometry, { CapabilityShader });
  add(CapabilityTessellation, { CapabilityShader });
  add(CapabilityVector16, { CapabilityKernel });
  add(CapabilityFloat16Buffer, { CapabilityKernel });
  add(CapabilityInt64Atomics, { CapabilityInt64 });
  add(CapabilityImageBasic, { CapabilityKernel });
  add(CapabilityImageReadWrite, { CapabilityImageBasic });
  add(CapabilityImageMipmap, { CapabilityImageBasic });
  add(CapabilityPipes, { CapabilityKernel });
  add(CapabilityDeviceEnqueue, { CapabilityKernel });
  add(CapabilityLiteralSampler, { CapabilityKernel });
  add(CapabilityAtomicStorage, { CapabilityShader });
  add(CapabilityTessellationPointSize, { CapabilityTessellation });
  add(CapabilityGeometryPointSize, { CapabilityGeometry });
  add(CapabilityImageGatherExtended, { CapabilityShader });
  add(CapabilityStorageImageMultisample, { CapabilityShader });
  add(CapabilityUniformBufferArrayDynamicIndexing, { CapabilityShader });
  add(CapabilitySampledImageArrayDynamicIndexing, { CapabilityShader });
  add(CapabilityStorageBufferArrayDynamicIndexing, { CapabilityShader });
  add(CapabilityStorageImageArrayDynamicIndexing, { CapabilityShader });
  add(CapabilityClipDistance, { CapabilityShader });
  add(CapabilityCullDistance, { CapabilityShader });
  add(CapabilityImageCubeArray, { CapabilitySampledCubeArray });
  add(CapabilitySampleRateShading, { CapabilityShader });
  add(CapabilityImageRect, { CapabilitySampledRect });
  add(CapabilitySampledRect, { CapabilityShader });
  add(CapabilityGenericPointer, { CapabilityAddresses });
  add(CapabilityInt8, { CapabilityKernel });
  add(CapabilityInputAttachment, { CapabilityShader });
  add(CapabilitySparseResidency, { CapabilityShader });
  add(CapabilityMinLod, { CapabilityShader });
  add(CapabilitySampled1D, { CapabilityShader });
  add(CapabilityImage1D, { CapabilitySampled1D });
  add(CapabilitySampledCubeArray, { CapabilityShader });
  add(CapabilitySampledBuffer, { CapabilityShader });
  add(CapabilityImageBuffer, { CapabilitySampledBuffer });
  add(CapabilityImageMSArray, { CapabilityShader });
  add(CapabilityStorageImageExtendedFormats, { CapabilityShader });
  add(CapabilityImageQuery, { CapabilityShader });
  add(CapabilityDerivativeControl, { CapabilityShader });
  add(CapabilityInterpolationFunction, { CapabilityShader });
  add(CapabilityTransformFeedback, { CapabilityShader });
  add(CapabilityGeometryStreams, { CapabilityGeometry });
  add(CapabilityStorageImageReadWithoutFormat, { CapabilityShader });
  add(CapabilityStorageImageWriteWithoutFormat, { CapabilityShader });
  add(CapabilityMultiViewport, { CapabilityGeometry });
}

template<> inline void
SPIRVMap<SPIRVExecutionModelKind, SPIRVCapVec>::init() {
  add(ExecutionModelVertex, { CapabilityShader });
  add(ExecutionModelTessellationControl, { CapabilityTessellation });
  add(ExecutionModelTessellationEvaluation, { CapabilityTessellation });
  add(ExecutionModelGeometry, { CapabilityGeometry });
  add(ExecutionModelFragment, { CapabilityShader });
  add(ExecutionModelGLCompute, { CapabilityShader });
  add(ExecutionModelKernel, { CapabilityKernel });
}

template<> inline void
SPIRVMap<SPIRVExecutionModeKind, SPIRVCapVec>::init() {
  add(ExecutionModeInvocations, { CapabilityGeometry });
  add(ExecutionModeSpacingEqual, { CapabilityTessellation });
  add(ExecutionModeSpacingFractionalEven, { CapabilityTessellation });
  add(ExecutionModeSpacingFractionalOdd, { CapabilityTessellation });
  add(ExecutionModeVertexOrderCw, { CapabilityTessellation });
  add(ExecutionModeVertexOrderCcw, { CapabilityTessellation });
  add(ExecutionModePixelCenterInteger, { CapabilityShader });
  add(ExecutionModeOriginUpperLeft, { CapabilityShader });
  add(ExecutionModeOriginLowerLeft, { CapabilityShader });
  add(ExecutionModeEarlyFragmentTests, { CapabilityShader });
  add(ExecutionModePointMode, { CapabilityTessellation });
  add(ExecutionModeXfb, { CapabilityTransformFeedback });
  add(ExecutionModeDepthReplacing, { CapabilityShader });
  add(ExecutionModeDepthGreater, { CapabilityShader });
  add(ExecutionModeDepthLess, { CapabilityShader });
  add(ExecutionModeDepthUnchanged, { CapabilityShader });
  add(ExecutionModeLocalSizeHint, { CapabilityKernel });
  add(ExecutionModeInputPoints, { CapabilityGeometry });
  add(ExecutionModeInputLines, { CapabilityGeometry });
  add(ExecutionModeInputLinesAdjacency, { CapabilityGeometry });
  add(ExecutionModeTriangles, { CapabilityGeometry, CapabilityTessellation });
  add(ExecutionModeInputTrianglesAdjacency, { CapabilityGeometry });
  add(ExecutionModeQuads, { CapabilityTessellation });
  add(ExecutionModeIsolines, { CapabilityTessellation });
  add(ExecutionModeOutputVertices, { CapabilityGeometry, CapabilityTessellation });
  add(ExecutionModeOutputPoints, { CapabilityGeometry });
  add(ExecutionModeOutputLineStrip, { CapabilityGeometry });
  add(ExecutionModeOutputTriangleStrip, { CapabilityGeometry });
  add(ExecutionModeVecTypeHint, { CapabilityKernel });
  add(ExecutionModeContractionOff, { CapabilityKernel });
}

template<> inline void
SPIRVMap<SPIRVMemoryModelKind, SPIRVCapVec>::init() {
  add(MemoryModelSimple, { CapabilityShader });
  add(MemoryModelGLSL450, { CapabilityShader });
  add(MemoryModelOpenCL, { CapabilityKernel });
}

template<> inline void
SPIRVMap<SPIRVStorageClassKind, SPIRVCapVec>::init() {
  add(StorageClassInput, { CapabilityShader });
  add(StorageClassUniform, { CapabilityShader });
  add(StorageClassOutput, { CapabilityShader });
  add(StorageClassPrivate, { CapabilityShader });
  add(StorageClassGeneric, { CapabilityGenericPointer });
  add(StorageClassPushConstant, { CapabilityShader });
  add(StorageClassAtomicCounter, { CapabilityAtomicStorage });
}

template<> inline void
SPIRVMap<SPIRVImageDimKind, SPIRVCapVec>::init() {
  add(Dim1D, { CapabilitySampled1D });
  add(DimCube, { CapabilityShader });
  add(DimRect, { CapabilitySampledRect });
  add(DimBuffer, { CapabilitySampledBuffer });
  add(DimSubpassData, {CapabilityInputAttachment });
}

template<> inline void
SPIRVMap<ImageFormat, SPIRVCapVec>::init() {
  add(ImageFormatRgba32f, { CapabilityShader });
  add(ImageFormatRgba16f, { CapabilityShader });
  add(ImageFormatR32f, { CapabilityShader });
  add(ImageFormatRgba8, { CapabilityShader });
  add(ImageFormatRgba8Snorm, { CapabilityShader });
  add(ImageFormatRg32f, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRg16f, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatR11fG11fB10f, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatR16f, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRgba16, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRgb10A2, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRg16, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRg8, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatR16, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatR8, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRgba16Snorm, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRg16Snorm, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRg8Snorm, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatR16Snorm, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatR8Snorm, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRgba32i, { CapabilityShader });
  add(ImageFormatRgba16i, { CapabilityShader });
  add(ImageFormatRgba8i, { CapabilityShader });
  add(ImageFormatR32i, { CapabilityShader });
  add(ImageFormatRg32i, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRg16i, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRg8i, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatR16i, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatR8i, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRgba32ui, { CapabilityShader });
  add(ImageFormatRgba16ui, { CapabilityShader });
  add(ImageFormatRgba8ui, { CapabilityShader });
  add(ImageFormatR32ui, { CapabilityShader });
  add(ImageFormatRgb10a2ui, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRg32ui, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatRg16ui, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatR16ui, { CapabilityStorageImageExtendedFormats });
  add(ImageFormatR8ui, { CapabilityStorageImageExtendedFormats });
}

template<> inline void
SPIRVMap<ImageOperandsMask, SPIRVCapVec>::init() {
  add(ImageOperandsBiasMask, { CapabilityShader });
  add(ImageOperandsOffsetMask, { CapabilityImageGatherExtended });
  add(ImageOperandsMinLodMask, { CapabilityMinLod });
}

template<> inline void
SPIRVMap<Decoration, SPIRVCapVec>::init() {
  add(DecorationRelaxedPrecision, { CapabilityShader });
  add(DecorationSpecId, { CapabilityShader });
  add(DecorationBlock, { CapabilityShader });
  add(DecorationBufferBlock, { CapabilityShader });
  add(DecorationRowMajor, { CapabilityMatrix });
  add(DecorationColMajor, { CapabilityMatrix });
  add(DecorationArrayStride, { CapabilityShader });
  add(DecorationMatrixStride, { CapabilityMatrix });
  add(DecorationGLSLShared, { CapabilityShader });
  add(DecorationGLSLPacked, { CapabilityShader });
  add(DecorationCPacked, { CapabilityKernel });
  add(DecorationNoPerspective, { CapabilityShader });
  add(DecorationFlat, { CapabilityShader });
  add(DecorationPatch, { CapabilityTessellation });
  add(DecorationCentroid, { CapabilityShader });
  add(DecorationSample, { CapabilitySampleRateShading });
  add(DecorationInvariant, { CapabilityShader });
  add(DecorationConstant, { CapabilityKernel });
  add(DecorationUniform, { CapabilityShader });
  add(DecorationSaturatedConversion, { CapabilityKernel });
  add(DecorationStream, { CapabilityGeometryStreams });
  add(DecorationLocation, { CapabilityShader });
  add(DecorationComponent, { CapabilityShader });
  add(DecorationIndex, { CapabilityShader });
  add(DecorationBinding, { CapabilityShader });
  add(DecorationDescriptorSet, { CapabilityShader });
  add(DecorationOffset, { CapabilityShader });
  add(DecorationXfbBuffer, { CapabilityTransformFeedback });
  add(DecorationXfbStride, { CapabilityTransformFeedback });
  add(DecorationFuncParamAttr, { CapabilityKernel });
  add(DecorationFPRoundingMode, { CapabilityKernel });
  add(DecorationFPFastMathMode, { CapabilityKernel });
  add(DecorationLinkageAttributes, { CapabilityLinkage });
  add(DecorationNoContraction, { CapabilityShader });
  add(DecorationInputAttachmentIndex, { CapabilityInputAttachment });
  add(DecorationAlignment, { CapabilityKernel });
}

template<> inline void
SPIRVMap<BuiltIn, SPIRVCapVec>::init() {
  add(BuiltInPosition, { CapabilityShader });
  add(BuiltInPointSize, { CapabilityShader });
  add(BuiltInClipDistance, { CapabilityClipDistance });
  add(BuiltInCullDistance, { CapabilityCullDistance });
  add(BuiltInVertexId, { CapabilityShader });
  add(BuiltInInstanceId, { CapabilityShader });
  add(BuiltInPrimitiveId, { CapabilityGeometry, CapabilityTessellation });
  add(BuiltInInvocationId, { CapabilityGeometry, CapabilityTessellation });
  add(BuiltInLayer, { CapabilityGeometry });
  add(BuiltInViewportIndex, { CapabilityMultiViewport });
  add(BuiltInTessLevelOuter, { CapabilityTessellation });
  add(BuiltInTessLevelInner, { CapabilityTessellation });
  add(BuiltInTessCoord, { CapabilityTessellation });
  add(BuiltInPatchVertices, { CapabilityTessellation });
  add(BuiltInFragCoord, { CapabilityShader });
  add(BuiltInPointCoord, { CapabilityShader });
  add(BuiltInFrontFacing, { CapabilityShader });
  add(BuiltInSampleId, { CapabilitySampleRateShading });
  add(BuiltInSamplePosition, { CapabilitySampleRateShading });
  add(BuiltInSampleMask, { CapabilitySampleRateShading });
  add(BuiltInFragDepth, { CapabilityShader });
  add(BuiltInHelperInvocation, { CapabilityShader });
  add(BuiltInWorkDim, { CapabilityKernel });
  add(BuiltInGlobalSize, { CapabilityKernel });
  add(BuiltInEnqueuedWorkgroupSize, { CapabilityKernel });
  add(BuiltInGlobalOffset, { CapabilityKernel });
  add(BuiltInGlobalLinearId, { CapabilityKernel });
  add(BuiltInSubgroupSize, { CapabilityKernel });
  add(BuiltInSubgroupMaxSize, { CapabilityKernel });
  add(BuiltInNumSubgroups, { CapabilityKernel });
  add(BuiltInNumEnqueuedSubgroups, { CapabilityKernel });
  add(BuiltInSubgroupId, { CapabilityKernel });
  add(BuiltInSubgroupLocalInvocationId, { CapabilityKernel });
  add(BuiltInVertexIndex, { CapabilityShader });
  add(BuiltInInstanceIndex, { CapabilityShader });
}

template<> inline void
SPIRVMap<MemorySemanticsMask, SPIRVCapVec>::init() {
  add(MemorySemanticsUniformMemoryMask, { CapabilityShader });
  add(MemorySemanticsAtomicCounterMemoryMask, { CapabilityAtomicStorage });
}

inline unsigned
getImageDimension(SPIRVImageDimKind K) {
  switch(K){
  case Dim1D:      return 1;
  case Dim2D:      return 2;
  case Dim3D:      return 3;
  case DimCube:    return 2;
  case DimRect:    return 2;
  case DimBuffer:  return 1;
  default:              return 0;
  }
}

/// Extract memory order part of SPIR-V memory semantics.
inline unsigned
extractSPIRVMemOrderSemantic(unsigned Sema) {
  return Sema & kSPIRVMemOrderSemanticMask;
}


}


#endif /* SPIRVENUM_HPP_ */
