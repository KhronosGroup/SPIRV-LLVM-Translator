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

#ifdef _SPRV_SUPPORT_TEXT_FMT
cl::opt<bool, true>
UseTextFormat("spirv-text",
    cl::desc("Use text format for SPIR-V for debugging purpose"),
    cl::location(SPRVUseTextFormat));
#endif

#ifdef _SPRVDBG
cl::opt<bool, true>
EnableDbgOutput("spirv-debug",
    cl::desc("Enable SPIR-V debug output"),
    cl::location(SPRVDbgEnable));
#endif

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
      llvm_unreachable("Invalid integer type");
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
  llvm_unreachable("Invalid type");
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

bool
isOCLImageType(llvm::Type* Ty, StringRef *Name) {
  if (auto PT = dyn_cast<PointerType>(Ty))
    if (auto ST = dyn_cast<StructType>(PT->getElementType()))
      if (ST->isOpaque()) {
        auto FullName = ST->getName();
        if (FullName.find(kSPR2TypeName::ImagePrefix) == 0) {
          if (Name)
            *Name = FullName.drop_front(strlen(kSPR2TypeName::OCLPrefix));
          return true;
        }
      }
  return false;
}

Function *
getOrCreateFunction(Module *M, Type *RetTy, ArrayRef<Type *> ArgTypes,
    StringRef Name, bool Mangle, AttributeSet *Attrs, bool takeName) {
  std::string MangledName = Name;
  if (Mangle)
    mangleOCLBuiltin(SPRVBIS_OpenCL20, Name, ArgTypes, MangledName);
  FunctionType *FT = FunctionType::get(
      RetTy,
      ArgTypes,
      false);
  Function *F = M->getFunction(MangledName);
  if (!F || F->getFunctionType() != FT) {
    auto NewF = Function::Create(FT,
      GlobalValue::ExternalLinkage,
      MangledName,
      M);
    if (F && takeName)
      NewF->takeName(F);
    DEBUG(dbgs() << "[getOrCreateFunction] ";
      if (F)
        dbgs() << *F << " => ";
      dbgs() << *NewF << '\n';
      );
    F = NewF;
    F->setCallingConv(CallingConv::SPIR_FUNC);
    if (Attrs)
      F->setAttributes(*Attrs);
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
  return std::string(kSPRVName::Prefix) + S + kSPRVName::Postfix;
}

std::string
undecorateSPRVFunction(const std::string& S) {
  assert (S.find(kSPRVName::Prefix) == 0);
  const size_t Start = strlen(kSPRVName::Prefix);
  auto End = S.rfind(kSPRVName::Postfix);
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
    if (Name.substr(NameSpaceStart, 11) != "2cl7__spirv")
      return false;
    size_t DemangledNameLenStart = NameSpaceStart + 11;
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

bool
hasArrayArg(Function *F) {
  for (auto I = F->arg_begin(), E = F->arg_end(); I != E; ++I) {
    DEBUG(dbgs() << "[hasArrayArg] " << *I << '\n');
    if (I->getType()->isArrayTy()) {
      return true;
    }
  }
  return false;
}

CallInst *
mutateCallInst(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    bool Mangle, AttributeSet *Attrs, bool TakeFuncName) {
  DEBUG(dbgs() << "[mutateCallInst] " << *CI);

  auto Args = getArguments(CI);
  auto NewName = ArgMutate(CI, Args);
  StringRef InstName;
  if (!CI->getType()->isVoidTy() && CI->hasName()) {
    InstName = CI->getName();
    CI->setName(InstName + ".old");
  }
  auto NewCI = addCallInst(M, NewName, CI->getType(), Args, Attrs, CI, Mangle,
      InstName, TakeFuncName);
  DEBUG(dbgs() << " => " << *NewCI << '\n');
  CI->replaceAllUsesWith(NewCI);
  CI->dropAllReferences();
  CI->removeFromParent();
  return NewCI;
}

Instruction *
mutateCallInst(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &,
        Type *&RetTy)>ArgMutate,
    std::function<Instruction *(CallInst *)> RetMutate,
    bool Mangle, AttributeSet *Attrs, bool TakeFuncName) {
  DEBUG(dbgs() << "[mutateCallInst] " << *CI);

  auto Args = getArguments(CI);
  Type *RetTy = CI->getType();
  auto NewName = ArgMutate(CI, Args, RetTy);
  StringRef InstName;
  if (CI->hasName()) {
    InstName = CI->getName();
    CI->setName(InstName + ".old");
  }
  auto NewCI = addCallInst(M, NewName, RetTy, Args, Attrs,
      CI, Mangle, InstName.str() + ".tmp", TakeFuncName);
  auto NewI = RetMutate(NewCI);
  NewI->takeName(CI);
  DEBUG(dbgs() << " => " << *NewI << '\n');
  CI->replaceAllUsesWith(NewI);
  CI->dropAllReferences();
  CI->removeFromParent();
  return NewI;
}

void
mutateFunction(Function *F,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    bool Mangle, AttributeSet *Attrs, bool TakeFuncName) {
  auto M = F->getParent();
  for (auto I = F->user_begin(), E = F->user_end(); I != E;) {
    if (auto CI = dyn_cast<CallInst>(*I++))
      mutateCallInst(M, CI, ArgMutate, Mangle, Attrs, TakeFuncName);
  }
  if (F->use_empty()) {
    F->dropAllReferences();
    F->removeFromParent();
  }
}

CallInst *
addCallInst(Module *M, StringRef FuncName, Type *RetTy, ArrayRef<Value *> Args,
    AttributeSet *Attrs, Instruction *Pos, bool Mangle, StringRef InstName,
    bool TakeFuncName) {
  auto F = getOrCreateFunction(M, RetTy, getTypes(Args),
      FuncName, Mangle, Attrs, TakeFuncName);
  auto CI = CallInst::Create(F, Args, InstName, Pos);
  CI->setCallingConv(F->getCallingConv());
  return CI;
}

Constant *
castToInt8Ptr(Constant *V, unsigned Addr = 0) {
  return ConstantExpr::getBitCast(V, Type::getInt8PtrTy(V->getContext(), Addr));
}

CallInst *
addBlockBind(Module *M, Function *InvokeFunc, Value *BlkCtx, Value *CtxLen,
    Value *CtxAlign, Instruction *InsPos, StringRef InstName) {
  auto BlkTy = getOrCreateOpaquePtrType(M, SPIR_TYPE_NAME_BLOCK_T,
      SPIRAS_Private);
  auto &Ctx = M->getContext();
  Value *BlkArgs[] = {
      castToInt8Ptr(InvokeFunc),
      CtxLen ? CtxLen : UndefValue::get(Type::getInt32Ty(Ctx)),
      CtxAlign ? CtxAlign : UndefValue::get(Type::getInt32Ty(Ctx)),
      BlkCtx ? BlkCtx : UndefValue::get(Type::getInt8PtrTy(Ctx))
  };
  return addCallInst(M, SPIR_INTRINSIC_BLOCK_BIND, BlkTy, BlkArgs, nullptr,
      InsPos, false, InstName);
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
isSPRVFunction(const Function *F, std::string *UndecoratedName) {
  if (!F->hasName() || !F->getName().startswith(kSPRVName::Prefix))
    return false;
  if (UndecoratedName)
    *UndecoratedName = undecorateSPRVFunction(F->getName());
  return true;
}

/// Additional information for mangling a function argument type.
struct OCLTypeMangleInfo {
  bool IsSigned;
  bool IsVoidPtr;
  bool IsEnum;
  bool IsSampler;
  SPIR::TypePrimitiveEnum Enum;
  unsigned Attr;
  OCLTypeMangleInfo():IsSigned(true), IsVoidPtr(false), IsEnum(false),
      IsSampler(false), Enum(SPIR::PRIMITIVE_NONE), Attr(0){}
};

/// Information for mangling an OpenCL builtin function.
class OCLBuiltinMangleInfo {
public:
  /// Translated uniqued OCL builtin name to its original name, and set
  /// argument attributes and unsigned args.
  OCLBuiltinMangleInfo(const std::string &UniqName);
  const std::string &getUnmangledName() const { return UnmangledName;}
  void addUnsignedArg(int Ndx) { UnsignedArgs.insert(Ndx);}
  void addVoidPtrArg(int Ndx) { VoidPtrArgs.insert(Ndx);}
  void addSamplerArg(int Ndx) { SamplerArgs.insert(Ndx);}
  void setEnumArg(int Ndx, SPIR::TypePrimitiveEnum Enum) {
    EnumArgs[Ndx] = Enum;}
  void setArgAttr(int Ndx, unsigned Attr) {
    Attrs[Ndx] = Attr;}
  bool isArgUnsigned(int Ndx) {
    return UnsignedArgs.count(-1) || UnsignedArgs.count(Ndx);}
  bool isArgVoidPtr(int Ndx) {
    return VoidPtrArgs.count(-1) || VoidPtrArgs.count(Ndx);}
  bool isArgSampler(int Ndx) {
    return SamplerArgs.count(Ndx);}
  bool isArgEnum(int Ndx, SPIR::TypePrimitiveEnum *Enum = nullptr) {
    auto Loc = EnumArgs.find(Ndx);
    if (Loc == EnumArgs.end())
      Loc = EnumArgs.find(-1);
    if (Loc == EnumArgs.end())
      return false;
    if (Enum)
      *Enum = Loc->second;
    return true;
  }
  unsigned getArgAttr(int Ndx) {
    auto Loc = Attrs.find(Ndx);
    if (Loc == Attrs.end())
      Loc = Attrs.find(-1);
    if (Loc == Attrs.end())
      return 0;
    return Loc->second;
  }
  OCLTypeMangleInfo getTypeMangleInfo(int Ndx) {
    OCLTypeMangleInfo Info;
    Info.IsSigned = !isArgUnsigned(Ndx);
    Info.IsVoidPtr = isArgVoidPtr(Ndx);
    Info.IsEnum = isArgEnum(Ndx, &Info.Enum);
    Info.IsSampler = isArgSampler(Ndx);
    Info.Attr = getArgAttr(Ndx);
    return Info;
  }
private:
  std::string UnmangledName;
  std::set<int> UnsignedArgs; // unsigned arguments, or -1 if all are unsigned
  std::set<int> VoidPtrArgs;  // void pointer arguments, or -1 if all are void
                              // pointer
  std::set<int> SamplerArgs;  // sampler arguments
  std::map<int, SPIR::TypePrimitiveEnum> EnumArgs; // enum arguments
  std::map<int, unsigned> Attrs;                   // argument attributes
};

OCLBuiltinMangleInfo::OCLBuiltinMangleInfo(const std::string &UniqName) {
  UnmangledName = UniqName;
  size_t Pos = std::string::npos;
  if (UnmangledName.find("write_imageui") == 0)
      addUnsignedArg(2);
  else if (UnmangledName.find("get_") == 0 ||
      UnmangledName.find("barrier") == 0 ||
      UnmangledName.find("work_group_barrier") == 0 ||
      UnmangledName.find("vstore") == 0 ||
      UnmangledName.find("async_work_group") == 0 ||
      UnmangledName == "prefetch" ||
      UnmangledName == "nan" ||
      UnmangledName.find("shuffle") == 0){
    addUnsignedArg(-1);
    if (UnmangledName.find("get_fence") == 0){
      setArgAttr(0, SPIR::ATTR_CONST);
      addVoidPtrArg(0);
    }
  } else if (UnmangledName.find("atomic") == 0) {
    setArgAttr(0, SPIR::ATTR_VOLATILE);
    if (UnmangledName == "atomic_umax" ||
        UnmangledName == "atomic_umin") {
      addUnsignedArg(-1);
      UnmangledName.erase(7, 1);
    }
  } else if (UnmangledName.find("uconvert_") == 0) {
    addUnsignedArg(0);
    UnmangledName.erase(0, 1);
  } else if (UnmangledName.find("s_") == 0) {
    UnmangledName.erase(0, 2);
  } else if (UnmangledName.find("u_") == 0) {
    addUnsignedArg(-1);
    UnmangledName.erase(0, 2);
  } else if (UnmangledName == "capture_event_profiling_info") {
    addVoidPtrArg(2);
    setEnumArg(1, SPIR::PRIMITIVE_CLK_PROFILING_INFO);
  } else if (UnmangledName == "enqueue_kernel") {
    setEnumArg(1, SPIR::PRIMITIVE_KERNEL_ENQUEUE_FLAGS_T);
    addUnsignedArg(3);
  } else if (UnmangledName == "enqueue_marker") {
    setArgAttr(2, SPIR::ATTR_CONST);
    addUnsignedArg(1);
  } else if (UnmangledName.find("vload") == 0) {
    addUnsignedArg(-1);
    setArgAttr(1, SPIR::ATTR_CONST);
  } else if (UnmangledName.find("ndrange_") == 0) {
    addUnsignedArg(-1);
    if (UnmangledName[8] == '2' || UnmangledName[8] == '3') {
      setArgAttr(-1, SPIR::ATTR_CONST);
    }
  } else if ((Pos = UnmangledName.find("umax")) != std::string::npos ||
             (Pos = UnmangledName.find("umin")) != std::string::npos) {
    addUnsignedArg(-1);
    UnmangledName.erase(Pos, 1);
  } else if (UnmangledName.find("broadcast") != std::string::npos)
    addUnsignedArg(-1);
  else if (UnmangledName.find(kOCLBuiltinName::SampledReadImage) == 0) {
    UnmangledName.erase(0, strlen(kOCLBuiltinName::Sampled));
    addSamplerArg(1);
  }
}

/// Translates LLVM type to descriptor for mangler.
/// \param Signed indicates integer type should be translated as signed.
/// \param VoidPtr indicates i8* should be translated as void*.
static SPIR::RefParamType
transTypeDesc(Type *Ty, const OCLTypeMangleInfo &Info) {
  bool Signed = Info.IsSigned;
  unsigned Attr = Info.Attr;
  bool VoidPtr = Info.IsVoidPtr;
  if (Info.IsEnum)
    return SPIR::RefParamType(new SPIR::PrimitiveType(Info.Enum));
  if (Info.IsSampler)
    return SPIR::RefParamType(new SPIR::PrimitiveType(
        SPIR::PRIMITIVE_SAMPLER_T));
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
      llvm_unreachable("invliad int size");
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
        transTypeDesc(Ty->getVectorElementType(), Info),
        Ty->getVectorNumElements()));
  }
  if (Ty->isArrayTy()) {
    return transTypeDesc(PointerType::get(Ty->getArrayElementType(), 0), Info);
  }
  if (Ty->isStructTy()) {
    auto Name = Ty->getStructName();
    if (Name.startswith(kLLVMTypeName::StructPrefix))
      Name = Name.drop_front(strlen(kLLVMTypeName::StructPrefix));
    // ToDo: Create a better unique name for struct without name
    if (Name.empty())
      Name = std::string("struct_") +
      std::to_string(reinterpret_cast<size_t>(Ty));
    return SPIR::RefParamType(new SPIR::UserDefinedType(Name));
  }

  if (Ty->isPointerTy()) {
    auto ET = Ty->getPointerElementType();
    SPIR::ParamType *EPT = nullptr;
    if (auto StructTy = dyn_cast<StructType>(ET)) {
      DEBUG(dbgs() << "ptr to struct: " << *Ty << '\n');
      auto TyName = StructTy->getStructName();
      if (TyName.startswith(kSPR2TypeName::ImagePrefix) ||
          TyName.startswith(SPIR_TYPE_NAME_PIPE_T)) {
        auto DelimPos = TyName.find_first_of(kSPR2TypeName::Delimiter,
            strlen(kSPR2TypeName::OCLPrefix));
        if (DelimPos != StringRef::npos)
          TyName = TyName.substr(0, DelimPos);
      }
      DEBUG(dbgs() << "  type name: " << TyName << '\n');

#define _SPRV_OP(x,y) .Case("opencl."#x"_t", \
    new SPIR::PrimitiveType(SPIR::PRIMITIVE_##y##_T))
      if (StructTy->isOpaque())
        EPT = StringSwitch<SPIR::ParamType *>(TyName)
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
          .Case("opencl.block",
              new SPIR::BlockType)
          .Case("struct.ndrange_t",
              new SPIR::PrimitiveType(SPIR::PRIMITIVE_NDRANGE_T))
          .Default(nullptr)
          ;
#undef _SPRV_OP
    }
    if (EPT)
      return SPIR::RefParamType(EPT);

    if (VoidPtr && ET->isIntegerTy(8))
      ET = Type::getVoidTy(ET->getContext());
    auto PT = new SPIR::PointerType(transTypeDesc(ET, Info));
    PT->setAddressSpace(static_cast<SPIR::TypeAttributeEnum>(
      Ty->getPointerAddressSpace() + (unsigned)SPIR::ATTR_ADDR_SPACE_FIRST));
    for (unsigned I = SPIR::ATTR_QUALIFIER_FIRST,
        E = SPIR::ATTR_QUALIFIER_LAST; I <= E; ++I)
      PT->setQualifier(static_cast<SPIR::TypeAttributeEnum>(I), I & Attr);
    return SPIR::RefParamType(PT);
  }
  DEBUG(dbgs() << "[transTypeDesc] " << *Ty << '\n');
  assert (0 && "not implemented");
  return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_INT));
}

