//===- SPRVDecorate.cpp -SPRV Decorations Implementation ----------*- C++ -*-===//
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
//
// This file implements SPIRV decorations.
//
//===----------------------------------------------------------------------===//

#include "SPRVDecorate.h"
#include "SPRVStream.h"
#include "SPRVValue.h"
#include "SPRVModule.h"

namespace SPRV{
template<class T, class B>
std::ostream &
operator<< (std::ostream &O, const std::multiset<T *, B>& V) {
  for (auto &I: V)
    O << *I;
  return O;
}

SPRVDecorateGeneric::SPRVDecorateGeneric(SPRVOpCode OC, SPRVWord WC,
    SPRVDecorateKind TheDec, SPRVEntry *TheTarget)
  :SPRVAnnotationGeneric(TheTarget, WC, OC), Dec(TheDec){
  validate();
}

SPRVDecorateGeneric::SPRVDecorateGeneric(SPRVOpCode OC, SPRVWord WC,
    SPRVDecorateKind TheDec, SPRVEntry *TheTarget, SPRVWord V)
  :SPRVAnnotationGeneric(TheTarget, WC, OC), Dec(TheDec){
  Literals.push_back(V);
  validate();
}

SPRVDecorateGeneric::SPRVDecorateGeneric(SPRVOpCode OC)
  :SPRVAnnotationGeneric(OC), Dec(SPRVDEC_Count){
}

SPRVDecorateKind
SPRVDecorateGeneric::getDecorateKind()const {
  return Dec;
}

SPRVWord
SPRVDecorateGeneric::getLiteral(size_t i) const {
  assert(0 <= i && i <= Literals.size() && "Out of bounds");
  return Literals[i];
}

size_t
SPRVDecorateGeneric::getLiteralCount() const {
  return Literals.size();
}

void
SPRVDecorate::encode(std::ostream &O)const {
  getEncoder(O) << Target << Dec << Literals;
}

void
SPRVDecorate::setWordCount(SPRVWord Count){
  WordCount = Count;
  Literals.resize(WordCount - FixedWC);
}

void
SPRVDecorate::decode(std::istream &I){
  getDecoder(I) >> Target >> Dec >> Literals;
  getOrCreateTarget()->addDecorate(this);
}

void
SPRVMemberDecorate::encode(std::ostream &O)const {
  getEncoder(O) << Target << MemberNumber << Dec << Literals;
}

void
SPRVMemberDecorate::setWordCount(SPRVWord Count){
  WordCount = Count;
  Literals.resize(WordCount - FixedWC);
}

void
SPRVMemberDecorate::decode(std::istream &I){
  getDecoder(I) >> Target >> MemberNumber >> Dec >> Literals;
  getOrCreateTarget()->addMemberDecorate(this);
}

void
SPRVDecorationGroup::encode(std::ostream &O)const {
  getEncoder(O) << Id;
}

void
SPRVDecorationGroup::decode(std::istream &I){
  getDecoder(I) >> Id;
  Module->addDecorationGroup(this);
}

void
SPRVDecorationGroup::encodeAll(std::ostream &O) const {
  O << Decorations;
  SPRVEntry::encodeAll(O);
}

void
SPRVGroupDecorateGeneric::encode(std::ostream &O)const {
  getEncoder(O) << DecorationGroup << Targets;
}

void
SPRVGroupDecorateGeneric::decode(std::istream &I){
  getDecoder(I) >> DecorationGroup >> Targets;
  Module->addGroupDecorateGeneric(this);
}

void
SPRVGroupDecorate::decorateTargets() {
  for(auto &I:Targets) {
    auto Target = getOrCreate(I);
    for (auto &Dec:DecorationGroup->getDecorations()) {
      assert(Dec->isDecorate());
      Target->addDecorate(static_cast<const SPRVDecorate *const>(Dec));
    }
  }
}

void
SPRVGroupMemberDecorate::decorateTargets() {
  for(auto &I:Targets) {
    auto Target = getOrCreate(I);
    for (auto &Dec:DecorationGroup->getDecorations()) {
      assert(Dec->isMemberDecorate());
      Target->addMemberDecorate(static_cast<const SPRVMemberDecorate*>(Dec));
    }
  }
}

bool
SPRVDecorateGeneric::Comparator::operator()(const SPRVDecorateGeneric *A,
    const SPRVDecorateGeneric *B) {
  if (A->getOpCode() < B->getOpCode())
    return true;
  if (A->getOpCode() > B->getOpCode())
    return false;
  if (A->getDecorateKind() < B->getDecorateKind())
    return true;
  if (A->getDecorateKind() > B->getDecorateKind())
    return false;
  if (A->getLiteralCount() < B->getLiteralCount())
    return true;
  if (A->getLiteralCount() > B->getLiteralCount())
    return false;
  for (size_t I = 0, E = A->getLiteralCount(); I != E; ++I) {
    auto EA = A->getLiteral(I);
    auto EB = B->getLiteral(I);
    if (EA < EB)
      return true;
    if (EA > EB)
      return false;
  }
  return false;
}

}

