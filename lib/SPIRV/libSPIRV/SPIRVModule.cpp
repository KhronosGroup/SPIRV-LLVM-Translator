//===- SPIRVModule.cpp - Class to represent SPIR-V module --------*- C++ -*-===//
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
/// This file implements Module class for SPIR-V.
///
//===----------------------------------------------------------------------===//

#include "SPIRVModule.h"
#include "SPIRVDebug.h"
#include "SPIRVEntry.h"
#include "SPIRVType.h"
#include "SPIRVValue.h"
#include "SPIRVExtInst.h"
#include "SPIRVFunction.h"
#include "SPIRVInstruction.h"
#include "SPIRVStream.h"

#include <set>
#include <unordered_map>
#include <unordered_set>

namespace SPIRV{

SPIRVModule::SPIRVModule():AutoAddCapability(true), ValidateCapability(false)
{}

SPIRVModule::~SPIRVModule()
{}

class SPIRVModuleImpl : public SPIRVModule {
public:
  SPIRVModuleImpl():SPIRVModule(), NextId(1), BoolType(NULL),
    SPIRVVersion(SPV_VERSION),
    GeneratorId(SPIRVGEN_KhronosLLVMSPIRVTranslator),
    GeneratorVer(0),
    InstSchema(SPIRVISCH_Default),
    SrcLang(SourceLanguageOpenCL_C),
    SrcLangVer(102000),
    MemoryModel(MemoryModelOpenCL){
    AddrModel = sizeof(size_t) == 32 ? AddressingModelPhysical32
        : AddressingModelPhysical64;
  };
  virtual ~SPIRVModuleImpl();

  // Object query functions
  bool exist(SPIRVId) const;
  bool exist(SPIRVId, SPIRVEntry **) const;
  SPIRVId getId(SPIRVId Id = SPIRVID_INVALID, unsigned Increment = 1);
  virtual SPIRVEntry *getEntry(SPIRVId Id) const;
  bool hasDebugInfo() const { return !LineVec.empty();}

  // Error handling functions
  SPIRVErrorLog &getErrorLog() { return ErrLog;}
  SPIRVErrorCode getError(std::string &ErrMsg) { return ErrLog.getError(ErrMsg);}

  // Module query functions
  SPIRVAddressingModelKind getAddressingModel() { return AddrModel;}
  SPIRVExtInstSetKind getBuiltinSet(SPIRVId SetId) const;
  const SPIRVCapSet &getCapability() const { return CapSet;}
  std::set<std::string> &getExtension() { return SPIRVExt;}
  SPIRVFunction *getFunction(unsigned I) const { return FuncVec[I];}
  SPIRVVariable *getVariable(unsigned I) const { return VariableVec[I];}
  virtual SPIRVValue *getValue(SPIRVId TheId) const;
  virtual std::vector<SPIRVValue *> getValues(const std::vector<SPIRVId>&)const;
  virtual std::vector<SPIRVId> getIds(const std::vector<SPIRVEntry *>&)const;
  virtual std::vector<SPIRVId> getIds(const std::vector<SPIRVValue *>&)const;
  virtual SPIRVType *getValueType(SPIRVId TheId)const;
  virtual std::vector<SPIRVType *> getValueTypes(const std::vector<SPIRVId>&)
      const;
  SPIRVMemoryModelKind getMemoryModel() const { return MemoryModel;}
  virtual SPIRVConstant* getLiteralAsConstant(unsigned Literal);
  unsigned getNumEntryPoints(SPIRVExecutionModelKind EM) const {
    auto Loc = EntryPointVec.find(EM);
    if (Loc == EntryPointVec.end())
      return 0;
    return Loc->second.size();
  }
  SPIRVFunction *getEntryPoint(SPIRVExecutionModelKind EM, unsigned I) const {
    auto Loc = EntryPointVec.find(EM);
    if (Loc == EntryPointVec.end())
      return nullptr;
    assert(I < Loc->second.size());
    return get<SPIRVFunction>(Loc->second[I]);
  }
  unsigned getNumFunctions() const { return FuncVec.size();}
  unsigned getNumVariables() const { return VariableVec.size();}
  SourceLanguage getSourceLanguage(SPIRVWord * Ver = nullptr) const {
    if (Ver)
      *Ver = SrcLangVer;
    return SrcLang;
  }
  std::set<std::string> &getSourceExtension() { return SrcExtension;}
  bool isEntryPoint(SPIRVExecutionModelKind, SPIRVId EP) const;
  unsigned short getGeneratorId() const { return GeneratorId; }
  unsigned short getGeneratorVer() const { return GeneratorVer; }

  // Module changing functions
  bool importBuiltinSet(const std::string &, SPIRVId *);
  bool importBuiltinSetWithId(const std::string &, SPIRVId);
  void optimizeDecorates();
  void setAddressingModel(SPIRVAddressingModelKind AM) { AddrModel = AM;}
  void setAlignment(SPIRVValue *, SPIRVWord);
  void setMemoryModel(SPIRVMemoryModelKind MM) {
    MemoryModel = MM;
    if (MemoryModel == spv::MemoryModelOpenCL)
      addCapability(CapabilityKernel);
  }
  void setName(SPIRVEntry *E, const std::string &Name);
  void setSourceLanguage(SourceLanguage Lang, SPIRVWord Ver) {
    SrcLang = Lang;
    SrcLangVer = Ver;
  }
  void setGeneratorId(unsigned short Id) { GeneratorId = Id; }
  void setGeneratorVer(unsigned short Ver) { GeneratorVer = Ver; }

  // Object creation functions
  template<class T> void addTo(std::vector<T *> &V, SPIRVEntry *E);
  virtual SPIRVEntry *addEntry(SPIRVEntry *E);
  virtual SPIRVBasicBlock *addBasicBlock(SPIRVFunction *, SPIRVId);
  virtual SPIRVString *getString(const std::string &Str);
  virtual SPIRVMemberName *addMemberName(SPIRVTypeStruct *ST,
      SPIRVWord MemberNumber, const std::string &Name);
  virtual SPIRVLine *addLine(SPIRVEntry *E, SPIRVString *FileName, SPIRVWord Line,
      SPIRVWord Column);
  virtual void addCapability(SPIRVCapabilityKind);
  virtual void addCapabilityInternal(SPIRVCapabilityKind);
  virtual const SPIRVDecorateGeneric *addDecorate(const SPIRVDecorateGeneric *);
  virtual SPIRVDecorationGroup *addDecorationGroup();
  virtual SPIRVDecorationGroup *addDecorationGroup(SPIRVDecorationGroup *Group);
  virtual SPIRVGroupDecorate *addGroupDecorate(SPIRVDecorationGroup *Group,
      const std::vector<SPIRVEntry *> &Targets);
  virtual SPIRVGroupDecorateGeneric *addGroupDecorateGeneric(
      SPIRVGroupDecorateGeneric *GDec);
  virtual SPIRVGroupMemberDecorate *addGroupMemberDecorate(
      SPIRVDecorationGroup *Group, const std::vector<SPIRVEntry *> &Targets);
  virtual void addEntryPoint(SPIRVExecutionModelKind ExecModel,
      SPIRVId EntryPoint);
  virtual SPIRVForward *addForward(SPIRVType *Ty);
  virtual SPIRVForward *addForward(SPIRVId, SPIRVType *Ty);
  virtual SPIRVFunction *addFunction(SPIRVFunction *);
  virtual SPIRVFunction *addFunction(SPIRVTypeFunction *, SPIRVId);
  virtual SPIRVEntry *replaceForward(SPIRVForward *, SPIRVEntry *);

