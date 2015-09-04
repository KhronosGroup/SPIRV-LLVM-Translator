//===- SPRVOpCode.h – Class to represent SPIR-V Operation Codes -*- C++ -*-===//
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
/// This file defines Operation Code class for SPIR-V.
///
//===----------------------------------------------------------------------===//

#ifndef SPRVOPCODE_HPP_
#define SPRVOPCODE_HPP_

#include "SPRVUtil.h"
#include <string>

namespace SPRV{

enum SPRVOpCode {
#define _SPRV_OP(x, y) SPRVOC_Op##x = y,
#include "SPRVOpCodeEnum.h"
#undef _SPRV_OP
};

template<> inline void
SPRVMap<SPRVOpCode, std::string>::init() {
#define _SPRV_OP(x, ...) add(SPRVOC_Op##x, #x);
#include "SPRVOpCodeEnum.h"
#undef _SPRV_OP
}
SPRV_DEF_NAMEMAP(SPRVOpCode, OpCodeNameMap)

inline bool isAtomicOpCode(SPRVOpCode OpCode) {
  assert(SPRVOC_OpAtomicTestSet < SPRVOC_OpAtomicXor);
  return (unsigned)OpCode >= SPRVOC_OpAtomicTestSet &&
      (unsigned)OpCode <= SPRVOC_OpAtomicXor;
}
inline bool isBinaryOpCode(SPRVOpCode OpCode) {
  return ((unsigned)OpCode >= SPRVOC_OpIAdd &&
      (unsigned)OpCode <= SPRVOC_OpFMod) ||
      OpCode == SPRVOC_OpDot;
}

inline bool isShiftOpCode(SPRVOpCode OpCode) {
  return (unsigned)OpCode >= SPRVOC_OpShiftRightLogical &&
      (unsigned)OpCode <= SPRVOC_OpShiftLeftLogical;
}

inline bool isLogicalOpCode(SPRVOpCode OpCode) {
  return (unsigned)OpCode >= SPRVOC_OpLogicalOr &&
      (unsigned)OpCode <= SPRVOC_OpLogicalAnd;
}

inline bool isBitwiseOpCode(SPRVOpCode OpCode) {
  return (unsigned)OpCode >= SPRVOC_OpBitwiseOr &&
      (unsigned)OpCode <= SPRVOC_OpBitwiseAnd;
}

inline bool isBinaryShiftLogicalBitwiseOpCode(SPRVOpCode OpCode) {
  return (((unsigned)OpCode >= SPRVOC_OpShiftRightLogical &&
      (unsigned)OpCode <= SPRVOC_OpBitwiseAnd) ||
      isBinaryOpCode(OpCode));
}

inline bool isCmpOpCode(SPRVOpCode OpCode) {
  return ((unsigned)OpCode >= SPRVOC_OpIEqual &&
      (unsigned)OpCode <= SPRVOC_OpFUnordGreaterThanEqual) ||
      (OpCode >= SPRVOC_OpLessOrGreater && OpCode <= SPRVOC_OpUnordered);
}

inline bool isCvtOpCode(SPRVOpCode OpCode) {
  return ((unsigned)OpCode >= SPRVOC_OpConvertFToU &&
      (unsigned)OpCode <= SPRVOC_OpBitcast) ||
      OpCode == SPRVOC_OpSatConvertSToU ||
      OpCode == SPRVOC_OpSatConvertUToS;
}

inline bool isCvtToUnsignedOpCode(SPRVOpCode OpCode) {
  return OpCode == SPRVOC_OpConvertFToU ||
      OpCode == SPRVOC_OpUConvert ||
      OpCode == SPRVOC_OpSatConvertSToU;
}

inline bool isCvtFromUnsignedOpCode(SPRVOpCode OpCode) {
  return OpCode == SPRVOC_OpConvertUToF ||
      OpCode == SPRVOC_OpUConvert ||
      OpCode == SPRVOC_OpSatConvertUToS;
}

inline bool isOpaqueGenericTypeOpCode(SPRVOpCode OpCode) {
  return (unsigned)OpCode >= SPRVOC_OpTypeEvent &&
      (unsigned)OpCode <= SPRVOC_OpTypeQueue;
}

inline bool isGenericNegateOpCode(SPRVOpCode OpCode) {
  return (unsigned)OpCode == SPRVOC_OpSNegate ||
      (unsigned)OpCode == SPRVOC_OpFNegate ||
      (unsigned)OpCode == SPRVOC_OpNot;
}

inline bool isAccessChainOpCode(SPRVOpCode OpCode) {
  return OpCode == SPRVOC_OpAccessChain ||
      OpCode == SPRVOC_OpInBoundsAccessChain;
}

inline bool isModuleScopeAllowedOpCode(SPRVOpCode OpCode) {
  return OpCode == SPRVOC_OpVariable ||
      isAccessChainOpCode(OpCode) ||
      OpCode == SPRVOC_OpBitcast ||
      OpCode == SPRVOC_OpConvertPtrToU ||
      OpCode == SPRVOC_OpConvertUToPtr;
}

inline bool hasExecScope(SPRVOpCode OpCode) {
  unsigned OC = OpCode;
  return (SPRVOC_OpWaitGroupEvents <= OC &&
            OC <= SPRVOC_OpGroupSMax) ||
      (SPRVOC_OpGroupReserveReadPipePackets <= OC &&
          OC <= SPRVOC_OpGroupCommitWritePipe);
}

inline bool hasGroupOperation(SPRVOpCode OpCode) {
  unsigned OC = OpCode;
  return SPRVOC_OpGroupIAdd <= OC && OC <= SPRVOC_OpGroupSMax;
}

inline bool isTypeOpCode(SPRVOpCode OpCode) {
  unsigned OC = OpCode;
  return SPRVOC_OpTypeVoid <= OC && OC <= SPRVOC_OpTypePipe;
}

inline bool isConstantOpCode(SPRVOpCode OpCode) {
  unsigned OC = OpCode;
  return (SPRVOC_OpConstantTrue <= OC
      && OC <= SPRVOC_OpSpecConstantOp)
      || OC == SPRVOC_OpUndef;
}

}

#endif /* SPRVOPCODE_HPP_ */
