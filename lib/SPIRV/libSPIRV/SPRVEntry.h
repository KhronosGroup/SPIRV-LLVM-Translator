//===- SPRVEntry.h - Base Class for SPIR-V Entities -------------*- C++ -*-===//
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
/// This file defines the base class for SPIRV entities.
///
//===----------------------------------------------------------------------===//

#ifndef SPRVENTRY_HPP_
#define SPRVENTRY_HPP_

#include "SPRVEnum.h"
#include "SPRVError.h"
#include <cassert>
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

namespace SPRV{

class SPRVModule;
class SPRVEncoder;
class SPRVDecoder;
class SPRVType;
class SPRVValue;
class SPRVDecorate;
class SPRVForward;
class SPRVMemberDecorate;

// Add declaration of encode/decode functions to a class.
// Used inside class definition.
#define _SPRV_DCL_ENCDEC \
    void encode(std::ostream &O) const; \
    void decode(std::istream &I);

// Add implementation of encode/decode functions to a class.
// Used out side of class definition.
#define _SPRV_IMP_ENCDEC0(Ty) \
    void Ty::encode(std::ostream &O) const {} \
    void Ty::decode(std::istream &I) {}
#define _SPRV_IMP_ENCDEC1(Ty,x) \
    void Ty::encode(std::ostream &O) const { getEncoder(O) << x; } \
    void Ty::decode(std::istream &I) { getDecoder(I) >> x;}
#define _SPRV_IMP_ENCDEC2(Ty,x,y) \
    void Ty::encode(std::ostream &O) const { getEncoder(O) << x << y; } \
    void Ty::decode(std::istream &I) { getDecoder(I) >> x >> y;}
#define _SPRV_IMP_ENCDEC3(Ty,x,y,z) \
    void Ty::encode(std::ostream &O) const { getEncoder(O) << x << y << z; } \
    void Ty::decode(std::istream &I) { getDecoder(I) >> x >> y >> z;}
#define _SPRV_IMP_ENCDEC4(Ty,x,y,z,u) \
    void Ty::encode(std::ostream &O) const { getEncoder(O) << x << y << z << \
      u; } \
    void Ty::decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u;}
#define _SPRV_IMP_ENCDEC5(Ty,x,y,z,u,v) \
    void Ty::encode(std::ostream &O) const { getEncoder(O) << x << y << z << \
      u << v; } \
    void Ty::decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u >> v;}
#define _SPRV_IMP_ENCDEC6(Ty,x,y,z,u,v,w) \
    void Ty::encode(std::ostream &O) const { getEncoder(O) << x << y << z << \
      u << v << w; } \
    void Ty::decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u >> \
      v >> w;}
#define _SPRV_IMP_ENCDEC7(Ty,x,y,z,u,v,w,r) \
    void Ty::encode(std::ostream &O) const { getEncoder(O) << x << y << z << \
      u << v << w << r; } \
    void Ty::decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u >> \
      v >> w >> r;}
#define _SPRV_IMP_ENCDEC8(Ty,x,y,z,u,v,w,r,s) \
    void Ty::encode(std::ostream &O) const { getEncoder(O) << x << y << z << \
      u << v << w << r << s; } \
    void Ty::decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u >> \
      v >> w >> r >> s;}

// Add definition of encode/decode functions to a class.
// Used inside class definition.
#define _SPRV_DEF_ENCDEC0 \
    void encode(std::ostream &O) const {} \
    void decode(std::istream &I) {}
#define _SPRV_DEF_ENCDEC1(x) \
    void encode(std::ostream &O) const { getEncoder(O) << x; } \
    void decode(std::istream &I) { getDecoder(I) >> x;}
#define _SPRV_DEF_ENCDEC2(x,y) \
    void encode(std::ostream &O) const { getEncoder(O) << x << y; } \
    void decode(std::istream &I) { getDecoder(I) >> x >> y;}
#define _SPRV_DEF_ENCDEC3(x,y,z) \
    void encode(std::ostream &O) const { getEncoder(O) << x << y << z; } \
    void decode(std::istream &I) { getDecoder(I) >> x >> y >> z;}
#define _SPRV_DEF_ENCDEC4(x,y,z,u) \
    void encode(std::ostream &O) const { getEncoder(O) << x << y << z << u; } \
    void decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u;}
#define _SPRV_DEF_ENCDEC5(x,y,z,u,v) \
    void encode(std::ostream &O) const { getEncoder(O) << x << y << z << u << \
      v; } \
    void decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u >> v;}
