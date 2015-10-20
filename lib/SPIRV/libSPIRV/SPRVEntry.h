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
class SPRVLine;
class SPRVString;
class SPRVExtInst;

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
#define _SPRV_IMP_ENCDEC9(Ty,x,y,z,u,v,w,r,s,t) \
    void Ty::encode(std::ostream &O) const { getEncoder(O) << x << y << z << \
      u << v << w << r << s << t; } \
    void Ty::decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u >> \
      v >> w >> r >> s >> t;}

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
#define _SPRV_DEF_ENCDEC9(x,y,z,u,v,w,r,s,t) \
    void encode(std::ostream &O) const { getEncoder(O) << x << y << z << u << \
      v << w << r << s << t; } \
    void decode(std::istream &I) { getDecoder(I) >> x >> y >> z >> u >> v >> \
      w >> r >> s >> t;}

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
  typedef std::vector<SPRVCapabilityKind> CapVec;
  enum SPRVEntryAttrib {
    SPRVEA_DEFAULT     = 0,
    SPRVEA_NOID        = 1,      // Entry has no valid id
    SPRVEA_NOTYPE      = 2,      // Value has no type
  };

  // Complete constructor for objects with id
  SPRVEntry(SPRVModule *M, unsigned TheWordCount, Op TheOpCode,
      SPRVId TheId)
    :Module(M), OpCode(TheOpCode), Id(TheId), Attrib(SPRVEA_DEFAULT),
     WordCount(TheWordCount), Line(nullptr){
    validate();
  }

  // Complete constructor for objects without id
  SPRVEntry(SPRVModule *M, unsigned TheWordCount, Op TheOpCode)
    :Module(M), OpCode(TheOpCode), Id(SPRVID_INVALID), Attrib(SPRVEA_NOID),
     WordCount(TheWordCount), Line(nullptr){
    validate();
  }

  // Incomplete constructor
  SPRVEntry(Op TheOpCode)
    :Module(NULL), OpCode(TheOpCode), Id(SPRVID_INVALID),
     Attrib(SPRVEA_DEFAULT), WordCount(0), Line(nullptr){}

  SPRVEntry()
    :Module(NULL), OpCode(OpNop), Id(SPRVID_INVALID),
     Attrib(SPRVEA_DEFAULT), WordCount(0), Line(nullptr){}


  virtual ~SPRVEntry(){}

  bool exist(SPRVId)const;
  template<class T>
  T* get(SPRVId TheId)const { return static_cast<T*>(getEntry(TheId));}
  SPRVEntry *getEntry(SPRVId) const;
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
  SPRVLine *getLine() const { return Line;}
  SPRVLinkageTypeKind getLinkageType() const;
  Op getOpCode() const { return OpCode;}
  SPRVModule *getModule() const { return Module;}
  virtual CapVec getRequiredCapability() const { return CapVec();}
  const std::string& getName() const { return Name;}
  bool hasDecorate(Decoration Kind, size_t Index = 0,
      SPRVWord *Result=0)const;
  std::set<SPRVWord> getDecorate(Decoration Kind, size_t Index = 0)const;
  bool hasId() const { return !(Attrib & SPRVEA_NOID);}
  bool hasLine() const { return Line != nullptr;}
  bool hasLinkageType() const;
  bool isAtomic() const { return isAtomicOpCode(OpCode);}
  bool isBasicBlock() const { return isLabel();}
  bool isBuiltinCall() const { return OpCode == OpExtInst;}
  bool isDecorate()const { return OpCode == OpDecorate;}
  bool isMemberDecorate()const { return OpCode == OpMemberDecorate;}
  bool isForward() const { return OpCode == OpForward;}
  bool isLabel() const { return OpCode == OpLabel;}
  bool isUndef() const { return OpCode == OpUndef;}
  bool isControlBarrier() const { return OpCode == OpControlBarrier;}
  bool isMemoryBarrier() const { return OpCode == OpMemoryBarrier;}
  bool isVariable() const { return OpCode == OpVariable;}
  virtual bool isInst() const { return false;}
  virtual bool isOperandLiteral(unsigned Index) const {
    assert(0 && "not implemented");
    return false;
  }

  void addDecorate(const SPRVDecorate *);
  void addDecorate(Decoration Kind);
  void addDecorate(Decoration Kind, SPRVWord Literal);
  void eraseDecorate(Decoration);
  void addMemberDecorate(const SPRVMemberDecorate *);
  void addMemberDecorate(SPRVWord MemberNumber, Decoration Kind);
  void addMemberDecorate(SPRVWord MemberNumber, Decoration Kind,
      SPRVWord Literal);
  void eraseMemberDecorate(SPRVWord MemberNumber, Decoration Kind);
  void setHasNoId() { Attrib |= SPRVEA_NOID;}
  void setId(SPRVId TheId) { Id = TheId;}
  void setLine(SPRVLine*);
  void setLinkageType(SPRVLinkageTypeKind);
  void setModule(SPRVModule *TheModule);
  void setName(const std::string& TheName);
  virtual void setScope(SPRVEntry *Scope){};
  void takeAnnotations(SPRVForward *);
  void takeDecorates(SPRVEntry *);
  void takeMemberDecorates(SPRVEntry *);
  void takeLine(SPRVEntry *);

  /// After a SPIRV entry is created during reading SPIRV binary by default
  /// constructor, this function is called to allow the SPIRV entry to resize
  /// its variable sized member before decoding the remaining words.
  virtual void setWordCount(SPRVWord TheWordCount);

  /// Create an empty SPIRV object by op code, e.g. OpTypeInt creates
  /// SPRVTypeInt.
  static SPRVEntry *create(Op);
  static std::unique_ptr<SPRVEntry> create_unique(Op);

  /// Create an empty extended instruction.
  static std::unique_ptr<SPRVExtInst> create_unique(
      SPRVExtInstSetKind Set,
      unsigned ExtOp);

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
    assert(OpCode != OpNop && "Invalid op code");
    assert((!hasId() || isValid(Id)) && "Invalid Id");
  }
  void validateFunctionControlMask(SPRVWord FCtlMask)const;
  void validateValues(const std::vector<SPRVId> &)const;
  void validateBuiltin(SPRVWord, SPRVWord)const;

