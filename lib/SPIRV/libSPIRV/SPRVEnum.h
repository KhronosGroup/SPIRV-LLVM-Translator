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

// ToDo: change to 100 for release
enum SPRVVersionKind {
  SPRVVER_100 = 99,
};

// ToDo: register the LLVM/SPIRV translator and get an official SPIRV generator
// magic number
enum SPRVGeneratorKind {
  SPRVGEN_AMDOpenSourceLLVMSPRVTranslator = 1,
};

enum SPRVInstructionSchemaKind {
  SPRVISCH_Default,
};

enum SPRVCapabilityKind {
  SPRVCAP_Matrix            = 0,
  SPRVCAP_Shader            = 1,
  SPRVCAP_Geom              = 2,
  SPRVCAP_Tess              = 3,
  SPRVCAP_Addresses         = 4,
  SPRVCAP_Linkage           = 5,
  SPRVCAP_Kernel            = 6,
  SPRVCAP_Vector16          = 7,
  SPRVCAP_Float16Buffer     = 8,
  SPRVCAP_Float16           = 9,
  SPRVCAP_Float64           = 10,
  SPRVCAP_Int64             = 11,
  SPRVCAP_Int64Atomics      = 12,
  SPRVCAP_ImageBasic        = 13,
  SPRVCAP_ImageReadWrite    = 14,
  SPRVCAP_ImageMipmap       = 15,
  SPRVCAP_ImageSRGBWrite    = 16,
  SPRVCAP_Pipe              = 17,
  SPRVCAP_Groups            = 18,
  SPRVCAP_DeviceEnqueue     = 19,
  SPRVCAP_LiteralSampler    = 20,
  SPRVCAP_AtomicStorage     = 21,
  SPRVCAP_Int16             = 22,
  SPRVCAP_Count             = 23,
  SPRVCAP_GeomTess          = 254,
  SPRVCAP_None              = 255,
};

template<typename K>
SPRVCapabilityKind
getCapability(K Key) {
  return SPRVMap<K, SPRVCapabilityKind>::map(Key);
}

enum SPRVExecutionModelKind {
#define _SPRV_OP(x,y) SPRVEMDL_##x,
  _SPRV_OP(Vertex, Shader)
  _SPRV_OP(TessellationControl, Tess)
  _SPRV_OP(TessellationEvalulation, Shader)
  _SPRV_OP(Geometry, Geom)
  _SPRV_OP(Fragment, Shader)
  _SPRV_OP(GLCompute, Shader)
  _SPRV_OP(Kernel, Kernel)
  _SPRV_OP(Count, Count)
#undef _SPRV_OP
};

template<> inline void
SPRVMap<SPRVExecutionModelKind, SPRVCapabilityKind>::init() {
#define _SPRV_OP(x,y) add(SPRVEMDL_##x, SPRVCAP_##y);
  _SPRV_OP(Vertex, Shader)
  _SPRV_OP(TessellationControl, Tess)
  _SPRV_OP(TessellationEvalulation, Shader)
  _SPRV_OP(Geometry, Geom)
  _SPRV_OP(Fragment, Shader)
  _SPRV_OP(GLCompute, Shader)
  _SPRV_OP(Kernel, Kernel)
  _SPRV_OP(Count, Count)
#undef _SPRV_OP
}

inline bool
isValid(SPRVExecutionModelKind E) {
  return (unsigned)E < (unsigned)SPRVEMDL_Count;
}

enum SPRVExecutionModeKind {
#define _SPRV_OP(x,y) SPRVEM_##x,
  _SPRV_OP(Invocations, Geom)
  _SPRV_OP(SpacingEqual, Tess)
  _SPRV_OP(SpacingFractionEven, Tess)
  _SPRV_OP(SpacingFractionOdd, Tess)
  _SPRV_OP(VertexOrderCw, Tess)
  _SPRV_OP(VertexOrderCcw, Tess)
  _SPRV_OP(PixelCenterInteger, Shader)
  _SPRV_OP(OriginUpperLeft, Shader)
  _SPRV_OP(OriginLowerLeft, Shader)
  _SPRV_OP(EarlyFragmentTests, Shader)
  _SPRV_OP(PointMode, Tess)
  _SPRV_OP(Xfb, Shader)
  _SPRV_OP(DepthReplacing, Shader)
  _SPRV_OP(DepthAny, Shader)
  _SPRV_OP(DepthGreater, Shader)
  _SPRV_OP(DepthLess, Shader)
  _SPRV_OP(DepthUnchanged, Shader)
  _SPRV_OP(LocalSize, Default)
  _SPRV_OP(LocalSizeHint, Kernel)
  _SPRV_OP(InputPoints, Geom)
  _SPRV_OP(InputLines, Geom)
  _SPRV_OP(InputLinesAdjacency, Geom)
  _SPRV_OP(InputTriangles, Geom)
  _SPRV_OP(InputTrianglesAdjacency, Geom)
  _SPRV_OP(InputQuads, Geom)
  _SPRV_OP(InputIsolines, Geom)
  _SPRV_OP(OutputVertices, GeomTess)
  _SPRV_OP(OutputPoints, Geom)
  _SPRV_OP(OutputLineStrip, Geom)
  _SPRV_OP(OutputTriangleStrip, Geom)
  _SPRV_OP(VecTypeHint, Kernel)
  _SPRV_OP(ContractionOff, Kernel)
  _SPRV_OP(Count, Count)
#undef _SPRV_OP
};

