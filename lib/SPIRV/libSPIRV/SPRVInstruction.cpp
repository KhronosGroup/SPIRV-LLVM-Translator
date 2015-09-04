//===- SPRVInstruction.cpp -Class to represent SPIR-V instruction - C++ -*-===//
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
/// This file implements SPIR-V instructions.
///
//===----------------------------------------------------------------------===//

#include "SPRVInstruction.h"
#include "SPRVBasicBlock.h"
#include "SPRVFunction.h"

#include <unordered_set>

namespace SPRV {

// Complete constructor for instruction with type and id
SPRVInstruction::SPRVInstruction(unsigned TheWordCount, Op TheOC,
    SPRVType *TheType, SPRVId TheId, SPRVBasicBlock *TheBB)
  :SPRVValue(TheBB->getModule(), TheWordCount, TheOC, TheType, TheId),
   BB(TheBB){
  validate();
}

SPRVInstruction::SPRVInstruction(unsigned TheWordCount, Op TheOC,
  SPRVType *TheType, SPRVId TheId, SPRVBasicBlock *TheBB, SPRVModule *TheBM)
  : SPRVValue(TheBM, TheWordCount, TheOC, TheType, TheId), BB(TheBB){
  validate();
}

// Complete constructor for instruction with id but no type
SPRVInstruction::SPRVInstruction(unsigned TheWordCount, Op TheOC,
    SPRVId TheId, SPRVBasicBlock *TheBB)
  :SPRVValue(TheBB->getModule(), TheWordCount, TheOC, TheId), BB(TheBB){
  validate();
}
// Complete constructor for instruction without type and id
SPRVInstruction::SPRVInstruction(unsigned TheWordCount, Op TheOC,
    SPRVBasicBlock *TheBB)
  :SPRVValue(TheBB->getModule(), TheWordCount, TheOC), BB(TheBB){
  validate();
}
// Complete constructor for instruction with type but no id
SPRVInstruction::SPRVInstruction(unsigned TheWordCount, Op TheOC,
    SPRVType *TheType, SPRVBasicBlock *TheBB)
  :SPRVValue(TheBB->getModule(), TheWordCount, TheOC, TheType), BB(TheBB){
  validate();
}

void
SPRVInstruction::setParent(SPRVBasicBlock *TheBB) {
  assert(TheBB && "Invalid BB");
  if (BB == TheBB)
    return;
  assert(BB == NULL && "BB cannot change parent");
  BB = TheBB;
}

void
SPRVInstruction::setScope(SPRVEntry *Scope) {
  assert(Scope && Scope->getOpCode() == OpLabel && "Invalid scope");
  setParent(static_cast<SPRVBasicBlock*>(Scope));
}

SPRVFunctionCall::SPRVFunctionCall(SPRVId TheId, SPRVFunction *TheFunction,
    const std::vector<SPRVValue *> &TheArgs, SPRVBasicBlock *BB)
  :SPRVFunctionCallGeneric(
      TheFunction->getFunctionType()->getReturnType(),
      TheId, TheArgs, BB), FunctionId(TheFunction->getId()){
  validate();
}

void
SPRVFunctionCall::validate()const {
  SPRVFunctionCallGeneric::validate();
}

// ToDo: Each instruction should implement this function
std::vector<SPRVValue *>
SPRVInstruction::getOperands() {
  std::vector<SPRVValue *> Empty;
  assert(0 && "not supported");
  return Empty;
}

std::vector<SPRVType*>
SPRVInstruction::getOperandTypes(const std::vector<SPRVValue *> &Ops) {
  std::vector<SPRVType*> Tys;
  for (auto& I : Ops) {
    SPRVType* Ty = nullptr;
    if (I->getOpCode() == OpFunction)
      Ty = reinterpret_cast<SPRVFunction*>(I)->getFunctionType();
    else
      Ty = I->getType();

    Tys.push_back(Ty);
  }
  return Tys;
}

std::vector<SPRVType*>
SPRVInstruction::getOperandTypes() {
  return getOperandTypes(getOperands());
}

bool
isSpecConstantOpAllowedOp(Op OC) {
  static SPRVWord Table[] =
  {
    OpSConvert,
    OpFConvert,
    OpConvertFToS,
    OpConvertSToF,
    OpConvertFToU,
    OpConvertUToF,
    OpUConvert,
    OpConvertPtrToU,
    OpConvertUToPtr,
    OpGenericCastToPtr,
    OpPtrCastToGeneric,
    OpBitcast,
    OpQuantizeToF16,
    OpSNegate,
    OpNot,
    OpIAdd,
    OpISub,
    OpIMul,
    OpUDiv,
    OpSDiv,
    OpUMod,
    OpSRem,
    OpSMod,
    OpShiftRightLogical,
    OpShiftRightArithmetic,
    OpShiftLeftLogical,
    OpBitwiseOr,
    OpBitwiseXor,
    OpBitwiseAnd,
    OpFNegate,
    OpFAdd,
    OpFSub,
    OpFMul,
    OpFDiv,
    OpFRem,
    OpFMod,
    OpVectorShuffle,
    OpCompositeExtract,
    OpCompositeInsert,
    OpLogicalOr,
    OpLogicalAnd,
    OpLogicalNot,
    OpLogicalEqual,
    OpLogicalNotEqual,
    OpSelect,
    OpIEqual,
    OpULessThan,
    OpSLessThan,
    OpUGreaterThan,
    OpSGreaterThan,
    OpULessThanEqual,
    OpSLessThanEqual,
    OpUGreaterThanEqual,
    OpSGreaterThanEqual,
    OpAccessChain,
    OpInBoundsAccessChain,
    OpPtrAccessChain,
    OpInBoundsPtrAccessChain,
  };
  static std::unordered_set<SPRVWord>
    Allow(std::begin(Table), std::end(Table));
  return Allow.count(OC);
}

SPRVSpecConstantOp *
createSpecConstantOpInst(SPRVInstruction *Inst) {
  auto OC = Inst->getOpCode();
  assert (isSpecConstantOpAllowedOp(OC) &&
      "Op code not allowed for OpSpecConstantOp");
  auto Ops = Inst->getIds(Inst->getOperands());
  Ops.insert(Ops.begin(), OC);
  return static_cast<SPRVSpecConstantOp *>(
    SPRVSpecConstantOp::create(OpSpecConstantOp, Inst->getType(),
        Inst->getId(), Ops, nullptr, Inst->getModule()));
}

SPRVInstruction *
createInstFromSpecConstantOp(SPRVSpecConstantOp *Inst) {
  assert(Inst->getOpCode() == OpSpecConstantOp &&
      "Not OpSpecConstantOp");
  auto Ops = Inst->getOpWords();
  auto OC = static_cast<Op>(Ops[0]);
  assert (isSpecConstantOpAllowedOp(OC) &&
      "Op code not allowed for OpSpecConstantOp");
  Ops.erase(Ops.begin(), Ops.begin() + 1);
  return SPRVInstTemplateBase::create(OC, Inst->getType(),
      Inst->getId(), Ops, nullptr, Inst->getModule());
}

}