  // Type creation functions
  template<class T> T * addType(T *Ty);
  virtual SPIRVTypeArray *addArrayType(SPIRVType *, SPIRVConstant *);
  virtual SPIRVTypeBool *addBoolType();
  virtual SPIRVTypeFloat *addFloatType(unsigned BitWidth);
  virtual SPIRVTypeFunction *addFunctionType(SPIRVType *,
      const std::vector<SPIRVType *> &);
  virtual SPIRVTypeInt *addIntegerType(unsigned BitWidth);
  virtual SPIRVTypeOpaque *addOpaqueType(const std::string &);
  virtual SPIRVTypePointer *addPointerType(SPIRVStorageClassKind, SPIRVType *);
  virtual SPIRVTypeImage *addImageType(SPIRVType *,
      const SPIRVTypeImageDescriptor &);
  virtual SPIRVTypeImage *addImageType(SPIRVType *,
      const SPIRVTypeImageDescriptor &, SPIRVAccessQualifierKind);
  virtual SPIRVTypeSampler *addSamplerType();
  virtual SPIRVTypeSampledImage *addSampledImageType(SPIRVTypeImage *T);
  virtual SPIRVTypeStruct *addStructType(const std::vector<SPIRVType *>&,
      const std::string &, bool);
  virtual SPIRVTypeVector *addVectorType(SPIRVType *, SPIRVWord);
  virtual SPIRVType *addOpaqueGenericType(Op);
  virtual SPIRVTypePipe *addPipeType();
  virtual SPIRVTypeVoid *addVoidType();

