//===- SPRVStream.h – Class to represent a SPIR-V Stream --------*- C++ -*-===//
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
/// This file defines Word class for SPIR-V.
///
//===----------------------------------------------------------------------===//

#ifndef SPRVSTREAM_H
#define SPRVSTREAM_H

#include "SPRVDebug.h"
#include "SPRVModule.h"
#include "SPRVExtInst.h"
#include <algorithm>
#include <cstdint>
#include <iostream>
#include <iterator>
#include <vector>
#include <string>

namespace SPRV{

class SPRVFunction;
class SPRVBasicBlock;

class SPRVDecoder {
public:
  SPRVDecoder(std::istream& InputStream, SPRVModule& Module)
    :IS(InputStream), M(Module), WordCount(0), OpCode(SPRVOC_OpNop),
     Scope(NULL){}
  SPRVDecoder(std::istream& InputStream, SPRVFunction& F);
  SPRVDecoder(std::istream& InputStream, SPRVBasicBlock &BB);

  void setScope(SPRVEntry *);
  bool getWordCountAndOpCode();
  SPRVEntry *getEntry();
  void validate()const;

  std::istream &IS;
  SPRVModule &M;
  SPRVWord WordCount;
  SPRVOpCode OpCode;
  SPRVEntry *Scope; // A function or basic block
};

class SPRVEncoder {
public:
  explicit SPRVEncoder(std::ostream& OutputStream)
    :OS(OutputStream){}
  std::ostream& OS;
};

template<typename T>
const SPRVDecoder&
DecodeBinary(const SPRVDecoder& I, T &V) {
  uint32_t W;
  I.IS.read(reinterpret_cast<char*>(&W), sizeof(W));
  V = static_cast<T>(W);
  SPRVDBG(bildbgs() << "Read word: W = " << W << " V = " << V << '\n');
  return I;
}

template<typename T>
const SPRVDecoder&
operator>>(const SPRVDecoder& I, T &V) {
#ifdef _SPRVDBG
  if (SPRVDbgUseTextFormat) {
    uint32_t W;
    I.IS >> W;
    V = static_cast<T>(W);
    SPRVDBG(bildbgs() << "Read word: W = " << W << " V = " << V << '\n');
    return I;
  }
#endif
  return DecodeBinary(I, V);
}

template<typename T>
const SPRVDecoder&
operator>>(const SPRVDecoder& I, T *&P) {
  SPRVId Id;
  I >> Id;
  P = static_cast<T*>(I.M.getEntry(Id));
  return I;
}

template<typename IterTy>
const SPRVDecoder&
operator>>(const SPRVDecoder& Decoder, const std::pair<IterTy,IterTy> &Range) {
  for (IterTy I = Range.first, E = Range.second; I != E; ++I)
    Decoder >> *I;
  return Decoder;
}

template<typename T>
const SPRVDecoder&
operator>>(const SPRVDecoder& I, std::vector<T> &V) {
  for (size_t i = 0, e = V.size(); i != e; ++i)
    I >> V[i];
  return I;
}

template<typename T>
const SPRVEncoder&
operator<<(const SPRVEncoder& O, T V) {
#ifdef _SPRVDBG
  if (SPRVDbgUseTextFormat) {
    O.OS << V << " ";
    return O;
  }
#endif
  uint32_t W = static_cast<uint32_t>(V);
  O.OS.write(reinterpret_cast<char*>(&W), sizeof(W));
  return O;
}

template<typename T>
const SPRVEncoder&
operator<<(const SPRVEncoder& O, T* P) {
  return O << P->getId();
}

template<typename T>
const SPRVEncoder&
operator<<(const SPRVEncoder& O, const std::vector<T>& V) {
  for (size_t i = 0, e = V.size(); i != e; ++i)
    O << V[i];
  return O;
}

template<typename IterTy>
const SPRVEncoder&
operator<<(const SPRVEncoder& Encoder, const std::pair<IterTy,IterTy> &Range) {
  for (IterTy I = Range.first, E = Range.second; I != E; ++I)
    Encoder << *I;
  return Encoder;
}

#define SPRV_DEC_ENCDEC(Type) \
const SPRVEncoder& \
operator<<(const SPRVEncoder& O, Type V); \
const SPRVDecoder& \
operator>>(const SPRVDecoder& I, Type &V);

SPRV_DEC_ENCDEC(SPRVOpCode)
SPRV_DEC_ENCDEC(SPRVDecorateKind)
SPRV_DEC_ENCDEC(SPRVBuiltinOCL12Kind)
SPRV_DEC_ENCDEC(SPRVBuiltinOCL20Kind)

const SPRVEncoder&
operator<<(const SPRVEncoder&O, const std::string& Str);
const SPRVDecoder&
operator>>(const SPRVDecoder&I, std::string& Str);

} // namespace SPRV
#endif
