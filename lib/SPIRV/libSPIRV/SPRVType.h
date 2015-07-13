//===- SPRVType.h – Class to represent a SPIR-V Type ------------*- C++ -*-===//
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
/// This file defines the types defined in SPIRV spec with op codes.
///
/// The name of the SPIR-V types follow the op code name in the spec, e.g.
/// SPIR-V type with op code name OpTypeInt is named as SPRVTypeInt. This is
/// for readability and ease of using macro to handle types.
///
//===----------------------------------------------------------------------===//

#ifndef SPRVTYPE_HPP_
#define SPRVTYPE_HPP_

#include "SPRVEntry.h"
#include "SPRVStream.h"

#include <cassert>
#include <tuple>
#include <vector>
#include <map>
#include <iostream>

namespace SPRV{

class SPRVType: public SPRVEntry {
public:
  // Complete constructor
  SPRVType(SPRVModule *M, unsigned TheWordCount, SPRVOpCode TheOpCode,
      SPRVId TheId)
    :SPRVEntry(M, TheWordCount, TheOpCode, TheId){}
  // Incomplete constructor
  SPRVType(SPRVOpCode TheOpCode):SPRVEntry(TheOpCode){}

  SPRVType *getArrayElementType() const;
  uint64_t getArrayLength() const;
  unsigned getBitWidth() const;
  unsigned getFloatBitWidth() const;
  SPRVType *getFunctionReturnType() const;
  unsigned getIntegerBitWidth() const;
  SPRVType *getPointerElementType() const;
  SPRVStorageClassKind getPointerStorageClass() const;
  SPRVType *getStructMemberType(size_t) const;
  SPRVWord getStructMemberCount() const;
  SPRVWord getVectorComponentCount() const;
  SPRVType *getVectorComponentType() const;

  bool isTypeVoid() const;
  bool isTypeArray() const;
  bool isTypeBool() const;
  bool isTypeComposite() const;
  bool isTypeEvent() const;
  bool isTypeDeviceEvent() const;
  bool isTypeFloat() const;
  bool isTypeOCLImage() const;
  bool isTypeOCLSampler() const;
  bool isTypePipe()const;
  bool isTypeInt() const;
  bool isTypeOpaque() const;
  bool isTypePointer() const;
  bool isTypeSampler() const;
  bool isTypeStruct() const;
  bool isTypeVector() const;
  bool isTypeVectorInt() const;
  bool isTypeVectorFloat() const;
  bool isTypeVectorBool() const;
  bool isTypeVectorOrScalarInt() const;
  bool isTypeVectorOrScalarFloat() const;
  bool isTypeVectorOrScalarBool() const;
};

class SPRVTypeVoid:public SPRVType {
public:
  // Complete constructor
  SPRVTypeVoid(SPRVModule *M, SPRVId TheId)
    :SPRVType(M, 2, SPRVOC_OpTypeVoid, TheId){}
  // Incomplete constructor
  SPRVTypeVoid():SPRVType(SPRVOC_OpTypeVoid){}
protected:
  _SPRV_DEF_ENCDEC1(Id)
};

class SPRVTypeBool:public SPRVType {
public:
  // Complete constructor
  SPRVTypeBool(SPRVModule *M, SPRVId TheId)
    :SPRVType(M, 2, SPRVOC_OpTypeBool, TheId){}
  // Incomplete constructor
  SPRVTypeBool():SPRVType(SPRVOC_OpTypeBool){}
protected:
  _SPRV_DEF_ENCDEC1(Id)
};

class SPRVTypeInt:public SPRVType {
public:
  // Complete constructor
  SPRVTypeInt(SPRVModule *M, SPRVId TheId, unsigned TheBitWidth,
      bool ItIsSigned)
    :SPRVType(M, 4, SPRVOC_OpTypeInt, TheId), BitWidth(TheBitWidth),
     IsSigned(ItIsSigned){
     validate();
     }
  // Incomplete constructor
  SPRVTypeInt():SPRVType(SPRVOC_OpTypeInt), BitWidth(0), IsSigned(false){}

  unsigned getBitWidth() const { return BitWidth;}
  bool isSigned() const { return IsSigned;}

protected:
  _SPRV_DEF_ENCDEC3(Id, BitWidth, IsSigned)
  void validate()const {
    SPRVEntry::validate();
    assert(BitWidth > 1 && BitWidth <= 64 && "Invalid bit width");
  }
private:
  unsigned BitWidth;    // Bit width
  bool IsSigned;        // Whether it is signed
};

class SPRVTypeFloat:public SPRVType {
public:
  // Complete constructor
  SPRVTypeFloat(SPRVModule *M, SPRVId TheId, unsigned TheBitWidth)
    :SPRVType(M, 3, SPRVOC_OpTypeFloat, TheId), BitWidth(TheBitWidth){}
  // Incomplete constructor
  SPRVTypeFloat():SPRVType(SPRVOC_OpTypeFloat), BitWidth(0){}

