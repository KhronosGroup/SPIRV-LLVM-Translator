//===- SPRVModule.cpp – Class to represent SPIR-V module --------*- C++ -*-===//
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

#include "SPRVModule.h"
#include "SPRVDebug.h"
#include "SPRVEntry.h"
#include "SPRVType.h"
#include "SPRVValue.h"
#include "SPRVExtInst.h"
#include "SPRVFunction.h"
#include "SPRVInstruction.h"
#include "SPRVStream.h"

#include <set>
#include <unordered_map>
#include <unordered_set>

namespace SPRV{

SPRVModule::SPRVModule():AutoAddCapability(true), ValidateCapability(false)
{}

SPRVModule::~SPRVModule()
{}

class SPRVModuleImpl : public SPRVModule {
public:
  SPRVModuleImpl():SPRVModule(), NextId(0), BoolType(NULL),
    SPRVVersion(SPRVVER_100),
    SPRVGenerator(SPRVGEN_AMDOpenSourceLLVMSPRVTranslator),
    InstSchema(SPRVISCH_Default),
    SrcLang(SPRVSL_OpenCL),
    SrcLangVer(12),
    MemoryModel(SPRVMM_OpenCL12){
    AddrModel = sizeof(size_t) == 32 ? SPRVAM_Physical32 : SPRVAM_Physical64;
  };
  virtual ~SPRVModuleImpl();

  // Object query functions
  bool exist(SPRVId) const;
  bool exist(SPRVId, SPRVEntry **) const;
  SPRVId getId(SPRVId Id = SPRVID_INVALID, unsigned Increment = 1);
  virtual SPRVEntry *getEntry(SPRVId Id) const;
  bool hasDebugInfo() const { return !LineVec.empty();}

  // Error handling functions
  SPRVErrorLog &getErrorLog() { return ErrLog;}
  SPRVErrorCode getError(std::string &ErrMsg) { return ErrLog.getError(ErrMsg);}

  // Module query functions
  SPRVAddressingModelKind getAddressingModel() { return AddrModel;}
  SPRVExtInstSetKind getBuiltinSet(SPRVId SetId) const;
  const SPRVCapSet &getCapability() const { return CapSet;}
  const std::string &getCompileFlag() const { return CompileFlag;}
  std::string &getCompileFlag() { return CompileFlag;}
  const std::string &getExtension() const { return SPRVExt;}
  SPRVFunction *getFunction(unsigned I) const { return FuncVec[I];}
  SPRVVariable *getVariable(unsigned I) const { return VariableVec[I];}
  virtual SPRVValue *getValue(SPRVId TheId) const;
  virtual std::vector<SPRVValue *> getValues(const std::vector<SPRVId>&)const;
  virtual std::vector<SPRVId> getIds(const std::vector<SPRVEntry *>&)const;
  virtual std::vector<SPRVId> getIds(const std::vector<SPRVValue *>&)const;
  virtual SPRVType *getValueType(SPRVId TheId)const;
  virtual std::vector<SPRVType *> getValueTypes(const std::vector<SPRVId>&)
      const;
  SPRVMemoryModelKind getMemoryModel() { return MemoryModel;}
  unsigned getNumEntryPoints(SPRVExecutionModelKind EM) const {
    auto Loc = EntryPointVec.find(EM);
    if (Loc == EntryPointVec.end())
      return 0;
    return Loc->second.size();
  }
  SPRVFunction *getEntryPoint(SPRVExecutionModelKind EM, unsigned I) const {
    auto Loc = EntryPointVec.find(EM);
    if (Loc == EntryPointVec.end())
      return nullptr;
    assert(I < Loc->second.size());
    return get<SPRVFunction>(Loc->second[I]);
  }
  unsigned getNumFunctions() const { return FuncVec.size();}
  unsigned getNumVariables() const { return VariableVec.size();}
  SPRVSourceLanguageKind getSourceLanguage(SPRVWord * Ver = nullptr) const {
    if (Ver)
      *Ver = SrcLangVer;
    return SrcLang;
  }
  const std::string &getSourceExtension() const { return SrcExtension;}
  bool isEntryPoint(SPRVExecutionModelKind, SPRVId EP) const;

  // Module changing functions
  bool importBuiltinSet(const std::string &, SPRVId *);
  bool importBuiltinSetWithId(const std::string &, SPRVId);
  void optimizeDecorates();
  void setAddressingModel(SPRVAddressingModelKind AM) { AddrModel = AM;}
  void setAlignment(SPRVValue *, SPRVWord);
  void setExtension(const std::string &Ext) { SPRVExt = Ext;}
  void setMemoryModel(SPRVMemoryModelKind MM) { MemoryModel = MM;}
  void setName(SPRVEntry *E, const std::string &Name);
  void setSourceLanguage(SPRVSourceLanguageKind Lang, SPRVWord Ver) {
    SrcLang = Lang;
    SrcLangVer = Ver;
  }
  void setSourceExtension(const std::string &Ext) { SrcExtension = Ext;}

  // Object creation functions
  template<class T> void addTo(std::vector<T *> &V, SPRVEntry *E);
  virtual SPRVEntry *addEntry(SPRVEntry *E);
  virtual SPRVBasicBlock *addBasicBlock(SPRVFunction *, SPRVId);
  virtual SPRVString *getString(const std::string &Str);
  virtual SPRVMemberName *addMemberName(SPRVTypeStruct *ST,
      SPRVWord MemberNumber, const std::string &Name);
  virtual SPRVLine *addLine(SPRVEntry *E, SPRVString *FileName, SPRVWord Line,
      SPRVWord Column);
  virtual void addCapability(SPRVCapabilityKind);
  virtual void addCapabilityInternal(SPRVCapabilityKind);
  virtual const SPRVDecorateGeneric *addDecorate(const SPRVDecorateGeneric *);
  virtual SPRVDecorationGroup *addDecorationGroup();
  virtual SPRVDecorationGroup *addDecorationGroup(SPRVDecorationGroup *Group);
  virtual SPRVGroupDecorate *addGroupDecorate(SPRVDecorationGroup *Group,
      const std::vector<SPRVEntry *> &Targets);
  virtual SPRVGroupDecorateGeneric *addGroupDecorateGeneric(
      SPRVGroupDecorateGeneric *GDec);
  virtual SPRVGroupMemberDecorate *addGroupMemberDecorate(
      SPRVDecorationGroup *Group, const std::vector<SPRVEntry *> &Targets);
  virtual void addEntryPoint(SPRVExecutionModelKind ExecModel,
      SPRVId EntryPoint);
  virtual SPRVForward *addForward();
  virtual SPRVForward *addForward(SPRVId);
  virtual SPRVFunction *addFunction(SPRVFunction *);
  virtual SPRVFunction *addFunction(SPRVTypeFunction *, SPRVId);
  virtual SPRVEntry *replaceForward(SPRVForward *, SPRVEntry *);

