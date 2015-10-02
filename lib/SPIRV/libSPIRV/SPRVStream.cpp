//===- SPRVStream.cpp – Class to represent a SPIR-V Stream ------*- C++ -*-===//
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
/// This file implements SPIR-V stream class.
///
//===----------------------------------------------------------------------===//
#include "SPRVDebug.h"
#include "SPRVStream.h"
#include "SPRVFunction.h"
#include "SPRVOpCode.h"

namespace SPRV{

/// Write string with quote. Replace " with \".
static void writeQuotedString(std::ostream& O, const std::string& Str) {
  O << '"';
  for (auto I : Str) {
    if (I == '"')
      O << '\\';
    O << I;
  }
  O << '"';
}

/// Read quoted string. Replace \" with ".
static void readQuotedString(std::istream &IS, std::string& Str) {
  char Ch = ' ';
  char PreCh = ' ';
  while (IS >> Ch && Ch != '"')
    ;

  if (IS >> PreCh) {
    while (IS >> Ch) {
      if (Ch == '"') {
        if (PreCh != '\\') {
          Str += PreCh;
          break;
        }
        else
          PreCh = Ch;
      } else {
        Str += PreCh;
        PreCh = Ch;
      }
    }
  }
}

#ifdef _SPRV_SUPPORT_TEXT_FMT
bool SPRVUseTextFormat = false;
#endif

SPRVDecoder::SPRVDecoder(std::istream &InputStream, SPRVFunction &F)
  :IS(InputStream), M(*F.getModule()), WordCount(0), OpCode(OpNop),
   Scope(&F){}

SPRVDecoder::SPRVDecoder(std::istream &InputStream, SPRVBasicBlock &BB)
  :IS(InputStream), M(*BB.getModule()), WordCount(0), OpCode(OpNop),
   Scope(&BB){}

void
SPRVDecoder::setScope(SPRVEntry *TheScope) {
  assert(TheScope && (TheScope->getOpCode() == OpFunction ||
      TheScope->getOpCode() == OpLabel));
  Scope = TheScope;
}

template<class T>
const SPRVDecoder&
decode(const SPRVDecoder& I, T &V) {
#ifdef _SPRV_SUPPORT_TEXT_FMT
  if (SPRVUseTextFormat) {
    std::string W;
    I.IS >> W;
    V = getNameMap(V).rmap(W);
    SPRVDBG(bildbgs() << "Read word: W = " << W << " V = " << V << '\n');
    return I;
  }
#endif
  return DecodeBinary(I, V);
}

template<class T>
const SPRVEncoder&
encode(const SPRVEncoder& O, T V) {
#ifdef _SPRV_SUPPORT_TEXT_FMT
  if (SPRVUseTextFormat) {
    O.OS << getNameMap(V).map(V) << " ";
    return O;
  }
#endif
  return O << static_cast<SPRVWord>(V);
}

#define SPRV_DEF_ENCDEC(Type) \
const SPRVDecoder& \
operator>>(const SPRVDecoder& I, Type &V) { \
  return decode(I, V); \
}\
const SPRVEncoder& \
operator<<(const SPRVEncoder& O, Type V) { \
  return encode(O, V); \
}

SPRV_DEF_ENCDEC(Op)
SPRV_DEF_ENCDEC(Decoration)
SPRV_DEF_ENCDEC(OCLExtOpKind)

// Read a string with padded 0's at the end so that they form a stream of
// words.
const SPRVDecoder&
operator>>(const SPRVDecoder&I, std::string& Str) {
#ifdef _SPRV_SUPPORT_TEXT_FMT
  if (SPRVUseTextFormat) {
    readQuotedString(I.IS, Str);
    SPRVDBG(bildbgs() << "Read string: \"" << Str << "\"\n");
    return I;
  }
#endif

  uint64_t Count = 0;
  char Ch;
  while (I.IS >> Ch && Ch != '\0') {
    Str += Ch;
    ++Count;
  }
  Count = (Count + 1) % 4;
  Count = Count ? 4 - Count : 0;
  for (;Count; --Count) {
    I.IS >> Ch;
    assert(Ch == '\0' && "Invalid string in SPRV");
  }
  SPRVDBG(bildbgs() << "Read string: \"" << Str << "\"\n");
  return I;
}

// Write a string with padded 0's at the end so that they form a stream of
// words.
const SPRVEncoder&
operator<<(const SPRVEncoder&O, const std::string& Str) {
#ifdef _SPRV_SUPPORT_TEXT_FMT
  if (SPRVUseTextFormat) {
    writeQuotedString(O.OS, Str);
    return O;
  }
#endif

  size_t L = Str.length();
  O.OS.write(Str.c_str(), L);
  char Zeros[4] = {0, 0, 0, 0};
  O.OS.write(Zeros, 4-L%4);
  return O;
}

bool
SPRVDecoder::getWordCountAndOpCode() {
  if (IS.eof()) {
    WordCount = 0;
    OpCode = OpNop;
    SPRVDBG(bildbgs() << "[SPRVDecoder] getWordCountAndOpCode EOF " <<
        WordCount << " " << OpCode << '\n');
    return false;
  }
#ifdef _SPRV_SUPPORT_TEXT_FMT
  if (SPRVUseTextFormat) {
    *this >> WordCount;
    assert(!IS.bad() && "SPRV stream is bad");
    if (IS.fail()) {
      WordCount = 0;
      OpCode = OpNop;
      SPRVDBG(bildbgs() << "[SPRVDecoder] getWordCountAndOpCode FAIL " <<
          WordCount << " " << OpCode << '\n');
      return false;
    }
    *this >> OpCode;
  } else {
#endif
  SPRVWord WordCountAndOpCode;
  *this >> WordCountAndOpCode;
  WordCount = WordCountAndOpCode >> 16;
  OpCode = static_cast<Op>(WordCountAndOpCode & 0xFFFF);
#ifdef _SPRV_SUPPORT_TEXT_FMT
  }
#endif
  assert(!IS.bad() && "SPRV stream is bad");
  if (IS.fail()) {
    WordCount = 0;
    OpCode = OpNop;
    SPRVDBG(bildbgs() << "[SPRVDecoder] getWordCountAndOpCode FAIL " <<
        WordCount << " " << OpCode << '\n');
    return false;
  }
  SPRVDBG(bildbgs() << "[SPRVDecoder] getWordCountAndOpCode " << WordCount <<
      " " << OpCodeNameMap::map(OpCode) << '\n');
  return true;
}

SPRVEntry *
SPRVDecoder::getEntry() {
  if (WordCount == 0 || OpCode == OpNop)
    return NULL;
  SPRVEntry *Entry = SPRVEntry::create(OpCode);
  Entry->setModule(&M);
  if (isModuleScopeAllowedOpCode(OpCode) && !Scope) {}
  else
    Entry->setScope(Scope);
  Entry->setWordCount(WordCount);
  IS >> *Entry;
  assert(!IS.bad() && !IS.fail() && "SPRV stream fails");
  M.add(Entry);
  return Entry;
}

void
SPRVDecoder::validate()const {
  assert(OpCode != OpNop && "Invalid op code");
  assert(WordCount && "Invalid word count");
  assert(!IS.bad() && "Bad iInput stream");
}

std::ostream& operator<<(std::ostream &IS, const SPRVNLTy& NL) {
#ifdef _SPRV_SUPPORT_TEXT_FMT
  if (SPRVUseTextFormat)
    IS << '\n';
#endif
  return IS;
}

}
