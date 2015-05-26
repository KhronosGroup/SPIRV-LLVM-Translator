//===- LLVMSPRVUtil.cpp –  SPRV-LLVM Utilities --------------------*- C++ -*-===//
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
// This file defines classes and functions shared by SPIRV reader/writer.
//
//===----------------------------------------------------------------------===//
#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/Support/ToolOutputFile.h"
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
#include "llvm/Support/FileSystem.h"
#endif

#include "LLVMSPRVInternal.h"

namespace SPRV{

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
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  std::error_code EC;
  tool_output_file Out(OutputFile.c_str(), EC, sys::fs::F_None);
  if (EC) {
    SPRVDBG(errs() << "Fails to open output file: " << EC.message();)
    return;
  }

  WriteBitcodeToFile(M, Out.os());
  Out.keep();
#else
  std::string Err;
  OwningPtr<tool_output_file> Out(new tool_output_file(OutputFile.c_str(), Err,
    sys::fs::F_Binary));
  if (!Err.empty()) {
    SPRVDBG(errs() << "Fails to open output file: " << Err;)
        return;
    }

  WriteBitcodeToFile(M, Out->os());
  Out->keep();
#endif
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
getOrCreateOpaquePtrType(Module *M, const std::string &Name) {
  auto OpaqueType = M->getTypeByName(Name);
  if (!OpaqueType)
    OpaqueType = StructType::create(M->getContext(), Name);
  return PointerType::get(OpaqueType, SPIRAS_Global);
}

}
