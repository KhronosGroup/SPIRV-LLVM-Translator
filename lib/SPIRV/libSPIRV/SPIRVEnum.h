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
SPIRVMap<Capability, std::string>::init() {
  add(CapabilityMatrix, "Matrix");
  add(CapabilityShader, "Shader");
  add(CapabilityGeometry, "Geometry");
  add(CapabilityTessellation, "Tessellation");
  add(CapabilityAddresses, "Addresses");
  add(CapabilityLinkage, "Linkage");
  add(CapabilityKernel, "Kernel");
  add(CapabilityVector16, "Vector16");
  add(CapabilityFloat16Buffer, "Float16Buffer");
  add(CapabilityFloat16, "Float16");
  add(CapabilityFloat64, "Float64");
  add(CapabilityInt64, "Int64");
  add(CapabilityInt64Atomics, "Int64Atomics");
  add(CapabilityImageBasic, "ImageBasic");
  add(CapabilityImageReadWrite, "ImageReadWrite");
  add(CapabilityImageMipmap, "ImageMipmap");
  add(CapabilityPipes, "Pipes");
  add(CapabilityGroups, "Groups");
  add(CapabilityDeviceEnqueue, "DeviceEnqueue");
  add(CapabilityLiteralSampler, "LiteralSampler");
  add(CapabilityAtomicStorage, "AtomicStorage");
  add(CapabilityInt16, "Int16");
  add(CapabilityTessellationPointSize, "TessellationPointSize");
  add(CapabilityGeometryPointSize, "GeometryPointSize");
  add(CapabilityImageGatherExtended, "ImageGatherExtended");
  add(CapabilityStorageImageMultisample, "StorageImageMultisample");
  add(CapabilityUniformBufferArrayDynamicIndexing, "UniformBufferArrayDynamicIndexing");
  add(CapabilitySampledImageArrayDynamicIndexing, "SampledImageArrayDynamicIndexing");
  add(CapabilityStorageBufferArrayDynamicIndexing, "StorageBufferArrayDynamicIndexing");
  add(CapabilityStorageImageArrayDynamicIndexing, "StorageImageArrayDynamicIndexing");
  add(CapabilityClipDistance, "ClipDistance");
  add(CapabilityCullDistance, "CullDistance");
  add(CapabilityImageCubeArray, "ImageCubeArray");
  add(CapabilitySampleRateShading, "SampleRateShading");
  add(CapabilityImageRect, "ImageRect");
  add(CapabilitySampledRect, "SampledRect");
  add(CapabilityGenericPointer, "GenericPointer");
  add(CapabilityInt8, "Int8");
  add(CapabilityInputAttachment, "InputAttachment");
  add(CapabilitySparseResidency, "SparseResidency");
  add(CapabilityMinLod, "MinLod");
  add(CapabilitySampled1D, "Sampled1D");
  add(CapabilityImage1D, "Image1D");
  add(CapabilitySampledCubeArray, "SampledCubeArray");
  add(CapabilitySampledBuffer, "SampledBuffer");
  add(CapabilityImageBuffer, "ImageBuffer");
  add(CapabilityImageMSArray, "ImageMSArray");
  add(CapabilityStorageImageExtendedFormats, "StorageImageExtendedFormats");
  add(CapabilityImageQuery, "ImageQuery");
  add(CapabilityDerivativeControl, "DerivativeControl");
  add(CapabilityInterpolationFunction, "InterpolationFunction");
  add(CapabilityTransformFeedback, "TransformFeedback");
  add(CapabilityGeometryStreams, "GeometryStreams");
  add(CapabilityStorageImageReadWithoutFormat, "StorageImageReadWithoutFormat");
  add(CapabilityStorageImageWriteWithoutFormat, "StorageImageWriteWithoutFormat");
}
SPIRV_DEF_NAMEMAP(Capability, SPIRVCapabilityNameMap)

