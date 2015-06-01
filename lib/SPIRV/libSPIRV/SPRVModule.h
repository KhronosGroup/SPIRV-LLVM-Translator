//===- SPRVModule.h – Class to represent a SPIR-V module --------*- C++ -*-===//
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
/// This file defines Module class for SPIR-V.
///
//===----------------------------------------------------------------------===//

#ifndef SPRVMODULE_HPP_
#define SPRVMODULE_HPP_

#include "SPRVEntry.h"

#include <iostream>
#include <vector>
#include <string>

namespace SPRV{

class SPRVBasicBlock;
class SPRVConstant;
class SPRVEntry;
class SPRVFunction;
class SPRVInstruction;
class SPRVType;
class SPRVTypeArray;
class SPRVTypeBool;
class SPRVTypeFloat;
class SPRVTypeFunction;
class SPRVTypeInt;
class SPRVTypeOpaque;
class SPRVTypePointer;
class SPRVTypeSampler;
class SPRVTypeStruct;
class SPRVTypeVector;
class SPRVTypeVoid;
class SPRVTypePipe;
class SPRVValue;
class SPRVVariable;
class SPRVDecorateGeneric;
class SPRVDecorationGroup;
class SPRVGroupDecorate;
class SPRVGroupMemberDecorate;
class SPRVGroupDecorateGeneric;

typedef SPRVBasicBlock SPRVLabel;
struct SPRVTypeSamplerDescriptor;

class SPRVModule {
public:
  static SPRVModule* createSPRVModule();
  SPRVModule();
  virtual ~SPRVModule();

  // Object query functions
  virtual bool exist(SPRVId) const = 0;
  virtual bool exist(SPRVId, SPRVEntry **)const = 0;
  template<class T> T* get(SPRVId Id) const {
    return static_cast<T*>(getEntry(Id));}
  virtual SPRVEntry *getEntry(SPRVId) const = 0;

  // Error handling functions
  virtual SPRVErrorLog &getErrorLog() = 0;
  virtual SPRVErrorCode getError(std::string&) = 0;

  // Module query functions
  virtual SPRVAddressingModelKind getAddressingModel() = 0;
  virtual SPRVExtInstSetKind getBuiltinSet(SPRVId) const = 0;
  virtual std::string &getCompileFlag() = 0;
  virtual const std::string &getCompileFlag() const = 0;
  virtual const std::string &getExtension() const = 0;
  virtual SPRVFunction *getFunction(unsigned) const = 0;
  virtual SPRVVariable *getVariable(unsigned) const = 0;
  virtual SPRVMemoryModelKind getMemoryModel() = 0;
  virtual unsigned getNumFunctions() const = 0;
  virtual unsigned getNumVariables() const = 0;
  virtual SPRVSourceLanguageKind getSourceLanguage(SPRVWord *) const = 0;
  virtual const std::string &getSourceExtension() const = 0;
  virtual SPRVValue *getValue(SPRVId TheId)const = 0;
  virtual std::vector<SPRVValue *> getValues(const std::vector<SPRVId>&)const
      = 0;
  virtual std::vector<SPRVId> getIds(const std::vector<SPRVEntry *>)const = 0;
  virtual SPRVType *getValueType(SPRVId TheId)const = 0;
  virtual std::vector<SPRVType *> getValueTypes(const std::vector<SPRVId>&)
      const = 0;
  virtual bool isEntryPoint(SPRVExecutionModelKind, SPRVId) const = 0;

  // Module changing functions
  virtual bool importBuiltinSet(const std::string &, SPRVId *) = 0;
  virtual bool importBuiltinSetWithId(const std::string &, SPRVId) = 0;
  virtual void setAddressingModel(SPRVAddressingModelKind) = 0;
  virtual void setAlignment(SPRVValue *, SPRVWord) = 0;
  virtual void setExtension(const std::string &) = 0;
  virtual void setMemoryModel(SPRVMemoryModelKind) = 0;
  virtual void setName(SPRVEntry *, const std::string&) = 0;
  virtual void setSourceLanguage(SPRVSourceLanguageKind, SPRVWord) = 0;
  virtual void setSourceExtension(const std::string &) = 0;
  virtual void optimizeDecorates() = 0;