#define _SPRV_DEF_ENCDEC6(x,y,z,u,v,w) \
    void encode(std::ostream &O) const { getEncoder(O) << x << y << z << u << \
      v << w; } \
    void decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u >> v >> w;}
#define _SPRV_DEF_ENCDEC7(x,y,z,u,v,w,r) \
    void encode(std::ostream &O) const { getEncoder(O) << x << y << z << u << \
      v << w << r; } \
    void decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u >> v >> \
      w >> r;}
#define _SPRV_DEF_ENCDEC8(x,y,z,u,v,w,r,s) \
    void encode(std::ostream &O) const { getEncoder(O) << x << y << z << u << \
      v << w << r << s; } \
    void decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u >> v >> \
      w >> r >> s;}

/// All SPIR-V in-memory-representation entities inherits from SPRVEntry.
/// Usually there are two flavors of constructors of SPIRV objects:
///
/// 1. complete constructor: It requires all the parameters needed to create a
///    SPIRV entity with complete information which can be validated. It is
///    usually used by LLVM/SPIR-V translator to create SPIRV object
///    corresponding to LLVM object. Such constructor calls validate() at
///    the end of the construction.
///
/// 2. incomplete constructor: For leaf classes, it has no parameters.
///    It is usually called by SPRVEntry::make(opcode) to create an incomplete
///    object which should not be validated. Then setWordCount(count) is
///    called to fix the size of the object if it is variable, and then the
///    information is filled by the virtual function decode(istream).
///    After that the object can be validated.
///
/// To add a new SPIRV class:
///
/// 1. It is recommended to name the class as SPRVXXX if it has a fixed op code
///    OpXXX. Although it is not mandatory, doing this facilitates adding it to
///    the table of the factory function SPRVEntry::create().
/// 2. Inherit from proper SPIRV class such as SPRVType, SPRVValue,
///    SPRVInstruction, etc.
/// 3. Implement virtual function encode(), decode(), validate().
/// 4. If the object has variable size, implement virtual function
///    setWordCount().
/// 5. If the class has special attributes, e.g. having no id, or having no
///    type as a value, set them in the constructors.
/// 6. Add the class to the Table of SPRVEntry::create().
/// 7. Add the class to SPRVToLLVM and LLVMToSPRV.

class SPRVEntry {
public:
  enum SPRVEntryAttrib {
    SPRVEA_DEFAULT     = 0,
    SPRVEA_NOID        = 1,      // Entry has no valid id
    SPRVEA_NOTYPE      = 2,      // Value has no type
  };

  // Complete constructor for objects with id
  SPRVEntry(SPRVModule *M, unsigned TheWordCount, SPRVOpCode TheOpCode,
      SPRVId TheId)
    :Module(M), OpCode(TheOpCode), Id(TheId), Attrib(SPRVEA_DEFAULT),
     WordCount(TheWordCount){
    validate();
  }

  // Complete constructor for objects without id
  SPRVEntry(SPRVModule *M, unsigned TheWordCount, SPRVOpCode TheOpCode)
    :Module(M), OpCode(TheOpCode), Id(SPRVID_INVALID), Attrib(SPRVEA_NOID),
     WordCount(TheWordCount){
    validate();
  }

  // Incomplete constructor
  SPRVEntry(SPRVOpCode TheOpCode)
    :OpCode(TheOpCode), Id(SPRVID_INVALID), Attrib(SPRVEA_DEFAULT),
     Module(NULL), WordCount(0){}

  SPRVEntry()
    :OpCode(SPRVOC_OpNop), Id(SPRVID_INVALID), Attrib(SPRVEA_DEFAULT),
     Module(NULL), WordCount(0){}


  virtual ~SPRVEntry(){}

  bool exist(SPRVId)const;
  template<class T>
  T* get(SPRVId TheId)const { return Module->get<T>(TheId);}
  SPRVEntry *getOrCreate(SPRVId TheId) const;
  SPRVValue *getValue(SPRVId TheId)const;
  std::vector<SPRVValue *> getValues(const std::vector<SPRVId>&)const;
  std::vector<SPRVId> getIds(const std::vector<SPRVValue *>)const;
  SPRVType *getValueType(SPRVId TheId)const;
  std::vector<SPRVType *> getValueTypes(const std::vector<SPRVId>&)const;

