//===- SPRVUtil.cpp –  SPIR-V Utilities -------------------------*- C++ -*-===//
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

#include "SPRVInternal.h"
#include "NameMangleAPI.h"

#include "llvm/ADT/StringSwitch.h"
#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/raw_ostream.h"

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
getOrCreateFunction(Module *M, Type *RetTy, ArrayRef<Type *> ArgTypes,
    StringRef Name, bool Mangle) {
  std::string MangledName = Name;
  if (Mangle)
    mangle(SPRVBIS_OpenCL20, Name, ArgTypes, MangledName);
  FunctionType *FT = FunctionType::get(
      RetTy,
      ArgTypes,
      false);
  Function *F = M->getFunction(MangledName);
  if (!F || F->getFunctionType() != FT) {
    F = Function::Create(FT,
      GlobalValue::ExternalLinkage,
      MangledName,
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
decorateSPRVFunction(const std::string &S) {
  return std::string(SPRV_BUILTIN_PREFIX) + S + SPRV_BUILTIN_POSTFIX;
}

std::string
undecorateSPRVFunction(const std::string& S) {
  assert (S.find(SPRV_BUILTIN_PREFIX) == 0);
  const size_t Start = strlen(SPRV_BUILTIN_PREFIX);
  auto End = S.rfind(SPRV_BUILTIN_POSTFIX);
  return S.substr(Start, End - Start);
}

bool oclIsBuiltin(const StringRef &Name, unsigned SrcLangVer,
                  std::string *DemangledName) {
  if (!Name.startswith("_Z"))
    return false;
  if (!DemangledName)
    return true;
  // OpenCL C++ built-ins are declared in cl namespace.
  // TODO: consider using 'St' abbriviation for cl namespace mangling.
  // Similar to ::std:: in C++.
  if (SrcLangVer == 21) {
    if (!Name.startswith("_ZN"))
      return false;
    // Skip CV and ref qualifiers.
    size_t NameSpaceStart = Name.find_first_not_of("rVKRO", 3);
    // All built-ins are in the ::cl:: namespace.
    if (Name.substr(NameSpaceStart, 3) != "2cl")
      return false;
    size_t DemangledNameLenStart = NameSpaceStart + 3;
    size_t Start = Name.find_first_not_of("0123456789", DemangledNameLenStart);
    size_t Len = 0;
    Name.substr(DemangledNameLenStart, Start - DemangledNameLenStart)
        .getAsInteger(10, Len);
    *DemangledName = Name.substr(Start, Len);
  } else {
    size_t Start = Name.find_first_not_of("0123456789", 2);
    size_t Len = 0;
    Name.substr(2, Start - 2).getAsInteger(10, Len);
    *DemangledName = Name.substr(Start, Len);
  }
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
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    bool Mangle) {
  DEBUG(dbgs() << "[mutateCallInst] " << *CI);

  auto Args = getArguments(CI);
  auto NewName = ArgMutate(CI, Args);
  auto InstName = CI->getName();
  CI->setName(InstName + ".old");
  auto NewCI = addCallInst(M, NewName, CI->getType(), Args, CI, Mangle,
      InstName);
  DEBUG(dbgs() << " => " << *NewCI << '\n');
  CI->replaceAllUsesWith(NewCI);
  CI->dropAllReferences();
  CI->removeFromParent();
}

void
mutateFunction(Function *F,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    bool Mangle) {
  auto M = F->getParent();
  for (auto I = F->user_begin(), E = F->user_end(); I != E; ++I) {
    if (auto CI = dyn_cast<CallInst>(*I))
      mutateCallInst(M, CI, ArgMutate, Mangle);
  }
  if (F->use_empty()) {
    F->dropAllReferences();
    F->removeFromParent();
  }
}

CallInst *
addCallInst(Module *M, StringRef FuncName, Type *RetTy, ArrayRef<Value *> Args,
    Instruction *Pos, bool Mangle, StringRef InstName) {
  auto SupportF = getOrCreateFunction(M, RetTy, getTypes(Args),
      FuncName, Mangle);
  return CallInst::Create(SupportF, Args, InstName, Pos);
}

CallInst *
addBlockBind(Module *M, Function *InvokeFunc, Value *BlkCtx, Value *CtxLen,
    Value *CtxAlign, Instruction *InsPos, StringRef InstName) {
  auto BlkTy = getOrCreateOpaquePtrType(M, SPIR_TYPE_NAME_BLOCK_T,
      SPIRAS_Private);
  auto &Ctx = M->getContext();
  Value *BlkArgs[] = {
      InvokeFunc,
      CtxLen ? CtxLen : UndefValue::get(Type::getInt64Ty(Ctx)),
      CtxAlign ? CtxAlign : UndefValue::get(Type::getInt64Ty(Ctx)),
      BlkCtx ? BlkCtx : UndefValue::get(Type::getInt8PtrTy(Ctx))
  };
  return addCallInst(M, SPIR_INTRINSIC_BLOCK_BIND, BlkTy, BlkArgs, InsPos,
      false, InstName);
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
isSPRVFunction(Function *F, std::string *UndecoratedName) {
  if (!F->hasName() || !F->getName().startswith(SPRV_BUILTIN_PREFIX))
    return false;
  if (UndecoratedName)
    *UndecoratedName = undecorateSPRVFunction(F->getName());
  return true;
}

// Translated uniqued OCL builtin name to its original name, and set
// argument attributes and unsigned args.
static void
getOCLBuiltinArgInfo(std::string& UnmangledName,
    std::set<int> &UnsignedArgs, unsigned& Attr) {
  if (UnmangledName.find("write_imageui") == 0)
      UnsignedArgs.insert(2);
  else if (UnmangledName.find("get_") == 0 ||
      UnmangledName.find("barrier") == 0 ||
      UnmangledName.find("vload") == 0 ||
      UnmangledName.find("vstore") == 0 ||
      UnmangledName.find("async_work_group") == 0 ||
      UnmangledName == "prefetch" ||
      UnmangledName == "nan" ||
      UnmangledName.find("shuffle") == 0 ||
      UnmangledName.find("ndrange_") == 0)
    UnsignedArgs.insert(-1);
  else if (UnmangledName.find("atomic") == 0) {
    Attr = SPIR::ATTR_VOLATILE;
    if (UnmangledName == "atomic_umax" ||
        UnmangledName == "atomic_umin") {
      UnsignedArgs.insert(-1);
      UnmangledName.erase(7, 1);
    }
  } else if (UnmangledName.find("uconvert_") == 0) {
    UnsignedArgs.insert(0);
    UnmangledName.erase(0, 1);
  } else if (UnmangledName.find("s_") == 0) {
    UnmangledName.erase(0, 2);
  } else if (UnmangledName.find("u_") == 0) {
    UnsignedArgs.insert(-1);
    UnmangledName.erase(0, 2);
  }
}

//ToDo: add translation of all LLVM types
static SPIR::RefParamType
transTypeDesc(Type *Ty, bool Signed = true, unsigned Attr = 0) {
  if(auto *IntTy = dyn_cast<IntegerType>(Ty)) {
    switch(IntTy->getBitWidth()) {
    case 8:
      return SPIR::RefParamType(new SPIR::PrimitiveType(Signed?
          SPIR::PRIMITIVE_CHAR:SPIR::PRIMITIVE_UCHAR));
    case 16:
      return SPIR::RefParamType(new SPIR::PrimitiveType(Signed?
          SPIR::PRIMITIVE_SHORT:SPIR::PRIMITIVE_USHORT));
    case 32:
      return SPIR::RefParamType(new SPIR::PrimitiveType(Signed?
          SPIR::PRIMITIVE_INT:SPIR::PRIMITIVE_UINT));
    case 64:
      return SPIR::RefParamType(new SPIR::PrimitiveType(Signed?
          SPIR::PRIMITIVE_LONG:SPIR::PRIMITIVE_ULONG));
    default:
      assert(0 && "invliad int size");
    }
  }
  if (Ty->isVoidTy())
    return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_VOID));
  if (Ty->isHalfTy())
    return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_HALF));
  if (Ty->isFloatTy())
    return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_FLOAT));
  if (Ty->isDoubleTy())
    return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_DOUBLE));
  if (Ty->isVectorTy()) {
    return SPIR::RefParamType(new SPIR::VectorType(
        transTypeDesc(Ty->getVectorElementType(), Signed),
        Ty->getVectorNumElements()));
  }
  if (Ty->isPointerTy()) {
    if (auto StructTy = dyn_cast<StructType>(Ty->getPointerElementType())) {
      DEBUG(dbgs() << "ptr to struct: " << *Ty << '\n');
      if (StructTy->getStructName() == "opencl.block")
        return SPIR::RefParamType(new SPIR::BlockType);

#define _SPRV_OP(x,y) .Case("opencl."#x"_t", SPIR::PRIMITIVE_##y##_T)
      return SPIR::RefParamType(new SPIR::PrimitiveType(
          StringSwitch<SPIR::TypePrimitiveEnum>(StructTy->getStructName())
          _SPRV_OP(image1d, IMAGE_1D)
          _SPRV_OP(image1d_array, IMAGE_1D_ARRAY)
          _SPRV_OP(image1d_buffer, IMAGE_1D_BUFFER)
          _SPRV_OP(image2d, IMAGE_2D)
          _SPRV_OP(image2d_array, IMAGE_2D_ARRAY)
          _SPRV_OP(image3d, IMAGE_3D)
          _SPRV_OP(image2d_msaa, IMAGE_2D_MSAA)
          _SPRV_OP(image2d_array_msaa, IMAGE_2D_ARRAY_MSAA)
          _SPRV_OP(image2d_msaa_depth, IMAGE_2D_MSAA_DEPTH)
          _SPRV_OP(image2d_array_msaa_depth, IMAGE_2D_ARRAY_MSAA_DEPTH)
          _SPRV_OP(image2d_depth, IMAGE_2D_DEPTH)
          _SPRV_OP(image2d_array_depth, IMAGE_2D_ARRAY_DEPTH)
          _SPRV_OP(event, EVENT)
          _SPRV_OP(pipe, PIPE)
          _SPRV_OP(reserve_id, RESERVE_ID)
          _SPRV_OP(queue, QUEUE)
          _SPRV_OP(clk_event, CLK_EVENT)
          _SPRV_OP(sampler, SAMPLER)
          .Case("struct.ndrange_t", SPIR::PRIMITIVE_NDRANGE_T)
          ));
#undef _SPRV_OP
    }
    auto PT = new SPIR::PointerType(transTypeDesc(
      Ty->getPointerElementType(), Signed));
    PT->setAddressSpace(static_cast<SPIR::TypeAttributeEnum>(
      Ty->getPointerAddressSpace() + (unsigned)SPIR::ATTR_ADDR_SPACE_FIRST));
    for (unsigned I = SPIR::ATTR_QUALIFIER_FIRST,
        E = SPIR::ATTR_QUALIFIER_LAST; I != E; ++I)
      PT->setQualifier(static_cast<SPIR::TypeAttributeEnum>(I), I & Attr);
    return SPIR::RefParamType(PT);
  }
  DEBUG(dbgs() << "[transTypeDesc] " << *Ty << '\n');
  assert (0 && "not implemented");
  return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_INT));
}

// If SignedArgIndices contains -1, all integer arment is signed.
void
mangle(SPRVExtInstSetKind BuiltinSet, const std::string &UnmangledName,
    ArrayRef<Type*> ArgTypes, std::string &MangledName) {
  assert(isOpenCLBuiltinSet(BuiltinSet) && "Not OpenCL builtin set");
  SPIR::NameMangler Mangler(BuiltinSet == SPRVBIS_OpenCL12 ? SPIR::SPIR12 :
      SPIR::SPIR20);
  SPIR::FunctionDescriptor FD;
  FD.name = UnmangledName;
  std::set<int> UnsignedArgs;
  unsigned Attr = 0;
  getOCLBuiltinArgInfo(FD.name, UnsignedArgs, Attr);
  for (unsigned I = 0, E = ArgTypes.size(); I != E; ++I) {
    FD.parameters.emplace_back(transTypeDesc(ArgTypes[I],
        !UnsignedArgs.count(-1) && !UnsignedArgs.count(I),
        Attr));
  }
  Mangler.mangle(FD, MangledName);
}

}