  // Type creation functions
  template<class T> T * addType(T *Ty);
  virtual SPRVTypeArray *addArrayType(SPRVType *, SPRVConstant *);
  virtual SPRVTypeBool *addBoolType();
  virtual SPRVTypeFloat *addFloatType(unsigned BitWidth);
  virtual SPRVTypeFunction *addFunctionType(SPRVType *,
      const std::vector<SPRVType *> &);
  virtual SPRVTypeInt *addIntegerType(unsigned BitWidth);
  virtual SPRVTypeOpaque *addOpaqueType(const std::string &);
  virtual SPRVTypePointer *addPointerType(SPRVStorageClassKind, SPRVType *);
  virtual SPRVTypeImage *addImageType(SPRVType *,
      const SPRVTypeImageDescriptor &);
  virtual SPRVTypeImage *addImageType(SPRVType *,
      const SPRVTypeImageDescriptor &, SPRVAccessQualifierKind);
  virtual SPRVTypeSampler *addSamplerType();
  virtual SPRVTypeSampledImage *addSampledImageType(SPRVTypeImage *T);
  virtual SPRVTypeStruct *addStructType(const std::vector<SPRVType *>&,
      const std::string &, bool);
  virtual SPRVTypeVector *addVectorType(SPRVType *, SPRVWord);
  virtual SPRVType *addOpaqueGenericType(SPRVOpCode);
  virtual SPRVTypePipe *addPipeType();
  virtual SPRVTypeVoid *addVoidType();

  // Constant creation functions
  virtual SPRVInstruction *addBranchInst(SPRVLabel *, SPRVBasicBlock *);
  virtual SPRVInstruction *addBranchConditionalInst(SPRVValue *, SPRVLabel *,
      SPRVLabel *, SPRVBasicBlock *);
  virtual SPRVValue *addCompositeConstant(SPRVType *,
      const std::vector<SPRVValue*>&);
  virtual SPRVValue *addConstant(SPRVValue *);
  virtual SPRVValue *addConstant(SPRVType *, uint64_t);
  virtual SPRVValue *addDoubleConstant(SPRVTypeFloat *, double);
  virtual SPRVValue *addFloatConstant(SPRVTypeFloat *, float);
  virtual SPRVValue *addIntegerConstant(SPRVTypeInt *, uint64_t);
  virtual SPRVValue *addNullConstant(SPRVType *);
  virtual SPRVValue *addUndef(SPRVType *TheType);
  virtual SPRVValue *addSamplerConstant(SPRVType *TheType, SPRVWord AddrMode,
      SPRVWord ParametricMode, SPRVWord FilterMode);

  // Instruction creation functions
  virtual SPRVInstruction *addPtrAccessChainInst(SPRVType *, SPRVValue *,
      std::vector<SPRVValue *>, SPRVBasicBlock *, bool);
  virtual SPRVInstruction *addAsyncGroupCopy(SPRVExecutionScopeKind Scope,
      SPRVValue *Dest, SPRVValue *Src, SPRVValue *NumElems, SPRVValue *Stride,
      SPRVValue *Event, SPRVBasicBlock *BB);
  virtual SPRVInstruction *addExtInst(SPRVType *,
      SPRVWord, SPRVWord, const std::vector<SPRVWord> &,
      SPRVBasicBlock *);
  virtual SPRVInstruction *addExtInst(SPRVType *,
      SPRVWord, SPRVWord, const std::vector<SPRVValue *> &,
      SPRVBasicBlock *);
  virtual SPRVInstruction *addBinaryInst(SPRVOpCode, SPRVType *, SPRVValue *,
      SPRVValue *, SPRVBasicBlock *);
  virtual SPRVInstruction *addCallInst(SPRVFunction*,
      const std::vector<SPRVValue *>, SPRVBasicBlock *);
  virtual SPRVInstruction *addCmpInst(SPRVOpCode, SPRVType *, SPRVValue *,
      SPRVValue *, SPRVBasicBlock *);
  virtual SPRVInstruction *addLoadInst(SPRVValue *,
      const std::vector<SPRVWord>&, SPRVBasicBlock *);
  virtual SPRVInstruction *addPhiInst(SPRVType *, std::vector<SPRVValue *>,
      SPRVBasicBlock *);
  virtual SPRVInstruction *addCompositeExtractInst(SPRVType *, SPRVValue *,
      const std::vector<SPRVWord>&, SPRVBasicBlock *);
  virtual SPRVInstruction *addCompositeInsertInst(SPRVValue *Object,
      SPRVValue *Composite, const std::vector<SPRVWord>& Indices,
      SPRVBasicBlock *BB);
  virtual SPRVInstruction *addCopyObjectInst(SPRVType *TheType,
      SPRVValue *Operand, SPRVBasicBlock *BB);
  virtual SPRVInstruction *addCopyMemoryInst(SPRVValue *, SPRVValue *,
    const std::vector<SPRVWord>&, SPRVBasicBlock *);
  virtual SPRVInstruction *addCopyMemorySizedInst(SPRVValue *, SPRVValue *,
      SPRVValue *, const std::vector<SPRVWord>&, SPRVBasicBlock *);
  virtual SPRVInstruction *addControlBarrierInst(
      SPRVExecutionScopeKind ExecKind, SPRVMemoryScopeKind MemKind,
      SPRVWord MemSema, SPRVBasicBlock *BB);
  virtual SPRVInstruction *addGroupInst(SPRVOpCode OpCode, SPRVType *Type,
      SPRVExecutionScopeKind Scope, const std::vector<SPRVValue *> &Ops,
      SPRVBasicBlock *BB);
  virtual SPRVInstruction *addInstruction(SPRVInstruction *Inst,
      SPRVBasicBlock *BB);
  virtual SPRVInstruction *addInstTemplate(SPRVOpCode OC,
      const std::vector<SPRVWord>& Ops, SPRVBasicBlock* BB, SPRVType *Ty);
  virtual SPRVInstruction *addMemoryBarrierInst(
      SPRVExecutionScopeKind ScopeKind, SPRVWord MemFlag, SPRVBasicBlock *BB);
  virtual SPRVInstruction *addReturnInst(SPRVBasicBlock *);
  virtual SPRVInstruction *addReturnValueInst(SPRVValue *, SPRVBasicBlock *);
  virtual SPRVInstruction *addSelectInst(SPRVValue *, SPRVValue *, SPRVValue *,
      SPRVBasicBlock *);
  virtual SPRVInstruction *addStoreInst(SPRVValue *, SPRVValue *,
      const std::vector<SPRVWord>&, SPRVBasicBlock *);
  virtual SPRVInstruction *addSwitchInst(SPRVValue *, SPRVBasicBlock *,
      const std::vector<std::pair<SPRVWord, SPRVBasicBlock *>>&,
      SPRVBasicBlock *);
  virtual SPRVInstruction *addUnaryInst(SPRVOpCode, SPRVType *, SPRVValue *,
      SPRVBasicBlock *);
  virtual SPRVInstruction *addVariable(SPRVType *, bool, SPRVLinkageTypeKind,
    SPRVValue *, const std::string &, SPRVStorageClassKind, SPRVBasicBlock *);
  virtual SPRVValue *addVectorShuffleInst(SPRVType *Type, SPRVValue *Vec1,
      SPRVValue *Vec2, const std::vector<SPRVWord> &Components,
      SPRVBasicBlock *BB);
  virtual SPRVInstruction *addVectorExtractDynamicInst(SPRVValue *,
      SPRVValue *, SPRVBasicBlock *);
  virtual SPRVInstruction *addVectorInsertDynamicInst(SPRVValue *,
    SPRVValue *, SPRVValue*, SPRVBasicBlock *);