  unsigned getBitWidth() const { return BitWidth;}

protected:
  _SPRV_DEF_ENCDEC2(Id, BitWidth)
  void validate()const {
    SPRVEntry::validate();
    assert(BitWidth >= 16 && BitWidth <= 64 && "Invalid bit width");
  }
private:
  unsigned BitWidth;    // Bit width
};

class SPRVTypePointer:public SPRVType {
public:
  // Complete constructor
  SPRVTypePointer(SPRVModule *M, SPRVId TheId,
      SPRVStorageClassKind TheStorageClass,
      SPRVType *ElementType)
    :SPRVType(M, 4, SPRVOC_OpTypePointer, TheId), StorageClass(TheStorageClass),
     ElemType(ElementType){
    validate();
  }
  // Incomplete constructor
  SPRVTypePointer():SPRVType(SPRVOC_OpTypePointer),
      StorageClass(SPRVSC_Private),
      ElemType(NULL){}

  SPRVType *getElementType() const { return ElemType;}
  SPRVStorageClassKind getStorageClass() const { return StorageClass;}

protected:
  _SPRV_DEF_ENCDEC3(Id, StorageClass, ElemType)
  void validate()const {
    SPRVEntry::validate();
    ElemType->validate();
    assert(isValid(StorageClass));
  }
private:
  SPRVStorageClassKind StorageClass;     // Storage Class
  SPRVType *ElemType;                    // Element Type
};

class SPRVTypeVector:public SPRVType {
public:
  // Complete constructor
  SPRVTypeVector(SPRVModule *M, SPRVId TheId, SPRVType *TheCompType,
      SPRVWord TheCompCount)
    :SPRVType(M, 4, SPRVOC_OpTypeVector, TheId), CompType(TheCompType),
     CompCount(TheCompCount){
    validate();
  }
  // Incomplete constructor
  SPRVTypeVector():SPRVType(SPRVOC_OpTypeVector), CompType(nullptr),
      CompCount(0){}

  SPRVType *getComponentType() const { return CompType;}
  SPRVWord getComponentCount() const { return CompCount;}
  bool isValidIndex(SPRVWord Index) const { return Index < CompCount;}

protected:
  _SPRV_DEF_ENCDEC3(Id, CompType, CompCount)
  void validate()const {
    SPRVEntry::validate();
    CompType->validate();
    assert(CompCount == 2 || CompCount == 3 || CompCount == 4 ||
        CompCount == 8 || CompCount == 16);
  }
private:
  SPRVType *CompType;                // Component Type
  SPRVWord CompCount;                // Component Count
};

class SPRVConstant;
class SPRVTypeArray:public SPRVType {
public:
  // Complete constructor
  SPRVTypeArray(SPRVModule *M, SPRVId TheId, SPRVType *TheElemType,
      SPRVConstant* TheLength);
  // Incomplete constructor
  SPRVTypeArray():SPRVType(SPRVOC_OpTypeArray), ElemType(nullptr),
      Length(SPRVID_INVALID){}