  // Object creation functions
  template<class T> T *add(T *Entry) { addEntry(Entry); return Entry;}
  virtual SPRVEntry *addEntry(SPRVEntry *) = 0;
  virtual SPRVBasicBlock *addBasicBlock(SPRVFunction *,
      SPRVId Id = SPRVID_INVALID) = 0;
  virtual SPRVString *addString(const std::string &Str) = 0;
  virtual SPRVMemberName *addMemberName(SPRVTypeStruct *ST,
      SPRVWord MemberNumber, const std::string &Name) = 0;
  virtual SPRVLine *addLineNo(SPRVEntry *E, SPRVString *FileName, SPRVWord Line,
      SPRVWord Column) = 0;
  virtual const SPRVDecorateGeneric *addDecorate(const SPRVDecorateGeneric*)
    = 0;
  virtual SPRVDecorationGroup *addDecorationGroup() = 0;
  virtual SPRVDecorationGroup *addDecorationGroup(SPRVDecorationGroup *Group)
    = 0;
  virtual SPRVGroupDecorate *addGroupDecorate(SPRVDecorationGroup *Group,
      const std::vector<SPRVEntry *> &Targets) = 0;
  virtual SPRVGroupMemberDecorate *addGroupMemberDecorate(
      SPRVDecorationGroup *Group, const std::vector<SPRVEntry *> &Targets) = 0;
  virtual SPRVGroupDecorateGeneric *addGroupDecorateGeneric(
      SPRVGroupDecorateGeneric *GDec) = 0;
  virtual void addEntryPoint(SPRVExecutionModelKind, SPRVId) = 0;
  virtual SPRVForward *addForward() = 0;
  virtual SPRVForward *addForward(SPRVId) = 0;
  virtual SPRVFunction *addFunction(SPRVFunction *) = 0;
  virtual SPRVFunction *addFunction(SPRVTypeFunction *,
      SPRVId Id = SPRVID_INVALID) = 0;
  virtual SPRVEntry *replaceForward(SPRVForward *, SPRVEntry *) = 0;

  // Type creation functions
  virtual SPRVTypeArray *addArrayType(SPRVType *, SPRVConstant *) = 0;
  virtual SPRVTypeBool *addBoolType() = 0;
  virtual SPRVTypeFloat *addFloatType(unsigned) = 0;
  virtual SPRVTypeFunction *addFunctionType(SPRVType *,
      const std::vector<SPRVType *> &) = 0;
  virtual SPRVTypeSampler *addSamplerType(SPRVType *,
      const SPRVTypeSamplerDescriptor &) = 0;
  virtual SPRVTypeSampler *addSamplerType(SPRVType *,
      const SPRVTypeSamplerDescriptor &, SPRVAccessQualifierKind) = 0;
  virtual SPRVTypeInt *addIntegerType(unsigned) = 0;
  virtual SPRVTypeOpaque *addOpaqueType(const std::string &) = 0;
  virtual SPRVTypePointer *addPointerType(SPRVStorageClassKind, SPRVType *) = 0;
  virtual SPRVTypeStruct *addStructType(const std::vector<SPRVType *> &,
      const std::string &, bool) = 0;
  virtual SPRVTypeVector *addVectorType(SPRVType *, SPRVWord) = 0;
  virtual SPRVTypeVoid *addVoidType() = 0;
  virtual SPRVType *addOpaqueGenericType(SPRVOpCode) = 0;
  virtual SPRVTypePipe *addPipeType() = 0;

  // Constants creation functions
  virtual SPRVValue *addCompositeConstant(SPRVType *,
      const std::vector<SPRVValue*>&) = 0;
  virtual SPRVValue *addConstant(SPRVValue *) = 0;
  virtual SPRVValue *addConstant(SPRVType *, uint64_t) = 0;
  virtual SPRVValue *addDoubleConstant(SPRVTypeFloat *, double) = 0;
  virtual SPRVValue *addFloatConstant(SPRVTypeFloat *, float) = 0;
  virtual SPRVValue *addIntegerConstant(SPRVTypeInt *, uint64_t) = 0;
  virtual SPRVValue *addNullConstant(SPRVType *) = 0;
  virtual SPRVValue *addUndef(SPRVType *TheType) = 0;
  virtual SPRVValue *addSamplerConstant(SPRVType *TheType, SPRVWord AddrMode,
      SPRVWord ParametricMode, SPRVWord FilterMode) = 0;