protected:
  /// An entry may have multiple FuncParamAttr decorations.
  typedef std::multimap<Decoration, const SPRVDecorate*> DecorateMapType;
  typedef std::map<std::pair<SPRVWord, Decoration>,
      const SPRVMemberDecorate*> MemberDecorateMapType;

  bool canHaveMemberDecorates() const {
    return OpCode == OpTypeStruct ||
        OpCode == OpForward;
  }
  MemberDecorateMapType& getMemberDecorates() {
    assert(canHaveMemberDecorates());
    return MemberDecorates;
  }

  SPRVModule *Module;
  Op OpCode;
  SPRVId Id;
  std::string Name;
  unsigned Attrib;
  SPRVWord WordCount;

  DecorateMapType Decorates;
  MemberDecorateMapType MemberDecorates;
  SPRVLine *Line;
};

class SPRVEntryNoIdGeneric:public SPRVEntry {
public:
  SPRVEntryNoIdGeneric(SPRVModule *M, unsigned TheWordCount, Op OC)
    :SPRVEntry(M, TheWordCount, OC){
    setAttr();
  }
  SPRVEntryNoIdGeneric(Op OC):SPRVEntry(OC){
    setAttr();
  }
protected:
  void setAttr() {
    setHasNoId();
  }
};

template<Op OC>
class SPRVEntryNoId:public SPRVEntryNoIdGeneric {
public:
  SPRVEntryNoId(SPRVModule *M, unsigned TheWordCount)
    :SPRVEntryNoIdGeneric(M, TheWordCount, OC){}
  SPRVEntryNoId():SPRVEntryNoIdGeneric(OC){}
};

template<Op TheOpCode>
class SPRVEntryOpCodeOnly:public SPRVEntryNoId<TheOpCode> {
public:
  SPRVEntryOpCodeOnly(){
    SPRVEntry::WordCount = 1;
    validate();
  }
protected:
  _SPRV_DEF_ENCDEC0
  void validate()const {
    assert(isValid(SPRVEntry::OpCode));
  }
};