  SPRVType *getElementType() const { return ElemType;}
  SPRVConstant *getLength() const;

protected:
  _SPRV_DCL_ENCDEC
  void validate()const;
private:
  SPRVType *ElemType;                // Element Type
  SPRVId Length;                     // Array Length
};

class SPRVTypeOpaque:public SPRVType {
public:
  // Complete constructor
  SPRVTypeOpaque(SPRVModule *M, SPRVId TheId, const std::string& TheName)
    :SPRVType(M, 2 + getSizeInWords(TheName), SPRVOC_OpTypeOpaque, TheId) {
    Name = TheName;
    validate();
  }
  // Incomplete constructor
  SPRVTypeOpaque():SPRVType(SPRVOC_OpTypeOpaque){}

protected:
  _SPRV_DEF_ENCDEC2(Id, Name)
  void validate()const {
    SPRVEntry::validate();
  }
};

struct SPRVTypeSamplerDescriptor {
  SPRVWord Dimensionality;
  SPRVWord Content;
  SPRVWord Arrayed;
  SPRVWord Compare;
  SPRVWord Multisampled;
  static std::tuple<SPRVWord, SPRVWord, SPRVWord, SPRVWord, SPRVWord>
    getAsTuple (const SPRVTypeSamplerDescriptor &Desc) {
    return std::make_tuple(Desc.Dimensionality, Desc.Content, Desc.Arrayed,
      Desc.Compare, Desc.Multisampled);
  }
  SPRVTypeSamplerDescriptor():Dimensionality(0), Content(0), Arrayed(0),
      Compare(0), Multisampled(0){}
  SPRVTypeSamplerDescriptor(SPRVWord Dim, SPRVWord Cont, SPRVWord Arr,
      SPRVWord Comp,  SPRVWord Mult):Dimensionality(Dim), Content(Cont),
          Arrayed(Arr), Compare(Comp), Multisampled(Mult){}
};

// Comparision function required to use the struct as map key.
inline bool
operator<(const SPRVTypeSamplerDescriptor &A,
    const SPRVTypeSamplerDescriptor &B){
  return SPRVTypeSamplerDescriptor::getAsTuple(A) <
      SPRVTypeSamplerDescriptor::getAsTuple(B);
}

// The type for OpenGL sampler, OpenCL image and sampler.
class SPRVTypeSampler:public SPRVType {
public:
  const static SPRVOpCode OC = SPRVOC_OpTypeSampler;
  const static SPRVWord FixedWC = 8;
  SPRVTypeSampler(SPRVModule *M, SPRVId TheId, SPRVId TheSampledType,
      const SPRVTypeSamplerDescriptor &TheDesc)
    :SPRVType(M, FixedWC, OC, TheId), SampledType(TheSampledType),
     Desc(TheDesc){
    validate();
  }
  SPRVTypeSampler(SPRVModule *M, SPRVId TheId, SPRVId TheSampledType,
      const SPRVTypeSamplerDescriptor &TheDesc, SPRVAccessQualifierKind TheAcc)
    :SPRVType(M, FixedWC + 1, OC, TheId), SampledType(TheSampledType),
     Desc(TheDesc){
    Acc.push_back(TheAcc);
    validate();
  }
  SPRVTypeSampler():SPRVType(OC), SampledType(SPRVID_INVALID),
    Desc(SPRVWORD_MAX, SPRVWORD_MAX, SPRVWORD_MAX, SPRVWORD_MAX, SPRVWORD_MAX){
  }
  const SPRVTypeSamplerDescriptor &getDescriptor()const {
    return Desc;
  }
  bool IsOCLImage()const {
    return SampledType == 0 && Desc.Content == 1;
  }
  bool IsOCLSampler()const {
    return SampledType == 0 && Desc.Content == 2;
  }
  bool hasAccessQualifier() const { return !Acc.empty();}
  SPRVAccessQualifierKind getAccessQualifier() const {
    assert(hasAccessQualifier());
    return Acc[0];
  }
protected:
  _SPRV_DEF_ENCDEC8(Id, SampledType, Desc.Dimensionality, Desc.Content,
      Desc.Arrayed, Desc.Compare, Desc.Multisampled, Acc)
  // The validation assumes OpenCL image or sampler type.
  void validate()const {
    assert(OpCode == OC);
    assert(WordCount == FixedWC + Acc.size());
    assert(SampledType == 0);
    assert(Desc.Dimensionality <= 5);
    assert(Desc.Content <= 2);
    assert(Desc.Arrayed <= 1);
    assert(Desc.Compare <= 1);
    assert(Desc.Multisampled <= 1);
    assert(Acc.size() <= 1);
  }
  void setWordCount(SPRVWord TheWC) {
    WordCount = TheWC;
    Acc.resize(WordCount - FixedWC);
  }
private:
  SPRVId SampledType;
  SPRVTypeSamplerDescriptor Desc;
  std::vector<SPRVAccessQualifierKind> Acc;
};

class SPRVTypeStruct:public SPRVType {
public:
  // Complete constructor
  SPRVTypeStruct(SPRVModule *M, SPRVId TheId,
      const std::vector<SPRVType *> &TheMemberTypes, const std::string &TheName)
    :SPRVType(M, 2 + TheMemberTypes.size(), SPRVOC_OpTypeStruct, TheId),
     MemberTypeVec(TheMemberTypes){
    Name = TheName;
    validate();
  }
  // Incomplete constructor
  SPRVTypeStruct():SPRVType(SPRVOC_OpTypeStruct){}

