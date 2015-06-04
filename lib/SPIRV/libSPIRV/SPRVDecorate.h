//===- SPRVDecorate.h - SPIR-V Decorations ----------------------*- C++ -*-===//
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
/// This file defines SPIR-V decorations.
///
//===----------------------------------------------------------------------===//

#ifndef SPRVDECORATE_HPP_
#define SPRVDECORATE_HPP_

#include "SPRVEntry.h"
#include "SPRVUtil.h"
#include <string>
#include <vector>
#include <utility>

namespace SPRV{

class SPRVDecorateGeneric:public SPRVAnnotationGeneric{
public:
  // Complete constructor for decorations without literals
  SPRVDecorateGeneric(SPRVOpCode OC, SPRVWord WC, SPRVDecorateKind TheDec,
      SPRVEntry *TheTarget);
  // Complete constructor for decorations with one word literal
  SPRVDecorateGeneric(SPRVOpCode OC, SPRVWord WC, SPRVDecorateKind TheDec,
      SPRVEntry *TheTarget, SPRVWord V);
  // Incomplete constructor
  SPRVDecorateGeneric(SPRVOpCode OC);

  SPRVWord getLiteral(size_t) const;
  SPRVDecorateKind getDecorateKind() const;
  size_t getLiteralCount() const;
  struct Comparator {
    bool operator()(const SPRVDecorateGeneric *A, const SPRVDecorateGeneric *B);
  };
protected:
  SPRVDecorateKind Dec;
  std::vector<SPRVWord> Literals;
};

typedef std::multiset<const SPRVDecorateGeneric *,
    SPRVDecorateGeneric::Comparator> SPRVDecorateSet;

class SPRVDecorate:public SPRVDecorateGeneric{
public:
  static const SPRVOpCode OC = SPRVOC_OpDecorate;
  static const SPRVWord FixedWC = 3;
  // Complete constructor for decorations without literals
  SPRVDecorate(SPRVDecorateKind TheDec, SPRVEntry *TheTarget)
    :SPRVDecorateGeneric(OC, 3, TheDec, TheTarget){}
  // Complete constructor for decorations with one word literal
  SPRVDecorate(SPRVDecorateKind TheDec, SPRVEntry *TheTarget, SPRVWord V)
    :SPRVDecorateGeneric(OC, 4, TheDec, TheTarget, V){}
  // Incomplete constructor
  SPRVDecorate():SPRVDecorateGeneric(OC){}

  _SPRV_DCL_ENCDEC
  void setWordCount(SPRVWord);
};

class SPRVMemberDecorate:public SPRVDecorateGeneric{
public:
  static const SPRVOpCode OC = SPRVOC_OpMemberDecorate;
  static const SPRVWord FixedWC = 4;
  // Complete constructor for decorations without literals
  SPRVMemberDecorate(SPRVDecorateKind TheDec, SPRVWord Member, SPRVEntry *TheTarget)
    :SPRVDecorateGeneric(OC, 4, TheDec, TheTarget), MemberNumber(Member){}
  // Complete constructor for decorations with one word literal
  SPRVMemberDecorate(SPRVDecorateKind TheDec, SPRVWord Member, SPRVEntry *TheTarget,
      SPRVWord V)
    :SPRVDecorateGeneric(OC, 5, TheDec, TheTarget, V), MemberNumber(Member){}
  // Incomplete constructor
  SPRVMemberDecorate():SPRVDecorateGeneric(OC), MemberNumber(SPRVWORD_MAX){}

  SPRVWord getMemberNumber() const { return MemberNumber;}
  std::pair<SPRVWord, SPRVDecorateKind> getPair() const {
    return std::make_pair(MemberNumber, Dec);
  }

  _SPRV_DCL_ENCDEC
  void setWordCount(SPRVWord);
protected:
  SPRVWord MemberNumber;
};

class SPRVDecorationGroup:public SPRVEntry{
public:
  static const SPRVOpCode OC = SPRVOC_OpDecorationGroup;
  static const SPRVWord WC = 2;
  // Complete constructor. Does not populate Decorations.
  SPRVDecorationGroup(SPRVModule *TheModule, SPRVId TheId)
    :SPRVEntry(TheModule, WC, OC, TheId){
    validate();
  };
  // Incomplete constructor
  SPRVDecorationGroup():SPRVEntry(OC){}
  void encodeAll(std::ostream &O) const;
  _SPRV_DCL_ENCDEC
  // Move the given decorates to the decoration group
  void takeDecorates(SPRVDecorateSet &Decs) {
    Decorations = std::move(Decs);
  }

  SPRVDecorateSet& getDecorations() {
    return Decorations;
  }

protected:
  SPRVDecorateSet Decorations;
  void validate()const {
    assert(OpCode == OC);
    assert(WordCount == WC);
  }
};

class SPRVGroupDecorateGeneric:public SPRVEntryNoIdGeneric{
public:
  static const SPRVWord FixedWC = 2;
  // Complete constructor
  SPRVGroupDecorateGeneric(SPRVOpCode OC, SPRVDecorationGroup *TheGroup,
      const std::vector<SPRVId> &TheTargets)
    :SPRVEntryNoIdGeneric(TheGroup->getModule(), FixedWC + TheTargets.size(), OC),
     DecorationGroup(TheGroup), Targets(TheTargets){
  }
  // Incomplete constructor
  SPRVGroupDecorateGeneric(SPRVOpCode OC)
    :SPRVEntryNoIdGeneric(OC), DecorationGroup(nullptr){}

  void setWordCount(SPRVWord WC) { Targets.resize(WC - FixedWC);}
  virtual void decorateTargets() = 0;
  _SPRV_DCL_ENCDEC
protected:
  SPRVDecorationGroup *DecorationGroup;
  std::vector<SPRVId> Targets;
};

class SPRVGroupDecorate:public SPRVGroupDecorateGeneric{
public:
  static const SPRVOpCode OC = SPRVOC_OpGroupDecorate;
  // Complete constructor
  SPRVGroupDecorate(SPRVDecorationGroup *TheGroup,
      const std::vector<SPRVId> &TheTargets)
    :SPRVGroupDecorateGeneric(OC, TheGroup, TheTargets){}
  // Incomplete constructor
  SPRVGroupDecorate()
    :SPRVGroupDecorateGeneric(OC){}

  virtual void decorateTargets();
};

class SPRVGroupMemberDecorate:public SPRVGroupDecorateGeneric{
public:
  static const SPRVOpCode OC = SPRVOC_OpGroupMemberDecorate;
  // Complete constructor
  SPRVGroupMemberDecorate(SPRVDecorationGroup *TheGroup,
      const std::vector<SPRVId> &TheTargets)
    :SPRVGroupDecorateGeneric(OC, TheGroup, TheTargets){}
  // Incomplete constructor
  SPRVGroupMemberDecorate()
    :SPRVGroupDecorateGeneric(OC){}

  virtual void decorateTargets();
};

}


#endif /* SPRVDECORATE_HPP_ */
