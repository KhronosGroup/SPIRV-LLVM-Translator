//===- SPRVEnum.h - SPIR-V enums --------------------------------*- C++ -*-===//
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

#ifndef SPRVENUM_HPP_
#define SPRVENUM_HPP_

#include "spirv.hpp"
#include "SPRVOpCode.h"
#include <cstdint>
using namespace spv;

namespace SPRV{

typedef uint32_t SPRVWord;
typedef uint32_t SPRVId;
#define SPRVID_MAX       ~0U
#define SPRVID_INVALID   ~0U
#define SPRVWORD_MAX     ~0U

inline bool
isValid(SPRVId Id) { return Id != SPRVID_INVALID;}

inline SPRVWord
mkWord(unsigned WordCount, Op OpCode) {
  return (WordCount << 16) | OpCode;
}

const static unsigned kSPRVMemOrderSemanticMask = 0x1F;

/// Extract memory order part of SPIR-V memory semantics.
inline unsigned extractSPRVMemOrderSemantic(unsigned Sema) {
  return Sema & kSPRVMemOrderSemanticMask;
}

// ToDo: register the LLVM/SPIRV translator and get an official SPIRV generator
// magic number
enum SPRVGeneratorKind {
  SPRVGEN_AMDOpenSourceLLVMSPRVTranslator = 1,
};

enum SPRVInstructionSchemaKind {
  SPRVISCH_Default,
};

typedef spv::Capability SPRVCapabilityKind;
typedef spv::ExecutionModel SPRVExecutionModelKind;
typedef spv::ExecutionMode SPRVExecutionModeKind;
typedef spv::AccessQualifier SPRVAccessQualifierKind;
typedef spv::AddressingModel SPRVAddressingModelKind;
typedef spv::LinkageType SPRVLinkageTypeKind;
typedef spv::MemoryModel SPRVMemoryModelKind;
typedef spv::StorageClass SPRVStorageClassKind;
typedef spv::FunctionControlMask SPRVFunctionControlMaskKind;
typedef spv::FPRoundingMode SPRVFPRoundingModeKind;
typedef spv::FunctionParameterAttribute SPRVFuncParamAttrKind;
typedef spv::BuiltIn SPRVBuiltinVariableKind;
typedef spv::MemoryAccessMask SPRVMemoryAccessKind;
typedef spv::GroupOperation SPRVGroupOperationKind;
typedef spv::Dim SPRVImageDimKind;

template<typename K>
SPRVCapabilityKind
getCapability(K Key) {
  return SPRVMap<K, SPRVCapabilityKind>::map(Key);
}

template<> inline void
SPRVMap<SPRVExecutionModelKind, SPRVCapabilityKind>::init() {
  add(ExecutionModelVertex, CapabilityShader);
  add(ExecutionModelTessellationControl, CapabilityTessellation);
  add(ExecutionModelTessellationEvaluation, CapabilityShader);
  add(ExecutionModelGeometry, CapabilityGeometry);
  add(ExecutionModelFragment, CapabilityShader);
  add(ExecutionModelGLCompute, CapabilityShader);
  add(ExecutionModelKernel, CapabilityKernel);
}

inline bool
isValid(SPRVExecutionModelKind E) {
  return (unsigned)E < (unsigned)ExecutionModelCount;
}

template<> inline void
SPRVMap<SPRVExecutionModeKind, SPRVCapabilityKind>::init() {
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
  add(ExecutionModeLocalSize, CapabilityNone);
  add(ExecutionModeLocalSizeHint, CapabilityKernel);
  add(ExecutionModeInputPoints, CapabilityGeometry);
  add(ExecutionModeInputLines, CapabilityGeometry);
  add(ExecutionModeInputLinesAdjacency, CapabilityGeometry);
  add(ExecutionModeInputTriangles, CapabilityTessellation);
  add(ExecutionModeInputTrianglesAdjacency, CapabilityGeometry);
  add(ExecutionModeInputQuads, CapabilityGeometry);
  add(ExecutionModeInputIsolines, CapabilityGeometry);
  add(ExecutionModeOutputVertices, CapabilityTessellation);
  add(ExecutionModeOutputPoints, CapabilityGeometry);
  add(ExecutionModeOutputLineStrip, CapabilityGeometry);
  add(ExecutionModeOutputTriangleStrip, CapabilityGeometry);
  add(ExecutionModeVecTypeHint, CapabilityKernel);
  add(ExecutionModeContractionOff, CapabilityKernel);
}

inline bool
isValid(SPRVExecutionModeKind E) {
  return (unsigned)E < (unsigned)ExecutionModeCount;
}

inline bool
isValid(SPRVLinkageTypeKind L) {
  return (unsigned)L < (unsigned)LinkageTypeCount;
}

template<> inline void
SPRVMap<SPRVStorageClassKind, SPRVCapabilityKind>::init() {
  add(StorageClassUniformConstant, CapabilityNone);
  add(StorageClassInput, CapabilityShader);
  add(StorageClassUniform, CapabilityShader);
  add(StorageClassOutput, CapabilityShader);
  add(StorageClassWorkgroupLocal, CapabilityNone);
  add(StorageClassWorkgroupGlobal, CapabilityNone);
  add(StorageClassPrivateGlobal, CapabilityShader);
  add(StorageClassFunction, CapabilityShader);
  add(StorageClassGeneric, CapabilityKernel);
  add(StorageClassAtomicCounter, CapabilityShader);
}

inline bool
isValid(SPRVStorageClassKind StorageClass) {
  return (unsigned)StorageClass < (unsigned)StorageClassCount;
}

template<> inline void
SPRVMap<Decoration, std::string>::init() {
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
  add(DecorationSmooth, "Smooth");
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
  add(DecorationInputTargetIndex, "InputTargetIndex");
  add(DecorationAlignment, "Alignment");
}
SPRV_DEF_NAMEMAP(Decoration, SPRVDecorateNameMap)

inline bool
isValid(SPRVFuncParamAttrKind FPA) {
  return (unsigned)FPA < (unsigned)FunctionParameterAttributeCount;
}

enum SPRVExtInstSetKind {
  SPRVEIS_OpenCL,
  SPRVEIS_Count,
};

inline bool
isValid(SPRVExtInstSetKind BIS) {
  return (unsigned)BIS < (unsigned)SPRVEIS_Count;
}

template<> inline void
SPRVMap<SPRVExtInstSetKind, std::string>::init() {
  add(SPRVEIS_OpenCL, "OpenCL.std");
}
typedef SPRVMap<SPRVExtInstSetKind, std::string> SPRVBuiltinSetNameMap;

inline bool
isValid(SPRVBuiltinVariableKind Kind) {
  return (unsigned)Kind < (unsigned)BuiltInCount;
}

template<> inline void
SPRVMap<SPRVBuiltinVariableKind, std::string>::init() {
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
  add(BuiltInFragColor, "FragColor");
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
  add(BuiltInWorkgroupLinearId, "WorkgroupLinearId");
  add(BuiltInSubgroupSize, "SubgroupSize");
  add(BuiltInSubgroupMaxSize, "SubgroupMaxSize");
  add(BuiltInNumSubgroups, "NumSubgroups");
  add(BuiltInNumEnqueuedSubgroups, "NumEnqueuedSubgroups");
  add(BuiltInSubgroupId, "SubgroupId");
  add(BuiltInSubgroupLocalInvocationId, "SubgroupLocalInvocationId");
  add(BuiltInCount, "Count");
}
typedef SPRVMap<SPRVBuiltinVariableKind, std::string>
  SPRVBuiltinVariableNameMap;

inline bool isValid(Scope Kind) {
  return (unsigned)Kind <= (unsigned)ScopeInvocation;
}

inline bool isValidSPRVMemSemanticsMask(SPRVWord MemMask) {
  return MemMask < 1 << ((unsigned)MemorySemanticsImageMemoryShift + 1);
}

enum SPRVSamplerAddressingModeKind {
  SPRVSAM_None = 0,
  SPRVSAM_ClampEdge = 2,
  SPRVSAM_Clamp = 4,
  SPRVSAM_Repeat = 6,
  SPRVSAM_RepeatMirrored = 8,
  SPRVSAM_Invalid = 255,
};

enum SPRVSamplerFilterModeKind {
  SPRVSFM_Nearest = 16,
  SPRVSFM_Linear = 32,
  SPRVSFM_Invalid = 255,
};

inline bool isValid(SPRVGroupOperationKind G) {
  return (unsigned)G < (unsigned)GroupOperationCount;
}

inline unsigned getImageDimension(SPRVImageDimKind K) {
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

}


#endif /* SPRVENUM_HPP_ */
