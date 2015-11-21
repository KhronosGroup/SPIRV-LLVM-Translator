//===- SPIRVEntry.cpp - Base Class for SPIR-V Entities -----------*- C++ -*-===//
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

#include "SPIRVDebug.h"
#include "SPIRVType.h"
#include "SPIRVFunction.h"
#include "SPIRVBasicBlock.h"
#include "SPIRVInstruction.h"
#include "SPIRVDecorate.h"
#include "SPIRVStream.h"

#include <algorithm>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <utility>

using namespace SPIRV;

namespace SPIRV{

template<typename T>
SPIRVEntry* create() {
  return new T();
}

SPIRVEntry *
SPIRVEntry::create(Op OpCode) {
  typedef SPIRVEntry *(*SPIRVFactoryTy)();
  struct TableEntry {
    Op Opn;
    SPIRVFactoryTy Factory;
    operator std::pair<const Op, SPIRVFactoryTy>() {
      return std::make_pair(Opn, Factory);
    }
  };

  static TableEntry Table[] = {
#define _SPIRV_OP(x,...) {Op##x, &SPIRV::create<SPIRV##x>},
#include "SPIRVOpCodeEnum.h"
#undef _SPIRV_OP
  };

  typedef std::map<Op, SPIRVFactoryTy> OpToFactoryMapTy;
  static const OpToFactoryMapTy OpToFactoryMap(std::begin(Table),
      std::end(Table));

  OpToFactoryMapTy::const_iterator Loc = OpToFactoryMap.find(OpCode);
  if (Loc != OpToFactoryMap.end())
    return Loc->second();

  SPIRVDBG(bildbgs() << "No factory for OpCode " << (unsigned)OpCode << '\n';)
  assert (0 && "Not implemented");
  return 0;
}

std::unique_ptr<SPIRV::SPIRVEntry>
SPIRVEntry::create_unique(Op OC) {
  return std::unique_ptr<SPIRVEntry>(create(OC));
}

std::unique_ptr<SPIRV::SPIRVExtInst>
SPIRVEntry::create_unique(SPIRVExtInstSetKind Set,
    unsigned ExtOp) {
  return std::unique_ptr<SPIRVExtInst>(new SPIRVExtInst(Set, ExtOp));
}

SPIRVErrorLog &
SPIRVEntry::getErrorLog()const {
  return Module->getErrorLog();
}

bool
SPIRVEntry::exist(SPIRVId TheId)const {
  return Module->exist(TheId);
}

SPIRVEntry *
SPIRVEntry::getOrCreate(SPIRVId TheId)const {
  SPIRVEntry *Entry = nullptr;
  bool Found = Module->exist(TheId, &Entry);
  if (!Found)
    return Module->addForward(TheId, nullptr);
  return Entry;
}

SPIRVValue *
SPIRVEntry::getValue(SPIRVId TheId)const {
  return get<SPIRVValue>(TheId);
}

SPIRVType *
SPIRVEntry::getValueType(SPIRVId TheId)const {
  return get<SPIRVValue>(TheId)->getType();
}

SPIRVEncoder
SPIRVEntry::getEncoder(std::ostream &O)const{
  return SPIRVEncoder(O);
}

SPIRVDecoder
SPIRVEntry::getDecoder(std::istream& I){
  return SPIRVDecoder(I, *Module);
}

void
SPIRVEntry::setWordCount(SPIRVWord TheWordCount){
  WordCount = TheWordCount;
}

void
SPIRVEntry::setName(const std::string& TheName) {
  Name = TheName;
  SPIRVDBG(bildbgs() << "Set name for obj " << Id << " " <<
    Name << '\n');
}

void
SPIRVEntry::setModule(SPIRVModule *TheModule) {
  assert(TheModule && "Invalid module");
  if (TheModule == Module)
    return;
  assert(Module == NULL && "Cannot change owner of entry");
  Module = TheModule;
}

void
SPIRVEntry::encode(std::ostream &O) const {
  assert (0 && "Not implemented");
}

void
SPIRVEntry::encodeName(std::ostream &O) const {
  if (!Name.empty())
    O << SPIRVName(this, Name);
}

void
SPIRVEntry::encodeAll(std::ostream &O) const {
  encodeWordCountOpCode(O);
  encode(O);
  encodeChildren(O);
}

void
SPIRVEntry::encodeChildren(std::ostream &O)const {
}

void
SPIRVEntry::encodeWordCountOpCode(std::ostream &O) const {
#ifdef _SPIRV_SUPPORT_TEXT_FMT
  if (SPIRVUseTextFormat) {
    getEncoder(O) << WordCount << OpCode;
    return;
  }
#endif
  getEncoder(O) << mkWord(WordCount, OpCode);
}
// Read words from SPIRV binary and create members for SPIRVEntry.
// The word count and op code has already been read before calling this
// function for creating the SPIRVEntry. Therefore the input stream only
// contains the remaining part of the words for the SPIRVEntry.
void
SPIRVEntry::decode(std::istream &I) {
  assert (0 && "Not implemented");
}

std::vector<SPIRVValue *>
SPIRVEntry::getValues(const std::vector<SPIRVId>& IdVec)const {
  std::vector<SPIRVValue *> ValueVec;
  for (auto i:IdVec)
    ValueVec.push_back(getValue(i));
  return ValueVec;
}

std::vector<SPIRVType *>
SPIRVEntry::getValueTypes(const std::vector<SPIRVId>& IdVec)const {
  std::vector<SPIRVType *> TypeVec;
  for (auto i:IdVec)
    TypeVec.push_back(getValue(i)->getType());
  return TypeVec;
}

std::vector<SPIRVId>
SPIRVEntry::getIds(const std::vector<SPIRVValue *> ValueVec)const {
  std::vector<SPIRVId> IdVec;
  for (auto i:ValueVec)
    IdVec.push_back(i->getId());
  return IdVec;
}

SPIRVEntry *
SPIRVEntry::getEntry(SPIRVId TheId) const {
  return Module->getEntry(TheId);
}

void
SPIRVEntry::validateFunctionControlMask(SPIRVWord TheFCtlMask)
  const {
  SPIRVCK(TheFCtlMask <= (unsigned)FunctionControlMaskMax,
      InvalidFunctionControlMask, "");
}

void
SPIRVEntry::validateValues(const std::vector<SPIRVId> &Ids)const {
  for (auto I:Ids)
    getValue(I)->validate();
}

void
SPIRVEntry::validateBuiltin(SPIRVWord TheSet, SPIRVWord Index)const {
  assert(TheSet != SPIRVWORD_MAX && Index != SPIRVWORD_MAX &&
      "Invalid builtin");
}

void
SPIRVEntry::addDecorate(const SPIRVDecorate *Dec){
  auto Kind = Dec->getDecorateKind();
  Decorates.insert(std::make_pair(Dec->getDecorateKind(), Dec));
  Module->addDecorate(Dec);
  SPIRVDBG(bildbgs() << "[addDecorate] " << *Dec << '\n';)
}

void
SPIRVEntry::addDecorate(Decoration Kind) {
  addDecorate(new SPIRVDecorate(Kind, this));
}

void
SPIRVEntry::addDecorate(Decoration Kind, SPIRVWord Literal) {
  addDecorate(new SPIRVDecorate(Kind, this, Literal));
}

void
SPIRVEntry::eraseDecorate(Decoration Dec){
  Decorates.erase(Dec);
}

void
SPIRVEntry::takeDecorates(SPIRVEntry *E){
  Decorates = std::move(E->Decorates);
  SPIRVDBG(bildbgs() << "[takeDecorates] " << Id << '\n';)
}

void
SPIRVEntry::setLine(SPIRVLine *L){
  Line = L;
  L->setTargetId(Id);
  SPIRVDBG(bildbgs() << "[setLine] " << *L << '\n';)
}

void
SPIRVEntry::takeLine(SPIRVEntry *E){
  Line = E->Line;
  if (Line == nullptr)
    return;
  Line->setTargetId(Id);
  E->Line = nullptr;
}

void
SPIRVEntry::addMemberDecorate(const SPIRVMemberDecorate *Dec){
  assert(canHaveMemberDecorates() && MemberDecorates.find(Dec->getPair()) ==
      MemberDecorates.end());
  MemberDecorates[Dec->getPair()] = Dec;
  Module->addDecorate(Dec);
  SPIRVDBG(bildbgs() << "[addMemberDecorate] " << *Dec << '\n';)
}

void
SPIRVEntry::addMemberDecorate(SPIRVWord MemberNumber, Decoration Kind) {
  addMemberDecorate(new SPIRVMemberDecorate(Kind, MemberNumber, this));
}

void
SPIRVEntry::addMemberDecorate(SPIRVWord MemberNumber, Decoration Kind,
    SPIRVWord Literal) {
  addMemberDecorate(new SPIRVMemberDecorate(Kind, MemberNumber, this, Literal));
}

void
SPIRVEntry::eraseMemberDecorate(SPIRVWord MemberNumber, Decoration Dec){
  MemberDecorates.erase(std::make_pair(MemberNumber, Dec));
}

void
SPIRVEntry::takeMemberDecorates(SPIRVEntry *E){
  MemberDecorates = std::move(E->MemberDecorates);
  SPIRVDBG(bildbgs() << "[takeMemberDecorates] " << Id << '\n';)
}

void
SPIRVEntry::takeAnnotations(SPIRVForward *E){
  Module->setName(this, E->getName());
  takeDecorates(E);
  takeMemberDecorates(E);
  takeLine(E);
  if (OpCode == OpFunction)
    static_cast<SPIRVFunction *>(this)->takeExecutionModes(E);
}

// Check if an entry has Kind of decoration and get the literal of the
// first decoration of such kind at Index.
bool
SPIRVEntry::hasDecorate(Decoration Kind, size_t Index, SPIRVWord *Result)const {
  DecorateMapType::const_iterator Loc = Decorates.find(Kind);
  if (Loc == Decorates.end())
    return false;
  if (Result)
    *Result = Loc->second->getLiteral(Index);
  return true;
}

// Get literals of all decorations of Kind at Index.
std::set<SPIRVWord>
SPIRVEntry::getDecorate(Decoration Kind, size_t Index) const {
  auto Range = Decorates.equal_range(Kind);
  std::set<SPIRVWord> Value;
  for (auto I = Range.first, E = Range.second; I != E; ++I) {
    assert(Index < I->second->getLiteralCount() && "Invalid index");
    Value.insert(I->second->getLiteral(Index));
  }
  return Value;
}

bool
SPIRVEntry::hasLinkageType() const {
  return OpCode == OpFunction || OpCode == OpVariable;
}

void
SPIRVEntry::encodeDecorate(std::ostream &O) const {
  for (auto& i:Decorates)
    O << *i.second;
}

SPIRVLinkageTypeKind
SPIRVEntry::getLinkageType() const {
  assert(hasLinkageType());
  DecorateMapType::const_iterator Loc = Decorates.find(DecorationLinkageAttributes);
  if (Loc == Decorates.end())
    return LinkageTypeInternal;
  return static_cast<const SPIRVDecorateLinkageAttr*>(Loc->second)->getLinkageType();
}

void
SPIRVEntry::setLinkageType(SPIRVLinkageTypeKind LT) {
  assert(isValid(LT));
  assert(hasLinkageType());
  addDecorate(new SPIRVDecorateLinkageAttr(this, Name, LT));
}

std::ostream &
operator<<(std::ostream &O, const SPIRVEntry &E) {
  E.validate();
  E.encodeAll(O);
  O << SPIRVNL;
  return O;
}

std::istream &
operator>>(std::istream &I, SPIRVEntry &E) {
  E.decode(I);
  return I;
}

SPIRVEntryPoint::SPIRVEntryPoint(SPIRVModule *TheModule,
  SPIRVExecutionModelKind TheExecModel, SPIRVId TheId,
  const std::string &TheName)
  :SPIRVAnnotation(TheModule->get<SPIRVFunction>(TheId),
   getSizeInWords(TheName) + 3), ExecModel(TheExecModel), Name(TheName){
}

void
SPIRVEntryPoint::encode(std::ostream &O) const {
  getEncoder(O) << ExecModel << Target << Name;
}

void
SPIRVEntryPoint::decode(std::istream &I) {
  getDecoder(I) >> ExecModel >> Target >> Name;
  Module->setName(getOrCreateTarget(), Name);
  Module->addEntryPoint(ExecModel, Target);
}

void
SPIRVExecutionMode::encode(std::ostream &O) const {
  getEncoder(O) << Target << ExecMode << WordLiterals;
}

void
SPIRVExecutionMode::decode(std::istream &I) {
  getDecoder(I) >> Target >> ExecMode;
  switch(ExecMode) {
  case ExecutionModeLocalSize:
  case ExecutionModeLocalSizeHint:
    WordLiterals.resize(3);
    break;
  case ExecutionModeInvocations:
  case ExecutionModeOutputVertices:
  case ExecutionModeVecTypeHint:
    WordLiterals.resize(1);
    break;
  default:
    // Do nothing. Keep this to avoid VS2013 warning.
    break;
  }
  getDecoder(I) >> WordLiterals;
  getOrCreateTarget()->addExecutionMode(this);
}

SPIRVForward *
SPIRVAnnotationGeneric::getOrCreateTarget()const {
  SPIRVEntry *Entry = nullptr;
  bool Found = Module->exist(Target, &Entry);
  assert((!Found || Entry->getOpCode() == OpForward) &&
      "Annotations only allowed on forward");
  if (!Found)
    Entry = Module->addForward(Target, nullptr);
  return static_cast<SPIRVForward *>(Entry);
}

SPIRVName::SPIRVName(const SPIRVEntry *TheTarget, const std::string& TheStr)
  :SPIRVAnnotation(TheTarget, getSizeInWords(TheStr) + 2), Str(TheStr){
}

void
SPIRVName::encode(std::ostream &O) const {
  getEncoder(O) << Target << Str;
}

void
SPIRVName::decode(std::istream &I) {
  getDecoder(I) >> Target >> Str;
  Module->setName(getOrCreateTarget(), Str);
}

void
SPIRVName::validate() const {
  assert(WordCount == getSizeInWords(Str) + 2 && "Incorrect word count");
}

_SPIRV_IMP_ENCDEC2(SPIRVString, Id, Str)
_SPIRV_IMP_ENCDEC3(SPIRVMemberName, Target, MemberNumber, Str)

void
SPIRVLine::encode(std::ostream &O) const {
  getEncoder(O) << Target << FileName << Line << Column;
}

void
SPIRVLine::decode(std::istream &I) {
  getDecoder(I) >> Target >> FileName >> Line >> Column;
  Module->addLine(getOrCreateTarget(), get<SPIRVString>(FileName), Line, Column);
}

void
SPIRVLine::validate() const {
  assert(OpCode == OpLine);
  assert(WordCount == 5);
  assert(get<SPIRVEntry>(Target));
  assert(get<SPIRVEntry>(FileName)->getOpCode() == OpString);
  assert(Line != SPIRVWORD_MAX);
  assert(Column != SPIRVWORD_MAX);
}

void
SPIRVMemberName::validate() const {
  assert(OpCode == OpMemberName);
  assert(WordCount == getSizeInWords(Str) + FixedWC);
  assert(get<SPIRVEntry>(Target)->getOpCode() == OpTypeStruct);
  assert(MemberNumber < get<SPIRVTypeStruct>(Target)->getStructMemberCount());
}

SPIRVExtInstImport::SPIRVExtInstImport(SPIRVModule *TheModule, SPIRVId TheId,
    const std::string &TheStr):
  SPIRVEntry(TheModule, 2 + getSizeInWords(TheStr), OC, TheId), Str(TheStr){
  validate();
}

void
SPIRVExtInstImport::encode(std::ostream &O) const {
  getEncoder(O) << Id << Str;
}

void
SPIRVExtInstImport::decode(std::istream &I) {
  getDecoder(I) >> Id >> Str;
  Module->importBuiltinSetWithId(Str, Id);
}

void
SPIRVExtInstImport::validate() const {
  SPIRVEntry::validate();
  assert(!Str.empty() && "Invalid builtin set");
}

void
SPIRVMemoryModel::encode(std::ostream &O) const {
  getEncoder(O) << Module->getAddressingModel() <<
      Module->getMemoryModel();
}

void
SPIRVMemoryModel::decode(std::istream &I) {
  SPIRVAddressingModelKind AddrModel;
  SPIRVMemoryModelKind MemModel;
  getDecoder(I) >> AddrModel >> MemModel;
  Module->setAddressingModel(AddrModel);
  Module->setMemoryModel(MemModel);
}

void
SPIRVMemoryModel::validate() const {
  unsigned AM = Module->getAddressingModel();
  unsigned MM = Module->getMemoryModel();
  SPIRVCK(AM < AddressingModelCount, InvalidAddressingModel, "Actual is "+AM );
  SPIRVCK(MM < MemoryModelCount, InvalidMemoryModel, "Actual is "+MM);
}

void
SPIRVSource::encode(std::ostream &O) const {
  SPIRVWord Ver = SPIRVWORD_MAX;
  auto Language = Module->getSourceLanguage(&Ver);
  getEncoder(O) << Language << Ver;
}

void
SPIRVSource::decode(std::istream &I) {
  SourceLanguage Lang = SourceLanguageUnknown;
  SPIRVWord Ver = SPIRVWORD_MAX;
  getDecoder(I) >> Lang >> Ver;
  Module->setSourceLanguage(Lang, Ver);
}

SPIRVSourceExtension::SPIRVSourceExtension(SPIRVModule *M,
    const std::string &SS)
  :SPIRVEntryNoId(M, 1 + getSizeInWords(SS)), S(SS){}

void
SPIRVSourceExtension::encode(std::ostream &O) const {
  getEncoder(O) << S;
}

void
SPIRVSourceExtension::decode(std::istream &I) {
  getDecoder(I) >> S;
  Module->getSourceExtension().insert(S);
}

SPIRVExtension::SPIRVExtension(SPIRVModule *M, const std::string &SS)
  :SPIRVEntryNoId(M, 1 + getSizeInWords(SS)), S(SS){}

void
SPIRVExtension::encode(std::ostream &O) const {
  getEncoder(O) << S;
}

void
SPIRVExtension::decode(std::istream &I) {
  getDecoder(I) >> S;
  Module->getExtension().insert(S);
}

SPIRVCapability::SPIRVCapability(SPIRVModule *M, SPIRVCapabilityKind K)
  :SPIRVEntryNoId(M, 2), Kind(K){
}

void
SPIRVCapability::encode(std::ostream &O) const {
  getEncoder(O) << Kind;
}

void
SPIRVCapability::decode(std::istream &I) {
  getDecoder(I) >> Kind;
  Module->addCapability(Kind);
}

} // namespace SPIRV