  virtual SPRVDecoder getDecoder(std::istream &);
  virtual SPRVEncoder getEncoder(std::ostream &)const;
  SPRVErrorLog &getErrorLog()const;
  SPRVId getId() const { assert(hasId()); return Id;}
  SPRVLinkageTypeKind getLinkageType() const;
  SPRVOpCode getOpCode() const { return OpCode;}
  SPRVModule *getModule() const { return Module;}
  const std::string& getName() const { return Name;}
  bool hasDecorate(SPRVDecorateKind Kind, size_t Index = 0,
      SPRVWord *Result=0)const;
  std::set<SPRVWord> getDecorate(SPRVDecorateKind Kind, size_t Index = 0)const;
  bool hasId() const { return !(Attrib & SPRVEA_NOID);}
  bool hasLinkageType() const;
  bool isAtomic() const { return isAtomicOpCode(OpCode);}
  bool isBasicBlock() const { return isLabel();}
  bool isBuiltinCall() const { return OpCode == SPRVOC_OpExtInst;}
  bool isDecorate()const { return OpCode == SPRVOC_OpDecorate;}
  bool isMemberDecorate()const { return OpCode == SPRVOC_OpMemberDecorate;}
  bool isForward() const { return OpCode == SPRVOC_OpForward;}
  bool isLabel() const { return OpCode == SPRVOC_OpLabel;}
  bool isUndef() const { return OpCode == SPRVOC_OpUndef;}
  bool isControlBarrier() const { return OpCode == SPRVOC_OpControlBarrier;}
  bool isMemoryBarrier() const { return OpCode == SPRVOC_OpMemoryBarrier;}
  bool isVariable() const { return OpCode == SPRVOC_OpVariable;}

  void addDecorate(const SPRVDecorate *);
  void addDecorate(SPRVDecorateKind Kind);
  void addDecorate(SPRVDecorateKind Kind, SPRVWord Literal);
  void eraseDecorate(SPRVDecorateKind);
  void addMemberDecorate(const SPRVMemberDecorate *);
  void addMemberDecorate(SPRVWord MemberNumber, SPRVDecorateKind Kind);
  void addMemberDecorate(SPRVWord MemberNumber, SPRVDecorateKind Kind,
      SPRVWord Literal);
  void eraseMemberDecorate(SPRVWord MemberNumber, SPRVDecorateKind Kind);
  void setHasNoId() { Attrib |= SPRVEA_NOID;}
  void setId(SPRVId TheId) { Id = TheId;}
  void setLinkageType(SPRVLinkageTypeKind);
  void setModule(SPRVModule *TheModule);
  void setName(const std::string& TheName);
  virtual void setScope(SPRVEntry *Scope){};
  void takeAnnotations(SPRVForward *);
  void takeDecorates(SPRVEntry *);
  void takeMemberDecorates(SPRVEntry *);

  /// After a SPIRV entry is created during reading SPIRV binary by default
  /// constructor, this function is called to allow the SPIRV entry to resize
  /// its variable sized member before decoding the remaining words.
  virtual void setWordCount(SPRVWord TheWordCount);

  /// Create an empty SPIRV object by op code, e.g. OpTypeInt creates
  /// SPRVTypeInt.
  static SPRVEntry *create(SPRVOpCode);

  friend std::ostream &operator<<(std::ostream &O, const SPRVEntry &E);
  friend std::istream &operator>>(std::istream &I, SPRVEntry &E);
  virtual void encodeAll(std::ostream &O) const;
  virtual void encodeName(std::ostream &O) const;
  virtual void encodeChildren(std::ostream &O)const;
  virtual void encodeDecorate(std::ostream &O)const;
  virtual void encodeWordCountOpCode(std::ostream &O)const;
  virtual void encode(std::ostream &O) const;
  virtual void decode(std::istream &I);

  friend class SPRVDecoder;

  /// Checks the integrity of the object.
  virtual void validate()const {
    assert(Module && "Invalid module");
    assert(OpCode != SPRVOC_OpNop && "Invalid op code");
    assert((!hasId() || isValid(Id)) && "Invalid Id");
  }
  void validateFunctionControlMask(SPRVWord FCtlMask)const;
  void validateValues(const std::vector<SPRVId> &)const;
  void validateBuiltin(SPRVWord, SPRVWord)const;

protected:
  /// An entry may have multiple FuncParamAttr decorations.
  typedef std::multimap<SPRVDecorateKind, const SPRVDecorate*> DecorateMapType;
  typedef std::map<std::pair<SPRVWord, SPRVDecorateKind>,
      const SPRVMemberDecorate*> MemberDecorateMapType;

  bool canHaveMemberDecorates() const {
    return OpCode == SPRVOC_OpTypeStruct ||
        OpCode == SPRVOC_OpForward;
  }
  MemberDecorateMapType& getMemberDecorates() {
    assert(canHaveMemberDecorates());
    return MemberDecorates;
  }