  // Instruction creation functions
  virtual SPRVInstruction *addAccessChainInst(SPRVType *, SPRVValue *,
      std::vector<SPRVValue *>, SPRVBasicBlock *, bool) = 0;
  virtual SPRVInstruction *addAtomicInst(SPRVOpCode OC, SPRVType *TheType,
      const std::vector<SPRVValue *> &Operands, SPRVExecutionScopeKind Scope,
      SPRVWord MemSema, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addAsyncGroupCopy(SPRVExecutionScopeKind Scope,
      SPRVValue *Dest, SPRVValue *Src, SPRVValue *NumElems, SPRVValue *Stride,
      SPRVValue *Event, SPRVBasicBlock *BB) = 0;
  virtual SPRVInstruction *addBinaryInst(SPRVOpCode, SPRVType *, SPRVValue *,
      SPRVValue *, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addBranchConditionalInst(SPRVValue *, SPRVLabel *,
      SPRVLabel *, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addBranchInst(SPRVLabel *, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addExtInst(SPRVType *, SPRVWord, SPRVWord,
      const std::vector<SPRVWord> &, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addExtInst(SPRVType *, SPRVWord, SPRVWord,
      const std::vector<SPRVValue *> &, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addCallInst(SPRVFunction*,
      const std::vector<SPRVValue *>, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addCompositeExtractInst(SPRVType *, SPRVValue *,
      const std::vector<SPRVWord>&, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addCompositeInsertInst(SPRVValue *,
      SPRVValue *, const std::vector<SPRVWord>&, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addCopyObjectInst(SPRVType *, SPRVValue *,
      SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addCopyMemoryInst(SPRVValue *, SPRVValue *,
    const std::vector<SPRVWord>&, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addCopyMemorySizedInst(SPRVValue *, SPRVValue *,
    SPRVValue *, const std::vector<SPRVWord>&,  SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addCmpInst(SPRVOpCode, SPRVType *, SPRVValue *,
      SPRVValue *, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addControlBarrierInst(SPRVExecutionScopeKind Kind,
      SPRVBasicBlock *BB) = 0;
  virtual SPRVInstruction *addControlBarrierInst(
      SPRVExecutionScopeKind ExecKind, SPRVWord MemSema, SPRVBasicBlock *BB)
    = 0;
  virtual SPRVInstruction *addGroupInst(SPRVOpCode OpCode, SPRVType *Type,
      SPRVExecutionScopeKind Scope, const std::vector<SPRVValue *> Ops,
      SPRVBasicBlock *BB) = 0;
  virtual SPRVInstruction* addInstTemplate(SPRVOpCode OC,
      const std::vector<SPRVWord>& Ops, SPRVBasicBlock* BB, SPRVType *Ty) = 0;
  virtual SPRVInstruction *addLoadInst(SPRVValue *,
      const std::vector<SPRVWord>&, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addMemoryBarrierInst(
      SPRVExecutionScopeKind ScopeKind, SPRVWord MemFlag, SPRVBasicBlock *BB)
    = 0;
  virtual SPRVInstruction *addPhiInst(SPRVType *, std::vector<SPRVValue *>,
      SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addReturnInst(SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addReturnValueInst(SPRVValue *, SPRVBasicBlock *)
    = 0;
  virtual SPRVInstruction *addSelectInst(SPRVValue *, SPRVValue *, SPRVValue *,
      SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addStoreInst(SPRVValue *, SPRVValue *,
      const std::vector<SPRVWord>&, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addSwitchInst(SPRVValue *, SPRVBasicBlock *,
      const std::vector<std::pair<SPRVWord, SPRVBasicBlock *>>&,
      SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addUnaryInst(SPRVOpCode, SPRVType *, SPRVValue *,
      SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addVariable(SPRVType *, bool, SPRVLinkageTypeKind,
      SPRVValue *, const std::string &, SPRVStorageClassKind, SPRVBasicBlock *)
    = 0;
  virtual SPRVInstruction *addVariableArrayInst(SPRVType *, const std::string &,
      SPRVStorageClassKind, SPRVWord, SPRVBasicBlock *) = 0;
  virtual SPRVValue *addVectorShuffleInst(SPRVType *Type, SPRVValue *Vec1,
      SPRVValue *Vec2, const std::vector<SPRVWord> &Components,
      SPRVBasicBlock *BB) = 0;
  virtual SPRVInstruction *addVectorExtractDynamicInst(SPRVValue *,
      SPRVValue *, SPRVBasicBlock *) = 0;
  virtual SPRVInstruction *addVectorInsertDynamicInst(SPRVValue *,
    SPRVValue *, SPRVValue*, SPRVBasicBlock *) = 0;
  // I/O functions
  friend std::ostream & operator<<(std::ostream &O, SPRVModule& M);
  friend std::istream & operator>>(std::istream &I, SPRVModule& M);
};


};



#endif /* SPRVMODULE_HPP_ */