void
mangleOCLBuiltin(SPRVExtInstSetKind BuiltinSet, const std::string &UniqName,
    ArrayRef<Type*> ArgTypes, std::string &MangledName) {
  DEBUG(dbgs() << "[mangle] " << UniqName << " => ");
  assert(isOpenCLBuiltinSet(BuiltinSet) && "Not OpenCL builtin set");
  SPIR::NameMangler Mangler(BuiltinSet == SPRVBIS_OpenCL12 ? SPIR::SPIR12 :
      SPIR::SPIR20);
  SPIR::FunctionDescriptor FD;
  OCLBuiltinMangleInfo BtnInfo(UniqName);
  FD.name = BtnInfo.getUnmangledName();
  for (unsigned I = 0, E = ArgTypes.size(); I != E; ++I) {
    auto T = ArgTypes[I];
    FD.parameters.emplace_back(transTypeDesc(T, BtnInfo.getTypeMangleInfo(I)));
  }
  if (FD.parameters.empty())
    FD.parameters.emplace_back(SPIR::RefParamType(new SPIR::PrimitiveType(
        SPIR::PRIMITIVE_VOID)));
  Mangler.mangle(FD, MangledName);
  DEBUG(dbgs() << MangledName << '\n');
}

Value *
getScalarOrArray(Value *V, unsigned Size, Instruction *Pos) {
  if (!V->getType()->isPointerTy())
    return V;
  auto GEP = dyn_cast<GetElementPtrInst>(V);
  assert (GEP);
  auto P = GEP->getPointerOperand();
  assert(P->getType()->getPointerElementType()->getArrayNumElements() == Size);
  assert(GEP->getNumIndices() == 2);
  auto Index0 = GEP->getOperand(1);
  assert(dyn_cast<ConstantInt>(Index0)->getZExtValue() == 0);
  auto Index1 = GEP->getOperand(2);
  assert(dyn_cast<ConstantInt>(Index1)->getZExtValue() == 0);
  return new LoadInst(P, "", Pos);
}

