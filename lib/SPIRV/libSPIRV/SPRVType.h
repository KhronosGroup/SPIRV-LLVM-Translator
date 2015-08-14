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
  bool isTypeReserveId() const;
  bool isTypeFloat(unsigned Bits = 0) const;
  bool isTypeImage() const;
  bool isTypeOCLImage() const;
  bool isTypePipe()const;
  bool isTypeInt(unsigned Bits = 0) const;
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
  static const SPRVOpCode OC = SPRVOC_OpTypeInt;
  // Complete constructor
  SPRVTypeInt(SPRVModule *M, SPRVId TheId, unsigned TheBitWidth,
      bool ItIsSigned)
    :SPRVType(M, 4, OC , TheId), BitWidth(TheBitWidth),
     IsSigned(ItIsSigned){
     validate();
     }
  // Incomplete constructor
  SPRVTypeInt():SPRVType(OC), BitWidth(0), IsSigned(false){}

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
  static const SPRVOpCode OC = SPRVOC_OpTypeFloat;
  // Complete constructor
  SPRVTypeFloat(SPRVModule *M, SPRVId TheId, unsigned TheBitWidth)
    :SPRVType(M, 3, OC, TheId), BitWidth(TheBitWidth){}
  // Incomplete constructor
  SPRVTypeFloat():SPRVType(OC), BitWidth(0){}

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
  CapVec getRequiredCapability() const {
    auto Cap = getVec(SPRVCAP_Addresses);
    if (ElemType->isTypeFloat(16))
      Cap.push_back(SPRVCAP_Float16Buffer);
    Cap.push_back(getCapability(StorageClass));
    return Cap;
  }
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
  CapVec getRequiredCapability() const {
    if (CompCount >= 8)
      return getVec(SPRVCAP_Vector16);
    return CapVec();
  }

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

struct SPRVTypeImageDescriptor {
  SPRVWord Dim;
  SPRVWord Depth;
  SPRVWord Arrayed;
  SPRVWord MS;
  SPRVWord Sampled;
  SPRVWord Format;
  static std::tuple<std::tuple<SPRVWord, SPRVWord, SPRVWord, SPRVWord,
    SPRVWord>, SPRVWord>
    getAsTuple (const SPRVTypeImageDescriptor &Desc) {
    return std::make_tuple(std::make_tuple(Desc.Dim, Desc.Depth, Desc.Arrayed,
      Desc.MS, Desc.Sampled), Desc.Format);
  }
  SPRVTypeImageDescriptor():Dim(0), Depth(0), Arrayed(0),
      MS(0), Sampled(0), Format(0){}
  SPRVTypeImageDescriptor(SPRVWord Dim, SPRVWord Cont, SPRVWord Arr,
      SPRVWord Comp,  SPRVWord Mult, SPRVWord F):Dim(Dim), Depth(Cont),
          Arrayed(Arr), MS(Comp), Sampled(Mult), Format(F){}
};