template<> inline void
SPIRVMap<Decoration, std::string>::init() {
  add(DecorationRelaxedPrecision, "RelaxedPrecision");
  add(DecorationSpecId, "SpecId");
  add(DecorationBlock, "Block");
  add(DecorationBufferBlock, "BufferBlock");
  add(DecorationRowMajor, "RowMajor");
  add(DecorationColMajor, "ColMajor");
  add(DecorationArrayStride, "ArrayStride");
  add(DecorationMatrixStride, "MatrixStride");
  add(DecorationGLSLShared, "GLSLShared");
  add(DecorationGLSLPacked, "GLSLPacked");
  add(DecorationCPacked, "CPacked");
  add(DecorationBuiltIn, "BuiltIn");
  add(DecorationNoPerspective, "NoPerspective");
  add(DecorationFlat, "Flat");
  add(DecorationPatch, "Patch");
  add(DecorationCentroid, "Centroid");
  add(DecorationSample, "Sample");
  add(DecorationInvariant, "Invariant");
  add(DecorationRestrict, "Restrict");
  add(DecorationAliased, "Aliased");
  add(DecorationVolatile, "Volatile");
  add(DecorationConstant, "Constant");
  add(DecorationCoherent, "Coherent");
  add(DecorationNonWritable, "NonWritable");
  add(DecorationNonReadable, "NonReadable");
  add(DecorationUniform, "Uniform");
  add(DecorationSaturatedConversion, "SaturatedConversion");
  add(DecorationStream, "Stream");
  add(DecorationLocation, "Location");
  add(DecorationComponent, "Component");
  add(DecorationIndex, "Index");
  add(DecorationBinding, "Binding");
  add(DecorationDescriptorSet, "DescriptorSet");
  add(DecorationOffset, "Offset");
  add(DecorationXfbBuffer, "XfbBuffer");
  add(DecorationXfbStride, "XfbStride");
  add(DecorationFuncParamAttr, "FuncParamAttr");
  add(DecorationFPRoundingMode, "FPRoundingMode");
  add(DecorationFPFastMathMode, "FPFastMathMode");
  add(DecorationLinkageAttributes, "LinkageAttributes");
  add(DecorationNoContraction, "NoContraction");
  add(DecorationInputAttachmentIndex, "InputTargetIndex");
  add(DecorationAlignment, "Alignment");
}
SPIRV_DEF_NAMEMAP(Decoration, SPIRVDecorateNameMap)

template<> inline void
SPIRVMap<SPIRVBuiltinVariableKind, std::string>::init() {
  add(BuiltInPosition, "Position");
  add(BuiltInPointSize, "PointSize");
  add(BuiltInClipDistance, "ClipDistance");
  add(BuiltInCullDistance, "CullDistance");
  add(BuiltInVertexId, "VertexId");
  add(BuiltInInstanceId, "InstanceId");
  add(BuiltInPrimitiveId, "PrimitiveId");
  add(BuiltInInvocationId, "InvocationId");
  add(BuiltInLayer, "Layer");
  add(BuiltInViewportIndex, "ViewportIndex");
  add(BuiltInTessLevelOuter, "TessLevelOuter");
  add(BuiltInTessLevelInner, "TessLevelInner");
  add(BuiltInTessCoord, "TessCoord");
  add(BuiltInPatchVertices, "PatchVertices");
  add(BuiltInFragCoord, "FragCoord");
  add(BuiltInPointCoord, "PointCoord");
  add(BuiltInFrontFacing, "FrontFacing");
  add(BuiltInSampleId, "SampleId");
  add(BuiltInSamplePosition, "SamplePosition");
  add(BuiltInSampleMask, "SampleMask");
  add(BuiltInFragDepth, "FragDepth");
  add(BuiltInHelperInvocation, "HelperInvocation");
  add(BuiltInNumWorkgroups, "NumWorkgroups");
  add(BuiltInWorkgroupSize, "WorkgroupSize");
  add(BuiltInWorkgroupId, "WorkgroupId");
  add(BuiltInLocalInvocationId, "LocalInvocationId");
  add(BuiltInGlobalInvocationId, "GlobalInvocationId");
  add(BuiltInLocalInvocationIndex, "LocalInvocationIndex");
  add(BuiltInWorkDim, "WorkDim");
  add(BuiltInGlobalSize, "GlobalSize");
  add(BuiltInEnqueuedWorkgroupSize, "EnqueuedWorkgroupSize");
  add(BuiltInGlobalOffset, "GlobalOffset");
  add(BuiltInGlobalLinearId, "GlobalLinearId");
  add(BuiltInSubgroupSize, "SubgroupSize");
  add(BuiltInSubgroupMaxSize, "SubgroupMaxSize");
  add(BuiltInNumSubgroups, "NumSubgroups");
  add(BuiltInNumEnqueuedSubgroups, "NumEnqueuedSubgroups");
  add(BuiltInSubgroupId, "SubgroupId");
  add(BuiltInSubgroupLocalInvocationId, "SubgroupLocalInvocationId");
  add(BuiltInCount, "Count");
}
typedef SPIRVMap<SPIRVBuiltinVariableKind, std::string>
  SPIRVBuiltinVariableNameMap;