  // I/O functions
  friend std::ostream & operator<<(std::ostream &O, SPRVModule& M);
  friend std::istream & operator>>(std::istream &I, SPRVModule& M);

private:
  SPRVErrorLog ErrLog;
  SPRVId NextId;
  SPRVTypeInt *BoolType;
  SPRVVersionKind SPRVVersion;
  SPRVGeneratorKind SPRVGenerator;
  SPRVInstructionSchemaKind InstSchema;
  SPRVSourceLanguageKind SrcLang;
  SPRVWord SrcLangVer;
  std::string SrcExtension;
  std::string SPRVExt;
  std::string CompileFlag;
  SPRVAddressingModelKind AddrModel;
  SPRVMemoryModelKind MemoryModel;

  typedef std::map<SPRVId, SPRVEntry *> SPRVIdToEntryMap;
  typedef std::vector<SPRVEntry *> SPRVEntryVector;
  typedef std::set<SPRVId> SPRVIdSet;
  typedef std::vector<SPRVId> SPRVIdVec;
  typedef std::vector<SPRVFunction *> SPRVFunctionVector;
  typedef std::vector<SPRVType *> SPRVTypeVec;
  typedef std::vector<SPRVValue *> SPRVConstantVector;
  typedef std::vector<SPRVVariable *> SPRVVariableVec;
  typedef std::vector<SPRVString *> SPRVStringVec;
  typedef std::vector<SPRVMemberName *> SPRVMemberNameVec;
  typedef std::vector<SPRVLine *> SPRVLineVec;
  typedef std::vector<SPRVDecorationGroup *> SPRVDecGroupVec;
  typedef std::vector<SPRVGroupDecorateGeneric *> SPRVGroupDecVec;
  typedef std::map<SPRVId, SPRVExtInstSetKind> SPRVIdToBuiltinSetMap;
  typedef std::map<SPRVExecutionModelKind, SPRVIdSet> SPRVExecModelIdSetMap;
  typedef std::map<SPRVExecutionModelKind, SPRVIdVec> SPRVExecModelIdVecMap;
  typedef std::unordered_map<std::string, SPRVString*> SPRVStringMap;

  SPRVTypeVec TypeVec;
  SPRVIdToEntryMap IdEntryMap;
  SPRVFunctionVector FuncVec;
  SPRVConstantVector ConstVec;
  SPRVVariableVec VariableVec;
  SPRVEntryVector EntryNoId;         // Entries without id
  SPRVIdToBuiltinSetMap IdBuiltinMap;
  SPRVIdSet NamedId;
  SPRVStringVec StringVec;
  SPRVMemberNameVec MemberNameVec;
  SPRVLineVec LineVec;
  SPRVDecorateSet DecorateSet;
  SPRVDecGroupVec DecGroupVec;
  SPRVGroupDecVec GroupDecVec;
  SPRVExecModelIdSetMap EntryPointSet;
  SPRVExecModelIdVecMap EntryPointVec;
  SPRVStringMap StrMap;
  SPRVCapSet CapSet;

