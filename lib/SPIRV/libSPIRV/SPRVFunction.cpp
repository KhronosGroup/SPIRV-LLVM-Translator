//===- SPRVFunction.cpp – Class to represent a SPIR-V Function --*- C++ -*-===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements Function class for SPRV.
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

#include "SPRVEntry.h"
#include "SPRVFunction.h"
#include "SPRVBasicBlock.h"
#include "SPRVInstruction.h"
#include "SPRVStream.h"

#include <functional>
#include <algorithm>
using namespace SPRV;

SPRVFunctionParameter::SPRVFunctionParameter(SPRVType *TheType, SPRVId TheId,
    SPRVFunction *TheParent, unsigned TheArgNo):
        SPRVValue(TheParent->getModule(), 3, OpFunctionParameter,
        TheType, TheId),
    ParentFunc(TheParent),
    ArgNo(TheArgNo){
  validate();
}

void
SPRVFunctionParameter::foreachAttr(
    std::function<void(SPRVFuncParamAttrKind)>Func){
  auto Locs = Decorates.equal_range(DecorationFuncParamAttr);
  for (auto I = Locs.first, E = Locs.second; I != E; ++I){
    auto Attr = static_cast<SPRVFuncParamAttrKind>(
        I->second->getLiteral(0));
    assert(isValid(Attr));
    Func(Attr);
  }
}

SPRVDecoder
SPRVFunction::getDecoder(std::istream &IS) {
  return SPRVDecoder(IS, *this);
}

void
SPRVFunction::encode(std::ostream &O) const {
  getEncoder(O) << Type << Id << FCtrlMask << FuncType;
}

void
SPRVFunction::encodeChildren(std::ostream &O) const {
  O << SPRVNL;
  for (auto &I:Parameters)
    O << *I;
  O << SPRVNL;
  for (auto &I:BBVec)
    O << *I;
  O << SPRVFunctionEnd();
}

void
SPRVFunction::encodeExecutionModes(std::ostream &O)const {
  for (auto &I:ExecModes)
    O << *I.second;
}

void
SPRVFunction::decode(std::istream &I) {
  SPRVDecoder Decoder = getDecoder(I);
  Decoder >> Type >> Id >> FCtrlMask >> FuncType;
  Module->addFunction(this);
  SPRVDBG(bildbgs() << "Decode function: " << Id << '\n');

  Decoder.getWordCountAndOpCode();
  while (!I.eof()) {
    if (Decoder.OpCode == OpFunctionEnd)
      break;

    switch(Decoder.OpCode) {
    case OpFunctionParameter: {
      auto Param = static_cast<SPRVFunctionParameter *>(Decoder.getEntry());
      Param->setParent(this);
      Parameters.push_back(Param);
      Decoder.getWordCountAndOpCode();
      continue;
      break;
    }
    case OpLabel: {
      decodeBB(Decoder);
      break;
    }
    default:
      assert (0 && "Invalid SPIRV format");
    }
  }
}

/// Decode basic block and contained instructions.
/// Do it here instead of in BB:decode to avoid back track in input stream.
void
SPRVFunction::decodeBB(SPRVDecoder &Decoder) {
  SPRVBasicBlock *BB = static_cast<SPRVBasicBlock*>(Decoder.getEntry());
  addBasicBlock(BB);
  SPRVDBG(bildbgs() << "Decode BB: " << BB->getId() << '\n');

  Decoder.setScope(BB);
  while(Decoder.getWordCountAndOpCode()) {
    if (Decoder.OpCode == OpFunctionEnd ||
        Decoder.OpCode == OpLabel) {
      break;
    }

    if (Decoder.OpCode == OpName ||
        Decoder.OpCode == OpDecorate) {
      Decoder.getEntry();
      continue;
    }

    SPRVInstruction *Inst = static_cast<SPRVInstruction *>(Decoder.getEntry());
    BB->addInstruction(Inst);
  }
  Decoder.setScope(this);
}

void
SPRVFunction::foreachReturnValueAttr(
    std::function<void(SPRVFuncParamAttrKind)>Func){
  auto Locs = Decorates.equal_range(DecorationFuncParamAttr);
  for (auto I = Locs.first, E = Locs.second; I != E; ++I){
    auto Attr = static_cast<SPRVFuncParamAttrKind>(
        I->second->getLiteral(0));
    assert(isValid(Attr));
    Func(Attr);
  }
}



