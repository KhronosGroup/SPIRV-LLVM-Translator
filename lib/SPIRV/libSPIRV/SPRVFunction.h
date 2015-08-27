//===- SPRVFunction.h – Class to represent a SPIR-V function ----*- C++ -*-===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines Function class for SPRV.
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

#ifndef SPRVFUNCTION_HPP_
#define SPRVFUNCTION_HPP_
#include "SPRVValue.h"
#include "SPRVBasicBlock.h"
#include <functional>

namespace SPRV{

class BIFunction;
class SPRVDecoder;

class SPRVFunctionParameter: public SPRVValue {
public:
  SPRVFunctionParameter(SPRVType *TheType, SPRVId TheId,
      SPRVFunction *TheParent, unsigned TheArgNo);
  SPRVFunctionParameter():SPRVValue(SPRVOC_OpFunctionParameter),
      ParentFunc(nullptr), ArgNo(0){}
  unsigned getArgNo()const { return ArgNo;}
  void foreachAttr(std::function<void(SPRVFuncParamAttrKind)>);
  void addAttr(SPRVFuncParamAttrKind Kind) {
    addDecorate(new SPRVDecorate(DecorationFuncParamAttr, this, Kind));
  }
  void setParent(SPRVFunction *Parent) { ParentFunc = Parent;}
  bool hasAttr(SPRVFuncParamAttrKind Kind) const {
    return getDecorate(DecorationFuncParamAttr).count(Kind) ;
  }
  bool isByVal()const { return hasAttr(SPRVFPA_ByVal);}
  bool isZext()const { return hasAttr(SPRVFPA_Zext);}
  CapVec getRequiredCapability() const {
    if (hasLinkageType() && getLinkageType() == SPRVLT_Import)
      return getVec(SPRVCAP_Linkage);
    return CapVec();
  }
protected:
  void validate()const {
    SPRVValue::validate();
    assert(ParentFunc && "Invalid parent function");
  }
  _SPRV_DEF_ENCDEC2(Type, Id)
private:
  SPRVFunction *ParentFunc;
  unsigned ArgNo;
};

class SPRVFunction: public SPRVValue, public SPRVComponentExecutionModes {
public:
  // Complete constructor. It does not construct basic blocks.
  SPRVFunction(SPRVModule *M, SPRVTypeFunction *FunctionType, SPRVId TheId)
    :SPRVValue(M, 5, SPRVOC_OpFunction, FunctionType->getReturnType(), TheId),
     FuncType(FunctionType), FCtrlMask(SPRVFCM_Default) {
    addAllArguments(TheId + 1);
    validate();
  }

  // Incomplete constructor
  SPRVFunction():SPRVValue(SPRVOC_OpFunction),FuncType(NULL),
      FCtrlMask(SPRVFCM_Default){}

  SPRVDecoder getDecoder(std::istream &IS);
  SPRVTypeFunction *getFunctionType() const { return FuncType;}
  SPRVWord getFuncCtlMask() const { return FCtrlMask;}
  size_t getNumBasicBlock() const { return BBVec.size();}
  SPRVBasicBlock *getBasicBlock(size_t i) const { return BBVec[i];}
  size_t getNumArguments() const {
    return getFunctionType()->getNumParameters();
  }
  SPRVId getArgumentId(size_t i)const { return Parameters[i]->getId();}
  SPRVFunctionParameter *getArgument(size_t i) const {
    return Parameters[i];
  }
  void foreachArgument(std::function<void(SPRVFunctionParameter *)>Func) {
    for (size_t I = 0, E = getNumArguments(); I != E; ++I)
      Func(getArgument(I));
  }

  void foreachReturnValueAttr(std::function<void(SPRVFuncParamAttrKind)>);

  void setFunctionControlMask(SPRVWord Mask) {
    FCtrlMask = Mask;
  }

  void takeExecutionModes(SPRVForward *Forward) {
    ExecModes = std::move(Forward->ExecModes);
  }

  // Assume BB contains valid Id.
  SPRVBasicBlock *addBasicBlock(SPRVBasicBlock *BB) {
    Module->add(BB);
    BB->setParent(this);
    BBVec.push_back(BB);
    return BB;
  }

  void encodeChildren(std::ostream &)const;
  void encodeExecutionModes(std::ostream &)const;
  _SPRV_DCL_ENCDEC
  void validate()const {
    SPRVValue::validate();
    assert(FuncType && "Invalid func type");
  }

private:
  SPRVFunctionParameter *addArgument(unsigned TheArgNo, SPRVId TheId) {
    SPRVFunctionParameter *Arg = new SPRVFunctionParameter(
        getFunctionType()->getParameterType(TheArgNo),
        TheId, this, TheArgNo);
    Module->add(Arg);
    Parameters.push_back(Arg);
    return Arg;
  }

  void addAllArguments(SPRVId FirstArgId) {
    for (size_t i = 0, e = getFunctionType()->getNumParameters(); i != e; ++i)
      addArgument(i, FirstArgId + i);
  }
  void decodeBB(SPRVDecoder &);

  SPRVTypeFunction *FuncType;                  // Function type
  SPRVWord FCtrlMask;                          // Function control mask

  std::vector<SPRVFunctionParameter *> Parameters;
  typedef std::vector<SPRVBasicBlock *> SPRVLBasicBlockVector;
  SPRVLBasicBlockVector BBVec;
};

typedef SPRVEntryOpCodeOnly<SPRVOC_OpFunctionEnd> SPRVFunctionEnd;

}

#endif /* SPRVFUNCTION_HPP_ */