template<> inline void
SPRVMap<std::string, SPRVTypeImageDescriptor>::init() {
#define _SPRV_OP(x,...) {SPRVTypeImageDescriptor S(__VA_ARGS__); \
  add("opencl."#x, S);}
_SPRV_OP(image1d_t,                  0, 0, 0, 0, 0, 0)
_SPRV_OP(image1d_buffer_t,           5, 0, 0, 0, 0, 0)
_SPRV_OP(image1d_array_t,            0, 0, 1, 0, 0, 0)
_SPRV_OP(image2d_t,                  1, 0, 0, 0, 0, 0)
_SPRV_OP(image2d_array_t,            1, 0, 1, 0, 0, 0)
_SPRV_OP(image2d_depth_t,            1, 1, 0, 0, 0, 0)
_SPRV_OP(image2d_array_depth_t,      1, 1, 1, 0, 0, 0)
_SPRV_OP(image2d_msaa_t,             1, 0, 0, 1, 0, 0)
_SPRV_OP(image2d_array_msaa_t,       1, 0, 1, 1, 0, 0)
_SPRV_OP(image2d_msaa_depth_t,       1, 1, 0, 1, 0, 0)
_SPRV_OP(image2d_array_msaa_depth_t, 1, 1, 1, 1, 0, 0)
_SPRV_OP(image3d_t,                  2, 0, 0, 0, 0, 0)
#undef _SPRV_OP
}
typedef SPRVMap<std::string, SPRVTypeImageDescriptor>
  OCLSPRVImageTypeMap;

// Comparision function required to use the struct as map key.
inline bool
operator<(const SPRVTypeImageDescriptor &A,
    const SPRVTypeImageDescriptor &B){
  return SPRVTypeImageDescriptor::getAsTuple(A) <
      SPRVTypeImageDescriptor::getAsTuple(B);
}

class SPRVTypeImage:public SPRVType {
public:
  const static SPRVOpCode OC = SPRVOC_OpTypeImage;
  const static SPRVWord FixedWC = 8;
  SPRVTypeImage(SPRVModule *M, SPRVId TheId, SPRVId TheSampledType,
      const SPRVTypeImageDescriptor &TheDesc)
    :SPRVType(M, FixedWC, OC, TheId), SampledType(TheSampledType),
     Desc(TheDesc){
    validate();
  }
  SPRVTypeImage(SPRVModule *M, SPRVId TheId, SPRVId TheSampledType,
      const SPRVTypeImageDescriptor &TheDesc, SPRVAccessQualifierKind TheAcc)
    :SPRVType(M, FixedWC + 1, OC, TheId), SampledType(TheSampledType),
     Desc(TheDesc){
    Acc.push_back(TheAcc);
    validate();
  }
  SPRVTypeImage():SPRVType(OC), SampledType(SPRVID_INVALID),
    Desc(SPRVWORD_MAX, SPRVWORD_MAX, SPRVWORD_MAX, SPRVWORD_MAX,
        SPRVWORD_MAX, SPRVWORD_MAX){
  }
  const SPRVTypeImageDescriptor &getDescriptor()const {
    return Desc;
  }
  bool isOCLImage()const {
    return get<SPRVType>(SampledType)->isTypeVoid() &&
        Desc.Sampled == 0 &&
        Desc.Format == 0;
  }
  bool hasAccessQualifier() const { return !Acc.empty();}
  SPRVAccessQualifierKind getAccessQualifier() const {
    assert(hasAccessQualifier());
    return Acc[0];
  }
  CapVec getRequiredCapability() const {
    CapVec CV;
    CV.push_back(SPRVCAP_ImageBasic);
    if (Acc.size() > 0 && Acc[0] == SPRVAC_ReadWrite)
      CV.push_back(SPRVCAP_ImageReadWrite);
    if (Desc.MS)
      CV.push_back(SPRVCAP_ImageMipmap);
    return CV;
  }
protected:
  _SPRV_DEF_ENCDEC9(Id, SampledType, Desc.Dim, Desc.Depth,
      Desc.Arrayed, Desc.MS, Desc.Sampled, Desc.Format, Acc)
  // The validation assumes OpenCL image or sampler type.
  void validate()const {
    assert(OpCode == OC);
    assert(WordCount == FixedWC + Acc.size());
    assert(get<SPRVType>(SampledType)->isTypeVoid());
    assert(Desc.Dim <= 5);
    assert(Desc.Depth <= 1);
    assert(Desc.Arrayed <= 1);
    assert(Desc.MS <= 1);
    assert(Desc.Sampled == 0); // For OCL only
    assert(Desc.Format == 0);  // For OCL only
    assert(Acc.size() <= 1);
  }
  void setWordCount(SPRVWord TheWC) {
    WordCount = TheWC;
    Acc.resize(WordCount - FixedWC);
  }
private:
  SPRVId SampledType;
  SPRVTypeImageDescriptor Desc;
  std::vector<SPRVAccessQualifierKind> Acc;
};

class SPRVTypeSampler:public SPRVType {
public:
  const static SPRVOpCode OC = SPRVOC_OpTypeSampler;
  const static SPRVWord FixedWC = 2;
  SPRVTypeSampler(SPRVModule *M, SPRVId TheId)
    :SPRVType(M, FixedWC, OC, TheId){
    validate();
  }
  SPRVTypeSampler():SPRVType(OC){
  }
protected:
  _SPRV_DEF_ENCDEC1(Id)
  void validate()const {
    assert(OpCode == OC);
    assert(WordCount == FixedWC);
  }
};

class SPRVTypeSampledImage:public SPRVType {
public:
  const static SPRVOpCode OC = SPRVOC_OpTypeSampledImage;
  const static SPRVWord FixedWC = 3;
  SPRVTypeSampledImage(SPRVModule *M, SPRVId TheId, SPRVTypeImage *TheImgTy)
    :SPRVType(M, FixedWC, OC, TheId), ImgTy(TheImgTy){
    validate();
  }
  SPRVTypeSampledImage():SPRVType(OC), ImgTy(nullptr){
  }

  const SPRVTypeImage *getImageType() const {
    return ImgTy;
  }

  void setImageType(SPRVTypeImage *TheImgTy) {
    ImgTy = TheImgTy;
  }

protected:
  SPRVTypeImage *ImgTy;
  _SPRV_DEF_ENCDEC2(Id, ImgTy)
  void validate()const {
    assert(OpCode == OC);
    assert(WordCount == FixedWC);
    assert(ImgTy && ImgTy->isTypeImage());
  }
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
  SPRVTypePipe(SPRVModule *M, SPRVId TheId,
      SPRVAccessQualifierKind AccessQual = SPRVAC_ReadOnly)
    :SPRVType(M, 3, SPRVOC_OpTypePipe, TheId),
     AccessQualifier(AccessQual){
       validate();
     }

  // Incomplete constructor
  SPRVTypePipe() :SPRVType(SPRVOC_OpTypePipe),
    AccessQualifier(SPRVAC_ReadOnly){}

  SPRVAccessQualifierKind getAccessQualifier() const {
      return AccessQualifier; 
  }
  void setPipeAcessQualifier(SPRVAccessQualifierKind AccessQual) {
    AccessQualifier = AccessQual;
    assert(isValid(AccessQualifier));
  }
  CapVec getRequiredCapability() const {
    return getVec(SPRVCAP_Pipe);
  }
protected:
  _SPRV_DEF_ENCDEC2(Id, AccessQualifier)
  void validate()const {
    SPRVEntry::validate();
  }
private:
  SPRVAccessQualifierKind AccessQualifier;     // Access Qualifier
};

template<typename T2, typename T1>
bool
isType(const T1 *Ty, unsigned Bits = 0) {
  bool Is = Ty->getOpCode() == T2::OC;
  if (Bits == 0)
    return Is;
  return static_cast<const T2*>(Ty)->getBitWidth() == Bits;
}

}
#endif // SPRVTYPE_HPP_
