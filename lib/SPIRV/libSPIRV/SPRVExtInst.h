//===- SPRVBuiltin.h - SPIR-V extended instruction --------------*- C++ -*-===//
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
/// This file defines SPIR-V extended instructions.
///
//===----------------------------------------------------------------------===//

#ifndef SPRVBUILTIN_HPP_
#define SPRVBUILTIN_HPP_

#include "SPRVUtil.h"
#include "OpenCL.std.h"

#include <string>
#include <vector>

namespace SPRV{


inline bool
isOpenCLBuiltinSet (SPRVExtInstSetKind Set) {
  return Set == SPRVBIS_OpenCL12 ||
      Set == SPRVBIS_OpenCL20 ||
      Set == SPRVBIS_OpenCL21;
}

enum SPRVBuiltinOCL12Kind {
#define _SPRV_OP(x,y,z) OCL12_##x = z,
#include "SPRVExtInstOCL12.h"
#undef _SPRV_OP
};

template<> inline void
SPRVMap<SPRVBuiltinOCL12Kind, std::string>::init() {
#define _SPRV_OP(x,y,z) add(OCL12_##x, #y);
#include "SPRVExtInstOCL12.h"
#undef _SPRV_OP
}
SPRV_DEF_NAMEMAP(SPRVBuiltinOCL12Kind, OCL12Map)

enum SPRVBuiltinOCL20Kind {
#define _SPRV_OP(x,y,z) OCL20_##x = z,
#include "SPRVExtInstOCL20.h"
#undef _SPRV_OP
};

template<> inline void
SPRVMap<SPRVBuiltinOCL20Kind, std::string>::init() {
#define _SPRV_OP(x,y,z) add(OCL20_##x, #y);
#include "SPRVExtInstOCL20.h"
#undef _SPRV_OP
}
SPRV_DEF_NAMEMAP(SPRVBuiltinOCL20Kind, OCL20Map)

enum SPRVBuiltinOCL21Kind {
#define _SPRV_OP(x,y,z) OCL21_##x = z,
#include "SPRVExtInstOCL21.h"
#undef _SPRV_OP
};

template<> inline void
SPRVMap<SPRVBuiltinOCL21Kind, std::string>::init() {
#define _SPRV_OP(x,y,z) add(OCL21_##x, #y);
#include "SPRVExtInstOCL21.h"
#undef _SPRV_OP
}
SPRV_DEF_NAMEMAP(SPRVBuiltinOCL21Kind, OCL21Map)

inline bool
isReadImage(SPRVWord EntryPoint) {
  return EntryPoint >= OCL20_Read_imagef && EntryPoint <= OCL20_Read_imageui;
}

inline bool
isWriteImage(SPRVWord EntryPoint) {
  return EntryPoint >= OCL20_Write_imagef && EntryPoint <= OCL20_Write_imageui;
}

inline bool
isReadOrWriteImage(SPRVWord EntryPoint) {
  return isReadImage(EntryPoint) || isWriteImage(EntryPoint);
}

}

#endif