template<> inline void
SPRVMap<SPRVExecutionModeKind, SPRVCapabilityKind>::init() {
#define _SPRV_OP(x,y) add(SPRVEM_##x, SPRVCAP_##y);
  _SPRV_OP(Invocations, Geom)
  _SPRV_OP(SpacingEqual, Tess)
  _SPRV_OP(SpacingFractionEven, Tess)
  _SPRV_OP(SpacingFractionOdd, Tess)
  _SPRV_OP(VertexOrderCw, Tess)
  _SPRV_OP(VertexOrderCcw, Tess)
  _SPRV_OP(PixelCenterInteger, Shader)
  _SPRV_OP(OriginUpperLeft, Shader)
  _SPRV_OP(OriginLowerLeft, Shader)
  _SPRV_OP(EarlyFragmentTests, Shader)
  _SPRV_OP(PointMode, Tess)
  _SPRV_OP(Xfb, Shader)
  _SPRV_OP(DepthReplacing, Shader)
  _SPRV_OP(DepthAny, Shader)
  _SPRV_OP(DepthGreater, Shader)
  _SPRV_OP(DepthLess, Shader)
  _SPRV_OP(DepthUnchanged, Shader)
  _SPRV_OP(LocalSize, None)
  _SPRV_OP(LocalSizeHint, Kernel)
  _SPRV_OP(InputPoints, Geom)
  _SPRV_OP(InputLines, Geom)
  _SPRV_OP(InputLinesAdjacency, Geom)
  _SPRV_OP(InputTriangles, GeomTess)
  _SPRV_OP(InputTrianglesAdjacency, Geom)
  _SPRV_OP(InputQuads, Geom)
  _SPRV_OP(InputIsolines, Geom)
  _SPRV_OP(OutputVertices, GeomTess)
  _SPRV_OP(OutputPoints, Geom)
  _SPRV_OP(OutputLineStrip, Geom)
  _SPRV_OP(OutputTriangleStrip, Geom)
  _SPRV_OP(VecTypeHint, Kernel)
  _SPRV_OP(ContractionOff, Kernel)
  _SPRV_OP(Count, Count)
#undef _SPRV_OP
}

inline bool
isValid(SPRVExecutionModeKind E) {
  return (unsigned)E < (unsigned)SPRVEM_Count;
}

enum SPRVAccessQualifierKind {
#define _SPRV_OP(x) SPRVAC_##x,
_SPRV_OP(ReadOnly)
_SPRV_OP(WriteOnly)
_SPRV_OP(ReadWrite)
_SPRV_OP(Count)
#undef _SPRV_OP
};

enum SPRVAddressingModelKind {
  SPRVAM_Logical,
  SPRVAM_Physical32,
  SPRVAM_Physical64,
  SPRVAM_Count
};

// SPIRV spec does not define enum for internal linkage.
// Use SPRVLT_Internal only in in-memory representation.
enum SPRVLinkageTypeKind {
  SPRVLT_Export,
  SPRVLT_Import,
  SPRVLT_Count,
  SPRVLT_Internal = SPRVLT_Count,
};

inline bool
isValid(SPRVLinkageTypeKind L) {
  return (unsigned)L < (unsigned)SPRVLT_Count;
}

enum SPRVMemoryModelKind {
  SPRVMM_Simple,
  SPRVMM_GLSL450,
  SPRVMM_OpenCL12,
  SPRVMM_OpenCL20,
  SPRVMM_Count,
};

enum SPRVStorageClassKind {
#define _SPRV_OP(x,y) SPRVSC_##x,
  _SPRV_OP(UniformConstant, None)
  _SPRV_OP(Input, Shader)
  _SPRV_OP(Uniform, Shader)
  _SPRV_OP(Output, Shader)
  _SPRV_OP(WorkgroupLocal, None)
  _SPRV_OP(WorkgroupGlobal, None)
  _SPRV_OP(PrivateGlobal, Shader)
  _SPRV_OP(Function, Shader)
  _SPRV_OP(Generic, Kernel)
  _SPRV_OP(Private, Kernel)
  _SPRV_OP(AtomicCounter, Shader)
  _SPRV_OP(Count, Count)
#undef _SPRV_OP
};