class SPRVEntryPoint:public SPRVEntryNoId<OpEntryPoint> {
public:
  SPRVEntryPoint(SPRVModule *TheModule, SPRVExecutionModelKind, SPRVId TheId);
  SPRVEntryPoint():ExecModel(ExecutionModelKernel),FuncId(SPRVID_INVALID){}
  _SPRV_DCL_ENCDEC
protected:
  SPRVExecutionModelKind ExecModel;
  SPRVId FuncId;
  CapVec getRequiredCapability() const {
    return getVec(getCapability(ExecModel));
  }
};

class SPRVAnnotationGeneric:public SPRVEntryNoIdGeneric {
public:
  // Complete constructor
  SPRVAnnotationGeneric(const SPRVEntry *TheTarget, unsigned TheWordCount,
      Op OC)
    :SPRVEntryNoIdGeneric(TheTarget->getModule(), TheWordCount, OC),
     Target(TheTarget ? TheTarget->getId() : SPRVID_INVALID){}
  // Incomplete constructor
  SPRVAnnotationGeneric(Op OC):SPRVEntryNoIdGeneric(OC),
      Target(SPRVID_INVALID){}

  SPRVId getTargetId()const { return Target;}
  SPRVForward *getOrCreateTarget()const;
  void setTargetId(SPRVId T) { Target = T;}
protected:
  SPRVId Target;
};

template<Op OC>
class SPRVAnnotation:public SPRVAnnotationGeneric {
public:
  // Complete constructor
  SPRVAnnotation(const SPRVEntry *TheTarget, unsigned TheWordCount)
    :SPRVAnnotationGeneric(TheTarget, TheWordCount, OC){}
  // Incomplete constructor
  SPRVAnnotation():SPRVAnnotationGeneric(OC){}
};

class SPRVName:public SPRVAnnotation<OpName> {
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

class SPRVMemberName:public SPRVAnnotation<OpName> {
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

class SPRVString:public SPRVEntry {
  static const Op OC = OpString;
  static const SPRVWord FixedWC = 2;
public:
  SPRVString(SPRVModule *M, SPRVId TheId, const std::string &TheStr)
    :SPRVEntry(M, FixedWC + getSizeInWords(TheStr), OC, TheId), Str(TheStr){}
  SPRVString():SPRVEntry(OC){}
  _SPRV_DCL_ENCDEC
  const std::string &getStr()const { return Str;}
protected:
  std::string Str;
};

class SPRVLine:public SPRVAnnotation<OpLine> {
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

  SPRVWord getColumn() const {
    return Column;
  }

  void setColumn(SPRVWord column) {
    Column = column;
  }

  SPRVId getFileName() const {
    return FileName;
  }

  const std::string &getFileNameStr() const {
    return get<SPRVString>(FileName)->getStr();
  }

  void setFileName(SPRVId fileName) {
    FileName = fileName;
  }

  SPRVWord getLine() const {
    return Line;
  }

