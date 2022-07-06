//===- SPIRVBuiltinHelper.h - Helpers for managing calls to builtins ------===//
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

#ifndef SPIRVBUILTINHELPER_H
#define SPIRVBUILTINHELPER_H

#include "libSPIRV/SPIRVOpCode.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/IRBuilder.h"

namespace SPIRV {
enum class ManglingRules {
  None,
  OpenCL,
  SPIRV
};

class BuiltinCallMutator {
  llvm::CallInst *CI;
  std::string FuncName;
  std::function<llvm::Value *(llvm::IRBuilder<> &, llvm::CallInst *)> MutateRet;
  typedef decltype(MutateRet) MutateRetFuncTy;
  llvm::AttributeList Attrs;
  llvm::Type *ReturnTy;
  llvm::SmallVector<llvm::Value *, 8> Args;
  llvm::SmallVector<llvm::Type *, 8> PointerElementTypes;
  ManglingRules Rules;

  friend class BuiltinCallHelper;
  BuiltinCallMutator(llvm::CallInst *CI, std::string FuncName,
      ManglingRules Rules);

  void setElementType(unsigned Index, llvm::Type *ElementType);

public:
  ~BuiltinCallMutator();
  BuiltinCallMutator(const BuiltinCallMutator &) = delete;
  BuiltinCallMutator &operator=(const BuiltinCallMutator &) = delete;
  BuiltinCallMutator &operator=(BuiltinCallMutator &&) = delete;

  // The move constructor shouldn't be called ever, but there's no way to return
  // a non-movable, non-copyable type in C++14 without a valid move constructor,
  // even if the move constructor would never be called. By not providing a move
  // constructor, we'll guarantee that any move that isn't elided produces an
  // error of some kind (even if it is a link error). In C++17 mode, however,
  // we'll have a fully-deleted constructor to make it a compiler error instead.
#ifndef __cpp_guaranteed_copy_elision
  BuiltinCallMutator(BuiltinCallMutator &&);
#else
  BuiltinCallMutator(BuiltinCallMutator &&) = delete;
#endif

  llvm::Value *getArg(unsigned Index) const { return Args[Index]; }

  struct ValueTypePair : public std::pair<llvm::Value *, llvm::Type *> {
    ValueTypePair(llvm::Value *V) : pair(V, nullptr) {
      assert(!V->getType()->isPointerTy() &&
          "Must specify a pointer element type if value is a pointer.");
    }
    ValueTypePair(std::pair<llvm::Value *, llvm::Type *> P) : pair(P) {}
    ValueTypePair(llvm::Value *V, llvm::Type * T) : pair(V, T) {}
  };


  /// Use the following arguments as the arguments of the new call, replacing
  /// any previous arguments. This version may not be used if any argument is of
  /// pointer type.
  BuiltinCallMutator &setArgs(llvm::ArrayRef<llvm::Value *> Args);

  BuiltinCallMutator &changeReturnType(llvm::Type *ReturnTy,
      MutateRetFuncTy MutateFunc);

  /// Insert an argument before the given index. This version may not be used if
  /// the argument is of pointer type.
  BuiltinCallMutator &insertArg(unsigned Index, ValueTypePair Arg);

  /// Add an argument to the end of the argument list.
  BuiltinCallMutator &appendArg(llvm::Value *Arg) {
    return insertArg(Args.size(), Arg);
  }

  BuiltinCallMutator &replaceArg(unsigned Index, ValueTypePair Arg);

  BuiltinCallMutator &removeArg(unsigned Index);

  BuiltinCallMutator &moveArg(unsigned FromIndex, unsigned ToIndex) {
    if (FromIndex == ToIndex)
      return *this;
    ValueTypePair Pair(Args[FromIndex], PointerElementTypes[FromIndex]);
    removeArg(FromIndex);
    insertArg(ToIndex, Pair);
    return *this;
  }

  template <typename FnType>
  BuiltinCallMutator &mapArg(unsigned Index, FnType Func,
      std::enable_if_t<llvm::is_invocable<FnType, llvm::Value*>::value>* = nullptr) {
    replaceArg(Index, Func(Args[Index]));
    return *this;
  }

  template <typename FnType>
  BuiltinCallMutator &mapArg(unsigned Index, FnType Func,
      std::enable_if_t<llvm::is_invocable<FnType, llvm::Value*, llvm::Type*>::value>* = nullptr) {
    replaceArg(Index, Func(Args[Index], PointerElementTypes[Index]));
    return *this;
  }

  template <typename FnType>
  BuiltinCallMutator &mapArgs(FnType Func) {
    for (unsigned I = 0, E = Args.size(); I < E; I++)
      mapArg(I, Func);
    return *this;
  }
};

class BuiltinCallHelper {
  ManglingRules Rules;

protected:
  llvm::Module *M = nullptr;

public:
  explicit BuiltinCallHelper(ManglingRules Rules) : Rules(Rules) {}
  void initialize(llvm::Module &M) { this->M = &M; }

  BuiltinCallMutator mutateCallInst(llvm::CallInst *CI, spv::Op Opcode);
  BuiltinCallMutator mutateCallInst(llvm::CallInst *CI, std::string FuncName);
};

} // namespace SPIRV

#endif // SPIRVBUILTINHELPER_H