  SPRVWord getMemberCount() const { return MemberTypeVec.size();}
  SPRVType *getMemberType(size_t I) const { return MemberTypeVec[I];}
  bool isPacked() const;
  void setPacked(bool Packed);

protected:
  _SPRV_DEF_ENCDEC2(Id, MemberTypeVec)
  void setWordCount(SPRVWord WordCount) { MemberTypeVec.resize(WordCount - 2);}
  void validate()const {
    SPRVEntry::validate();
    for (auto T:MemberTypeVec)
      T->validate();
  }
private:
  std::vector<SPRVType *> MemberTypeVec;      // Member Types
};

class SPRVTypeFunction:public SPRVType {
public:
  // Complete constructor
  SPRVTypeFunction(SPRVModule *M, SPRVId TheId, SPRVType *TheReturnType,
      const std::vector<SPRVType *> &TheParameterTypes)
    :SPRVType(M, 3 + TheParameterTypes.size(), SPRVOC_OpTypeFunction, TheId),
     ReturnType(TheReturnType), ParamTypeVec(TheParameterTypes){
     validate();
  }
  // Incomplete constructor
  SPRVTypeFunction():SPRVType(SPRVOC_OpTypeFunction), ReturnType(NULL){}

  SPRVType *getReturnType() const { return ReturnType;}
  SPRVWord getNumParameters() const { return ParamTypeVec.size();}
  SPRVType *getParameterType(unsigned I) const { return ParamTypeVec[I];}

protected:
  _SPRV_DEF_ENCDEC3(Id, ReturnType, ParamTypeVec)
  void setWordCount(SPRVWord WordCount) { ParamTypeVec.resize(WordCount - 3);}
  void validate()const {
    SPRVEntry::validate();
    ReturnType->validate();
    for (auto T:ParamTypeVec)
      T->validate();
  }
private:
  SPRVType *ReturnType;                      // Return Type
  std::vector<SPRVType *> ParamTypeVec;      // Parameter Types
};

class SPRVTypeOpaqueGeneric:public SPRVType {
public:
  // Complete constructor
  SPRVTypeOpaqueGeneric(SPRVOpCode TheOpCode, SPRVModule *M, SPRVId TheId)
    :SPRVType(M, 2, TheOpCode, TheId){
    validate();
  }

  // Incomplete constructor
  SPRVTypeOpaqueGeneric(SPRVOpCode TheOpCode):SPRVType(TheOpCode),
      Op(SPRVID_INVALID) {}

  SPRVValue *getOperand() {
    return getValue(Op);
  }
protected:
  _SPRV_DEF_ENCDEC1(Id)
  void validate()const {
    SPRVEntry::validate();
    }
  SPRVId Op;
};

template<SPRVOpCode TheOpCode>
class SPRVOpaqueGenericType:public SPRVTypeOpaqueGeneric {
public:
  // Complete constructor
  SPRVOpaqueGenericType(SPRVModule *M, SPRVId TheId)
    :SPRVTypeOpaqueGeneric(TheOpCode, M, TheId){}
  // Incomplete constructor
  SPRVOpaqueGenericType():SPRVTypeOpaqueGeneric(TheOpCode){}
};

#define _SPRV_OP(x) typedef SPRVOpaqueGenericType<SPRVOC_OpType##x> SPRVType##x;
_SPRV_OP(Event)
_SPRV_OP(DeviceEvent)
_SPRV_OP(ReserveId)
_SPRV_OP(Queue)
#undef _SPRV_OP

class SPRVTypePipe :public SPRVType {
public:
  // Complete constructor
  SPRVTypePipe(SPRVModule *M, SPRVId TheId, SPRVType *ThePipeType,
      SPRVAccessQualifierKind AccessQual)
    :SPRVType(M, 4, SPRVOC_OpTypePipe, TheId), PipeType(ThePipeType),
     AccessQualifier(AccessQual){
       validate();
     }

  SPRVTypePipe(SPRVModule *M, SPRVId TheId)
    :SPRVType(M, 4, SPRVOC_OpTypePipe, TheId), PipeType(NULL){
  }

  // Incomplete constructor
  SPRVTypePipe() :SPRVType(SPRVOC_OpTypePipe), PipeType(NULL),
    AccessQualifier(SPRVAC_ReadOnly){}

  SPRVType *getPipeType() const { return PipeType; }
  SPRVAccessQualifierKind getAccessQualifier() const {
      return AccessQualifier; 
  }
  void setPipeType(SPRVType *ThePipeType) {
    PipeType = ThePipeType;
    PipeType->validate();
  }
  void setPipeAcessQualifier(SPRVAccessQualifierKind AccessQual) {
    AccessQualifier = AccessQual;
    assert(isValid(AccessQualifier));
  }

protected:
  _SPRV_DEF_ENCDEC3(Id, PipeType, AccessQualifier)
  void validate()const {
    SPRVEntry::validate();
  }
private:
  SPRVType *PipeType;                          // Pipe Type
  SPRVAccessQualifierKind AccessQualifier;     // Access Qualifier
};
}
#endif // SPRVTYPE_HPP_
