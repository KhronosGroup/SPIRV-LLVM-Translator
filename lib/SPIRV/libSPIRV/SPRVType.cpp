//===- SPRVtype.cpp – Class to represent a SPIR-V type ----------*- C++ -*-===//
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
/// This file implements the types defined in SPIRV spec with op codes.
///
//===----------------------------------------------------------------------===//

#include "SPRVType.h"
#include "SPRVModule.h"
#include "SPRVDecorate.h"
#include "SPRVValue.h"

#include <cassert>

namespace SPRV{

SPRVType*
SPRVType::getArrayElementType() const {
  assert(OpCode == SPRVOC_OpTypeArray && "Not array type");
  return static_cast<const SPRVTypeArray *const>(this)->getElementType();
}

uint64_t
SPRVType::getArrayLength() const {
  assert(OpCode == SPRVOC_OpTypeArray && "Not array type");
  return static_cast<const SPRVTypeArray *const>(this)->getLength()->
      getZExtIntValue();
}

SPRVWord
SPRVType::getBitWidth() const {
  if (isTypeVector())
    return getVectorComponentType()->getBitWidth();
  if (isTypeBool())
    return 1;
  return isTypeInt()? getIntegerBitWidth() : getFloatBitWidth();
}

SPRVWord
SPRVType::getFloatBitWidth()const {
  assert(OpCode == SPRVOC_OpTypeFloat && "Not an integer type");
  return static_cast<const SPRVTypeFloat *const>(this)->getBitWidth();
}

SPRVWord
SPRVType::getIntegerBitWidth()const {
  assert((OpCode == SPRVOC_OpTypeInt || OpCode == SPRVOC_OpTypeBool) &&
      "Not an integer type");
  if (isTypeBool())
    return 1;
  return static_cast<const SPRVTypeInt *const>(this)->getBitWidth();
}

SPRVType *
SPRVType::getFunctionReturnType() const {
  assert(OpCode == SPRVOC_OpTypeFunction);
  return static_cast<const SPRVTypeFunction *const>(this)->getReturnType();
}

SPRVType *
SPRVType::getPointerElementType()const {
  assert(OpCode == SPRVOC_OpTypePointer && "Not a pointer type");
  return static_cast<const SPRVTypePointer *const>(this)->getElementType();
}

SPRVStorageClassKind
SPRVType::getPointerStorageClass() const {
  assert(OpCode == SPRVOC_OpTypePointer && "Not a pointer type");
  return static_cast<const SPRVTypePointer *const>(this)->getStorageClass();
}

SPRVType*
SPRVType::getStructMemberType(size_t Index) const {
  assert(OpCode == SPRVOC_OpTypeStruct && "Not struct type");
  return static_cast<const SPRVTypeStruct *const>(this)->getMemberType(Index);
}

SPRVWord
SPRVType::getStructMemberCount() const {
  assert(OpCode == SPRVOC_OpTypeStruct && "Not struct type");
  return static_cast<const SPRVTypeStruct *const>(this)->getMemberCount();
}

SPRVWord
SPRVType::getVectorComponentCount() const {
  assert(OpCode == SPRVOC_OpTypeVector && "Not vector type");
  return static_cast<const SPRVTypeVector *const>(this)->getComponentCount();
}

SPRVType*
SPRVType::getVectorComponentType() const {
  assert(OpCode == SPRVOC_OpTypeVector && "Not vector type");
  return static_cast<const SPRVTypeVector *const>(this)->getComponentType();
}

bool
SPRVType::isTypeVoid() const {
  return OpCode == SPRVOC_OpTypeVoid;
}
bool
SPRVType::isTypeArray() const {
  return OpCode == SPRVOC_OpTypeArray;
}

bool
SPRVType::isTypeBool()const {
  return OpCode == SPRVOC_OpTypeBool;
}

bool
SPRVType::isTypeComposite() const {
  return isTypeVector() || isTypeArray() || isTypeStruct();
}

bool
SPRVType::isTypeFloat()const {
  return OpCode == SPRVOC_OpTypeFloat;
}

bool
SPRVType::isTypeOCLImage()const {
  return isTypeSampler() && static_cast<const SPRVTypeSampler *>(this)->
    IsOCLImage();
}

bool
SPRVType::isTypeOCLSampler()const {
  return isTypeSampler() && static_cast<const SPRVTypeSampler *>(this)->
    IsOCLSampler();
}

bool
SPRVType::isTypePipe()const {
  return OpCode == SPRVOC_OpTypePipe;
}

bool
SPRVType::isTypeReserveId() const {
  return OpCode == SPRVOC_OpTypeReserveId;
}

bool
SPRVType::isTypeInt()const {
  return OpCode == SPRVOC_OpTypeInt;
}

bool
SPRVType::isTypePointer()const {
  return OpCode == SPRVOC_OpTypePointer;
}

bool
SPRVType::isTypeOpaque()const {
  return OpCode == SPRVOC_OpTypeOpaque;
}

bool
SPRVType::isTypeEvent()const {
  return OpCode == SPRVOC_OpTypeEvent;
}

bool
SPRVType::isTypeDeviceEvent()const {
  return OpCode == SPRVOC_OpTypeDeviceEvent;
}

bool
SPRVType::isTypeSampler()const {
  return OpCode == SPRVOC_OpTypeSampler;
}

bool
SPRVType::isTypeStruct() const {
  return OpCode == SPRVOC_OpTypeStruct;
}

bool
SPRVType::isTypeVector() const {
  return OpCode == SPRVOC_OpTypeVector;
}

bool
SPRVType::isTypeVectorBool() const {
  return isTypeVector() && getVectorComponentType()->isTypeBool();
}

bool
SPRVType::isTypeVectorInt() const {
  return isTypeVector() && getVectorComponentType()->isTypeInt();
}

bool
SPRVType::isTypeVectorFloat() const {
  return isTypeVector() && getVectorComponentType()->isTypeFloat();
}

bool
SPRVType::isTypeVectorOrScalarBool() const {
  return isTypeBool() || isTypeVectorBool();
}

bool
SPRVType::isTypeVectorOrScalarInt() const {
  return isTypeInt() || isTypeVectorInt();
}

bool
SPRVType::isTypeVectorOrScalarFloat() const {
  return isTypeFloat() || isTypeVectorFloat();
}

bool
SPRVTypeStruct::isPacked() const {
  return hasDecorate(SPRVDEC_CPacked);
}

void
SPRVTypeStruct::setPacked(bool Packed) {
  if (Packed)
    addDecorate(new SPRVDecorate(SPRVDEC_CPacked, this));
  else
    eraseDecorate(SPRVDEC_CPacked);
}

SPRVTypeArray::SPRVTypeArray(SPRVModule *M, SPRVId TheId, SPRVType *TheElemType,
        SPRVConstant* TheLength)
      :SPRVType(M, 4, SPRVOC_OpTypeArray, TheId), ElemType(TheElemType),
       Length(TheLength->getId()){
      validate();
    }

void
SPRVTypeArray::validate()const {
  SPRVEntry::validate();
  ElemType->validate();
  assert(getValue(Length)->getType()->isTypeInt() &&
      get<SPRVConstant>(Length)->getZExtIntValue() > 0);
}

SPRVConstant*
SPRVTypeArray::getLength() const {
  return get<SPRVConstant>(Length);
}

_SPRV_IMP_ENCDEC3(SPRVTypeArray, Id, ElemType, Length)

}