template<> inline void
SPRVMap<SPRVStorageClassKind, SPRVCapabilityKind>::init() {
#define _SPRV_OP(x,y) add(SPRVSC_##x, SPRVCAP_##y);
  _SPRV_OP(UniformConstant, None)
  _SPRV_OP(Input, Shader)
  _SPRV_OP(Uniform, Shader)
  _SPRV_OP(Output, Shader)
  _SPRV_OP(WorkgroupLocal, None)
  _SPRV_OP(WorkgroupGlobal, None)
  _SPRV_OP(PrivateGlobal, Shader)
  _SPRV_OP(Function, Shader)
  _SPRV_OP(Generic, Kernel)
  _SPRV_OP(Private, Kernel)
  _SPRV_OP(AtomicCounter, Shader)
  _SPRV_OP(Count, Count)
#undef _SPRV_OP
}

inline bool
isValid(SPRVStorageClassKind StorageClass) {
  return (unsigned)StorageClass < (unsigned)SPRVSC_Count;
}

enum SPRVFunctionControlMaskKind {
  SPRVFCM_Default                = 0,
  SPRVFCM_Inline                 = 1,
  SPRVFCM_NoInline               = 2,
  SPRVFCM_Pure                   = 4,
  SPRVFCM_Const                  = 8,
  SPRVFCM_Max                    = 15, // maximum possible value
};

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

enum SPRVFPRoundingModeKind {
#define _SPRV_OP(x) SPRVFRM_##x,
_SPRV_OP(RTE)
_SPRV_OP(RTZ)
_SPRV_OP(RTP)
_SPRV_OP(RTN)
_SPRV_OP(Count)
#undef _SPRV_OP
};

enum SPRVFuncParamAttrKind {
#define _SPRV_OP(x) SPRVFPA_##x,
_SPRV_OP(Zext)
_SPRV_OP(Sext)
_SPRV_OP(ByVal)
_SPRV_OP(Sret)
_SPRV_OP(NoAlias)
_SPRV_OP(NoCapture)
_SPRV_OP(SVM)
_SPRV_OP(Pure)
_SPRV_OP(Const)
_SPRV_OP(Count)
#undef _SPRV_OP
};

inline bool
isValid(SPRVFuncParamAttrKind FPA) {
  return (unsigned)FPA < (unsigned)SPRVFPA_Count;
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

enum SPRVBuiltinVariableKind {
#define _SPRV_OP(x,y) SPRVBI_##x,
#include "SPRVBuiltinVariables.h"
#undef _SPRV_OP
};

inline bool
isValid(SPRVBuiltinVariableKind Kind) {
  return (unsigned)Kind < (unsigned)SPRVBI_Count;
}

template<> inline void
SPRVMap<SPRVBuiltinVariableKind, std::string>::init() {
#define _SPRV_OP(x,y) add(SPRVBI_##x, #x);
#include "SPRVBuiltinVariables.h"
#undef _SPRV_OP
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
#define _SPRV_OP(x, y) SPRVSAM_##x = y,
_SPRV_OP(None, 0)
_SPRV_OP(ClampEdge, 2)
_SPRV_OP(Clamp, 4)
_SPRV_OP(Repeat, 6)
_SPRV_OP(RepeatMirrored, 8)
_SPRV_OP(Invalid, 255)
#undef _SPRV_OP
};

enum SPRVSamplerFilterModeKind {
#define _SPRV_OP(x, y) SPRVSFM_##x = y,
_SPRV_OP(Nearest, 16)
_SPRV_OP(Linear, 32)
_SPRV_OP(Invalid, 255)
#undef _SPRV_OP
};

enum SPRVMemoryAccessKind {
#define _SPRV_OP(x, y) SPRVMA_##x = y,
  _SPRV_OP(None, 0x0)
  _SPRV_OP(Volatile, 0x1)
  _SPRV_OP(Aligned, 0x2)
  _SPRV_OP(Count, 0x4)
#undef _SPRV_OP
};

enum SPRVGroupOperationKind {
#define _SPRV_OP(x) SPRVGO_##x,
  _SPRV_OP(Reduce)
  _SPRV_OP(InclusiveScan)
  _SPRV_OP(ExclusiveScan)
  _SPRV_OP(Count)
#undef _SPRV_OP
};

inline bool isValid(SPRVGroupOperationKind G) {
  return (unsigned)G < (unsigned)SPRVGO_Count;
}

enum SPRVImageDimKind {
  SPRVDIM_1D,
  SPRVDIM_2D,
  SPRVDIM_3D,
  SPRVDIM_Cube,
  SPRVDIM_Rect,
  SPRVDIM_Buffer,
  SPRVDIM_InputTarget,
  SPRVDIM_Count,
};

inline unsigned getImageDimension(SPRVImageDimKind K) {
  switch(K){
  case SPRVDIM_1D:      return 1;
  case SPRVDIM_2D:      return 2;
  case SPRVDIM_3D:      return 3;
  case SPRVDIM_Cube:    return 2;
  case SPRVDIM_Rect:    return 2;
  case SPRVDIM_Buffer:  return 1;
  default:              return 0;
  }
}

}


#endif /* SPRVENUM_HPP_ */