  SPRVOpCode OpCode;
  SPRVModule *Module;
  SPRVId Id;
  std::string Name;
  SPRVWord WordCount;
  unsigned Attrib;

  DecorateMapType Decorates;
  MemberDecorateMapType MemberDecorates;
};

class SPRVEntryNoIdGeneric:public SPRVEntry {
public:
  SPRVEntryNoIdGeneric(SPRVModule *M, unsigned TheWordCount, SPRVOpCode OC)
    :SPRVEntry(M, TheWordCount, OC){
    setAttr();
  }
  SPRVEntryNoIdGeneric(SPRVOpCode OC):SPRVEntry(OC){
    setAttr();
  }
protected:
  void setAttr() {
    setHasNoId();
  }
};

template<SPRVOpCode OC>
class SPRVEntryNoId:public SPRVEntryNoIdGeneric {
public:
  SPRVEntryNoId(SPRVModule *M, unsigned TheWordCount)
    :SPRVEntryNoIdGeneric(M, TheWordCount, OC){}
  SPRVEntryNoId():SPRVEntryNoIdGeneric(OC){}
};

template<SPRVOpCode TheOpCode>
class SPRVEntryOpCodeOnly:public SPRVEntryNoId<TheOpCode> {
public:
  SPRVEntryOpCodeOnly(){
    WordCount = 1;
    validate();
  }
protected:
  _SPRV_DEF_ENCDEC0
  void validate()const {
    assert(isValid(OpCode));
  }
};

class SPRVEntryPoint:public SPRVEntryNoId<SPRVOC_OpEntryPoint> {
public:
  SPRVEntryPoint(SPRVModule *TheModule, SPRVExecutionModelKind, SPRVId TheId);
  SPRVEntryPoint():ExecModel(SPRVEMDL_Count),FuncId(SPRVID_INVALID){}
  _SPRV_DCL_ENCDEC
protected:
  SPRVExecutionModelKind ExecModel;
  SPRVId FuncId;
};

class SPRVAnnotationGeneric:public SPRVEntryNoIdGeneric {
public:
  // Complete constructor
  SPRVAnnotationGeneric(const SPRVEntry *TheTarget, unsigned TheWordCount,
      SPRVOpCode OC)
    :SPRVEntryNoIdGeneric(TheTarget->getModule(), TheWordCount, OC),
     Target(TheTarget->getId()){}
  // Incomplete constructor
  SPRVAnnotationGeneric(SPRVOpCode OC):SPRVEntryNoIdGeneric(OC),
      Target(SPRVID_INVALID){}

  SPRVId getTargetId()const { return Target;}
  SPRVForward *getOrCreateTarget()const;
protected:
  SPRVId Target;
};

template<SPRVOpCode OC>
class SPRVAnnotation:public SPRVAnnotationGeneric {
public:
  // Complete constructor
  SPRVAnnotation(const SPRVEntry *TheTarget, unsigned TheWordCount)
    :SPRVAnnotationGeneric(TheTarget, TheWordCount, OC){}
  // Incomplete constructor
  SPRVAnnotation():SPRVAnnotationGeneric(OC){}
};

class SPRVName:public SPRVAnnotation<SPRVOC_OpName> {
public:
  // Complete constructor
  SPRVName(const SPRVEntry *TheTarget, const std::string& TheStr);
  // Incomplete constructor
  SPRVName(){}
protected:
  _SPRV_DCL_ENCDEC
  void validate() const;

  std::string Str;
};

class SPRVMemberName:public SPRVAnnotation<SPRVOC_OpName> {
public:
  static const SPRVWord FixedWC = 3;
  // Complete constructor
  SPRVMemberName(const SPRVEntry *TheTarget, SPRVWord TheMemberNumber,
      const std::string& TheStr)
    :SPRVAnnotation(TheTarget, FixedWC + getSizeInWords(TheStr)),
     MemberNumber(TheMemberNumber), Str(TheStr){
    validate();
  }
  // Incomplete constructor
  SPRVMemberName():MemberNumber(SPRVWORD_MAX){}
protected:
  _SPRV_DCL_ENCDEC
  void validate() const;
  SPRVWord MemberNumber;
  std::string Str;
};

class SPRVLine:public SPRVAnnotation<SPRVOC_OpLine> {
public:
  static const SPRVWord WC = 5;
  // Complete constructor
  SPRVLine(const SPRVEntry *TheTarget, SPRVId TheFileName, SPRVWord TheLine,
      SPRVWord TheColumn)
    :SPRVAnnotation(TheTarget, WC), FileName(TheFileName), Line(TheLine),
     Column(TheColumn){
    validate();
  }
  // Incomplete constructor
  SPRVLine():FileName(SPRVID_INVALID), Line(SPRVWORD_MAX),
      Column(SPRVWORD_MAX){}
protected:
  _SPRV_DCL_ENCDEC
  void validate() const;
  SPRVId FileName;
  SPRVWord Line;
  SPRVWord Column;
};