void
MangleOpenCLBuiltin(const std::string &UnmangledName,
    ArrayRef<Type*> ArgTypes, std::string &MangledName) {
  mangleOCLBuiltin(SPRVBIS_OpenCL20, UnmangledName, ArgTypes, MangledName);
}

SPIRAddressSpace
getOCLOpaqueTypeAddrSpace(SPRVOpCode OpCode) {
  switch (OpCode) {
  case SPRVOC_OpTypePipe:
  case SPRVOC_OpTypeQueue:
  case SPRVOC_OpTypeEvent:
  case SPRVOC_OpTypeDeviceEvent:
  case SPRVOC_OpTypeSampler:
    return SPIRAS_Global;
  case SPRVOC_OpTypeReserveId:
    return SPIRAS_Private;
  default:
    return SPIRAS_Private;
  }
}

Constant *
getScalarOrVectorConstantInt(Type *T, uint64_t V, bool isSigned) {
  if (auto IT = dyn_cast<IntegerType>(T))
    return ConstantInt::get(IT, V);
  if (auto VT = dyn_cast<VectorType>(T)) {
    std::vector<Constant *> EV(VT->getVectorNumElements(),
        getScalarOrVectorConstantInt(VT->getVectorElementType(), V, isSigned));
    return ConstantVector::get(EV);
  }
  llvm_unreachable("Invalid type");
  return nullptr;
}