  void setLine(SPRVWord line) {
    Line = line;
  }

protected:
  _SPRV_DCL_ENCDEC
  void validate() const;
  SPRVId FileName;
  SPRVWord Line;
  SPRVWord Column;
};

class SPRVExecutionMode:public SPRVAnnotation<OpExecutionMode> {
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
  SPRVExecutionMode():ExecMode(ExecutionModeCount){}
  SPRVExecutionModeKind getExecutionMode()const { return ExecMode;}
  const std::vector<SPRVWord>& getLiterals()const { return WordLiterals;}
  const std::string& getStringLiteral()const { return StrLiteral;}
  CapVec getRequiredCapability() const {
    return getVec(getCapability(ExecMode));
  }
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
  const static Op OC = OpExtInstImport;
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

class SPRVMemoryModel:public SPRVEntryNoId<OpMemoryModel> {
public:
  SPRVMemoryModel(SPRVModule *M):SPRVEntryNoId(M, 3){}
  SPRVMemoryModel(){}
  _SPRV_DCL_ENCDEC
  void validate() const;
};

class SPRVSource:public SPRVEntryNoId<OpSource> {
public:
  SPRVSource(SPRVModule *M):SPRVEntryNoId(M, 3){}
  SPRVSource(){}
  _SPRV_DCL_ENCDEC
};

class SPRVSourceExtension:public SPRVEntryNoId<OpSourceExtension> {
public:
  SPRVSourceExtension(SPRVModule *M);
  SPRVSourceExtension(){}
  _SPRV_DCL_ENCDEC
};

class SPRVExtension:public SPRVEntryNoId<OpExtension> {
public:
  SPRVExtension(SPRVModule *M);
  SPRVExtension(){}
  _SPRV_DCL_ENCDEC
};

class SPRVCapability:public SPRVEntryNoId<OpCapability> {
public:
  SPRVCapability(SPRVModule *M, SPRVCapabilityKind K);
  SPRVCapability():Kind(CapabilityNone){}
  _SPRV_DCL_ENCDEC
private:
  SPRVCapabilityKind Kind;
};

template<class T>
T* bcast(SPRVEntry *E) {
  return static_cast<T*>(E);
}

// ToDo: The following typedef's are place holders for SPIRV entity classes
// to be implemented.
// Each time a new class is implemented, remove the corresponding typedef.
// This is also an indication of how much work is left.
#define _SPRV_OP(x, ...) typedef SPRVEntryOpCodeOnly<Op##x> SPRV##x;
_SPRV_OP(Nop)
_SPRV_OP(SourceContinued, 2)
_SPRV_OP(TypeMatrix)
_SPRV_OP(TypeRuntimeArray)
_SPRV_OP(TypeForwardPointer, 39)
_SPRV_OP(SpecConstantTrue)
_SPRV_OP(SpecConstantFalse)
_SPRV_OP(SpecConstant)
_SPRV_OP(SpecConstantComposite)
_SPRV_OP(ImageTexelPointer)
_SPRV_OP(CompositeConstruct)
_SPRV_OP(ImageSampleDrefImplicitLod)
_SPRV_OP(ImageSampleDrefExplicitLod)
_SPRV_OP(ImageSampleProjImplicitLod)
_SPRV_OP(ImageSampleProjExplicitLod)
_SPRV_OP(ImageSampleProjDrefImplicitLod)
_SPRV_OP(ImageSampleProjDrefExplicitLod)
_SPRV_OP(ImageFetch)
_SPRV_OP(ImageGather)
_SPRV_OP(ImageDrefGather)
_SPRV_OP(QuantizeToF16)
_SPRV_OP(Transpose)
_SPRV_OP(ArrayLength)
_SPRV_OP(SMod)
_SPRV_OP(FMod)
_SPRV_OP(VectorTimesScalar)
_SPRV_OP(MatrixTimesScalar)
_SPRV_OP(VectorTimesMatrix)
_SPRV_OP(MatrixTimesVector)
_SPRV_OP(MatrixTimesMatrix)
_SPRV_OP(OuterProduct)
_SPRV_OP(IAddCarry)
_SPRV_OP(ISubBorrow)
_SPRV_OP(SMulExtended)
_SPRV_OP(UMulExtended)
_SPRV_OP(BitFieldInsert)
_SPRV_OP(BitFieldSExtract)
_SPRV_OP(BitFieldUExtract)
_SPRV_OP(BitReverse)
_SPRV_OP(BitCount)
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
_SPRV_OP(LoopMerge)
_SPRV_OP(SelectionMerge)
_SPRV_OP(Kill)
_SPRV_OP(Unreachable)
_SPRV_OP(LifetimeStart)
_SPRV_OP(LifetimeStop)
_SPRV_OP(GenericCastToPtrExplicit)
_SPRV_OP(ImageSparseSampleImplicitLod, 305)
_SPRV_OP(ImageSparseSampleExplicitLod, 306)
_SPRV_OP(ImageSparseSampleDrefImplicitLod, 307)
_SPRV_OP(ImageSparseSampleDrefExplicitLod, 308)
_SPRV_OP(ImageSparseSampleProjImplicitLod, 309)
_SPRV_OP(ImageSparseSampleProjExplicitLod, 310)
_SPRV_OP(ImageSparseSampleProjDrefImplicitLod, 311)
_SPRV_OP(ImageSparseSampleProjDrefExplicitLod, 312)
_SPRV_OP(ImageSparseFetch, 313)
_SPRV_OP(ImageSparseGather, 314)
_SPRV_OP(ImageSparseDrefGather, 315)
_SPRV_OP(ImageSparseTexelsResident, 316)
_SPRV_OP(NoLine, 317)
#undef _SPRV_OP

}
#endif /* SPRVENTRY_HPP_ */