class SPRVString:public SPRVEntry {
  static const SPRVOpCode OC = SPRVOC_OpString;
  static const SPRVWord FixedWC = 2;
public:
  SPRVString(SPRVModule *M, SPRVId TheId, const std::string &TheStr)
    :SPRVEntry(M, FixedWC + getSizeInWords(TheStr), OC, TheId), Str(TheStr){}
  SPRVString():SPRVEntry(OC){}
  _SPRV_DCL_ENCDEC
protected:
  std::string Str;
};

class SPRVExecutionMode:public SPRVAnnotation<SPRVOC_OpExecutionMode> {
public:
  // Complete constructor for LocalSize, LocalSizeHint
  SPRVExecutionMode(SPRVEntry *TheTarget, SPRVExecutionModeKind TheExecMode,
      SPRVWord x, SPRVWord y, SPRVWord z)
  :SPRVAnnotation(TheTarget, 6), ExecMode(TheExecMode){
    WordLiterals.push_back(x);
    WordLiterals.push_back(y);
    WordLiterals.push_back(z);
  }
  // Complete constructor for VecTypeHint
  SPRVExecutionMode(SPRVEntry *TheTarget, SPRVExecutionModeKind TheExecMode,
      SPRVId VecType, const std::string &VecTypeName)
  :SPRVAnnotation(TheTarget, 4 + getSizeInWords(VecTypeName)),
   ExecMode(TheExecMode), StrLiteral(VecTypeName){
    WordLiterals.push_back(VecType);
  }
  // Complete constructor for ContractionOff
  SPRVExecutionMode(SPRVEntry *TheTarget, SPRVExecutionModeKind TheExecMode)
  :SPRVAnnotation(TheTarget, 3), ExecMode(TheExecMode){}
  // Incomplete constructor
  SPRVExecutionMode():ExecMode(SPRVEM_Count){}
  SPRVExecutionModeKind getExecutionMode()const { return ExecMode;}
  const std::vector<SPRVWord>& getLiterals()const { return WordLiterals;}
  const std::string& getStringLiteral()const { return StrLiteral;}
protected:
  _SPRV_DCL_ENCDEC
  SPRVExecutionModeKind ExecMode;
  std::vector<SPRVWord> WordLiterals;
  std::string StrLiteral;
};


class SPRVComponentExecutionModes {
  typedef std::map<SPRVExecutionModeKind, SPRVExecutionMode*>
    SPRVExecutionModeMap;
public:
  void addExecutionMode(SPRVExecutionMode *ExecMode) {
    ExecModes[ExecMode->getExecutionMode()] = ExecMode;
  }
  SPRVExecutionMode *getExecutionMode(SPRVExecutionModeKind EMK)const {
    auto Loc = ExecModes.find(EMK);
    if (Loc == ExecModes.end())
      return nullptr;
    return Loc->second;
  }
protected:
  SPRVExecutionModeMap ExecModes;
};

class SPRVExtInstImport:public SPRVEntry {
public:
  const static SPRVOpCode OC = SPRVOC_OpExtInstImport;
  // Complete constructor
  SPRVExtInstImport(SPRVModule *TheModule, SPRVId TheId,
      const std::string& TheStr);
  // Incomplete constructor
  SPRVExtInstImport():SPRVEntry(OC){}
protected:
  _SPRV_DCL_ENCDEC
  void validate() const;

  std::string Str;
};

class SPRVMemoryModel:public SPRVEntryNoId<SPRVOC_OpMemoryModel> {
public:
  SPRVMemoryModel(SPRVModule *M):SPRVEntryNoId(M, 3){}
  SPRVMemoryModel(){}
  _SPRV_DCL_ENCDEC
  void validate() const;
};

class SPRVSource:public SPRVEntryNoId<SPRVOC_OpSource> {
public:
  SPRVSource(SPRVModule *M):SPRVEntryNoId(M, 3){}
  SPRVSource(){}
  _SPRV_DCL_ENCDEC
};

class SPRVSourceExtension:public SPRVEntryNoId<SPRVOC_OpSourceExtension> {
public:
  SPRVSourceExtension(SPRVModule *M);
  SPRVSourceExtension(){}
  _SPRV_DCL_ENCDEC
};