Value *
getScalarOrArrayConstantInt(Instruction *Pos, Type *T, unsigned Len, uint64_t V,
    bool isSigned) {
  if (auto IT = dyn_cast<IntegerType>(T)) {
    assert(Len == 1 && "Invalid length");
    return ConstantInt::get(IT, V, isSigned);
  }
  if (auto PT = dyn_cast<PointerType>(T)) {
    auto ET = PT->getPointerElementType();
    auto AT = ArrayType::get(ET, Len);
    std::vector<Constant *> EV(Len, ConstantInt::get(ET, V, isSigned));
    auto CA = ConstantArray::get(AT, EV);
    auto Alloca = new AllocaInst(AT, "", Pos);
    new StoreInst(CA, Alloca, Pos);
    auto Zero = ConstantInt::getNullValue(Type::getInt32Ty(T->getContext()));
    Value *Index[] = {Zero, Zero};
    auto Ret = GetElementPtrInst::CreateInBounds(Alloca, Index, "", Pos);
    DEBUG(dbgs() << "[getScalarOrArrayConstantInt] Alloca: " <<
        *Alloca << ", Return: " << *Ret << '\n');
    return Ret;
  }
  if (auto AT = dyn_cast<ArrayType>(T)) {
    auto ET = AT->getArrayElementType();
    assert(AT->getArrayNumElements() == Len);
    std::vector<Constant *> EV(Len, ConstantInt::get(ET, V, isSigned));
    auto Ret = ConstantArray::get(AT, EV);
    DEBUG(dbgs() << "[getScalarOrArrayConstantInt] Array type: " <<
        *AT << ", Return: " << *Ret << '\n');
    return Ret;
  }
  llvm_unreachable("Invalid type");
  return nullptr;
}

