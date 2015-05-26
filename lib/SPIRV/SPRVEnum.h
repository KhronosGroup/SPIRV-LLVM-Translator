//===- SPRVEnum.h - SPIRV enums ----------------------------------*- C++ -*-===//
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
// This file defines SPIRV enums.
//
//===----------------------------------------------------------------------===//

#ifndef SPRVENUM_HPP_
#define SPRVENUM_HPP_

#include "SPRVOpCode.h"
#include <cstdint>

namespace SPRV{

typedef uint32_t SPRVWord;
typedef uint32_t SPRVId;
#define SPRVID_MAX       ~0UL
#define SPRVID_INVALID   ~0UL
#define SPRVWORD_MAX     ~0UL

inline bool
isValid(SPRVId Id) { return Id != SPRVID_INVALID;}

inline SPRVWord
mkWord(unsigned WordCount, SPRVOpCode OpCode) {
  return (WordCount << 16) | OpCode;
}

const SPRVWord SPRVMagicNumber = 0x07230203;

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

enum SPRVSourceLanguageKind {
#define _SPRV_OP(x) SPRVSL_##x,
  _SPRV_OP(Unknown)
  _SPRV_OP(ESSL)
  _SPRV_OP(GLSL)
  _SPRV_OP(OpenCL)
  _SPRV_OP(Count)
#undef _SPRV_OP
};

enum SPRVCapabilityKind {
#define _SPRV_OP(x) SPRVCAP_##x,
  _SPRV_OP(Default)
  _SPRV_OP(Matrix)
  _SPRV_OP(Shader)
  _SPRV_OP(Geom)
  _SPRV_OP(Tess)
  _SPRV_OP(Addr)
  _SPRV_OP(Link)
  _SPRV_OP(Kernel)
  _SPRV_OP(Count)
#undef _SPRV_OP
};

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
  _SPRV_OP(UniformConstant, Default)
  _SPRV_OP(Input, Shader)
  _SPRV_OP(Uniform, Shader)
  _SPRV_OP(Output, Shader)
  _SPRV_OP(WorkgroupLocal, Default)
  _SPRV_OP(WorkgroupGlobal, Default)
  _SPRV_OP(PrivateGlobal, Shader)
  _SPRV_OP(Function, Shader)
  _SPRV_OP(Generic, Kernel)
  _SPRV_OP(Private, Kernel)
  _SPRV_OP(AtomicCounter, Shader)
  _SPRV_OP(Count, Count)
#undef _SPRV_OP
};

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

enum SPRVDecorateKind {
#define _SPRV_OP(x) SPRVDEC_##x,
#include "SPRVDecorate.inc"
#undef _SPRV_OP
};

template<> inline void
SPRVMap<SPRVDecorateKind, std::string>::init() {
#define _SPRV_OP(x) add(SPRVDEC_##x, #x);
#include "SPRVDecorate.inc"
#undef _SPRV_OP
}
SPRV_DEF_NAMEMAP(SPRVDecorateKind, SPRVDecorateNameMap)

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
#define _SPRV_OP(x) SPRVBIS_##x,
  _SPRV_OP(OpenCL12)
  _SPRV_OP(OpenCL20)
  _SPRV_OP(OpenCL21)
  _SPRV_OP(Count)
#undef _SPRV_OP
};

inline bool
isValid(SPRVExtInstSetKind BIS) {
  return (unsigned)BIS < (unsigned)SPRVBIS_Count;
}

template<> inline void
SPRVMap<SPRVExtInstSetKind, std::string>::init() {
#define _SPRV_OP(x,y) add(SPRVBIS_##x, #y);
  _SPRV_OP(OpenCL12,OpenCL.std.12)
  _SPRV_OP(OpenCL20,OpenCL.std.20)
  _SPRV_OP(OpenCL21,OpenCL.std.21)
#undef _SPRV_OP
}
typedef SPRVMap<SPRVExtInstSetKind, std::string> SPRVBuiltinSetNameMap;

enum SPRVBuiltinVariableKind {
#define _SPRV_OP(x,y) SPRVBI_##x,
#include "SPRVBuiltinVariables.inc"
#undef _SPRV_OP
};

inline bool
isValid(SPRVBuiltinVariableKind Kind) {
  return (unsigned)Kind < (unsigned)SPRVBI_Count;
}

template<> inline void
SPRVMap<SPRVBuiltinVariableKind, std::string>::init() {
#define _SPRV_OP(x,y) add(SPRVBI_##x, #x);
#include "SPRVBuiltinVariables.inc"
#undef _SPRV_OP
}
typedef SPRVMap<SPRVBuiltinVariableKind, std::string> SPRVBuiltinVariableNameMap;

enum SPRVExecutionScopeKind {
#define _SPRV_OP(x) SPRVES_##x,
_SPRV_OP(CrossDevice)
_SPRV_OP(Device)
_SPRV_OP(Workgroup)
_SPRV_OP(Subgroup)
_SPRV_OP(Count)
#undef _SPRV_OP
};

inline bool isValid(SPRVExecutionScopeKind Kind) {
  return (unsigned)Kind < (unsigned)SPRVES_Count;
}

enum SPRVMemorySemanticsMaskKind {
#define _SPRV_OP(x, y) SPRVMSM_##x = y,
_SPRV_OP(Relaxed, 1)
_SPRV_OP(SequentiallyConsistent, 2)
_SPRV_OP(Acquire, 4)
_SPRV_OP(Release, 8)
_SPRV_OP(UniformMemory, 16)
_SPRV_OP(SubgroupMemory, 32)
_SPRV_OP(WorkgroupLocalMemory, 64)
_SPRV_OP(WorkgroupGlobalMemory, 128)
_SPRV_OP(AtomicCounterMemory, 256)
_SPRV_OP(ImageMemory, 512)
_SPRV_OP(Max, 1023)
#undef _SPRV_OP
};

inline bool isValidSPRVMemSemanticsMask(SPRVWord MemMask) {
  return MemMask <= (unsigned)SPRVMSM_Max;
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
#define _SPRV_OP(x) SPRVMA_##x,
  _SPRV_OP(Volatile)
  _SPRV_OP(Aligned)
  _SPRV_OP(Count)
#undef _SPRV_OP
};
}


#endif /* SPRVENUM_HPP_ */
