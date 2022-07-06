//===- SPIRVBuiltinHelper.cpp - Helpers for managing calls to builtins ----===//
//
//                     The LLVM/SPIR-V Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2022 The Khronos Group Inc.
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
// Neither the names of The Khronos Group, nor the names of its
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
// This file implements helper functions for adding calls to OpenCL or SPIR-V
// builtin functions, or for rewriting calls to one into calls to the other.
//
//===----------------------------------------------------------------------===//

#include "SPIRVBuiltinHelper.h"
#include "SPIRVInternal.h"

using namespace llvm;
using namespace SPIRV;

static std::unique_ptr<BuiltinFuncMangleInfo> makeMangler(ManglingRules Rules) {
  switch (Rules) {
  case ManglingRules::None:
    return nullptr;
  case ManglingRules::SPIRV:
    return std::make_unique<BuiltinFuncMangleInfo>();
  case ManglingRules::OpenCL:
    assert(false && "Not yet implemented");
    return nullptr;
  }
}

BuiltinCallMutator::BuiltinCallMutator(CallInst *CI, std::string FuncName,
    ManglingRules Rules)
: CI(CI), FuncName(FuncName), Attrs(CI->getAttributes()),
  ReturnTy(CI->getType()), Args(CI->args()), Rules(Rules) {
  // XXX: replace this with real stuff
  for (Value *Arg : Args) {
    Type *PET = Arg->getType()->isPointerTy() ? Arg->getType()->getPointerElementType() : nullptr;
    PointerElementTypes.push_back(PET);
  }
}

#if 0
BuiltinCallMutator::BuiltinCallMutator(BuiltinCallMutator &&Other)
: CI(Other.CI), FuncName(std::move(Other.FuncName)),
  MutateRet(std::move(Other.MutateRet)), Attrs(Other.Attrs),
  ReturnTy(Other.ReturnTy), Args(std::move(Other.Args)),
  Rules(std::move(Other.Rules)) {
  // Clear the other's CI instance so that it knows not to construct the actual
  // call.
  Other.CI = nullptr;
}
#endif

BuiltinCallMutator::~BuiltinCallMutator() {
  if (!CI)
    return;
  IRBuilder<> Builder(CI);
  auto Mangler = makeMangler(Rules);
  for (unsigned I = 0; I < Args.size(); I++)
    Mangler->getTypeMangleInfo(I).PointerElementType = PointerElementTypes[I];
  CallInst *NewCall = Builder.Insert(
    addCallInst(CI->getModule(), FuncName, ReturnTy, Args, &Attrs, nullptr,
      Mangler.get()));
  Value *Result = MutateRet ? MutateRet(Builder, NewCall) : NewCall;
  Result->takeName(CI);
  if (!CI->getType()->isVoidTy())
    CI->replaceAllUsesWith(Result);
  CI->eraseFromParent();
}

BuiltinCallMutator &BuiltinCallMutator::setArgs(ArrayRef<Value *> NewArgs) {
  // Retain only the function attributes, not any parameter attributes.
  Attrs = AttributeList::get(CI->getContext(),
      Attrs.getFnAttrs(), Attrs.getRetAttrs(), {});
  Args.clear();
  PointerElementTypes.clear();
  for (Value *Arg : NewArgs) {
    //assert(!Arg->getType()->isPointerTy() &&
    //  "Cannot use this signature with pointer types");
    Args.push_back(Arg);
    // XXX
    Type *PET = Arg->getType()->isPointerTy() ? Arg->getType()->getPointerElementType() : nullptr;
    PointerElementTypes.push_back(PET);
  }
  return *this;
}

static void moveAttributes(LLVMContext &Ctx, AttributeList &Attrs,
    unsigned Start, unsigned Len, unsigned Dest) {
  unsigned CopyFromIndex = Start;
  unsigned CopyToIndex = Dest;
  signed Dir = 1;
  // If we would overwrite the values we need to copy going from low to high,
  // reverse the dierction.
  if (Start < Dest && Dest < Start + Len) {
    Dir = -1;
    CopyFromIndex += Len - 1;
    CopyToIndex += Len - 1;
  }
  for (unsigned Index = 0; Index < Len; Index++, CopyFromIndex += Dir,
      CopyToIndex += Dir) {
    AttributeSet ParamAttrs = Attrs.getParamAttrs(CopyFromIndex);
    Attrs = Attrs.removeParamAttributes(Ctx, CopyToIndex);
    Attrs = Attrs.addParamAttributes(Ctx, CopyToIndex,
        AttrBuilder(Ctx, ParamAttrs));
  }
}

BuiltinCallMutator &BuiltinCallMutator::insertArg(unsigned Index,
    ValueTypePair Arg) {
  // Move all the param attributes
  moveAttributes(CI->getContext(), Attrs, Index, Args.size() - Index,
      Index + 1);
  Args.insert(Args.begin() + Index, Arg.first);
  PointerElementTypes.insert(PointerElementTypes.begin() + Index, Arg.second);
  return *this;
}

BuiltinCallMutator &BuiltinCallMutator::replaceArg(unsigned Index,
    ValueTypePair Arg) {
  Args[Index] = Arg.first;
  Attrs = Attrs.removeParamAttributes(CI->getContext(), Index);
  PointerElementTypes[Index] = Arg.second;
  return *this;
}

BuiltinCallMutator &BuiltinCallMutator::removeArg(unsigned Index) {
  moveAttributes(CI->getContext(), Attrs, Index + 1, Args.size() - Index - 1,
    Index);
  Args.erase(Args.begin() + Index);
  PointerElementTypes.erase(PointerElementTypes.begin() + Index);
  return *this;
}

BuiltinCallMutator &BuiltinCallMutator::changeReturnType(Type *NewReturnTy,
    MutateRetFuncTy MutateFunc) {
  ReturnTy = NewReturnTy;
  MutateRet = std::move(MutateFunc);
  return *this;
}

BuiltinCallMutator BuiltinCallHelper::mutateCallInst(CallInst *CI, spv::Op Opcode) {
  return mutateCallInst(CI, getSPIRVFuncName(Opcode));
}

BuiltinCallMutator BuiltinCallHelper::mutateCallInst(CallInst *CI, std::string FuncName) {
  return BuiltinCallMutator(CI, std::move(FuncName), Rules);
}