void
dumpUsers(Value* V, StringRef Prompt) {
  DEBUG(dbgs() << Prompt << " Users of " << *V << " :\n");
  for (auto UI = V->user_begin(), UE = V->user_end(); UI != UE; ++UI)
    DEBUG(dbgs() << "  " << **UI << '\n');
}

Type *
getSPRVSampledImageType(Module *M, Type *ImageType) {
  StringRef ImgTyName;
  if (isOCLImageType(ImageType, &ImgTyName))
    return getOrCreateOpaquePtrType(M,
        std::string(kSPRVTypeName::SampledImg) + kSPRVTypeName::Delimiter
        + ImgTyName.str());
  llvm_unreachable("Invalid image type");
  return nullptr;
}

bool
eraseUselessFunctions(Module *M) {
  bool changed = false;
  for (auto I = M->begin(), E = M->end(); I != E;) {
    Function *F = I++;
    if (!GlobalValue::isInternalLinkage(F->getLinkage()) &&
        !F->isDeclaration())
      continue;

    dumpUsers(F, "[eraseUselessFunctions] ");
    for (auto UI = F->user_begin(), UE = F->user_end(); UI != UE;) {
      auto U = *UI++;
      if (auto CE = dyn_cast<ConstantExpr>(U)){
        if (CE->use_empty()) {
          CE->dropAllReferences();
          changed = true;
        }
      }
    }
    if (F->use_empty()) {
      F->dropAllReferences();
      F->eraseFromParent();
      changed = true;
    }
  }
  return changed;
}

}

