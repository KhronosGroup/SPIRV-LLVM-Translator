//===- SPRVValue.h – Class to represent a SPIR-V Value ----------*- C++ -*-===//
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
/// This file defines the values defined in SPIR-V spec with op codes.
///
/// The name of the SPIR-V values follow the op code name in the spec.
/// This is for readability and ease of using macro to handle types.
//
//===----------------------------------------------------------------------===//

#ifndef SPRVVALUE_HPP_
#define SPRVVALUE_HPP_

#include "SPRVEntry.h"
#include "SPRVType.h"
#include "SPRVDecorate.h"

#include <iostream>
#include <map>
#include <memory>

namespace SPRV{

class SPRVValue: public SPRVEntry {
public:
  // Complete constructor for value with id and type
  SPRVValue(SPRVModule *M, unsigned TheWordCount, SPRVOpCode TheOpCode,
      SPRVType *TheType, SPRVId TheId)
    :SPRVEntry(M, TheWordCount, TheOpCode, TheId), Type(TheType) {
    validate();
  }
  // Complete constructor for value with type but without id
  SPRVValue(SPRVModule *M, unsigned TheWordCount, SPRVOpCode TheOpCode,
      SPRVType *TheType)
    :SPRVEntry(M, TheWordCount, TheOpCode), Type(TheType) {
    setHasNoId();
    validate();
  }
  // Complete constructor for value with id but without type
  SPRVValue(SPRVModule *M, unsigned TheWordCount, SPRVOpCode TheOpCode,
      SPRVId TheId)
    :SPRVEntry(M, TheWordCount, TheOpCode, TheId), Type(NULL) {
    setHasNoType();
    validate();
  }
  // Complete constructor for value without id and type
  SPRVValue(SPRVModule *M, unsigned TheWordCount, SPRVOpCode TheOpCode)
    :SPRVEntry(M, TheWordCount, TheOpCode), Type(NULL) {
    setHasNoId();
    setHasNoType();
    validate();
  }
  // Incomplete constructor
  SPRVValue(SPRVOpCode TheOpCode):SPRVEntry(TheOpCode), Type(NULL) {}

  bool hasType()const { return !(Attrib & SPRVEA_NOTYPE);}
  SPRVType *getType()const {
    assert(hasType() && "value has no type");
    return Type;
  }
  bool isVolatile()const;
  bool hasAlignment(SPRVWord *Result=0)const;

  void setAlignment(SPRVWord);
  void setVolatile(bool IsVolatile);

  void validate()const {
    SPRVEntry::validate();
    assert((!hasType() || Type) && "Invalid type");
  }

  void setType(SPRVType *Ty) {
    Type = Ty;
  }

  CapVec getRequiredCapability() const {
    CapVec CV;
    if (!hasType())
      return CV;
    if (Type->isTypeFloat(16))
      CV.push_back(SPRVCAP_Float16);
    else if (Type->isTypeFloat(64))
      CV.push_back(SPRVCAP_Float64);
    else if (Type->isTypeInt(16))
      CV.push_back(SPRVCAP_Int16);
    else if (Type->isTypeInt(64))
      CV.push_back(SPRVCAP_Int64);
    return CV;
  }

protected:
  void setHasNoType() { Attrib |= SPRVEA_NOTYPE;}

  SPRVType *Type;                 // Value Type
};

class SPRVConstant: public SPRVValue {
public:
  // Complete constructor for integer constant
  SPRVConstant(SPRVModule *M, SPRVType *TheType, SPRVId TheId,
      uint64_t TheValue)
    :SPRVValue(M, 0, SPRVOC_OpConstant, TheType, TheId){
    Union.UInt64Val = TheValue;
    recalculateWordCount();
    validate();
  }
  // Complete constructor for float constant
  SPRVConstant(SPRVModule *M, SPRVType *TheType, SPRVId TheId, float TheValue)
    :SPRVValue(M, 0, SPRVOC_OpConstant, TheType, TheId){
    Union.FloatVal = TheValue;
    recalculateWordCount();
    validate();
  }
  // Complete constructor for double constant
  SPRVConstant(SPRVModule *M, SPRVType *TheType, SPRVId TheId, double TheValue)
    :SPRVValue(M, 0, SPRVOC_OpConstant, TheType, TheId){
    Union.DoubleVal = TheValue;
    recalculateWordCount();
    validate();
  }
  // Incomplete constructor
  SPRVConstant():SPRVValue(SPRVOC_OpConstant), NumWords(0){}
  uint64_t getZExtIntValue() const { return Union.UInt64Val;}
  float getFloatValue() const { return Union.FloatVal;}
  double getDoubleValue() const { return Union.DoubleVal;}
protected:
  void recalculateWordCount() {
    NumWords = Type->getBitWidth()/32;
    if (NumWords < 1)
      NumWords = 1;
    WordCount = 3 + NumWords;
  }
  void validate() const {
    SPRVValue::validate();
    assert(NumWords >= 1 && NumWords <= 2 && "Invalid constant size");
  }
  void encode(std::ostream &O) const {
    getEncoder(O) << Type << Id;
    for (unsigned i = 0; i < NumWords; ++i)
      getEncoder(O) << Union.Words[i];
  }
  void setWordCount(SPRVWord WordCount) {
    SPRVValue::setWordCount(WordCount);
    NumWords = WordCount - 3;
  }
  void decode(std::istream &I) {
    getDecoder(I) >> Type >> Id;
    for (unsigned i = 0; i < NumWords; ++i)
      getDecoder(I) >> Union.Words[i];
  }