  // Constant creation functions
  virtual SPIRVInstruction *addBranchInst(SPIRVLabel *, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addBranchConditionalInst(SPIRVValue *, SPIRVLabel *,
      SPIRVLabel *, SPIRVBasicBlock *);
  virtual SPIRVValue *addCompositeConstant(SPIRVType *,
      const std::vector<SPIRVValue*>&);
  virtual SPIRVValue *addConstant(SPIRVValue *);
  virtual SPIRVValue *addConstant(SPIRVType *, uint64_t);
  virtual SPIRVValue *addDoubleConstant(SPIRVTypeFloat *, double);
  virtual SPIRVValue *addFloatConstant(SPIRVTypeFloat *, float);
  virtual SPIRVValue *addIntegerConstant(SPIRVTypeInt *, uint64_t);
  virtual SPIRVValue *addNullConstant(SPIRVType *);
  virtual SPIRVValue *addUndef(SPIRVType *TheType);
  virtual SPIRVValue *addSamplerConstant(SPIRVType *TheType, SPIRVWord AddrMode,
      SPIRVWord ParametricMode, SPIRVWord FilterMode);

  // Instruction creation functions
  virtual SPIRVInstruction *addPtrAccessChainInst(SPIRVType *, SPIRVValue *,
      std::vector<SPIRVValue *>, SPIRVBasicBlock *, bool);
  virtual SPIRVInstruction *addAsyncGroupCopy(SPIRVValue *Scope,
      SPIRVValue *Dest, SPIRVValue *Src, SPIRVValue *NumElems, SPIRVValue *Stride,
      SPIRVValue *Event, SPIRVBasicBlock *BB);
  virtual SPIRVInstruction *addExtInst(SPIRVType *,
      SPIRVWord, SPIRVWord, const std::vector<SPIRVWord> &,
      SPIRVBasicBlock *);
  virtual SPIRVInstruction *addExtInst(SPIRVType *,
      SPIRVWord, SPIRVWord, const std::vector<SPIRVValue *> &,
      SPIRVBasicBlock *);
  virtual SPIRVInstruction *addBinaryInst(Op, SPIRVType *, SPIRVValue *,
      SPIRVValue *, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addCallInst(SPIRVFunction*,
      const std::vector<SPIRVWord> &, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addCmpInst(Op, SPIRVType *, SPIRVValue *,
      SPIRVValue *, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addLoadInst(SPIRVValue *,
      const std::vector<SPIRVWord>&, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addPhiInst(SPIRVType *, std::vector<SPIRVValue *>,
      SPIRVBasicBlock *);
  virtual SPIRVInstruction *addCompositeExtractInst(SPIRVType *, SPIRVValue *,
      const std::vector<SPIRVWord>&, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addCompositeInsertInst(SPIRVValue *Object,
      SPIRVValue *Composite, const std::vector<SPIRVWord>& Indices,
      SPIRVBasicBlock *BB);
  virtual SPIRVInstruction *addCopyObjectInst(SPIRVType *TheType,
      SPIRVValue *Operand, SPIRVBasicBlock *BB);
  virtual SPIRVInstruction *addCopyMemoryInst(SPIRVValue *, SPIRVValue *,
    const std::vector<SPIRVWord>&, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addCopyMemorySizedInst(SPIRVValue *, SPIRVValue *,
      SPIRVValue *, const std::vector<SPIRVWord>&, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addControlBarrierInst(
      Scope ExecKind, Scope MemKind,
      SPIRVWord MemSema, SPIRVBasicBlock *BB);
  virtual SPIRVInstruction *addGroupInst(Op OpCode, SPIRVType *Type,
      Scope Scope, const std::vector<SPIRVValue *> &Ops,
      SPIRVBasicBlock *BB);
  virtual SPIRVInstruction *addInstruction(SPIRVInstruction *Inst,
      SPIRVBasicBlock *BB);
  virtual SPIRVInstTemplateBase *addInstTemplate(Op OC,
      SPIRVBasicBlock* BB, SPIRVType *Ty);
  virtual SPIRVInstTemplateBase *addInstTemplate(Op OC,
      const std::vector<SPIRVWord>& Ops, SPIRVBasicBlock* BB, SPIRVType *Ty);
  virtual SPIRVInstruction *addMemoryBarrierInst(
      Scope ScopeKind, SPIRVWord MemFlag, SPIRVBasicBlock *BB);
  virtual SPIRVInstruction *addReturnInst(SPIRVBasicBlock *);
  virtual SPIRVInstruction *addReturnValueInst(SPIRVValue *, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addSelectInst(SPIRVValue *, SPIRVValue *, SPIRVValue *,
      SPIRVBasicBlock *);
  virtual SPIRVInstruction *addStoreInst(SPIRVValue *, SPIRVValue *,
      const std::vector<SPIRVWord>&, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addSwitchInst(SPIRVValue *, SPIRVBasicBlock *,
      const std::vector<std::pair<SPIRVWord, SPIRVBasicBlock *>>&,
      SPIRVBasicBlock *);
  virtual SPIRVInstruction *addUnaryInst(Op, SPIRVType *, SPIRVValue *,
      SPIRVBasicBlock *);
  virtual SPIRVInstruction *addVariable(SPIRVType *, bool, SPIRVLinkageTypeKind,
    SPIRVValue *, const std::string &, SPIRVStorageClassKind, SPIRVBasicBlock *);
  virtual SPIRVValue *addVectorShuffleInst(SPIRVType *Type, SPIRVValue *Vec1,
      SPIRVValue *Vec2, const std::vector<SPIRVWord> &Components,
      SPIRVBasicBlock *BB);
  virtual SPIRVInstruction *addVectorExtractDynamicInst(SPIRVValue *,
      SPIRVValue *, SPIRVBasicBlock *);
  virtual SPIRVInstruction *addVectorInsertDynamicInst(SPIRVValue *,
    SPIRVValue *, SPIRVValue*, SPIRVBasicBlock *);

  // I/O functions
  friend spv_ostream & operator<<(spv_ostream &O, SPIRVModule& M);
  friend std::istream & operator>>(std::istream &I, SPIRVModule& M);

private:
  SPIRVErrorLog ErrLog;
  SPIRVId NextId;
  SPIRVTypeInt *BoolType;
  SPIRVWord SPIRVVersion;
  unsigned short GeneratorId;
  unsigned short GeneratorVer;
  SPIRVInstructionSchemaKind InstSchema;
  SourceLanguage SrcLang;
  SPIRVWord SrcLangVer;
  std::set<std::string> SrcExtension;
  std::set<std::string> SPIRVExt;
  SPIRVAddressingModelKind AddrModel;
  SPIRVMemoryModelKind MemoryModel;

  typedef std::map<SPIRVId, SPIRVEntry *> SPIRVIdToEntryMap;
  typedef std::vector<SPIRVEntry *> SPIRVEntryVector;
  typedef std::set<SPIRVId> SPIRVIdSet;
  typedef std::vector<SPIRVId> SPIRVIdVec;
  typedef std::vector<SPIRVFunction *> SPIRVFunctionVector;
  typedef std::vector<SPIRVType *> SPIRVTypeVec;
  typedef std::vector<SPIRVValue *> SPIRVConstantVector;
  typedef std::vector<SPIRVVariable *> SPIRVVariableVec;
  typedef std::vector<SPIRVString *> SPIRVStringVec;
  typedef std::vector<SPIRVMemberName *> SPIRVMemberNameVec;
  typedef std::vector<SPIRVLine *> SPIRVLineVec;
  typedef std::vector<SPIRVDecorationGroup *> SPIRVDecGroupVec;
  typedef std::vector<SPIRVGroupDecorateGeneric *> SPIRVGroupDecVec;
  typedef std::map<SPIRVId, SPIRVExtInstSetKind> SPIRVIdToBuiltinSetMap;
  typedef std::map<SPIRVExecutionModelKind, SPIRVIdSet> SPIRVExecModelIdSetMap;
  typedef std::map<SPIRVExecutionModelKind, SPIRVIdVec> SPIRVExecModelIdVecMap;
  typedef std::unordered_map<std::string, SPIRVString*> SPIRVStringMap;

  SPIRVTypeVec TypeVec;
  SPIRVIdToEntryMap IdEntryMap;
  SPIRVFunctionVector FuncVec;
  SPIRVConstantVector ConstVec;
  SPIRVVariableVec VariableVec;
  SPIRVEntryVector EntryNoId;         // Entries without id
  SPIRVIdToBuiltinSetMap IdBuiltinMap;
  SPIRVIdSet NamedId;
  SPIRVStringVec StringVec;
  SPIRVMemberNameVec MemberNameVec;
  SPIRVLineVec LineVec;
  SPIRVDecorateSet DecorateSet;
  SPIRVDecGroupVec DecGroupVec;
  SPIRVGroupDecVec GroupDecVec;
  SPIRVExecModelIdSetMap EntryPointSet;
  SPIRVExecModelIdVecMap EntryPointVec;
  SPIRVStringMap StrMap;
  SPIRVCapSet CapSet;
  std::map<unsigned, SPIRVTypeInt*> IntTypeMap;
  std::map<unsigned, SPIRVConstant*> LiteralMap;

  void layoutEntry(SPIRVEntry* Entry);
};

SPIRVModuleImpl::~SPIRVModuleImpl() {
  //ToDo: Fix bug causing crash
  //for (auto I:IdEntryMap)
  //  delete I.second;

  // ToDo: Fix bug causing crash
  //for (auto I:EntryNoId) {
  //  bildbgs() << "[delete] " << *I;
  //  delete I;
  //}
}

SPIRVLine*
SPIRVModuleImpl::addLine(SPIRVEntry* E, SPIRVString* FileName,
    SPIRVWord Line, SPIRVWord Column) {
  auto L = add(new SPIRVLine(E, FileName->getId(), Line, Column));
  E->setLine(L);
  return L;
}

// Creates decoration group and group decorates from decorates shared by
// multiple targets.
void
SPIRVModuleImpl::optimizeDecorates() {
  SPIRVDBG(spvdbgs() << "[optimizeDecorates] begin\n");
  for (auto I = DecorateSet.begin(), E = DecorateSet.end(); I != E;) {
    auto D = *I;
    SPIRVDBG(spvdbgs() << "  check " << *D << '\n');
    if (D->getOpCode() == OpMemberDecorate) {
      ++I;
      continue;
    }
    auto ER = DecorateSet.equal_range(D);
    SPIRVDBG(spvdbgs() << "  equal range " << **ER.first
                      << " to ";
            if (ER.second != DecorateSet.end())
              spvdbgs() << **ER.second;
            else
              spvdbgs() << "end";
            spvdbgs() << '\n');
    if (std::distance(ER.first, ER.second) < 2) {
      I = ER.second;
      SPIRVDBG(spvdbgs() << "  skip equal range \n");
      continue;
    }
    SPIRVDBG(spvdbgs() << "  add deco group. erase equal range\n");
    auto G = new SPIRVDecorationGroup(this, getId());
    std::vector<SPIRVId> Targets;
    Targets.push_back(D->getTargetId());
    const_cast<SPIRVDecorateGeneric*>(D)->setTargetId(G->getId());
    G->getDecorations().insert(D);
    for (I = ER.first; I != ER.second; ++I) {
      auto E = *I;
      if (*E == *D)
        continue;
      Targets.push_back(E->getTargetId());
    }

    // WordCount is only 16 bits.  We can only have 65535 - FixedWC targtets per
    // group.
    // For now, just skip using a group if the number of targets to too big
    if (Targets.size() < 65530) {
      DecorateSet.erase(ER.first, ER.second);
      auto GD = new SPIRVGroupDecorate(G, Targets);
      DecGroupVec.push_back(G);
      GroupDecVec.push_back(GD);
    }
  }
}

SPIRVValue*
SPIRVModuleImpl::addSamplerConstant(SPIRVType* TheType,
    SPIRVWord AddrMode, SPIRVWord ParametricMode, SPIRVWord FilterMode) {
  return addConstant(new SPIRVConstantSampler(this, TheType, getId(), AddrMode,
      ParametricMode, FilterMode));
}

void
SPIRVModuleImpl::addCapability(SPIRVCapabilityKind Cap) {
  addCapabilities(SPIRV::getCapability(Cap));
  SPIRVDBG(spvdbgs() << "addCapability: " << Cap << '\n');
  CapSet.insert(Cap);
}

void
SPIRVModuleImpl::addCapabilityInternal(SPIRVCapabilityKind Cap) {
  if (AutoAddCapability)
    CapSet.insert(Cap);
}

SPIRVConstant*
SPIRVModuleImpl::getLiteralAsConstant(unsigned Literal) {
  auto Loc = LiteralMap.find(Literal);
  if (Loc != LiteralMap.end())
    return Loc->second;
  auto Ty = addIntegerType(32);
  auto V = new SPIRVConstant(this, Ty, getId(), static_cast<uint64_t>(Literal));
  LiteralMap[Literal] = V;
  addConstant(V);
  return V;
}

void
SPIRVModuleImpl::layoutEntry(SPIRVEntry* E) {
  auto OC = E->getOpCode();
  switch (OC) {
  case OpString:
    addTo(StringVec, E);
    break;
  case OpMemberName:
    addTo(MemberNameVec, E);
    break;
  case OpLine:
    addTo(LineVec, E);
    break;
  case OpVariable: {
    auto BV = static_cast<SPIRVVariable*>(E);
    if (!BV->getParent())
      addTo(VariableVec, E);
    }
    break;
  default:
    if (isTypeOpCode(OC))
      TypeVec.push_back(static_cast<SPIRVType*>(E));
    else if (isConstantOpCode(OC))
      ConstVec.push_back(static_cast<SPIRVConstant*>(E));
    break;
  }
}

// Add an entry to the id to entry map.
// Assert if the id is mapped to a different entry.
// Certain entries need to be add to specific collectors to maintain
// logic layout of SPIRV.
SPIRVEntry *
SPIRVModuleImpl::addEntry(SPIRVEntry *Entry) {
  assert(Entry && "Invalid entry");
  if (Entry->hasId()) {
    SPIRVId Id = Entry->getId();
    assert(Entry->getId() != SPIRVID_INVALID && "Invalid id");
    SPIRVEntry *Mapped = nullptr;
    if (exist(Id, &Mapped)) {
      if (Mapped->getOpCode() == OpForward) {
        replaceForward(static_cast<SPIRVForward *>(Mapped), Entry);
      } else {
        assert(Mapped == Entry && "Id used twice");
      }
    } else
      IdEntryMap[Id] = Entry;
  } else {
    EntryNoId.push_back(Entry);
  }

  Entry->setModule(this);

  layoutEntry(Entry);
  if (AutoAddCapability) {
    for (auto &I:Entry->getRequiredCapability()) {
      addCapability(I);
    }
  }
  if (ValidateCapability) {
    for (auto &I:Entry->getRequiredCapability()) {
      assert(CapSet.count(I));
    }
  }
  return Entry;
}

bool
SPIRVModuleImpl::exist(SPIRVId Id) const {
  return exist(Id, nullptr);
}

bool
SPIRVModuleImpl::exist(SPIRVId Id, SPIRVEntry **Entry) const {
  assert (Id != SPIRVID_INVALID && "Invalid Id");
  SPIRVIdToEntryMap::const_iterator Loc = IdEntryMap.find(Id);
  if (Loc == IdEntryMap.end())
    return false;
  if (Entry)
    *Entry = Loc->second;
  return true;
}

// If Id is invalid, returns the next available id.
// Otherwise returns the given id and adjust the next available id by increment.
SPIRVId
SPIRVModuleImpl::getId(SPIRVId Id, unsigned increment) {
  if (!isValidId(Id))
    Id = NextId;
  else
    NextId = std::max(Id, NextId);
  NextId += increment;
  return Id;
}

SPIRVEntry *
SPIRVModuleImpl::getEntry(SPIRVId Id) const {
  assert (Id != SPIRVID_INVALID && "Invalid Id");
  SPIRVIdToEntryMap::const_iterator Loc = IdEntryMap.find(Id);
  assert (Loc != IdEntryMap.end() && "Id is not in map");
  return Loc->second;
}

SPIRVExtInstSetKind
SPIRVModuleImpl::getBuiltinSet(SPIRVId SetId) const {
  auto Loc = IdBuiltinMap.find(SetId);
  assert(Loc != IdBuiltinMap.end() && "Invalid builtin set id");
  return Loc->second;
}

bool
SPIRVModuleImpl::isEntryPoint(SPIRVExecutionModelKind ExecModel, SPIRVId EP)
  const {
  assert(isValid(ExecModel) && "Invalid execution model");
  assert(EP != SPIRVID_INVALID && "Invalid function id");
  auto Loc = EntryPointSet.find(ExecModel);
  if (Loc == EntryPointSet.end())
    return false;
  return Loc->second.count(EP);
}

// Module change functions
bool
SPIRVModuleImpl::importBuiltinSet(const std::string& BuiltinSetName,
    SPIRVId *BuiltinSetId) {
  SPIRVId TmpBuiltinSetId = getId();
  if (!importBuiltinSetWithId(BuiltinSetName, TmpBuiltinSetId))
    return false;
  if (BuiltinSetId)
    *BuiltinSetId = TmpBuiltinSetId;
  return true;
}

bool
SPIRVModuleImpl::importBuiltinSetWithId(const std::string& BuiltinSetName,
    SPIRVId BuiltinSetId) {
  SPIRVExtInstSetKind BuiltinSet = SPIRVEIS_Count;
  SPIRVCKRT(SPIRVBuiltinSetNameMap::rfind(BuiltinSetName, &BuiltinSet),
      InvalidBuiltinSetName, "Actual is " + BuiltinSetName);
  IdBuiltinMap[BuiltinSetId] = BuiltinSet;
  return true;
}

void
SPIRVModuleImpl::setAlignment(SPIRVValue *V, SPIRVWord A) {
  V->setAlignment(A);
}

void
SPIRVModuleImpl::setName(SPIRVEntry *E, const std::string &Name) {
  E->setName(Name);
  if (!E->hasId())
    return;
  if (!Name.empty())
    NamedId.insert(E->getId());
  else
    NamedId.erase(E->getId());
}

// Type creation functions
template<class T>
T *
SPIRVModuleImpl::addType(T *Ty) {
  add(Ty);
  if (!Ty->getName().empty())
    setName(Ty, Ty->getName());
  return Ty;
}

SPIRVTypeVoid *
SPIRVModuleImpl::addVoidType() {
  return addType(new SPIRVTypeVoid(this, getId()));
}

SPIRVTypeArray *
SPIRVModuleImpl::addArrayType(SPIRVType *ElementType, SPIRVConstant *Length) {
  return addType(new SPIRVTypeArray(this, getId(), ElementType, Length));
}

SPIRVTypeBool *
SPIRVModuleImpl::addBoolType() {
  return addType(new SPIRVTypeBool(this, getId()));
}

SPIRVTypeInt *
SPIRVModuleImpl::addIntegerType(unsigned BitWidth) {
  auto Loc = IntTypeMap.find(BitWidth);
  if (Loc != IntTypeMap.end())
    return Loc->second;
  auto Ty = new SPIRVTypeInt(this, getId(), BitWidth, false);
  IntTypeMap[BitWidth] = Ty;
  return addType(Ty);
}

SPIRVTypeFloat *
SPIRVModuleImpl::addFloatType(unsigned BitWidth) {
  SPIRVTypeFloat *T = addType(new SPIRVTypeFloat(this, getId(), BitWidth));
  return T;
}

SPIRVTypePointer *
SPIRVModuleImpl::addPointerType(SPIRVStorageClassKind StorageClass,
    SPIRVType *ElementType) {
  return addType(new SPIRVTypePointer(this, getId(), StorageClass,
      ElementType));
}

SPIRVTypeFunction *
SPIRVModuleImpl::addFunctionType(SPIRVType *ReturnType,
    const std::vector<SPIRVType *>& ParameterTypes) {
  return addType(new SPIRVTypeFunction(this, getId(), ReturnType,
      ParameterTypes));
}

SPIRVTypeOpaque*
SPIRVModuleImpl::addOpaqueType(const std::string& Name) {
  return addType(new SPIRVTypeOpaque(this, getId(), Name));
}

SPIRVTypeStruct*
SPIRVModuleImpl::addStructType(const std::vector<SPIRVType*> &MemberTypes,
    const std::string &Name, bool Packed) {
  auto T = new SPIRVTypeStruct(this, getId(), MemberTypes, Name);
  addType(T);
  T->setPacked(Packed);
  return T;
}

SPIRVTypeVector*
SPIRVModuleImpl::addVectorType(SPIRVType* CompType, SPIRVWord CompCount) {
  return addType(new SPIRVTypeVector(this, getId(), CompType, CompCount));
}
SPIRVType *
SPIRVModuleImpl::addOpaqueGenericType(Op TheOpCode) {
  return addType(new SPIRVTypeOpaqueGeneric(TheOpCode, this, getId()));
}
SPIRVTypePipe*
SPIRVModuleImpl::addPipeType() {
  return addType(new SPIRVTypePipe(this, getId()));
}

SPIRVTypeImage *
SPIRVModuleImpl::addImageType(SPIRVType *SampledType,
    const SPIRVTypeImageDescriptor &Desc) {
  return addType(new SPIRVTypeImage(this, getId(),
    SampledType ? SampledType->getId() : 0, Desc));
}

SPIRVTypeImage *
SPIRVModuleImpl::addImageType(SPIRVType *SampledType,
    const SPIRVTypeImageDescriptor &Desc, SPIRVAccessQualifierKind Acc) {
  return addType(new SPIRVTypeImage(this, getId(),
    SampledType ? SampledType->getId() : 0, Desc, Acc));
}

SPIRVTypeSampler *
SPIRVModuleImpl::addSamplerType() {
  return addType(new SPIRVTypeSampler(this, getId()));
}

SPIRVTypeSampledImage *
SPIRVModuleImpl::addSampledImageType(SPIRVTypeImage *T) {
  return addType(new SPIRVTypeSampledImage(this, getId(), T));
}

SPIRVFunction *
SPIRVModuleImpl::addFunction(SPIRVFunction *Func) {
  FuncVec.push_back(add(Func));
  return Func;
}

SPIRVFunction *
SPIRVModuleImpl::addFunction(SPIRVTypeFunction *FuncType, SPIRVId Id) {
  return addFunction(new SPIRVFunction(this, FuncType,
      getId(Id, FuncType->getNumParameters() + 1)));
}

SPIRVBasicBlock *
SPIRVModuleImpl::addBasicBlock(SPIRVFunction *Func, SPIRVId Id) {
  return Func->addBasicBlock(new SPIRVBasicBlock(getId(Id), Func));
}

const SPIRVDecorateGeneric *
SPIRVModuleImpl::addDecorate(const SPIRVDecorateGeneric *Dec) {
  SPIRVId Id = Dec->getTargetId();
  SPIRVEntry *Target = nullptr;
  bool Found = exist(Id, &Target);
  assert (Found && "Decorate target does not exist");
  if (!Dec->getOwner())
    DecorateSet.insert(Dec);
  addCapabilities(Dec->getRequiredCapability());
  return Dec;
}

void
SPIRVModuleImpl::addEntryPoint(SPIRVExecutionModelKind ExecModel,
    SPIRVId EntryPoint){
  assert(isValid(ExecModel) && "Invalid execution model");
  assert(EntryPoint != SPIRVID_INVALID && "Invalid entry point");
  EntryPointSet[ExecModel].insert(EntryPoint);
  EntryPointVec[ExecModel].push_back(EntryPoint);
  addCapabilities(SPIRV::getCapability(ExecModel));
}

SPIRVForward *
SPIRVModuleImpl::addForward(SPIRVType *Ty) {
  return add(new SPIRVForward(this, Ty, getId()));
}

SPIRVForward *
SPIRVModuleImpl::addForward(SPIRVId Id, SPIRVType *Ty) {
  return add(new SPIRVForward(this, Ty, Id));
}

SPIRVEntry *
SPIRVModuleImpl::replaceForward(SPIRVForward *Forward, SPIRVEntry *Entry) {
  SPIRVId Id = Entry->getId();
  SPIRVId ForwardId = Forward->getId();
  if (ForwardId == Id)
    IdEntryMap[Id] = Entry;
  else {
    auto Loc = IdEntryMap.find(Id);
    assert(Loc != IdEntryMap.end());
    IdEntryMap.erase(Loc);
    Entry->setId(ForwardId);
    IdEntryMap[ForwardId] = Entry;
  }
  // Annotations include name, decorations, execution modes
  Entry->takeAnnotations(Forward);
  delete Forward;
  return Entry;
}

SPIRVValue *
SPIRVModuleImpl::addConstant(SPIRVValue *C) {
  return add(C);
}

SPIRVValue *
SPIRVModuleImpl::addConstant(SPIRVType *Ty, uint64_t V) {
  if (Ty->isTypeBool()) {
    if (V)
      return new SPIRVConstantTrue(this, Ty, getId());
    else
      return new SPIRVConstantFalse(this, Ty, getId());
  }
  return addConstant(new SPIRVConstant(this, Ty, getId(), V));
}

SPIRVValue *
SPIRVModuleImpl::addIntegerConstant(SPIRVTypeInt *Ty, uint64_t V) {
  if (Ty->getBitWidth() == 32) {
    unsigned I32 = V;
    assert(I32 == V && "Integer value truncated");
    return getLiteralAsConstant(I32);
  }
  return addConstant(new SPIRVConstant(this, Ty, getId(), V));
}

SPIRVValue *
SPIRVModuleImpl::addFloatConstant(SPIRVTypeFloat *Ty, float V) {
  return addConstant(new SPIRVConstant(this, Ty, getId(), V));
}

SPIRVValue *
SPIRVModuleImpl::addDoubleConstant(SPIRVTypeFloat *Ty, double V) {
  return addConstant(new SPIRVConstant(this, Ty, getId(), V));
}

SPIRVValue *
SPIRVModuleImpl::addNullConstant(SPIRVType *Ty) {
  return addConstant(new SPIRVConstantNull(this, Ty, getId()));
}

SPIRVValue *
SPIRVModuleImpl::addCompositeConstant(SPIRVType *Ty,
    const std::vector<SPIRVValue*>& Elements) {
  return addConstant(new SPIRVConstantComposite(this, Ty, getId(), Elements));
}

SPIRVValue *
SPIRVModuleImpl::addUndef(SPIRVType *TheType) {
  return addConstant(new SPIRVUndef(this, TheType, getId()));
}

// Instruction creation functions

SPIRVInstruction *
SPIRVModuleImpl::addStoreInst(SPIRVValue *Target, SPIRVValue *Source,
    const std::vector<SPIRVWord> &TheMemoryAccess, SPIRVBasicBlock *BB) {
  return BB->addInstruction(new SPIRVStore(Target->getId(),
      Source->getId(), TheMemoryAccess, BB));
}

SPIRVInstruction *
SPIRVModuleImpl::addSwitchInst(SPIRVValue *Select, SPIRVBasicBlock *Default,
    const std::vector<std::pair<SPIRVWord, SPIRVBasicBlock *>>& Pairs,
    SPIRVBasicBlock *BB) {
  return BB->addInstruction(new SPIRVSwitch(Select, Default, Pairs, BB));
}

SPIRVInstruction *
SPIRVModuleImpl::addGroupInst(Op OpCode, SPIRVType *Type,
    Scope Scope, const std::vector<SPIRVValue *> &Ops,
    SPIRVBasicBlock *BB) {
  assert(!Type || !Type->isTypeVoid());
  auto WordOps = getIds(Ops);
  WordOps.insert(WordOps.begin(), Scope);
  return addInstTemplate(OpCode, WordOps, BB, Type);
}

SPIRVInstruction *
SPIRVModuleImpl::addInstruction(SPIRVInstruction *Inst, SPIRVBasicBlock *BB) {
  if (BB)
    return BB->addInstruction(Inst);
  if (Inst->getOpCode() != OpSpecConstantOp)
    Inst = createSpecConstantOpInst(Inst);
  return static_cast<SPIRVInstruction *>(addConstant(Inst));
}

SPIRVInstruction *
SPIRVModuleImpl::addLoadInst(SPIRVValue *Source,
    const std::vector<SPIRVWord> &TheMemoryAccess, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVLoad(getId(), Source->getId(),
      TheMemoryAccess, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addPhiInst(SPIRVType *Type,
    std::vector<SPIRVValue *> IncomingPairs, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVPhi(Type, getId(), IncomingPairs, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addExtInst(SPIRVType *TheType, SPIRVWord BuiltinSet,
    SPIRVWord EntryPoint, const std::vector<SPIRVWord> &Args,
    SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVExtInst(TheType, getId(),
      BuiltinSet, EntryPoint, Args, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addExtInst(SPIRVType *TheType, SPIRVWord BuiltinSet,
    SPIRVWord EntryPoint, const std::vector<SPIRVValue *> &Args,
    SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVExtInst(TheType, getId(),
      BuiltinSet, EntryPoint, Args, BB), BB);
}

SPIRVInstruction*
SPIRVModuleImpl::addCallInst(SPIRVFunction* TheFunction,
    const std::vector<SPIRVWord> &TheArguments, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVFunctionCall(getId(), TheFunction,
      TheArguments, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addBinaryInst(Op TheOpCode, SPIRVType *Type,
    SPIRVValue *Op1, SPIRVValue *Op2, SPIRVBasicBlock *BB){
  return addInstruction(SPIRVInstTemplateBase::create(TheOpCode, Type, getId(),
      getVec(Op1->getId(), Op2->getId()), BB, this), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addReturnInst(SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVReturn(BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addReturnValueInst(SPIRVValue *ReturnValue, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVReturnValue(ReturnValue, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addUnaryInst(Op TheOpCode, SPIRVType *TheType,
    SPIRVValue *Op, SPIRVBasicBlock *BB) {
  return addInstruction(SPIRVInstTemplateBase::create(TheOpCode,
      TheType, getId(), getVec(Op->getId()), BB, this), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addVectorExtractDynamicInst(SPIRVValue *TheVector,
    SPIRVValue *Index, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVVectorExtractDynamic(getId(), TheVector,
      Index, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addVectorInsertDynamicInst(SPIRVValue *TheVector,
SPIRVValue *TheComponent, SPIRVValue*Index, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVVectorInsertDynamic(getId(), TheVector,
      TheComponent, Index, BB), BB);
}

SPIRVValue *
SPIRVModuleImpl::addVectorShuffleInst(SPIRVType * Type, SPIRVValue *Vec1,
    SPIRVValue *Vec2, const std::vector<SPIRVWord> &Components,
    SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVVectorShuffle(getId(), Type, Vec1, Vec2,
      Components, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addBranchInst(SPIRVLabel *TargetLabel, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVBranch(TargetLabel, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addBranchConditionalInst(SPIRVValue *Condition,
    SPIRVLabel *TrueLabel, SPIRVLabel *FalseLabel, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVBranchConditional(Condition, TrueLabel,
      FalseLabel, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addCmpInst(Op TheOpCode, SPIRVType *TheType,
    SPIRVValue *Op1, SPIRVValue *Op2, SPIRVBasicBlock *BB) {
  return addInstruction(SPIRVInstTemplateBase::create(TheOpCode,
      TheType, getId(), getVec(Op1->getId(), Op2->getId()), BB, this), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addControlBarrierInst(Scope ExecKind,
    Scope MemKind, SPIRVWord MemSema, SPIRVBasicBlock *BB) {
  return addInstruction(
      new SPIRVControlBarrier(ExecKind, MemKind, MemSema, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addMemoryBarrierInst(Scope ScopeKind,
    SPIRVWord MemFlag, SPIRVBasicBlock *BB) {
  return addInstruction(SPIRVInstTemplateBase::create(OpMemoryBarrier,
      nullptr, SPIRVID_INVALID,
      getVec(static_cast<SPIRVWord>(ScopeKind), MemFlag), BB, this), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addSelectInst(SPIRVValue *Condition, SPIRVValue *Op1,
    SPIRVValue *Op2, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVSelect(getId(), Condition->getId(),
      Op1->getId(), Op2->getId(), BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addPtrAccessChainInst(SPIRVType *Type, SPIRVValue *Base,
    std::vector<SPIRVValue *> Indices, SPIRVBasicBlock *BB, bool IsInBounds){
  return addInstruction(SPIRVInstTemplateBase::create(
    IsInBounds?OpInBoundsPtrAccessChain:OpPtrAccessChain,
    Type, getId(), getVec(Base->getId(), Base->getIds(Indices)),
    BB, this), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addAsyncGroupCopy(SPIRVValue *Scope,
    SPIRVValue *Dest, SPIRVValue *Src, SPIRVValue *NumElems, SPIRVValue *Stride,
    SPIRVValue *Event, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVGroupAsyncCopy(Scope, getId(), Dest, Src,
    NumElems, Stride, Event, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addCompositeExtractInst(SPIRVType *Type, SPIRVValue *TheVector,
    const std::vector<SPIRVWord>& Indices, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVCompositeExtract(Type, getId(), TheVector,
      Indices, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addCompositeInsertInst(SPIRVValue *Object,
    SPIRVValue *Composite, const std::vector<SPIRVWord>& Indices,
    SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVCompositeInsert(getId(), Object, Composite,
      Indices, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addCopyObjectInst(SPIRVType *TheType, SPIRVValue *Operand,
    SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVCopyObject(TheType, getId(), Operand, BB), BB);

}

SPIRVInstruction *
SPIRVModuleImpl::addCopyMemoryInst(SPIRVValue *TheTarget, SPIRVValue *TheSource,
    const std::vector<SPIRVWord> &TheMemoryAccess, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVCopyMemory(TheTarget, TheSource,
      TheMemoryAccess, BB), BB);
}

SPIRVInstruction *
SPIRVModuleImpl::addCopyMemorySizedInst(SPIRVValue *TheTarget,
    SPIRVValue *TheSource, SPIRVValue *TheSize,
    const std::vector<SPIRVWord> &TheMemoryAccess, SPIRVBasicBlock *BB) {
  return addInstruction(new SPIRVCopyMemorySized(TheTarget, TheSource, TheSize,
    TheMemoryAccess, BB), BB);
}

SPIRVInstruction*
SPIRVModuleImpl::addVariable(SPIRVType *Type, bool IsConstant,
    SPIRVLinkageTypeKind LinkageType, SPIRVValue *Initializer,
    const std::string &Name, SPIRVStorageClassKind StorageClass,
    SPIRVBasicBlock *BB) {
  SPIRVVariable *Variable = new SPIRVVariable(Type, getId(), Initializer,
      Name, StorageClass, BB, this);
  if (BB)
    return addInstruction(Variable, BB);

  add(Variable);
  if (LinkageType != LinkageTypeInternal)
    Variable->setLinkageType(LinkageType);
  Variable->setIsConstant(IsConstant);
  return Variable;
}

template<class T>
spv_ostream &
operator<< (spv_ostream &O, const std::vector<T *>& V) {
  for (auto &I: V)
    O << *I;
  return O;
}

template<class T, class B>
spv_ostream &
operator<< (spv_ostream &O, const std::multiset<T *, B>& V) {
  for (auto &I: V)
    O << *I;
  return O;
}

spv_ostream &
operator<< (spv_ostream &O, SPIRVModule &M) {
  SPIRVModuleImpl &MI = *static_cast<SPIRVModuleImpl*>(&M);

  SPIRVEncoder Encoder(O);
  Encoder << MagicNumber
          << MI.SPIRVVersion
          << (((SPIRVWord)MI.GeneratorId << 16) | MI.GeneratorVer)
          << MI.NextId /* Bound for Id */
          << MI.InstSchema;
  O << SPIRVNL();

  for (auto &I:MI.CapSet)
    O << SPIRVCapability(&M, I);

  for (auto &I:M.getExtension()) {
    assert(!I.empty() && "Invalid extension");
    O << SPIRVExtension(&M, I);
  }

  for (auto &I:MI.IdBuiltinMap)
    O <<  SPIRVExtInstImport(&M, I.first, SPIRVBuiltinSetNameMap::map(I.second));

  O << SPIRVMemoryModel(&M);

  for (auto &I:MI.EntryPointVec)
    for (auto &II:I.second)
      O << SPIRVEntryPoint(&M, I.first, II,
          M.get<SPIRVFunction>(II)->getName());

  for (auto &I:MI.EntryPointVec)
    for (auto &II:I.second)
      MI.get<SPIRVFunction>(II)->encodeExecutionModes(O);

  O << MI.StringVec;

  for (auto &I:M.getSourceExtension()) {
    assert(!I.empty() && "Invalid source extension");
    O << SPIRVSourceExtension(&M, I);
  }

  O << SPIRVSource(&M);

  for (auto &I:MI.NamedId) {
    // Don't output name for entry point since it is redundant
    bool IsEntryPoint = false;
    for (auto &EPS:MI.EntryPointSet)
      if (EPS.second.count(I)) {
        IsEntryPoint = true;
        break;
      }
    if (!IsEntryPoint)
      M.getEntry(I)->encodeName(O);
  }

  O << MI.MemberNameVec
    << MI.LineVec
    << MI.DecGroupVec
    << MI.DecorateSet
    << MI.GroupDecVec
    << MI.TypeVec
    << MI.ConstVec
    << MI.VariableVec
    << SPIRVNL()
    << MI.FuncVec;
  return O;
}

template<class T>
void SPIRVModuleImpl::addTo(std::vector<T*>& V, SPIRVEntry* E) {
  V.push_back(static_cast<T *>(E));
}


// The first decoration group includes all the previously defined decorates.
// The second decoration group includes all the decorates defined between the
// first and second decoration group. So long so forth.
SPIRVDecorationGroup*
SPIRVModuleImpl::addDecorationGroup() {
  return addDecorationGroup(new SPIRVDecorationGroup(this, getId()));
}

SPIRVDecorationGroup*
SPIRVModuleImpl::addDecorationGroup(SPIRVDecorationGroup* Group) {
  add(Group);
  Group->takeDecorates(DecorateSet);
  DecGroupVec.push_back(Group);
  SPIRVDBG(spvdbgs() << "[addDecorationGroup] {" << *Group << "}\n";
          spvdbgs() << "  Remaining DecorateSet: {" << DecorateSet << "}\n");
  assert(DecorateSet.empty());
  return Group;
}

SPIRVGroupDecorateGeneric*
SPIRVModuleImpl::addGroupDecorateGeneric(SPIRVGroupDecorateGeneric *GDec) {
  add(GDec);
  GDec->decorateTargets();
  GroupDecVec.push_back(GDec);
  return GDec;
}
SPIRVGroupDecorate*
SPIRVModuleImpl::addGroupDecorate(
    SPIRVDecorationGroup* Group, const std::vector<SPIRVEntry*>& Targets) {
  auto GD = new SPIRVGroupDecorate(Group, getIds(Targets));
  addGroupDecorateGeneric(GD);
  return GD;
}

SPIRVGroupMemberDecorate*
SPIRVModuleImpl::addGroupMemberDecorate(
    SPIRVDecorationGroup* Group, const std::vector<SPIRVEntry*>& Targets) {
  auto GMD = new SPIRVGroupMemberDecorate(Group, getIds(Targets));
  addGroupDecorateGeneric(GMD);
  return GMD;
}

SPIRVString*
SPIRVModuleImpl::getString(const std::string& Str) {
  auto Loc = StrMap.find(Str);
  if (Loc != StrMap.end())
    return Loc->second;
  auto S = add(new SPIRVString(this, getId(), Str));
  StrMap[Str] = S;
  return S;
}

SPIRVMemberName*
SPIRVModuleImpl::addMemberName(SPIRVTypeStruct* ST,
    SPIRVWord MemberNumber, const std::string& Name) {
  return add(new SPIRVMemberName(ST, MemberNumber, Name));
}

std::istream &
operator>> (std::istream &I, SPIRVModule &M) {
  SPIRVDecoder Decoder(I, M);
  SPIRVModuleImpl &MI = *static_cast<SPIRVModuleImpl*>(&M);

  SPIRVWord Magic;
  Decoder >> Magic;
  assert(Magic == MagicNumber && "Invalid magic number");

  Decoder >> MI.SPIRVVersion;
  assert(MI.SPIRVVersion <= SPV_VERSION && "Unsupported SPIRV version number");

  SPIRVWord Generator = 0;
  Decoder >> Generator;
  MI.GeneratorId = Generator >> 16;
  MI.GeneratorVer = Generator & 0xFFFF;

  // Bound for Id
  Decoder >> MI.NextId;

  Decoder >> MI.InstSchema;
  assert(MI.InstSchema == SPIRVISCH_Default && "Unsupported instruction schema");

  while(Decoder.getWordCountAndOpCode())
    Decoder.getEntry();

  MI.optimizeDecorates();
  return I;
}

SPIRVModule *
SPIRVModule::createSPIRVModule() {
  return new SPIRVModuleImpl;
}

SPIRVValue *
SPIRVModuleImpl::getValue(SPIRVId TheId)const {
  return get<SPIRVValue>(TheId);
}

SPIRVType *
SPIRVModuleImpl::getValueType(SPIRVId TheId)const {
  return get<SPIRVValue>(TheId)->getType();
}

std::vector<SPIRVValue *>
SPIRVModuleImpl::getValues(const std::vector<SPIRVId>& IdVec)const {
  std::vector<SPIRVValue *> ValueVec;
  for (auto i:IdVec)
    ValueVec.push_back(getValue(i));
  return ValueVec;
}

std::vector<SPIRVType *>
SPIRVModuleImpl::getValueTypes(const std::vector<SPIRVId>& IdVec)const {
  std::vector<SPIRVType *> TypeVec;
  for (auto i:IdVec)
    TypeVec.push_back(getValue(i)->getType());
  return TypeVec;
}

std::vector<SPIRVId>
SPIRVModuleImpl::getIds(const std::vector<SPIRVEntry *> &ValueVec)const {
  std::vector<SPIRVId> IdVec;
  for (auto i:ValueVec)
    IdVec.push_back(i->getId());
  return IdVec;
}

std::vector<SPIRVId>
SPIRVModuleImpl::getIds(const std::vector<SPIRVValue *> &ValueVec)const {
  std::vector<SPIRVId> IdVec;
  for (auto i:ValueVec)
    IdVec.push_back(i->getId());
  return IdVec;
}

SPIRVInstTemplateBase*
SPIRVModuleImpl::addInstTemplate(Op OC,
    SPIRVBasicBlock* BB, SPIRVType *Ty) {
  assert (!Ty || !Ty->isTypeVoid());
  SPIRVId Id = Ty ? getId() : SPIRVID_INVALID;
  auto Ins = SPIRVInstTemplateBase::create(OC, Ty, Id, BB, this);
  BB->addInstruction(Ins);
  return Ins;
}

SPIRVInstTemplateBase*
SPIRVModuleImpl::addInstTemplate(Op OC,
    const std::vector<SPIRVWord>& Ops, SPIRVBasicBlock* BB, SPIRVType *Ty) {
  assert (!Ty || !Ty->isTypeVoid());
  SPIRVId Id = Ty ? getId() : SPIRVID_INVALID;
  auto Ins = SPIRVInstTemplateBase::create(OC, Ty, Id, Ops, BB, this);
  BB->addInstruction(Ins);
  return Ins;
}

SPIRVDbgInfo::SPIRVDbgInfo(SPIRVModule *TM)
:M(TM){
}

std::string
SPIRVDbgInfo::getEntryPointFileStr(SPIRVExecutionModelKind EM, unsigned I) {
  if (M->getNumEntryPoints(EM) == 0)
    return "";
  return getFunctionFileStr(M->getEntryPoint(EM, I));
}

std::string
SPIRVDbgInfo::getFunctionFileStr(SPIRVFunction *F) {
  if (F->hasLine())
    return F->getLine()->getFileNameStr();
  return "";
}

unsigned
SPIRVDbgInfo::getFunctionLineNo(SPIRVFunction *F) {
  if (F->hasLine())
    return F->getLine()->getLine();
  return 0;
}

bool IsSPIRVBinary(const std::string &Img) {
  if (Img.size() < sizeof(unsigned))
    return false;
  auto Magic = reinterpret_cast<const unsigned*>(Img.data());
  return *Magic == MagicNumber;
}

#ifdef _SPIRV_SUPPORT_TEXT_FMT

bool ConvertSPIRV(std::istream &IS, spv_ostream &OS,
    std::string &ErrMsg, bool FromText, bool ToText) {
  auto SaveOpt = SPIRVUseTextFormat;
  SPIRVUseTextFormat = FromText;
  SPIRVModuleImpl M;
  IS >> M;
  if (M.getError(ErrMsg) != SPIRVEC_Success) {
    SPIRVUseTextFormat = SaveOpt;
    return false;
  }
  SPIRVUseTextFormat = ToText;
  OS << M;
  if (M.getError(ErrMsg) != SPIRVEC_Success) {
    SPIRVUseTextFormat = SaveOpt;
    return false;
  }
  SPIRVUseTextFormat = SaveOpt;
  return true;
}

bool IsSPIRVText(const std::string &Img) {
  std::istringstream SS(Img);
  unsigned Magic = 0;
  SS >> Magic;
  if (SS.bad())
    return false;
  return Magic == MagicNumber;
}

bool ConvertSPIRV(std::string &Input, std::string &Out,
    std::string &ErrMsg, bool ToText) {
  auto FromText = IsSPIRVText(Input);
  if (ToText == FromText) {
    Out = Input;
    return true;
  }
  std::istringstream IS(Input);
#ifdef _SPIRV_LLVM_API
  llvm::raw_string_ostream OS(Out);
#else
  std::ostringstream OS;
#endif
  if (!ConvertSPIRV(IS, OS, ErrMsg, FromText, ToText))
    return false;
  Out = OS.str();
  return true;
}

#endif // _SPIRV_SUPPORT_TEXT_FMT

}