class SPRVCompileFlag:public SPRVEntryNoId<SPRVOC_OpCompileFlag> {
public:
  SPRVCompileFlag(SPRVModule *M);
  SPRVCompileFlag(){}
  _SPRV_DCL_ENCDEC
};

class SPRVExtension:public SPRVEntryNoId<SPRVOC_OpExtension> {
public:
  SPRVExtension(SPRVModule *M);
  SPRVExtension(){}
  _SPRV_DCL_ENCDEC
};

template<class T>
T* bcast(SPRVEntry *E) {
  return static_cast<T*>(E);
}

// ToDo: The following typedef's are place holders for SPIRV entity classes
// to be implemented.
// Each time a new class is implemented, comment out the corresponding typedef.
// This is also an indication of how much work is left.
#define _SPRV_OP(x) typedef SPRVEntryOpCodeOnly<SPRVOC_Op##x> SPRV##x;
_SPRV_OP(Nop)
//_SPRV_OP(Source)
//_SPRV_OP(SourceExtension)
//_SPRV_OP(Extension)
//_SPRV_OP(ExtInstImport)
//_SPRV_OP(MemoryModel)
//_SPRV_OP(EntryPoint)
//_SPRV_OP(ExecutionMode)
//_SPRV_OP(TypeVoid)
//_SPRV_OP(TypeBool)
//_SPRV_OP(TypeInt)
//_SPRV_OP(TypeFloat)
//_SPRV_OP(TypeVector)
_SPRV_OP(TypeMatrix)
//_SPRV_OP(TypeSampler)
_SPRV_OP(TypeFilter)
//_SPRV_OP(TypeArray)
_SPRV_OP(TypeRuntimeArray)
//_SPRV_OP(TypeStruct)
//_SPRV_OP(TypeOpaque)
//_SPRV_OP(TypePointer)
//_SPRV_OP(TypeFunction)
//_SPRV_OP(TypeEvent)
//_SPRV_OP(TypeDeviceEvent)
//_SPRV_OP(TypeReserveId)
//_SPRV_OP(TypeQueue)
//_SPRV_OP(TypePipe)
//_SPRV_OP(ConstantTrue)
//_SPRV_OP(ConstantFalse)
//_SPRV_OP(Constant)
//_SPRV_OP(ConstantComposite)
//_SPRV_OP(ConstantSampler)
//_SPRV_OP(ConstantNull)
_SPRV_OP(Dummy)
_SPRV_OP(SpecConstantTrue)
_SPRV_OP(SpecConstantFalse)
_SPRV_OP(SpecConstant)
_SPRV_OP(SpecConstantComposite)
//_SPRV_OP(Variable)
//_SPRV_OP(VariableArray)
//_SPRV_OP(Function)
//_SPRV_OP(FunctionParameter)
//_SPRV_OP(FunctionEnd)
//_SPRV_OP(FunctionCall)
//_SPRV_OP(ExtInst)
//_SPRV_OP(Undef)
//_SPRV_OP(Load)
//_SPRV_OP(Store)
//_SPRV_OP(Phi)
//_SPRV_OP(DecorationGroup)
//_SPRV_OP(Decorate)
//_SPRV_OP(MemberDecorate)
//_SPRV_OP(GroupDecorate)
//_SPRV_OP(GroupMemberDecorate)
//_SPRV_OP(Name)
//_SPRV_OP(MemberName)
//_SPRV_OP(String)
//_SPRV_OP(Line)
//_SPRV_OP(VectorExtractDynamic)
//_SPRV_OP(VectorInsertDynamic)
//_SPRV_OP(VectorShuffle)
_SPRV_OP(CompositeConstruct)
//_SPRV_OP(CompositeExtract)
//_SPRV_OP(CompositeInsert)
//_SPRV_OP(CopyObject)
//_SPRV_OP(CopyMemory)
//_SPRV_OP(CopyMemorySized)
_SPRV_OP(Sampler)
_SPRV_OP(TextureSample)
_SPRV_OP(TextureSampleDref)
_SPRV_OP(TextureSampleLod)
_SPRV_OP(TextureSampleProj)
_SPRV_OP(TextureSampleGrad)
_SPRV_OP(TextureSampleOffset)
_SPRV_OP(TextureSampleProjLod)
_SPRV_OP(TextureSampleProjGrad)
_SPRV_OP(TextureSampleLodOffset)
_SPRV_OP(TextureSampleProjOffset)
_SPRV_OP(TextureSampleGradOffset)
_SPRV_OP(TextureSampleProjLodOffset)
_SPRV_OP(TextureSampleProjGradOffset)
_SPRV_OP(TextureFetchTexel)
_SPRV_OP(TextureFetchTexelOffset)
_SPRV_OP(TextureFetchSample)
_SPRV_OP(TextureFetchBuffer)
_SPRV_OP(TextureGather)
_SPRV_OP(TextureGatherOffset)
_SPRV_OP(TextureGatherOffsets)
_SPRV_OP(TextureQuerySizeLod)
_SPRV_OP(TextureQuerySize)
_SPRV_OP(TextureQueryLod)
_SPRV_OP(TextureQueryLevels)
_SPRV_OP(TextureQuerySamples)
//_SPRV_OP(AccessChain)
//_SPRV_OP(InBoundsAccessChain)
//_SPRV_OP(SNegate)
//_SPRV_OP(FNegate)
//_SPRV_OP(Not)
//_SPRV_OP(Any)
//_SPRV_OP(All)
//_SPRV_OP(ConvertFToU)
//_SPRV_OP(ConvertFToS)
//_SPRV_OP(ConvertSToF)
//_SPRV_OP(ConvertUToF)
//_SPRV_OP(UConvert)
//_SPRV_OP(SConvert)
//_SPRV_OP(FConvert)
//_SPRV_OP(ConvertPtrToU)
//_SPRV_OP(ConvertUToPtr)
//_SPRV_OP(PtrCastToGeneric)
//_SPRV_OP(GenericCastToPtr)
//_SPRV_OP(Bitcast)
_SPRV_OP(Transpose)
//_SPRV_OP(IsNan)
//_SPRV_OP(IsInf)
//_SPRV_OP(IsFinite)
//_SPRV_OP(IsNormal)
//_SPRV_OP(SignBitSet)
//_SPRV_OP(LessOrGreater)
//_SPRV_OP(Ordered)
//_SPRV_OP(Unordered)
_SPRV_OP(ArrayLength)
//_SPRV_OP(IAdd)
//_SPRV_OP(FAdd)
//_SPRV_OP(ISub)
//_SPRV_OP(FSub)
//_SPRV_OP(IMul)
//_SPRV_OP(FMul)
//_SPRV_OP(UDiv)
//_SPRV_OP(SDiv)
//_SPRV_OP(FDiv)
//_SPRV_OP(UMod)
//_SPRV_OP(SRem)
_SPRV_OP(SMod)
//_SPRV_OP(FRem)
_SPRV_OP(FMod)
_SPRV_OP(VectorTimesScalar)
_SPRV_OP(MatrixTimesScalar)
_SPRV_OP(VectorTimesMatrix)
_SPRV_OP(MatrixTimesVector)
_SPRV_OP(MatrixTimesMatrix)
_SPRV_OP(OuterProduct)
//_SPRV_OP(Dot)
//_SPRV_OP(ShiftRightLogical)
//_SPRV_OP(ShiftRightArithmetic)
//_SPRV_OP(ShiftLeftLogical)
//_SPRV_OP(LogicalOr)
//_SPRV_OP(LogicalXor)
//_SPRV_OP(LogicalAnd)
//_SPRV_OP(BitwiseOr)
//_SPRV_OP(BitwiseXor)
//_SPRV_OP(BitwiseAnd)
//_SPRV_OP(Select)
//_SPRV_OP(IEqual)
//_SPRV_OP(FOrdEqual)
//_SPRV_OP(FUnordEqual)
//_SPRV_OP(INotEqual)
//_SPRV_OP(FOrdNotEqual)
//_SPRV_OP(FUnordNotEqual)
//_SPRV_OP(ULessThan)
//_SPRV_OP(SLessThan)
//_SPRV_OP(FOrdLessThan)
//_SPRV_OP(FUnordLessThan)
//_SPRV_OP(UGreaterThan)
//_SPRV_OP(SGreaterThan)
//_SPRV_OP(FOrdGreaterThan)
//_SPRV_OP(FUnordGreaterThan)
//_SPRV_OP(ULessThanEqual)
//_SPRV_OP(SLessThanEqual)
//_SPRV_OP(FOrdLessThanEqual)
//_SPRV_OP(FUnordLessThanEqual)
//_SPRV_OP(UGreaterThanEqual)
//_SPRV_OP(SGreaterThanEqual)
//_SPRV_OP(FOrdGreaterThanEqual)
//_SPRV_OP(FUnordGreaterThanEqual)
_SPRV_OP(DPdx)
_SPRV_OP(DPdy)
_SPRV_OP(Fwidth)
_SPRV_OP(DPdxFine)
_SPRV_OP(DPdyFine)
_SPRV_OP(FwidthFine)
_SPRV_OP(DPdxCoarse)
_SPRV_OP(DPdyCoarse)
_SPRV_OP(FwidthCoarse)
_SPRV_OP(EmitVertex)
_SPRV_OP(EndPrimitive)
_SPRV_OP(EmitStreamVertex)
_SPRV_OP(EndStreamPrimitive)
//_SPRV_OP(ControlBarrier)
//_SPRV_OP(MemoryBarrier)
_SPRV_OP(ImagePointer)
//_SPRV_OP(AtomicInit)
//_SPRV_OP(AtomicLoad)
//_SPRV_OP(AtomicStore)
//_SPRV_OP(AtomicExchange)
//_SPRV_OP(AtomicCompareExchange)
_SPRV_OP(AtomicCompareExchangeWeak)
//_SPRV_OP(AtomicIIncrement)
//_SPRV_OP(AtomicIDecrement)
//_SPRV_OP(AtomicIAdd)
//_SPRV_OP(AtomicISub)
//_SPRV_OP(AtomicIMin)
//_SPRV_OP(AtomicIMax)
//_SPRV_OP(AtomicUMin)
//_SPRV_OP(AtomicUMax)
//_SPRV_OP(AtomicAnd)
//_SPRV_OP(AtomicOr)
//_SPRV_OP(AtomicXor)
_SPRV_OP(LoopMerge)
_SPRV_OP(SelectionMerge)
//_SPRV_OP(Label)
//_SPRV_OP(Branch)
//_SPRV_OP(BranchConditional)
//_SPRV_OP(Switch)
_SPRV_OP(Kill)
//_SPRV_OP(Return)
//_SPRV_OP(ReturnValue)
_SPRV_OP(Unreachable)
_SPRV_OP(LifetimeStart)
_SPRV_OP(LifetimeStop)
//_SPRV_OP(CompileFlag)
//_SPRV_OP(AsyncGroupCopy)
//_SPRV_OP(WaitGroupEvents)
//_SPRV_OP(GroupAll)
//_SPRV_OP(GroupAny)
//_SPRV_OP(GroupBroadcast)
//_SPRV_OP(GroupIAdd)
//_SPRV_OP(GroupFAdd)
//_SPRV_OP(GroupFMin)
//_SPRV_OP(GroupUMin)
//_SPRV_OP(GroupSMin)
//_SPRV_OP(GroupFMax)
//_SPRV_OP(GroupUMax)
//_SPRV_OP(GroupSMax)
_SPRV_OP(GenericCastToPtrExplicit)
_SPRV_OP(GenericPtrMemSemantics)
_SPRV_OP(ReadPipe)
_SPRV_OP(WritePipe)
_SPRV_OP(ReservedReadPipe)
_SPRV_OP(ReservedWritePipe)
_SPRV_OP(ReserveReadPipePackets)
_SPRV_OP(ReserveWritePipePackets)
_SPRV_OP(CommitReadPipe)
_SPRV_OP(CommitWritePipe)
_SPRV_OP(IsValidReserveId)
_SPRV_OP(GetNumPipePackets)
_SPRV_OP(GetMaxPipePackets)
//_SPRV_OP(GroupReserveReadPipePackets)
//_SPRV_OP(GroupReserveWritePipePackets)
//_SPRV_OP(GroupCommitReadPipe)
//_SPRV_OP(GroupCommitWritePipe)
//_SPRV_OP(EnqueueMarker)
//_SPRV_OP(EnqueueKernel)
//_SPRV_OP(GetKernelNDrangeSubGroupCount)
//_SPRV_OP(GetKernelNDrangeMaxSubGroupSize)
//_SPRV_OP(GetKernelWorkGroupSize)
//_SPRV_OP(GetKernelPreferredWorkGroupSizeMultiple)
//_SPRV_OP(RetainEvent)
//_SPRV_OP(ReleaseEvent)
//_SPRV_OP(CreateUserEvent)
//_SPRV_OP(IsValidEvent)
//_SPRV_OP(SetUserEventStatus)
//_SPRV_OP(CaptureEventProfilingInfo)
//_SPRV_OP(GetDefaultQueue)
//_SPRV_OP(BuildNDRange)
//_SPRV_OP(SatConvertSToU),
//_SPRV_OP(SatConvertUToS),
//_SPRV_OP(AtomicIMin)
//_SPRV_OP(AtomicIMax)
_SPRV_OP(SpecConstantOp)
_SPRV_OP(Count)
//_SPRV_OP(Forward)
#undef _SPRV_OP

}
#endif /* SPRVENTRY_HPP_ */
