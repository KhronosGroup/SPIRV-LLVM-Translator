//===- LLVMSPRVUtil.cpp –  SPIR-V Utilities ---------------------*- C++ -*-===//
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
/// This file defines utility classes and functions shared by SPIR-V
/// reader/writer.
///
//===----------------------------------------------------------------------===//
#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/raw_ostream.h"

#include "SPRVInternal.h"

#include <functional>

#define DEBUG_TYPE "spirv"

namespace SPRV{

cl::opt<bool, true>
UseTextFormat("spirv-text",
    cl::desc("Use text format for SPIR-V for debugging purpose"),
    cl::location(SPRVDbgUseTextFormat));

cl::opt<bool, true>
EnableDbgOutput("spirv-debug",
    cl::desc("Enable SPIR-V debug output"),
    cl::location(SPRVDbgEnable));

void
addFnAttr(LLVMContext *Context, CallInst *Call, Attribute::AttrKind Attr) {
  Call->addAttribute(AttributeSet::FunctionIndex, Attr);
}

void
removeFnAttr(LLVMContext *Context, CallInst *Call, Attribute::AttrKind Attr) {
  Call->removeAttribute(AttributeSet::FunctionIndex,
      Attribute::get(*Context, Attr));
}

void
saveLLVMModule(Module *M, const std::string &OutputFile) {
  std::error_code EC;
  tool_output_file Out(OutputFile.c_str(), EC, sys::fs::F_None);
  if (EC) {
    SPRVDBG(errs() << "Fails to open output file: " << EC.message();)
    return;
  }

  WriteBitcodeToFile(M, Out.os());
  Out.keep();
}

std::string
mapLLVMTypeToOpenCLType(Type* Ty, bool Signed) {
  if (Ty->isHalfTy())
    return "half";
  if (Ty->isFloatTy())
    return "float";
  if (Ty->isDoubleTy())
    return "double";
  if (IntegerType* intTy = dyn_cast<IntegerType>(Ty)) {
    std::string SignPrefix;
    std::string Stem;
    if (!Signed)
      SignPrefix = "u";
    switch (intTy->getIntegerBitWidth()) {
    case 8:
      Stem = "char";
      break;
    case 16:
      Stem = "short";
      break;
    case 32:
      Stem = "int";
      break;
    case 64:
      Stem = "long";
      break;
    default:
      Stem = "invalid_type";
      break;
    }
    return SignPrefix + Stem;
  }
  if (VectorType* vecTy = dyn_cast<VectorType>(Ty)) {
    Type* eleTy = vecTy->getElementType();
    unsigned size = vecTy->getVectorNumElements();
    std::stringstream ss;
    ss << mapLLVMTypeToOpenCLType(eleTy, Signed) << size;
    return ss.str();
  }
  return "invalid_type";
}

std::string
mapSPRVTypeToOpenCLType(SPRVType* Ty, bool Signed) {
  if (Ty->isTypeFloat()) {
    auto W = Ty->getBitWidth();
    switch (W) {
    case 16:
      return "half";
    case 32:
      return "float";
    case 64:
      return "double";
    default:
      assert (0 && "Invalid floating pointer type");
      return std::string("float") + W + "_t";
    }
  }
  if (Ty->isTypeInt()) {
    std::string SignPrefix;
    std::string Stem;
    if (!Signed)
      SignPrefix = "u";
    auto W = Ty->getBitWidth();
    switch (W) {
    case 8:
      Stem = "char";
      break;
    case 16:
      Stem = "short";
      break;
    case 32:
      Stem = "int";
      break;
    case 64:
      Stem = "long";
      break;
    default:
      assert(0 && "Invalid integer type");
      Stem = std::string("int") + W + "_t";
      break;
    }
    return SignPrefix + Stem;
  }
  if (Ty->isTypeVector()) {
    auto eleTy = Ty->getVectorComponentType();
    auto size = Ty->getVectorComponentCount();
    std::stringstream ss;
    ss << mapSPRVTypeToOpenCLType(eleTy, Signed) << size;
    return ss.str();
  }
  assert(0 && "Invalid type");
  return "unknown_type";
}

PointerType*
getOrCreateOpaquePtrType(Module *M, const std::string &Name,
    unsigned AddrSpace) {
  auto OpaqueType = M->getTypeByName(Name);
  if (!OpaqueType)
    OpaqueType = StructType::create(M->getContext(), Name);
  return PointerType::get(OpaqueType, AddrSpace);
}

void
getFunctionTypeParameterTypes(llvm::FunctionType* FT,
    std::vector<Type*>& ArgTys) {
  for (auto I = FT->param_begin(), E = FT->param_end(); I != E; ++I) {
    ArgTys.push_back(*I);
  }
}

bool
isPointerToOpaqueStructType(llvm::Type* Ty) {
  if (auto PT = dyn_cast<PointerType>(Ty))
    if (auto ST = dyn_cast<StructType>(PT->getElementType()))
      if (ST->isOpaque())
        return true;
  return false;
}

bool
isPointerToOpaqueStructType(llvm::Type* Ty, const std::string &Name) {
  if (auto PT = dyn_cast<PointerType>(Ty))
    if (auto ST = dyn_cast<StructType>(PT->getElementType()))
      if (ST->isOpaque() && ST->getName() == Name)
        return true;
  return false;
}

Function *
getOrCreateFunction(Module *M, Type *RetTy,
    ArrayRef<Type *> ArgTypes, StringRef Name) {
  FunctionType *FT = FunctionType::get(
      RetTy,
      ArgTypes,
      false);
  Function *F = M->getFunction(Name);
  if (!F || F->getFunctionType() != FT) {
    F = Function::Create(FT,
      GlobalValue::ExternalLinkage,
      Name,
      M);
    F->setCallingConv(CallingConv::SPIR_FUNC);
  }
  return F;
}

std::vector<Value *>
getArguments(CallInst* CI) {
  std::vector<Value*> Args;
  for (unsigned I = 0, E = CI->getNumArgOperands(); I != E; ++I) {
    Args.push_back(CI->getArgOperand(I));
  }
  return Args;
}


std::string
addSPRVPrefix(const std::string S) {
  return std::string(SPRV_BUILTIN_PREFIX) + S;
}

std::string
removeSPRVPrefix(const std::string S) {
  assert (S.find(SPRV_BUILTIN_PREFIX) == 0);
  const size_t Len = strlen(SPRV_BUILTIN_PREFIX);
  return S.substr(Len);
}

bool
oclIsBuiltin(const StringRef& Name,
    std::string* DemangledName) {
  if (!Name.startswith("_Z"))
    return false;
  if (!DemangledName)
    return true;
  size_t Start = Name.find_first_not_of("0123456789", 2);
  size_t Len = 0;
  Name.substr(2, Start - 2).getAsInteger(10, Len);
  *DemangledName = Name.substr(Start, Len);
  return true;
}

bool
isFunctionPointerType(Type *T) {
  if (isa<PointerType>(T) &&
      isa<FunctionType>(T->getPointerElementType())) {
    return true;
  }
  return false;
}

bool
hasFunctionPointerArg(Function *F, Function::arg_iterator& AI) {
  AI = F->arg_begin();
  for (auto AE = F->arg_end(); AI != AE; ++AI) {
    DEBUG(dbgs() << "[hasFuncPointerArg] " << *AI << '\n');
    if (isFunctionPointerType(AI->getType())) {
      return true;
    }
  }
  return false;
}

void
mutateCallInst(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate) {
  DEBUG(dbgs() << "[mutateCallInst] " << *CI);

  auto Args = getArguments(CI);
  auto NewName = ArgMutate(CI, Args);
  auto InstName = CI->getName();
  CI->setName(InstName + ".old");
  auto NewCI = addCallInst(M, NewName, CI->getType(), Args, CI, InstName);
  DEBUG(dbgs() << " => " << *NewCI << '\n');
  CI->replaceAllUsesWith(NewCI);
  CI->dropAllReferences();
  CI->removeFromParent();
}

void
mutateFunction(Function *F,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate) {
  auto M = F->getParent();
  for (auto I = F->user_begin(), E = F->user_end(); I != E; ++I) {
    if (auto CI = dyn_cast<CallInst>(*I))
      mutateCallInst(M, CI, ArgMutate);
  }
  if (F->use_empty()) {
    F->dropAllReferences();
    F->removeFromParent();
  }
}

CallInst *
addCallInst(Module *M, StringRef FuncName, Type *RetTy, ArrayRef<Value *> Args,
    Instruction *Pos, StringRef InstName) {
  auto SupportF = getOrCreateFunction(M, RetTy, getTypes(Args),
      FuncName);
  return CallInst::Create(SupportF, Args, InstName, Pos);
}

CallInst *
addBlockBind(Module *M, Function *InvokeFunc, Value *BlkCtx, unsigned CtxLen,
    unsigned CtxAlign, Instruction *InsPos, StringRef InstName) {
  auto BlkTy = getOrCreateOpaquePtrType(M, SPIR_TYPE_NAME_BLOCK_T,
      SPIRAS_Private);
  Value *BlkArgs[] = {
      InvokeFunc,
      BlkCtx ? BlkCtx : UndefValue::get(Type::getInt8PtrTy(M->getContext())),
      getInt64(M, CtxLen),
      getInt64(M, CtxAlign)
  };
  return addCallInst(M, SPIR_INTRINSIC_BLOCK_BIND, BlkTy, BlkArgs, InsPos,
      InstName);
}

ConstantInt *
getInt64(Module *M, int64_t value) {
  return ConstantInt::get(Type::getInt64Ty(M->getContext()), value, true);
}

ConstantInt *
getInt32(Module *M, int value) {
  return ConstantInt::get(Type::getInt32Ty(M->getContext()), value, true);
}

bool
isSPRVSupportFunction(Function *F) {
  return F->hasName() && F->getName().startswith(SPRV_BUILTIN_PREFIX);
}
}