  unsigned NumWords;
  union UnionType{
    uint64_t UInt64Val;
    float FloatVal;
    double DoubleVal;
    SPRVWord Words[2];
    UnionType() {
      UInt64Val = 0;
    }
  } Union;
};

template<SPRVOpCode OC>
class SPRVConstantEmpty: public SPRVValue {
public:
  // Complete constructor
  SPRVConstantEmpty(SPRVModule *M, SPRVType *TheType, SPRVId TheId)
    :SPRVValue(M, 3, OC, TheType, TheId){
    validate();
  }
  // Incomplete constructor
  SPRVConstantEmpty():SPRVValue(OC){}
protected:
  void validate() const {
    SPRVValue::validate();
  }
  _SPRV_DEF_ENCDEC2(Type, Id)
};

template<SPRVOpCode OC>
class SPRVConstantBool: public SPRVConstantEmpty<OC> {
public:
  // Complete constructor
  SPRVConstantBool(SPRVModule *M, SPRVType *TheType, SPRVId TheId)
    :SPRVConstantEmpty<OC>(M, TheType, TheId){}
  // Incomplete constructor
  SPRVConstantBool(){}
protected:
  void validate() const {
    SPRVConstantEmpty<OC>::validate();
    assert(this->Type->isTypeBool() && "Invalid type");
  }
};

typedef SPRVConstantBool<SPRVOC_OpConstantTrue> SPRVConstantTrue;
typedef SPRVConstantBool<SPRVOC_OpConstantFalse> SPRVConstantFalse;

class SPRVConstantNull:
    public SPRVConstantEmpty<SPRVOC_OpConstantNull> {
public:
  // Complete constructor
  SPRVConstantNull(SPRVModule *M, SPRVType *TheType, SPRVId TheId)
    :SPRVConstantEmpty(M, TheType, TheId){
    validate();
  }
  // Incomplete constructor
  SPRVConstantNull(){}
protected:
  void validate() const {
    SPRVConstantEmpty::validate();
    assert((Type->isTypeComposite() ||
            Type->isTypeOpaque() ||
            Type->isTypeEvent() ||
            Type->isTypePointer() ||
            Type->isTypeReserveId() ||
            Type->isTypeDeviceEvent()) &&
            "Invalid type");
  }
};

class SPRVUndef:
    public SPRVConstantEmpty<SPRVOC_OpUndef> {
public:
  // Complete constructor
  SPRVUndef(SPRVModule *M, SPRVType *TheType, SPRVId TheId)
    :SPRVConstantEmpty(M, TheType, TheId){
    validate();
  }
  // Incomplete constructor
  SPRVUndef(){}
protected:
  void validate() const {
    SPRVConstantEmpty::validate();
  }
};

class SPRVConstantComposite: public SPRVValue {
public:
  // Complete constructor for composite constant
  SPRVConstantComposite(SPRVModule *M, SPRVType *TheType, SPRVId TheId,
      const std::vector<SPRVValue *> TheElements)
    :SPRVValue(M, TheElements.size()+3, SPRVOC_OpConstantComposite, TheType,
        TheId){
    Elements = getIds(TheElements);
    validate();
  }
  // Incomplete constructor
  SPRVConstantComposite():SPRVValue(SPRVOC_OpConstantComposite){}
  std::vector<SPRVValue*> getElements()const {
    return getValues(Elements);
  }
protected:
  void validate() const {
    SPRVValue::validate();
    for (auto &I:Elements)
      getValue(I)->validate();
  }
  void setWordCount(SPRVWord WordCount) {
    Elements.resize(WordCount - 3);
  }
  _SPRV_DEF_ENCDEC3(Type, Id, Elements)

  std::vector<SPRVId> Elements;
};

class SPRVConstantSampler: public SPRVValue {
public:
  const static SPRVOpCode OC = SPRVOC_OpConstantSampler;
  const static SPRVWord WC = 6;
  // Complete constructor
  SPRVConstantSampler(SPRVModule *M, SPRVType *TheType, SPRVId TheId,
      SPRVWord TheAddrMode, SPRVWord TheNormalized, SPRVWord TheFilterMode)
    :SPRVValue(M, WC, OC, TheType, TheId), AddrMode(TheAddrMode),
     Normalized(TheNormalized), FilterMode(TheFilterMode){
    validate();
  }
  // Incomplete constructor
  SPRVConstantSampler():SPRVValue(OC), AddrMode(SPRVSAM_Invalid),
      Normalized(SPRVWORD_MAX), FilterMode(SPRVSFM_Invalid){}

  SPRVWord getAddrMode() const {
    return AddrMode;
  }

  SPRVWord getFilterMode() const {
    return FilterMode;
  }

  SPRVWord getNormalized() const {
    return Normalized;
  }
  CapVec getRequiredCapability() const {
    return getVec(SPRVCAP_LiteralSampler);
  }
protected:
  SPRVWord AddrMode;
  SPRVWord Normalized;
  SPRVWord FilterMode;
  void validate() const {
    SPRVValue::validate();
    assert(OpCode == OC);
    assert(WordCount == WC);
    assert(Type->isTypeSampler());
  }
  _SPRV_DEF_ENCDEC5(Type, Id, AddrMode, Normalized, FilterMode)
};

class SPRVForward:public SPRVValue, public SPRVComponentExecutionModes {
public:
  const static SPRVOpCode OC = SPRVOC_OpForward;
  // Complete constructor
  SPRVForward(SPRVModule *TheModule, SPRVId TheId):
    SPRVValue(TheModule, 0, OC, TheId){}
  SPRVForward():SPRVValue(OC) {
    assert(0 && "should never be called");
  }
  _SPRV_DEF_ENCDEC1(Id)
  friend class SPRVFunction;
protected:
  void validate() const {}
};

}


#endif /* SPRVVALUE_HPP_ */