template<> inline void
SPIRVMap<SPIRVExtInstSetKind, std::string>::init() {
  add(SPIRVEIS_OpenCL, "OpenCL.std");
}
typedef SPIRVMap<SPIRVExtInstSetKind, std::string> SPIRVBuiltinSetNameMap;

inline bool
isValid(SPIRVAccessQualifierKind Acc) {
  return static_cast<unsigned>(Acc) <= AccessQualifierReadWrite;
}

inline bool
isValid(SPIRVExecutionModelKind E) {
  return (unsigned)E < (unsigned)ExecutionModelCount;
}

inline bool
isValid(SPIRVExecutionModeKind E) {
  return (unsigned)E < (unsigned)ExecutionModeCount;
}

inline bool
isValid(SPIRVLinkageTypeKind L) {
  return (unsigned)L < (unsigned)LinkageTypeCount;
}

inline bool
isValid(SPIRVStorageClassKind StorageClass) {
  return (unsigned)StorageClass < (unsigned)StorageClassCount;
}

inline bool
isValid(SPIRVFuncParamAttrKind FPA) {
  return (unsigned)FPA < (unsigned)FunctionParameterAttributeCount;
}

inline bool
isValid(SPIRVExtInstSetKind BIS) {
  return (unsigned)BIS < (unsigned)SPIRVEIS_Count;
}

inline bool
isValid(SPIRVBuiltinVariableKind Kind) {
  return (unsigned)Kind < (unsigned)BuiltInCount;
}

inline bool
isValid(Scope Kind) {
  return (unsigned)Kind <= (unsigned)ScopeInvocation;
}

inline bool
isValid(SPIRVGroupOperationKind G) {
  return (unsigned)G < (unsigned)GroupOperationCount;
}

template<typename K>
SPIRVCapVec
getCapability(K Key) {
  SPIRVCapVec V;
  SPIRVCapabilityKind C;
  if (SPIRVMap<K, SPIRVCapabilityKind>::find(Key, &C))
    V.push_back(C);
  return std::move(V);
}

template<> inline void
SPIRVMap<SPIRVExecutionModelKind, SPIRVCapabilityKind>::init() {
  add(ExecutionModelVertex, CapabilityShader);
  add(ExecutionModelTessellationControl, CapabilityTessellation);
  add(ExecutionModelTessellationEvaluation, CapabilityShader);
  add(ExecutionModelGeometry, CapabilityGeometry);
  add(ExecutionModelFragment, CapabilityShader);
  add(ExecutionModelGLCompute, CapabilityShader);
  add(ExecutionModelKernel, CapabilityKernel);
}

