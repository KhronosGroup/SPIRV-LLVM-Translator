//===- SPRVEntry.cpp - Base Class for SPIR-V Entities -----------*- C++ -*-===//
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
/// This file implements base class for SPIR-V entities.
///
//===----------------------------------------------------------------------===//

#include "SPRVDebug.h"
#include "SPRVType.h"
#include "SPRVFunction.h"
#include "SPRVBasicBlock.h"
#include "SPRVInstruction.h"
#include "SPRVDecorate.h"
#include "SPRVStream.h"

#include <algorithm>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <utility>

using namespace SPRV;

namespace SPRV{

template<typename T>
SPRVEntry* create() {
  return new T();
}

SPRVEntry *
SPRVEntry::create(SPRVOpCode OpCode) {
  typedef SPRVEntry *(*SPRVFactoryTy)();
  struct TableEntry {
    SPRVOpCode Op;
    SPRVFactoryTy Factory;
    operator std::pair<const SPRVOpCode, SPRVFactoryTy>() {
      return std::make_pair(Op, Factory);
    }
  };

  static TableEntry Table[] = {
#define _SPRV_OP(x,...) {SPRVOC_Op##x, &SPRV::create<SPRV##x>},
#include "SPRVOpCodeEnum.h"
#undef _SPRV_OP
  };

  typedef std::map<SPRVOpCode, SPRVFactoryTy> OpToFactoryMapTy;
  static const OpToFactoryMapTy OpToFactoryMap(std::begin(Table),
      std::end(Table));

  OpToFactoryMapTy::const_iterator Loc = OpToFactoryMap.find(OpCode);
  if (Loc != OpToFactoryMap.end())
    return Loc->second();

  SPRVDBG(bildbgs() << "No factory for OpCode " << (unsigned)OpCode << '\n';)
  assert (0 && "Not implemented");
  return 0;
}

SPRVErrorLog &
SPRVEntry::getErrorLog()const {
  return Module->getErrorLog();
}

bool
SPRVEntry::exist(SPRVId TheId)const {
  return Module->exist(TheId);
}

SPRVEntry *
SPRVEntry::getOrCreate(SPRVId TheId)const {
  SPRVEntry *Entry = nullptr;
  bool Found = Module->exist(TheId, &Entry);
  if (!Found)
    return Module->addForward(TheId);
  return Entry;
}

SPRVValue *
SPRVEntry::getValue(SPRVId TheId)const {
  return get<SPRVValue>(TheId);
}

SPRVType *
SPRVEntry::getValueType(SPRVId TheId)const {
  return get<SPRVValue>(TheId)->getType();
}

SPRVEncoder
SPRVEntry::getEncoder(std::ostream &O)const{
  return SPRVEncoder(O);
}

SPRVDecoder
SPRVEntry::getDecoder(std::istream& I){
  return SPRVDecoder(I, *Module);
}

void
SPRVEntry::setWordCount(SPRVWord TheWordCount){
  WordCount = TheWordCount;
}

void
SPRVEntry::setName(const std::string& TheName) {
  Name = TheName;
  SPRVDBG(bildbgs() << "Set name for obj " << Id << " " <<
    Name << '\n');
}

void
SPRVEntry::setModule(SPRVModule *TheModule) {
  assert(TheModule && "Invalid module");
  if (TheModule == Module)
    return;
  assert(Module == NULL && "Cannot change owner of entry");
  Module = TheModule;
}

void
SPRVEntry::encode(std::ostream &O) const {
  assert (0 && "Not implemented");
}

void
SPRVEntry::encodeName(std::ostream &O) const {
  if (!Name.empty())
    O << SPRVName(this, Name);
}

void
SPRVEntry::encodeAll(std::ostream &O) const {
  encodeWordCountOpCode(O);
  encode(O);
  encodeChildren(O);
}

void
SPRVEntry::encodeChildren(std::ostream &O)const {
}

void
SPRVEntry::encodeWordCountOpCode(std::ostream &O) const {
#ifdef _SPRV_SUPPORT_TEXT_FMT
  if (SPRVUseTextFormat) {
    getEncoder(O) << WordCount << OpCode;
    return;
  }
#endif
  getEncoder(O) << mkWord(WordCount, OpCode);
}
// Read words from SPIRV binary and create members for SPRVEntry.
// The word count and op code has already been read before calling this
// function for creating the SPRVEntry. Therefore the input stream only
// contains the remaining part of the words for the SPRVEntry.
void
SPRVEntry::decode(std::istream &I) {
  assert (0 && "Not implemented");
}

std::vector<SPRVValue *>
SPRVEntry::getValues(const std::vector<SPRVId>& IdVec)const {
  std::vector<SPRVValue *> ValueVec;
  for (auto i:IdVec)
    ValueVec.push_back(getValue(i));
  return ValueVec;
}

std::vector<SPRVType *>
SPRVEntry::getValueTypes(const std::vector<SPRVId>& IdVec)const {
  std::vector<SPRVType *> TypeVec;
  for (auto i:IdVec)
    TypeVec.push_back(getValue(i)->getType());
  return TypeVec;
}

std::vector<SPRVId>
SPRVEntry::getIds(const std::vector<SPRVValue *> ValueVec)const {
  std::vector<SPRVId> IdVec;
  for (auto i:ValueVec)
    IdVec.push_back(i->getId());
  return IdVec;
}

SPRVEntry *
SPRVEntry::getEntry(SPRVId TheId) const {
  return Module->getEntry(TheId);
}

void
SPRVEntry::validateFunctionControlMask(SPRVWord TheFCtlMask)
  const {
  SPRVCK(TheFCtlMask <= (unsigned)SPRVFCM_Max,
      InvalidFunctionControlMask, "");
}

void
SPRVEntry::validateValues(const std::vector<SPRVId> &Ids)const {
  for (auto I:Ids)
    getValue(I)->validate();
}

void
SPRVEntry::validateBuiltin(SPRVWord TheSet, SPRVWord Index)const {
  assert(TheSet != SPRVWORD_MAX && Index != SPRVWORD_MAX &&
      "Invalid builtin");
}

void
SPRVEntry::addDecorate(const SPRVDecorate *Dec){
  auto Kind = Dec->getDecorateKind();
  Decorates.insert(std::make_pair(Dec->getDecorateKind(), Dec));
  Module->addDecorate(Dec);
  SPRVDBG(bildbgs() << "[addDecorate] " << *Dec << '\n';)
}

void
SPRVEntry::addDecorate(SPRVDecorateKind Kind) {
  addDecorate(new SPRVDecorate(Kind, this));
}

void
SPRVEntry::addDecorate(SPRVDecorateKind Kind, SPRVWord Literal) {
  addDecorate(new SPRVDecorate(Kind, this, Literal));
}

void
SPRVEntry::eraseDecorate(SPRVDecorateKind Dec){
  Decorates.erase(Dec);
}

void
SPRVEntry::takeDecorates(SPRVEntry *E){
  Decorates = std::move(E->Decorates);
  SPRVDBG(bildbgs() << "[takeDecorates] " << Id << '\n';)
}

void
SPRVEntry::setLine(SPRVLine *L){
  Line = L;
  L->setTargetId(Id);
  SPRVDBG(bildbgs() << "[setLine] " << *L << '\n';)
}

void
SPRVEntry::takeLine(SPRVEntry *E){
  Line = E->Line;
  if (Line == nullptr)
    return;
  Line->setTargetId(Id);
  E->Line = nullptr;
}

void
SPRVEntry::addMemberDecorate(const SPRVMemberDecorate *Dec){
  assert(canHaveMemberDecorates() && MemberDecorates.find(Dec->getPair()) ==
      MemberDecorates.end());
  MemberDecorates[Dec->getPair()] = Dec;
  Module->addDecorate(Dec);
  SPRVDBG(bildbgs() << "[addMemberDecorate] " << *Dec << '\n';)
}

void
SPRVEntry::addMemberDecorate(SPRVWord MemberNumber, SPRVDecorateKind Kind) {
  addMemberDecorate(new SPRVMemberDecorate(Kind, MemberNumber, this));
}

void
SPRVEntry::addMemberDecorate(SPRVWord MemberNumber, SPRVDecorateKind Kind,
    SPRVWord Literal) {
  addMemberDecorate(new SPRVMemberDecorate(Kind, MemberNumber, this, Literal));
}

void
SPRVEntry::eraseMemberDecorate(SPRVWord MemberNumber, SPRVDecorateKind Dec){
  MemberDecorates.erase(std::make_pair(MemberNumber, Dec));
}

void
SPRVEntry::takeMemberDecorates(SPRVEntry *E){
  MemberDecorates = std::move(E->MemberDecorates);
  SPRVDBG(bildbgs() << "[takeMemberDecorates] " << Id << '\n';)
}

void
SPRVEntry::takeAnnotations(SPRVForward *E){
  Module->setName(this, E->getName());
  takeDecorates(E);
  takeMemberDecorates(E);
  takeLine(E);
  if (OpCode == SPRVOC_OpFunction)
    static_cast<SPRVFunction *>(this)->takeExecutionModes(E);
}

// Check if an entry has Kind of decoration and get the literal of the
// first decoration of such kind at Index.
bool
SPRVEntry::hasDecorate(SPRVDecorateKind Kind, size_t Index, SPRVWord *Result)const {
  DecorateMapType::const_iterator Loc = Decorates.find(Kind);
  if (Loc == Decorates.end())
    return false;
  if (Result)
    *Result = Loc->second->getLiteral(Index);
  return true;
}

// Get literals of all decorations of Kind at Index.
std::set<SPRVWord>
SPRVEntry::getDecorate(SPRVDecorateKind Kind, size_t Index) const {
  auto Range = Decorates.equal_range(Kind);
  std::set<SPRVWord> Value;
  for (auto I = Range.first, E = Range.second; I != E; ++I) {
    assert(Index < I->second->getLiteralCount() && "Invalid index");
    Value.insert(I->second->getLiteral(Index));
  }
  return Value;
}

bool
SPRVEntry::hasLinkageType() const {
  return OpCode == SPRVOC_OpFunction || OpCode == SPRVOC_OpVariable;
}

void
SPRVEntry::encodeDecorate(std::ostream &O) const {
  for (auto& i:Decorates)
    O << *i.second;
}

SPRVLinkageTypeKind
SPRVEntry::getLinkageType() const {
  assert(hasLinkageType());
  SPRVWord LT = SPRVLT_Count;
  if (!hasDecorate(SPRVDEC_LinkageType, 0, &LT))
    return SPRVLT_Count;
  return static_cast<SPRVLinkageTypeKind>(LT);
}

void
SPRVEntry::setLinkageType(SPRVLinkageTypeKind LT) {
  assert(isValid(LT));
  assert(hasLinkageType());
  addDecorate(new SPRVDecorate(SPRVDEC_LinkageType, this, LT));
}

std::ostream &
operator<<(std::ostream &O, const SPRVEntry &E) {
  E.validate();
  E.encodeAll(O);
  O << SPRVNL;
  return O;
}

std::istream &
operator>>(std::istream &I, SPRVEntry &E) {
  E.decode(I);
  return I;
}

SPRVEntryPoint::SPRVEntryPoint(SPRVModule *TheModule,
    SPRVExecutionModelKind TheExecModel, SPRVId TheId)
      :SPRVEntryNoId(TheModule, 3), ExecModel(TheExecModel), FuncId(TheId) {

}
void
SPRVEntryPoint::encode(std::ostream &O) const {
  getEncoder(O) << ExecModel << FuncId;
}

void
SPRVEntryPoint::decode(std::istream &I) {
  getDecoder(I) >> ExecModel >> FuncId;
  Module->addEntryPoint(ExecModel, FuncId);
}

void
SPRVExecutionMode::encode(std::ostream &O) const {
  getEncoder(O) << Target << ExecMode << WordLiterals;
  if (ExecMode == SPRVEM_VecTypeHint)
    getEncoder(O) << StrLiteral;
}

void
SPRVExecutionMode::decode(std::istream &I) {
  getDecoder(I) >> Target >> ExecMode;
  switch(ExecMode) {
  case SPRVEM_LocalSize:
  case SPRVEM_LocalSizeHint:
    WordLiterals.resize(3);
    break;
  case SPRVEM_Invocations:
  case SPRVEM_OutputVertices:
  case SPRVEM_VecTypeHint:
    WordLiterals.resize(1);
    break;
  default:
    // Do nothing. Keep this to avoid VS2013 warning.
    break;
  }
  getDecoder(I) >> WordLiterals;
  if (ExecMode == SPRVEM_VecTypeHint)
    getDecoder(I) >> StrLiteral;
  getOrCreateTarget()->addExecutionMode(this);
}

SPRVForward *
SPRVAnnotationGeneric::getOrCreateTarget()const {
  SPRVEntry *Entry = nullptr;
  bool Found = Module->exist(Target, &Entry);
  assert((!Found || Entry->getOpCode() == SPRVOC_OpForward) &&
      "Annotations only allowed on forward");
  if (!Found)
    Entry = Module->addForward(Target);
  return static_cast<SPRVForward *>(Entry);
}

SPRVName::SPRVName(const SPRVEntry *TheTarget, const std::string& TheStr)
  :SPRVAnnotation(TheTarget, getSizeInWords(TheStr) + 2), Str(TheStr){
}

void
SPRVName::encode(std::ostream &O) const {
  getEncoder(O) << Target << Str;
}

void
SPRVName::decode(std::istream &I) {
  getDecoder(I) >> Target >> Str;
  Module->setName(getOrCreateTarget(), Str);
}

void
SPRVName::validate() const {
  assert(WordCount == getSizeInWords(Str) + 2 && "Incorrect word count");
}

_SPRV_IMP_ENCDEC2(SPRVString, Id, Str)
_SPRV_IMP_ENCDEC3(SPRVMemberName, Target, MemberNumber, Str)

void
SPRVLine::encode(std::ostream &O) const {
  getEncoder(O) << Target << FileName << Line << Column;
}

void
SPRVLine::decode(std::istream &I) {
  getDecoder(I) >> Target >> FileName >> Line >> Column;
  Module->addLine(getOrCreateTarget(), get<SPRVString>(FileName), Line, Column);
}

void
SPRVLine::validate() const {
  assert(OpCode == SPRVOC_OpLine);
  assert(WordCount == 5);
  assert(get<SPRVEntry>(Target));
  assert(get<SPRVEntry>(FileName)->getOpCode() == SPRVOC_OpString);
  assert(Line != SPRVWORD_MAX);
  assert(Column != SPRVWORD_MAX);
}

void
SPRVMemberName::validate() const {
  assert(OpCode == SPRVOC_OpMemberName);
  assert(WordCount == getSizeInWords(Str) + FixedWC);
  assert(get<SPRVEntry>(Target)->getOpCode() == SPRVOC_OpTypeStruct);
  assert(MemberNumber < get<SPRVTypeStruct>(Target)->getStructMemberCount());
}

SPRVExtInstImport::SPRVExtInstImport(SPRVModule *TheModule, SPRVId TheId,
    const std::string &TheStr):
  SPRVEntry(TheModule, 2 + getSizeInWords(TheStr), OC, TheId), Str(TheStr){
  validate();
}

void
SPRVExtInstImport::encode(std::ostream &O) const {
  getEncoder(O) << Id << Str;
}

void
SPRVExtInstImport::decode(std::istream &I) {
  getDecoder(I) >> Id >> Str;
  Module->importBuiltinSetWithId(Str, Id);
}

void
SPRVExtInstImport::validate() const {
  SPRVEntry::validate();
  assert(!Str.empty() && "Invalid builtin set");
}

void
SPRVMemoryModel::encode(std::ostream &O) const {
  getEncoder(O) << Module->getAddressingModel() <<
      Module->getMemoryModel();
}

void
SPRVMemoryModel::decode(std::istream &I) {
  SPRVAddressingModelKind AddrModel;
  SPRVMemoryModelKind MemModel;
  getDecoder(I) >> AddrModel >> MemModel;
  Module->setAddressingModel(AddrModel);
  Module->setMemoryModel(MemModel);
}

void
SPRVMemoryModel::validate() const {
  unsigned AM = Module->getAddressingModel();
  unsigned MM = Module->getMemoryModel();
  SPRVCK(AM < SPRVAM_Count, InvalidAddressingModel, "Actual is "+AM );
  SPRVCK(MM < SPRVMM_Count, InvalidMemoryModel, "Actual is "+MM);
}

void
SPRVSource::encode(std::ostream &O) const {
  SPRVWord Ver = SPRVWORD_MAX;
  auto Language = Module->getSourceLanguage(&Ver);
  getEncoder(O) << Language << Ver;
}

void
SPRVSource::decode(std::istream &I) {
  SPRVSourceLanguageKind Lang = SPRVSL_Count;
  SPRVWord Ver = SPRVWORD_MAX;
  getDecoder(I) >> Lang >> Ver;
  Module->setSourceLanguage(Lang, Ver);
}

SPRVSourceExtension::SPRVSourceExtension(SPRVModule *M)
  :SPRVEntryNoId(M, 1 + getSizeInWords(M->getSourceExtension())){}

void
SPRVSourceExtension::encode(std::ostream &O) const {
  getEncoder(O) << Module->getSourceExtension();
}

void
SPRVSourceExtension::decode(std::istream &I) {
  std::string S;
  getDecoder(I) >> S;
  Module->setSourceExtension(S);
}

SPRVExtension::SPRVExtension(SPRVModule *M)
  :SPRVEntryNoId(M, 1 + getSizeInWords(M->getExtension())){}

void
SPRVExtension::encode(std::ostream &O) const {
  getEncoder(O) << Module->getExtension();
}

void
SPRVExtension::decode(std::istream &I) {
  std::string S;
  getDecoder(I) >> S;
  Module->setExtension(S);
}

SPRVCapability::SPRVCapability(SPRVModule *M, SPRVCapabilityKind K)
  :SPRVEntryNoId(M, 2), Kind(K){
}

void
SPRVCapability::encode(std::ostream &O) const {
  getEncoder(O) << Kind;
}

void
SPRVCapability::decode(std::istream &I) {
  getDecoder(I) >> Kind;
  Module->addCapability(Kind);
}

} // namespace SPRV