  void layoutEntry(SPRVEntry* Entry);
};

SPRVModuleImpl::~SPRVModuleImpl() {
  //ToDo: Fix bug causing crash
  //for (auto I:IdEntryMap)
  //  delete I.second;

  // ToDo: Fix bug causing crash
  //for (auto I:EntryNoId) {
  //  bildbgs() << "[delete] " << *I;
  //  delete I;
  //}
}

SPRVLine*
SPRVModuleImpl::addLine(SPRVEntry* E, SPRVString* FileName,
    SPRVWord Line, SPRVWord Column) {
  auto L = add(new SPRVLine(E, FileName->getId(), Line, Column));
  E->setLine(L);
  return L;
}

// Creates decoration group and group decorates from decorates shared by
// multiple targets.
void
SPRVModuleImpl::optimizeDecorates() {
  SPRVDBG(bildbgs() << "[optimizeDecorates] begin\n");
  for (auto I = DecorateSet.begin(), E = DecorateSet.end(); I != E;) {
    auto D = *I;
    SPRVDBG(bildbgs() << "  check " << *D << '\n');
    if (D->getOpCode() == SPRVOC_OpMemberDecorate) {
      ++I;
      continue;
    }
    auto ER = DecorateSet.equal_range(D);
    SPRVDBG(bildbgs() << "  equal range " << **ER.first
                      << " to ";
            if (ER.second != DecorateSet.end())
              bildbgs() << **ER.second;
            else
              bildbgs() << "end";
            bildbgs() << '\n');
    if (std::distance(ER.first, ER.second) < 2) {
      I = ER.second;
      SPRVDBG(bildbgs() << "  skip equal range \n");
      continue;
    }
    SPRVDBG(bildbgs() << "  add deco group. erase equal range\n");
    auto G = new SPRVDecorationGroup(this, getId());
    std::vector<SPRVId> Targets;
    G->getDecorations().insert(D);
    Targets.push_back(D->getTargetId());
    for (I = ER.first; I != ER.second; ++I) {
      auto E = *I;
      if (*E == *D)
        continue;
      Targets.push_back(E->getTargetId());
    }
    DecorateSet.erase(ER.first, ER.second);
    auto GD = new SPRVGroupDecorate(G, Targets);
    DecGroupVec.push_back(G);
    GroupDecVec.push_back(GD);
  }
}

SPRVValue*
SPRVModuleImpl::addSamplerConstant(SPRVType* TheType,
    SPRVWord AddrMode, SPRVWord ParametricMode, SPRVWord FilterMode) {
  return addConstant(new SPRVConstantSampler(this, TheType, getId(), AddrMode,
      ParametricMode, FilterMode));
}

void
SPRVModuleImpl::addCapability(SPRVCapabilityKind Cap) {
  CapSet.insert(Cap);
}

void
SPRVModuleImpl::addCapabilityInternal(SPRVCapabilityKind Cap) {
  if (AutoAddCapability)
    CapSet.insert(Cap);
}

void
SPRVModuleImpl::layoutEntry(SPRVEntry* E) {
  auto OC = E->getOpCode();
  switch (OC) {
  case SPRVOC_OpString:
    addTo(StringVec, E);
    break;
  case SPRVOC_OpMemberName:
    addTo(MemberNameVec, E);
    break;
  case SPRVOC_OpLine:
    addTo(LineVec, E);
    break;
  case SPRVOC_OpVariable: {
    auto BV = static_cast<SPRVVariable*>(E);
    if (!BV->getParent())
      addTo(VariableVec, E);
    }
    break;
  default:
    if (isTypeOpCode(OC))
      TypeVec.push_back(static_cast<SPRVType*>(E));
    else if (isConstantOpCode(OC))
      ConstVec.push_back(static_cast<SPRVConstant*>(E));
    break;
  }
}

// Add an entry to the id to entry map.
// Assert if the id is mapped to a different entry.
// Certain entries need to be add to specific collectors to maintain
// logic layout of SPRV.
SPRVEntry *
SPRVModuleImpl::addEntry(SPRVEntry *Entry) {
  assert(Entry && "Invalid entry");
  if (Entry->hasId()) {
    SPRVId Id = Entry->getId();
    assert(Entry->getId() != SPRVID_INVALID && "Invalid id");
    SPRVEntry *Mapped = nullptr;
    if (exist(Id, &Mapped)) {
      if (Mapped->getOpCode() == SPRVOC_OpForward) {
        replaceForward(static_cast<SPRVForward *>(Mapped), Entry);
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
      if (I != SPRVCAP_None)
        addCapability(I);
    }
  }
  if (ValidateCapability) {
    for (auto &I:Entry->getRequiredCapability()) {
      if (I != SPRVCAP_None)
        assert(CapSet.count(I));
    }
  }
  return Entry;
}

bool
SPRVModuleImpl::exist(SPRVId Id) const {
  return exist(Id, nullptr);
}

bool
SPRVModuleImpl::exist(SPRVId Id, SPRVEntry **Entry) const {
  assert (Id != SPRVID_INVALID && "Invalid Id");
  SPRVIdToEntryMap::const_iterator Loc = IdEntryMap.find(Id);
  if (Loc == IdEntryMap.end())
    return false;
  if (Entry)
    *Entry = Loc->second;
  return true;
}

// If Id is invalid, returns the next available id.
// Otherwise returns the given id and adjust the next available id by increment.
SPRVId
SPRVModuleImpl::getId(SPRVId Id, unsigned increment) {
  if (!isValid(Id))
    Id = NextId;
  else
    NextId = std::max(Id, NextId);
  NextId += increment;
  return Id;
}

SPRVEntry *
SPRVModuleImpl::getEntry(SPRVId Id) const {
  assert (Id != SPRVID_INVALID && "Invalid Id");
  SPRVIdToEntryMap::const_iterator Loc = IdEntryMap.find(Id);
  assert (Loc != IdEntryMap.end() && "Id is not in map");
  return Loc->second;
}

SPRVExtInstSetKind
SPRVModuleImpl::getBuiltinSet(SPRVId SetId) const {
  auto Loc = IdBuiltinMap.find(SetId);
  assert(Loc != IdBuiltinMap.end() && "Invalid builtin set id");
  return Loc->second;
}

bool
SPRVModuleImpl::isEntryPoint(SPRVExecutionModelKind ExecModel, SPRVId EP)
  const {
  assert(isValid(ExecModel) && "Invalid execution model");
  assert(EP != SPRVID_INVALID && "Invalid function id");
  auto Loc = EntryPointSet.find(ExecModel);
  if (Loc == EntryPointSet.end())
    return false;
  return Loc->second.count(EP);
}

// Module change functions
bool
SPRVModuleImpl::importBuiltinSet(const std::string& BuiltinSetName,
    SPRVId *BuiltinSetId) {
  SPRVId TmpBuiltinSetId = getId();
  if (!importBuiltinSetWithId(BuiltinSetName, TmpBuiltinSetId))
    return false;
  if (BuiltinSetId)
    *BuiltinSetId = TmpBuiltinSetId;
  return true;
}

bool
SPRVModuleImpl::importBuiltinSetWithId(const std::string& BuiltinSetName,
    SPRVId BuiltinSetId) {
  SPRVExtInstSetKind BuiltinSet = SPRVBIS_Count;
  SPRVCKRT(SPRVBuiltinSetNameMap::rfind(BuiltinSetName, &BuiltinSet),
      InvalidBuiltinSetName, "Actual is " + BuiltinSetName);
  IdBuiltinMap[BuiltinSetId] = BuiltinSet;
  return true;
}

void
SPRVModuleImpl::setAlignment(SPRVValue *V, SPRVWord A) {
  V->setAlignment(A);
}

void
SPRVModuleImpl::setName(SPRVEntry *E, const std::string &Name) {
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
SPRVModuleImpl::addType(T *Ty) {
  add(Ty);
  if (!Ty->getName().empty())
    setName(Ty, Ty->getName());
  return Ty;
}

SPRVTypeVoid *
SPRVModuleImpl::addVoidType() {
  return addType(new SPRVTypeVoid(this, getId()));
}

SPRVTypeArray *
SPRVModuleImpl::addArrayType(SPRVType *ElementType, SPRVConstant *Length) {
  return addType(new SPRVTypeArray(this, getId(), ElementType, Length));
}

SPRVTypeBool *
SPRVModuleImpl::addBoolType() {
  return addType(new SPRVTypeBool(this, getId()));
}

SPRVTypeInt *
SPRVModuleImpl::addIntegerType(unsigned BitWidth) {
  return addType(new SPRVTypeInt(this, getId(), BitWidth, false));
}

SPRVTypeFloat *
SPRVModuleImpl::addFloatType(unsigned BitWidth) {
  SPRVTypeFloat *T = addType(new SPRVTypeFloat(this, getId(), BitWidth));
  return T;
}

SPRVTypePointer *
SPRVModuleImpl::addPointerType(SPRVStorageClassKind StorageClass,
    SPRVType *ElementType) {
  return addType(new SPRVTypePointer(this, getId(), StorageClass,
      ElementType));
}

SPRVTypeFunction *
SPRVModuleImpl::addFunctionType(SPRVType *ReturnType,
    const std::vector<SPRVType *>& ParameterTypes) {
  return addType(new SPRVTypeFunction(this, getId(), ReturnType,
      ParameterTypes));
}

SPRVTypeOpaque*
SPRVModuleImpl::addOpaqueType(const std::string& Name) {
  return addType(new SPRVTypeOpaque(this, getId(), Name));
}

SPRVTypeStruct*
SPRVModuleImpl::addStructType(const std::vector<SPRVType*> &MemberTypes,
    const std::string &Name, bool Packed) {
  auto T = new SPRVTypeStruct(this, getId(), MemberTypes, Name);
  addType(T);
  T->setPacked(Packed);
  return T;
}

SPRVTypeVector*
SPRVModuleImpl::addVectorType(SPRVType* CompType, SPRVWord CompCount) {
  return addType(new SPRVTypeVector(this, getId(), CompType, CompCount));
}
SPRVType *
SPRVModuleImpl::addOpaqueGenericType(SPRVOpCode TheOpCode) {
  return addType(new SPRVTypeOpaqueGeneric(TheOpCode, this, getId()));
}
SPRVTypePipe*
SPRVModuleImpl::addPipeType() {
  return addType(new SPRVTypePipe(this, getId()));
}

SPRVTypeImage *
SPRVModuleImpl::addImageType(SPRVType *SampledType,
    const SPRVTypeImageDescriptor &Desc) {
  return addType(new SPRVTypeImage(this, getId(),
    SampledType ? SampledType->getId() : 0, Desc));
}

SPRVTypeImage *
SPRVModuleImpl::addImageType(SPRVType *SampledType,
    const SPRVTypeImageDescriptor &Desc, SPRVAccessQualifierKind Acc) {
  return addType(new SPRVTypeImage(this, getId(),
    SampledType ? SampledType->getId() : 0, Desc, Acc));
}

SPRVTypeSampler *
SPRVModuleImpl::addSamplerType() {
  return addType(new SPRVTypeSampler(this, getId()));
}

SPRVTypeSampledImage *
SPRVModuleImpl::addSampledImageType(SPRVTypeImage *T) {
  return addType(new SPRVTypeSampledImage(this, getId(), T));
}

SPRVFunction *
SPRVModuleImpl::addFunction(SPRVFunction *Func) {
  FuncVec.push_back(add(Func));
  return Func;
}

SPRVFunction *
SPRVModuleImpl::addFunction(SPRVTypeFunction *FuncType, SPRVId Id) {
  return addFunction(new SPRVFunction(this, FuncType,
      getId(Id, FuncType->getNumParameters() + 1)));
}

SPRVBasicBlock *
SPRVModuleImpl::addBasicBlock(SPRVFunction *Func, SPRVId Id) {
  return Func->addBasicBlock(new SPRVBasicBlock(getId(Id), Func));
}

const SPRVDecorateGeneric *
SPRVModuleImpl::addDecorate(const SPRVDecorateGeneric *Dec) {
  SPRVId Id = Dec->getTargetId();
  SPRVEntry *Target = nullptr;
  bool Found = exist(Id, &Target);
  assert (Found && "Decorate target does not exist");
  if (!Dec->getOwner())
    DecorateSet.insert(Dec);
  return Dec;
}

void
SPRVModuleImpl::addEntryPoint(SPRVExecutionModelKind ExecModel,
    SPRVId EntryPoint){
  assert(isValid(ExecModel) && "Invalid execution model");
  assert(EntryPoint != SPRVID_INVALID && "Invalid entry point");
  EntryPointSet[ExecModel].insert(EntryPoint);
  EntryPointVec[ExecModel].push_back(EntryPoint);
}

SPRVForward *
SPRVModuleImpl::addForward() {
  return add(new SPRVForward(this, getId()));
}

SPRVForward *
SPRVModuleImpl::addForward(SPRVId Id) {
  return add(new SPRVForward(this, Id));
}

SPRVEntry *
SPRVModuleImpl::replaceForward(SPRVForward *Forward, SPRVEntry *Entry) {
  SPRVId Id = Entry->getId();
  SPRVId ForwardId = Forward->getId();
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

SPRVValue *
SPRVModuleImpl::addConstant(SPRVValue *C) {
  return add(C);
}

SPRVValue *
SPRVModuleImpl::addConstant(SPRVType *Ty, uint64_t V) {
  if (Ty->isTypeBool()) {
    if (V)
      return new SPRVConstantTrue(this, Ty, getId());
    else
      return new SPRVConstantFalse(this, Ty, getId());
  }
  return addConstant(new SPRVConstant(this, Ty, getId(), V));
}

SPRVValue *
SPRVModuleImpl::addIntegerConstant(SPRVTypeInt *Ty, uint64_t V) {
  return addConstant(new SPRVConstant(this, Ty, getId(), V));
}

SPRVValue *
SPRVModuleImpl::addFloatConstant(SPRVTypeFloat *Ty, float V) {
  return addConstant(new SPRVConstant(this, Ty, getId(), V));
}

SPRVValue *
SPRVModuleImpl::addDoubleConstant(SPRVTypeFloat *Ty, double V) {
  return addConstant(new SPRVConstant(this, Ty, getId(), V));
}

SPRVValue *
SPRVModuleImpl::addNullConstant(SPRVType *Ty) {
  return addConstant(new SPRVConstantNull(this, Ty, getId()));
}

SPRVValue *
SPRVModuleImpl::addCompositeConstant(SPRVType *Ty,
    const std::vector<SPRVValue*>& Elements) {
  return addConstant(new SPRVConstantComposite(this, Ty, getId(), Elements));
}

SPRVValue *
SPRVModuleImpl::addUndef(SPRVType *TheType) {
  return addConstant(new SPRVUndef(this, TheType, getId()));
}

// Instruction creation functions

SPRVInstruction *
SPRVModuleImpl::addStoreInst(SPRVValue *Target, SPRVValue *Source,
    const std::vector<SPRVWord> &TheMemoryAccess, SPRVBasicBlock *BB) {
  return BB->addInstruction(new SPRVStore(getId(), Target->getId(),
      Source->getId(), TheMemoryAccess, BB));
}

SPRVInstruction *
SPRVModuleImpl::addSwitchInst(SPRVValue *Select, SPRVBasicBlock *Default,
    const std::vector<std::pair<SPRVWord, SPRVBasicBlock *>>& Pairs,
    SPRVBasicBlock *BB) {
  return BB->addInstruction(new SPRVSwitch(Select, Default, Pairs, BB));
}

SPRVInstruction *
SPRVModuleImpl::addGroupInst(SPRVOpCode OpCode, SPRVType *Type,
    SPRVExecutionScopeKind Scope, const std::vector<SPRVValue *> &Ops,
    SPRVBasicBlock *BB) {
  auto WordOps = getIds(Ops);
  WordOps.insert(WordOps.begin(), Scope);
  return addInstTemplate(OpCode, WordOps, BB, Type);
}

SPRVInstruction *
SPRVModuleImpl::addInstruction(SPRVInstruction *Inst, SPRVBasicBlock *BB) {
  if (BB)
    return BB->addInstruction(Inst);
  if (Inst->getOpCode() != SPRVOC_OpSpecConstantOp)
    Inst = createSpecConstantOpInst(Inst);
  return static_cast<SPRVInstruction *>(addConstant(Inst));
}

SPRVInstruction *
SPRVModuleImpl::addLoadInst(SPRVValue *Source,
    const std::vector<SPRVWord> &TheMemoryAccess, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVLoad(getId(), Source->getId(),
      TheMemoryAccess, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addPhiInst(SPRVType *Type,
    std::vector<SPRVValue *> IncomingPairs, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVPhi(Type, getId(), IncomingPairs, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addExtInst(SPRVType *TheType, SPRVWord BuiltinSet,
    SPRVWord EntryPoint, const std::vector<SPRVWord> &Args,
    SPRVBasicBlock *BB) {
  return addInstruction(new SPRVExtInst(TheType, getId(),
      BuiltinSet, EntryPoint, Args, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addExtInst(SPRVType *TheType, SPRVWord BuiltinSet,
    SPRVWord EntryPoint, const std::vector<SPRVValue *> &Args,
    SPRVBasicBlock *BB) {
  return addInstruction(new SPRVExtInst(TheType, getId(),
      BuiltinSet, EntryPoint, Args, BB), BB);
}

SPRVInstruction*
SPRVModuleImpl::addCallInst(SPRVFunction* TheFunction,
    const std::vector<SPRVValue *> TheArguments, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVFunctionCall(getId(), TheFunction,
      TheArguments, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addBinaryInst(SPRVOpCode TheOpCode, SPRVType *Type,
    SPRVValue *Op1, SPRVValue *Op2, SPRVBasicBlock *BB){
  return addInstruction(SPRVInstTemplateBase::create(TheOpCode, Type, getId(),
      getVec(Op1->getId(), Op2->getId()), BB, this), BB);
}

SPRVInstruction *
SPRVModuleImpl::addReturnInst(SPRVBasicBlock *BB) {
  return addInstruction(new SPRVReturn(BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addReturnValueInst(SPRVValue *ReturnValue, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVReturnValue(ReturnValue, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addUnaryInst(SPRVOpCode TheOpCode, SPRVType *TheType,
    SPRVValue *Op, SPRVBasicBlock *BB) {
  return addInstruction(SPRVInstTemplateBase::create(TheOpCode,
      TheType, getId(), getVec(Op->getId()), BB, this), BB);
}

SPRVInstruction *
SPRVModuleImpl::addVectorExtractDynamicInst(SPRVValue *TheVector,
    SPRVValue *Index, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVVectorExtractDynamic(getId(), TheVector,
      Index, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addVectorInsertDynamicInst(SPRVValue *TheVector,
SPRVValue *TheComponent, SPRVValue*Index, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVVectorInsertDynamic(getId(), TheVector,
      TheComponent, Index, BB), BB);
}

SPRVValue *
SPRVModuleImpl::addVectorShuffleInst(SPRVType * Type, SPRVValue *Vec1,
    SPRVValue *Vec2, const std::vector<SPRVWord> &Components,
    SPRVBasicBlock *BB) {
  return addInstruction(new SPRVVectorShuffle(getId(), Type, Vec1, Vec2,
      Components, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addBranchInst(SPRVLabel *TargetLabel, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVBranch(TargetLabel, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addBranchConditionalInst(SPRVValue *Condition,
    SPRVLabel *TrueLabel, SPRVLabel *FalseLabel, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVBranchConditional(Condition, TrueLabel,
      FalseLabel, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addCmpInst(SPRVOpCode TheOpCode, SPRVType *TheType,
    SPRVValue *Op1, SPRVValue *Op2, SPRVBasicBlock *BB) {
  return addInstruction(SPRVInstTemplateBase::create(TheOpCode,
      TheType, getId(), getVec(Op1->getId(), Op2->getId()), BB, this), BB);
}

SPRVInstruction *
SPRVModuleImpl::addControlBarrierInst(SPRVExecutionScopeKind ExecKind,
    SPRVMemoryScopeKind MemKind, SPRVWord MemSema, SPRVBasicBlock *BB) {
  return addInstruction(
      new SPRVControlBarrier(ExecKind, MemKind, MemSema, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addMemoryBarrierInst(SPRVExecutionScopeKind ScopeKind,
    SPRVWord MemFlag, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVMemoryBarrier(ScopeKind, MemFlag, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addSelectInst(SPRVValue *Condition, SPRVValue *Op1,
    SPRVValue *Op2, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVSelect(getId(), Condition->getId(),
      Op1->getId(), Op2->getId(), BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addPtrAccessChainInst(SPRVType *Type, SPRVValue *Base,
    std::vector<SPRVValue *> Indices, SPRVBasicBlock *BB, bool IsInBounds){
  return addInstruction(SPRVInstTemplateBase::create(
    IsInBounds?SPRVOC_OpInBoundsPtrAccessChain:SPRVOC_OpPtrAccessChain,
    Type, getId(), getVec(Base->getId(), Base->getIds(Indices)),
    BB, this), BB);
}

SPRVInstruction *
SPRVModuleImpl::addAsyncGroupCopy(SPRVExecutionScopeKind Scope,
    SPRVValue *Dest, SPRVValue *Src, SPRVValue *NumElems, SPRVValue *Stride,
    SPRVValue *Event, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVAsyncGroupCopy(Scope, getId(), Dest, Src,
    NumElems, Stride, Event, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addCompositeExtractInst(SPRVType *Type, SPRVValue *TheVector,
    const std::vector<SPRVWord>& Indices, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVCompositeExtract(Type, getId(), TheVector,
      Indices, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addCompositeInsertInst(SPRVValue *Object,
    SPRVValue *Composite, const std::vector<SPRVWord>& Indices,
    SPRVBasicBlock *BB) {
  return addInstruction(new SPRVCompositeInsert(getId(), Object, Composite,
      Indices, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addCopyObjectInst(SPRVType *TheType, SPRVValue *Operand,
    SPRVBasicBlock *BB) {
  return addInstruction(new SPRVCopyObject(TheType, getId(), Operand, BB), BB);

}

SPRVInstruction *
SPRVModuleImpl::addCopyMemoryInst(SPRVValue *TheTarget, SPRVValue *TheSource,
    const std::vector<SPRVWord> &TheMemoryAccess, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVCopyMemory(TheTarget, TheSource,
      TheMemoryAccess, BB), BB);
}

SPRVInstruction *
SPRVModuleImpl::addCopyMemorySizedInst(SPRVValue *TheTarget,
    SPRVValue *TheSource, SPRVValue *TheSize,
    const std::vector<SPRVWord> &TheMemoryAccess, SPRVBasicBlock *BB) {
  return addInstruction(new SPRVCopyMemorySized(TheTarget, TheSource, TheSize,
    TheMemoryAccess, BB), BB);
}

SPRVInstruction*
SPRVModuleImpl::addVariable(SPRVType *Type, bool IsConstant,
    SPRVLinkageTypeKind LinkageType, SPRVValue *Initializer,
    const std::string &Name, SPRVStorageClassKind StorageClass,
    SPRVBasicBlock *BB) {
  SPRVVariable *Variable = new SPRVVariable(Type, getId(), Initializer,
      Name, StorageClass, BB, this);
  if (BB)
    return addInstruction(Variable, BB);

  add(Variable);
  if (LinkageType != SPRVLT_Internal)
    Variable->setLinkageType(LinkageType);
  Variable->setIsConstant(IsConstant);
  return Variable;
}

template<class T>
std::ostream &
operator<< (std::ostream &O, const std::vector<T *>& V) {
  for (auto &I: V)
    O << *I;
  return O;
}

template<class T, class B>
std::ostream &
operator<< (std::ostream &O, const std::multiset<T *, B>& V) {
  for (auto &I: V)
    O << *I;
  return O;
}

std::ostream &
operator<< (std::ostream &O, SPRVModule &M) {
  SPRVModuleImpl &MI = *static_cast<SPRVModuleImpl*>(&M);

  SPRVEncoder Encoder(O);
  Encoder << SPRVMagicNumber
          << MI.SPRVVersion
          << MI.SPRVGenerator
          << MI.NextId /* Bound for Id */
          << MI.InstSchema;
  O << SPRVNL;
  O << SPRVSource(&M);
  if (!M.getSourceExtension().empty())
    O << SPRVSourceExtension(&M);
  if (!M.getExtension().empty())
    O << SPRVExtension(&M);
  for (auto &I:MI.CapSet)
    O << SPRVCapability(&M, I);

  for (auto &I:MI.EntryPointVec)
    for (auto &II:I.second)
      O << SPRVEntryPoint(&M, I.first, II);

  for (auto &I:MI.EntryPointVec)
    for (auto &II:I.second)
      MI.get<SPRVFunction>(II)->encodeExecutionModes(O);

  for (auto &I:MI.IdBuiltinMap)
    O <<  SPRVExtInstImport(&M, I.first, SPRVBuiltinSetNameMap::map(I.second));

  O << SPRVMemoryModel(&M);

  O << MI.StringVec;

  for (auto &I:MI.NamedId)
    M.getEntry(I)->encodeName(O);

  O << MI.MemberNameVec
    << MI.LineVec
    << MI.DecGroupVec
    << MI.DecorateSet
    << MI.GroupDecVec
    << MI.TypeVec
    << MI.ConstVec
    << MI.VariableVec
    << SPRVNL
    << MI.FuncVec;
  return O;
}

template<class T>
void SPRVModuleImpl::addTo(std::vector<T*>& V, SPRVEntry* E) {
  V.push_back(static_cast<T *>(E));
}


// The first decoration group includes all the previously defined decorates.
// The second decoration group includes all the decorates defined between the
// first and second decoration group. So long so forth.
SPRVDecorationGroup*
SPRVModuleImpl::addDecorationGroup() {
  return addDecorationGroup(new SPRVDecorationGroup(this, getId()));
}

SPRVDecorationGroup*
SPRVModuleImpl::addDecorationGroup(SPRVDecorationGroup* Group) {
  add(Group);
  Group->takeDecorates(DecorateSet);
  DecGroupVec.push_back(Group);
  SPRVDBG(bildbgs() << "[addDecorationGroup] {" << *Group << "}\n";
          bildbgs() << "  Remaining DecorateSet: {" << DecorateSet << "}\n");
  assert(DecorateSet.empty());
  return Group;
}

SPRVGroupDecorateGeneric*
SPRVModuleImpl::addGroupDecorateGeneric(SPRVGroupDecorateGeneric *GDec) {
  add(GDec);
  GDec->decorateTargets();
  GroupDecVec.push_back(GDec);
  return GDec;
}
SPRVGroupDecorate*
SPRVModuleImpl::addGroupDecorate(
    SPRVDecorationGroup* Group, const std::vector<SPRVEntry*>& Targets) {
  auto GD = new SPRVGroupDecorate(Group, getIds(Targets));
  addGroupDecorateGeneric(GD);
  return GD;
}

SPRVGroupMemberDecorate*
SPRVModuleImpl::addGroupMemberDecorate(
    SPRVDecorationGroup* Group, const std::vector<SPRVEntry*>& Targets) {
  auto GMD = new SPRVGroupMemberDecorate(Group, getIds(Targets));
  addGroupDecorateGeneric(GMD);
  return GMD;
}

SPRVString*
SPRVModuleImpl::getString(const std::string& Str) {
  auto Loc = StrMap.find(Str);
  if (Loc != StrMap.end())
    return Loc->second;
  auto S = add(new SPRVString(this, getId(), Str));
  StrMap[Str] = S;
  return S;
}

SPRVMemberName*
SPRVModuleImpl::addMemberName(SPRVTypeStruct* ST,
    SPRVWord MemberNumber, const std::string& Name) {
  return add(new SPRVMemberName(ST, MemberNumber, Name));
}

std::istream &
operator>> (std::istream &I, SPRVModule &M) {
  SPRVDecoder Decoder(I, M);
  SPRVModuleImpl &MI = *static_cast<SPRVModuleImpl*>(&M);

  SPRVWord Magic;
  Decoder >> Magic;
  assert(Magic == SPRVMagicNumber && "Invalid magic number");

  Decoder >> MI.SPRVVersion;
  assert(MI.SPRVVersion == SPRVVER_100 && "Unsupported SPIRV version number");

  Decoder >> MI.SPRVGenerator;

  // Bound for Id
  Decoder >> MI.NextId;

  Decoder >> MI.InstSchema;
  assert(MI.InstSchema == SPRVISCH_Default && "Unsupported instruction schema");

  while(Decoder.getWordCountAndOpCode())
    Decoder.getEntry();

  MI.optimizeDecorates();
  return I;
}

SPRVModule *
SPRVModule::createSPRVModule() {
  return new SPRVModuleImpl;
}

SPRVValue *
SPRVModuleImpl::getValue(SPRVId TheId)const {
  return get<SPRVValue>(TheId);
}

SPRVType *
SPRVModuleImpl::getValueType(SPRVId TheId)const {
  return get<SPRVValue>(TheId)->getType();
}

std::vector<SPRVValue *>
SPRVModuleImpl::getValues(const std::vector<SPRVId>& IdVec)const {
  std::vector<SPRVValue *> ValueVec;
  for (auto i:IdVec)
    ValueVec.push_back(getValue(i));
  return ValueVec;
}

std::vector<SPRVType *>
SPRVModuleImpl::getValueTypes(const std::vector<SPRVId>& IdVec)const {
  std::vector<SPRVType *> TypeVec;
  for (auto i:IdVec)
    TypeVec.push_back(getValue(i)->getType());
  return TypeVec;
}

std::vector<SPRVId>
SPRVModuleImpl::getIds(const std::vector<SPRVEntry *> &ValueVec)const {
  std::vector<SPRVId> IdVec;
  for (auto i:ValueVec)
    IdVec.push_back(i->getId());
  return IdVec;
}

std::vector<SPRVId>
SPRVModuleImpl::getIds(const std::vector<SPRVValue *> &ValueVec)const {
  std::vector<SPRVId> IdVec;
  for (auto i:ValueVec)
    IdVec.push_back(i->getId());
  return IdVec;
}

SPRVInstruction*
SPRVModuleImpl::addInstTemplate(SPRVOpCode OC,
    const std::vector<SPRVWord>& Ops, SPRVBasicBlock* BB, SPRVType *Ty) {
  SPRVId Id = Ty ? getId() : SPRVID_INVALID;
  auto Ins = SPRVInstTemplateBase::create(OC, Ty, Id, Ops, BB, this);
  return BB->addInstruction(Ins);
}

SPRVDbgInfo::SPRVDbgInfo(SPRVModule *TM)
:M(TM){
}

std::string
SPRVDbgInfo::getEntryPointFileStr(SPRVExecutionModelKind EM, unsigned I) {
  if (M->getNumEntryPoints(EM) == 0)
    return "";
  return getFunctionFileStr(M->getEntryPoint(EM, I));
}

std::string
SPRVDbgInfo::getFunctionFileStr(SPRVFunction *F) {
  if (F->hasLine())
    return F->getLine()->getFileNameStr();
  return "";
}

unsigned
SPRVDbgInfo::getFunctionLineNo(SPRVFunction *F) {
  if (F->hasLine())
    return F->getLine()->getLine();
  return 0;
}

bool IsSPRVBinary(const std::string &Img) {
  if (Img.size() < sizeof(unsigned))
    return false;
  auto Magic = reinterpret_cast<const unsigned*>(Img.data());
  return *Magic == SPRVMagicNumber;
}

#ifdef _SPRV_SUPPORT_TEXT_FMT

bool ConvertSPRV(std::istream &IS, std::ostream &OS,
    std::string &ErrMsg, bool FromText, bool ToText) {
  auto SaveOpt = SPRVUseTextFormat;
  SPRVUseTextFormat = FromText;
  SPRVModuleImpl M;
  IS >> M;
  if (M.getError(ErrMsg) != SPRVEC_Success) {
    SPRVUseTextFormat = SaveOpt;
    return false;
  }
  SPRVUseTextFormat = ToText;
  OS << M;
  if (M.getError(ErrMsg) != SPRVEC_Success) {
    SPRVUseTextFormat = SaveOpt;
    return false;
  }
  SPRVUseTextFormat = SaveOpt;
  return true;
}

bool IsSPRVText(const std::string &Img) {
  std::istringstream SS(Img);
  unsigned Magic = 0;
  SS >> Magic;
  if (SS.bad())
    return false;
  return Magic == SPRVMagicNumber;
}

bool ConvertSPRV(std::string &Input, std::string &Out,
    std::string &ErrMsg, bool ToText) {
  auto FromText = IsSPRVText(Input);
  if (ToText == FromText) {
    Out = Input;
    return true;
  }
  std::istringstream IS(Input);
  std::ostringstream OS;
  if (!ConvertSPRV(IS, OS, ErrMsg, FromText, ToText))
    return false;
  Out = OS.str();
  return true;
}

#endif // _SPRV_SUPPORT_TEXT_FMT

}