template<> inline void
SPIRVMap<SPIRVExecutionModeKind, SPIRVCapabilityKind>::init() {
  add(ExecutionModeInvocations, CapabilityGeometry);
  add(ExecutionModeSpacingEqual, CapabilityTessellation);
  add(ExecutionModeSpacingFractionalEven, CapabilityTessellation);
  add(ExecutionModeSpacingFractionalOdd, CapabilityTessellation);
  add(ExecutionModeVertexOrderCw, CapabilityTessellation);
  add(ExecutionModeVertexOrderCcw, CapabilityTessellation);
  add(ExecutionModePixelCenterInteger, CapabilityShader);
  add(ExecutionModeOriginUpperLeft, CapabilityShader);
  add(ExecutionModeOriginLowerLeft, CapabilityShader);
  add(ExecutionModeEarlyFragmentTests, CapabilityShader);
  add(ExecutionModePointMode, CapabilityTessellation);
  add(ExecutionModeXfb, CapabilityShader);
  add(ExecutionModeDepthReplacing, CapabilityShader);
  add(ExecutionModeDepthGreater, CapabilityShader);
  add(ExecutionModeDepthLess, CapabilityShader);
  add(ExecutionModeDepthUnchanged, CapabilityShader);
  add(ExecutionModeLocalSizeHint, CapabilityKernel);
  add(ExecutionModeInputPoints, CapabilityGeometry);
  add(ExecutionModeInputLines, CapabilityGeometry);
  add(ExecutionModeInputLinesAdjacency, CapabilityGeometry);
  add(ExecutionModeTriangles, CapabilityTessellation);
  add(ExecutionModeInputTrianglesAdjacency, CapabilityGeometry);
  add(ExecutionModeQuads, CapabilityGeometry);
  add(ExecutionModeIsolines, CapabilityGeometry);
  add(ExecutionModeOutputVertices, CapabilityTessellation);
  add(ExecutionModeOutputPoints, CapabilityGeometry);
  add(ExecutionModeOutputLineStrip, CapabilityGeometry);
  add(ExecutionModeOutputTriangleStrip, CapabilityGeometry);
  add(ExecutionModeVecTypeHint, CapabilityKernel);
  add(ExecutionModeContractionOff, CapabilityKernel);
}

template<> inline void
SPIRVMap<SPIRVStorageClassKind, SPIRVCapabilityKind>::init() {
  add(StorageClassInput, CapabilityShader);
  add(StorageClassUniform, CapabilityShader);
  add(StorageClassOutput, CapabilityShader);
  add(StorageClassPrivate, CapabilityShader);
  add(StorageClassFunction, CapabilityShader);
  add(StorageClassGeneric, CapabilityKernel);
  add(StorageClassAtomicCounter, CapabilityShader);
}

template<> inline void
SPIRVMap<Decoration, SPIRVCapabilityKind>::init() {
  add(DecorationRelaxedPrecision, CapabilityShader);
  add(DecorationSpecId, CapabilityShader);
  add(DecorationBlock, CapabilityShader);
  add(DecorationBufferBlock, CapabilityShader);
  add(DecorationRowMajor, CapabilityMatrix);
  add(DecorationColMajor, CapabilityMatrix);
  add(DecorationArrayStride, CapabilityShader);
  add(DecorationMatrixStride, CapabilityShader);
  add(DecorationGLSLShared, CapabilityShader);
  add(DecorationGLSLPacked, CapabilityShader);
  add(DecorationCPacked, CapabilityKernel);
  add(DecorationNoPerspective, CapabilityShader);
  add(DecorationFlat, CapabilityShader);
  add(DecorationPatch, CapabilityTessellation);
  add(DecorationCentroid, CapabilityShader);
  add(DecorationSample, CapabilityShader);
  add(DecorationInvariant, CapabilityShader);
  add(DecorationConstant, CapabilityKernel);
  add(DecorationUniform, CapabilityShader);
  add(DecorationSaturatedConversion, CapabilityKernel);
  add(DecorationStream, CapabilityGeometryStreams);
  add(DecorationLocation, CapabilityShader);
  add(DecorationComponent, CapabilityShader);
  add(DecorationIndex, CapabilityShader);
  add(DecorationBinding, CapabilityShader);
  add(DecorationDescriptorSet, CapabilityShader);
  add(DecorationXfbBuffer, CapabilityTransformFeedback);
  add(DecorationXfbStride, CapabilityTransformFeedback);
  add(DecorationFuncParamAttr, CapabilityKernel);
  add(DecorationFPRoundingMode, CapabilityKernel);
  add(DecorationFPFastMathMode, CapabilityKernel);
  add(DecorationLinkageAttributes, CapabilityLinkage);
  add(DecorationNoContraction, CapabilityShader);
  add(DecorationInputAttachmentIndex, CapabilityInputAttachment);
  add(DecorationAlignment, CapabilityKernel);
}

inline bool
isValidSPIRVMemSemanticsMask(SPIRVWord MemMask) {
  return MemMask < 1 << ((unsigned)MemorySemanticsImageMemoryShift + 1);
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
