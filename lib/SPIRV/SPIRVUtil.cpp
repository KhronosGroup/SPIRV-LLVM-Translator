//===- SPIRVUtil.cpp –  SPIR-V Utilities -------------------------*- C++ -*-===//
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

#include "SPIRVInternal.h"
#include "libSPIRV/SPIRVDecorate.h"
#include "libSPIRV/SPIRVValue.h"
#include "SPIRVMDWalker.h"
#include "OCLUtil.h"

#include "llvm/ADT/StringSwitch.h"
#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/raw_ostream.h"

#include <functional>
#include <sstream>

#define DEBUG_TYPE "spirv"

namespace SPIRV{

#ifdef _SPIRV_SUPPORT_TEXT_FMT
cl::opt<bool, true>
UseTextFormat("spirv-text",
    cl::desc("Use text format for SPIR-V for debugging purpose"),
    cl::location(SPIRVUseTextFormat));
#endif

#ifdef _SPIRVDBG
cl::opt<bool, true>
EnableDbgOutput("spirv-debug",
    cl::desc("Enable SPIR-V debug output"),
    cl::location(SPIRVDbgEnable));
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

Value *
removeCast(Value *V) {
  auto Cast = dyn_cast<ConstantExpr>(V);
  if (Cast && Cast->isCast()) {
    return removeCast(Cast->getOperand(0));
  }
  if (auto Cast = dyn_cast<CastInst>(V))
    return removeCast(Cast->getOperand(0));
  return V;
}

void
saveLLVMModule(Module *M, const std::string &OutputFile) {
  std::error_code EC;
  tool_output_file Out(OutputFile.c_str(), EC, sys::fs::F_None);
  if (EC) {
    SPIRVDBG(errs() << "Fails to open output file: " << EC.message();)
    return;
  }

  WriteBitcodeToFile(M, Out.os());
  Out.keep();
}

std::string
mapLLVMTypeToOCLType(const Type* Ty, bool Signed) {
  if (Ty->isHalfTy())
    return "half";
  if (Ty->isFloatTy())
    return "float";
  if (Ty->isDoubleTy())
    return "double";
  if (auto intTy = dyn_cast<IntegerType>(Ty)) {
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
  if (auto vecTy = dyn_cast<VectorType>(Ty)) {
    Type* eleTy = vecTy->getElementType();
    unsigned size = vecTy->getVectorNumElements();
    std::stringstream ss;
    ss << mapLLVMTypeToOCLType(eleTy, Signed) << size;
    return ss.str();
  }
  return "invalid_type";
}

std::string
mapSPIRVTypeToOCLType(SPIRVType* Ty, bool Signed) {
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
    ss << mapSPIRVTypeToOCLType(eleTy, Signed) << size;
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
isVoidFuncTy(FunctionType *FT) {
  return FT->getReturnType()->isVoidTy() && FT->getNumParams() == 0;
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
    StringRef Name, BuiltinFuncMangleInfo *Mangle, AttributeSet *Attrs,
    bool takeName) {
  std::string MangledName = Name;
  bool isVarArg = false;
  if (Mangle) {
    MangledName = mangleBuiltin(Name, ArgTypes, Mangle);
    isVarArg = 0 <= Mangle->getVarArg();
    if(isVarArg) ArgTypes = ArgTypes.slice(0, Mangle->getVarArg());
  }
  FunctionType *FT = FunctionType::get(RetTy, ArgTypes, isVarArg);
  Function *F = M->getFunction(MangledName);
  if (!takeName && F && F->getFunctionType() != FT && Mangle != nullptr) {
    std::string S;
    raw_string_ostream SS(S);
    SS << "Error: Attempt to redefine function: " << *F << " => " <<
        *FT << '\n';
    report_fatal_error(SS.str(), false);
  }
  if (!F || F->getFunctionType() != FT) {
    auto NewF = Function::Create(FT,
      GlobalValue::ExternalLinkage,
      MangledName,
      M);
    if (F && takeName) {
      NewF->takeName(F);
      DEBUG(dbgs() << "[getOrCreateFunction] Warning: taking function name\n");
    }
    if (NewF->getName() != MangledName) {
      DEBUG(dbgs() << "[getOrCreateFunction] Warning: function name changed\n");
    }
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
getArguments(CallInst* CI, unsigned Start, unsigned End) {
  std::vector<Value*> Args;
  if (End == 0)
    End = CI->getNumArgOperands();
  for (; Start != End; ++Start) {
    Args.push_back(CI->getArgOperand(Start));
  }
  return Args;
}

uint64_t getArgAsInt(CallInst *CI, unsigned I){
  return cast<ConstantInt>(CI->getArgOperand(I))->getZExtValue();
}

Scope getArgAsScope(CallInst *CI, unsigned I){
  return static_cast<Scope>(getArgAsInt(CI, I));
}

Decoration getArgAsDecoration(CallInst *CI, unsigned I) {
  return static_cast<Decoration>(getArgAsInt(CI, I));
}

std::string
decorateSPIRVFunction(const std::string &S) {
  return std::string(kSPIRVName::Prefix) + S + kSPIRVName::Postfix;
}

std::string
undecorateSPIRVFunction(const std::string& S) {
  assert (S.find(kSPIRVName::Prefix) == 0);
  const size_t Start = strlen(kSPIRVName::Prefix);
  auto End = S.rfind(kSPIRVName::Postfix);
  return S.substr(Start, End - Start);
}

std::string
prefixSPIRVName(const std::string &S) {
  return std::string(kSPIRVName::Prefix) + S;
}

StringRef
dePrefixSPIRVName(StringRef R,
    SmallVectorImpl<StringRef> &Postfix) {
  const size_t Start = strlen(kSPIRVName::Prefix);
  if (!R.startswith(kSPIRVName::Prefix))
    return R;
  R = R.drop_front(Start);
  R.split(Postfix, "_", -1, false);
  auto Name = Postfix.front();
  Postfix.erase(Postfix.begin());
  return Name;
}

std::string
getSPIRVFuncName(Op OC, StringRef PostFix) {
  return prefixSPIRVName(getName(OC) + PostFix.str());
}

std::string
getSPIRVFuncName(Op OC, const Type *pRetTy, bool IsSigned) {
  return prefixSPIRVName(getName(OC) + kSPIRVPostfix::Divider +
                         getPostfixForReturnType(pRetTy, false));
}

std::string
getSPIRVExtFuncName(SPIRVExtInstSetKind Set, unsigned ExtOp,
    StringRef PostFix) {
  std::string ExtOpName;
  switch(Set) {
  default:
    llvm_unreachable("invalid extended instruction set");
    ExtOpName = "unknown";
    break;
  case SPIRVEIS_OpenCL:
    ExtOpName = getName(static_cast<OCLExtOpKind>(ExtOp));
    break;
  }
  return prefixSPIRVName(SPIRVExtSetShortNameMap::map(Set)
      + '_' + ExtOpName + PostFix.str());
}

SPIRVDecorate *
mapPostfixToDecorate(StringRef Postfix, SPIRVEntry *Target) {
  if (Postfix == kSPIRVPostfix::Sat)
    return new SPIRVDecorate(spv::DecorationSaturatedConversion, Target);

  if (Postfix.startswith(kSPIRVPostfix::Rt))
    return new SPIRVDecorate(spv::DecorationFPRoundingMode, Target,
      map<SPIRVFPRoundingModeKind>(Postfix.str()));

  return nullptr;
}

SPIRVValue *
addDecorations(SPIRVValue *Target, const SmallVectorImpl<std::string>& Decs){
  for (auto &I:Decs)
    if (auto Dec = mapPostfixToDecorate(I, Target))
      Target->addDecorate(Dec);
  return Target;
}

std::string
getPostfix(Decoration Dec, unsigned Value) {
  switch(Dec) {
  default:
    llvm_unreachable("not implemented");
    return "unknown";
  case spv::DecorationSaturatedConversion:
    return kSPIRVPostfix::Sat;
  case spv::DecorationFPRoundingMode:
    return rmap<std::string>(static_cast<SPIRVFPRoundingModeKind>(Value));
  }
}

std::string
getPostfixForReturnType(CallInst *CI, bool IsSigned) {
  return getPostfixForReturnType(CI->getType(), IsSigned);
}

std::string getPostfixForReturnType(const Type *pRetTy, bool IsSigned) {
  return std::string(kSPIRVPostfix::Return) +
         mapLLVMTypeToOCLType(pRetTy, IsSigned);
}

Op
getSPIRVFuncOC(const std::string& S, SmallVectorImpl<std::string> *Dec) {
  Op OC;
  SmallVector<StringRef, 2> Postfix;
  std::string Name;
  if (!oclIsBuiltin(S, 20, &Name))
    Name = S;
  StringRef R(Name);
  R = dePrefixSPIRVName(R, Postfix);
  if (!getByName(R.str(), OC))
    return OpNop;
  if (Dec)
    for (auto &I:Postfix)
      Dec->push_back(I.str());
  return OC;
}

spv::BuiltIn
getSPIRVBuiltin(const std::string &OrigName) {
  SmallVector<StringRef, 2> Postfix;
  StringRef R(OrigName);
  R = dePrefixSPIRVName(R, Postfix);
  assert(Postfix.empty() && "Invalid SPIR-V builtin name");
  spv::BuiltIn B = spv::BuiltInCount;
  getByName(R.str(), B);
  return B;
}

bool oclIsBuiltin(const StringRef &Name, unsigned SrcLangVer,
                  std::string *DemangledName, bool isCPP) {
  if (Name == "printf") {
    if (DemangledName)
      *DemangledName = Name;
    return true;
  }
  if (!Name.startswith("_Z"))
    return false;
  if (!DemangledName)
    return true;
  // OpenCL C++ built-ins are declared in cl namespace.
  // TODO: consider using 'St' abbriviation for cl namespace mangling.
  // Similar to ::std:: in C++.
  if (isCPP) {
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

// Check if a mangled type name is unsigned
bool isMangledTypeUnsigned(char Mangled) {
  return Mangled == 'h'    /* uchar */
         || Mangled == 't' /* ushort */
         || Mangled == 'j' /* uint */
         || Mangled == 'm' /* ulong */;
}

// Check if a mangled type name is signed
bool isMangledTypeSigned(char Mangled) {
  return Mangled == 'c'    /* char */
         || Mangled == 'a' /* signed char */
         || Mangled == 's' /* short */
         || Mangled == 'i' /* int */
         || Mangled == 'l' /* long */;
}

// Check if a mangled type name is floating point (excludes half)
bool isMangledTypeFP(char Mangled) {
  return Mangled == 'f'     /* float */
         || Mangled == 'd'; /* double */
}

// Check if a mangled type name is half
bool isMangledTypeHalf(std::string Mangled) {
  return Mangled == "Dh"; /* half */
}

void
eraseSubstitutionFromMangledName(std::string& MangledName) {
  auto Len = MangledName.length();
  while (Len >= 2 && MangledName.substr(Len - 2, 2) == "S_") {
    Len -= 2;
    MangledName.erase(Len, 2);
  }
}

ParamType LastFuncParamType(const std::string &MangledName) {
  auto Copy = MangledName;
  eraseSubstitutionFromMangledName(Copy);
  char Mangled = Copy.back();
  std::string Mangled2 = Copy.substr(Copy.size() - 2);

  if (isMangledTypeFP(Mangled) || isMangledTypeHalf(Mangled2)) {
    return ParamType::FLOAT;
  } else if (isMangledTypeUnsigned(Mangled)) {
    return ParamType::UNSIGNED;
  } else if (isMangledTypeSigned(Mangled)) {
    return ParamType::SIGNED;
  }

  return ParamType::UNKNOWN;
}

// Check if the last argument is signed
bool
isLastFuncParamSigned(const std::string& MangledName) {
  return LastFuncParamType(MangledName) == ParamType::SIGNED;
}


// Check if a mangled function name contains unsigned atomic type
bool
containsUnsignedAtomicType(StringRef Name) {
  auto Loc = Name.find(kMangledName::AtomicPrefixIncoming);
  if (Loc == StringRef::npos)
    return false;
  return isMangledTypeUnsigned(Name[Loc + strlen(
      kMangledName::AtomicPrefixIncoming)]);
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

Constant *
castToVoidFuncPtr(Function *F) {
  auto T = getVoidFuncPtrType(F->getParent());
  return ConstantExpr::getBitCast(F, T);
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
    BuiltinFuncMangleInfo *Mangle, AttributeSet *Attrs, bool TakeFuncName) {
  DEBUG(dbgs() << "[mutateCallInst] " << *CI);

  auto Args = getArguments(CI);
  auto NewName = ArgMutate(CI, Args);
  std::string InstName;
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
    BuiltinFuncMangleInfo *Mangle, AttributeSet *Attrs, bool TakeFuncName) {
  DEBUG(dbgs() << "[mutateCallInst] " << *CI);

  auto Args = getArguments(CI);
  Type *RetTy = CI->getType();
  auto NewName = ArgMutate(CI, Args, RetTy);
  std::string InstName;
  if (CI->hasName()) {
    InstName = CI->getName();
    CI->setName(InstName + ".old");
  }
  auto NewCI = addCallInst(M, NewName, RetTy, Args, Attrs,
      CI, Mangle, InstName + ".tmp", TakeFuncName);
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
    BuiltinFuncMangleInfo *Mangle, AttributeSet *Attrs,
    bool TakeFuncName) {
  auto M = F->getParent();
  for (auto I = F->user_begin(), E = F->user_end(); I != E;) {
    if (auto CI = dyn_cast<CallInst>(*I++))
      mutateCallInst(M, CI, ArgMutate, Mangle, Attrs, TakeFuncName);
  }
  if (F->use_empty())
    F->eraseFromParent();
}

CallInst *
mutateCallInstSPIRV(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    AttributeSet *Attrs) {
  BuiltinFuncMangleInfo BtnInfo;
  return mutateCallInst(M, CI, ArgMutate, &BtnInfo, Attrs);
}

Instruction *
mutateCallInstSPIRV(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &,
        Type *&RetTy)> ArgMutate,
    std::function<Instruction *(CallInst *)> RetMutate,
    AttributeSet *Attrs) {
  BuiltinFuncMangleInfo BtnInfo;
  return mutateCallInst(M, CI, ArgMutate, RetMutate, &BtnInfo, Attrs);
}

CallInst *
addCallInst(Module *M, StringRef FuncName, Type *RetTy, ArrayRef<Value *> Args,
    AttributeSet *Attrs, Instruction *Pos, BuiltinFuncMangleInfo *Mangle,
    StringRef InstName, bool TakeFuncName) {

  auto F = getOrCreateFunction(M, RetTy, getTypes(Args),
      FuncName, Mangle, Attrs, TakeFuncName);
  auto CI = CallInst::Create(F, Args, InstName, Pos);
  CI->setCallingConv(F->getCallingConv());
  return CI;
}

CallInst *
addCallInstSPIRV(Module *M, StringRef FuncName, Type *RetTy, ArrayRef<Value *> Args,
    AttributeSet *Attrs, Instruction *Pos, StringRef InstName) {
  BuiltinFuncMangleInfo BtnInfo;
  return addCallInst(M, FuncName, RetTy, Args, Attrs, Pos, &BtnInfo,
      InstName);
}

bool
isValidVectorSize(unsigned I) {
  return I == 2 ||
         I == 3 ||
         I == 4 ||
         I == 8 ||
         I == 16;
}

Value *
addVector(Instruction *InsPos, ValueVecRange Range) {
  size_t VecSize = Range.second - Range.first;
  if (VecSize == 1)
    return *Range.first;
  assert(isValidVectorSize(VecSize) && "Invalid vector size");
  IRBuilder<> Builder(InsPos);
  auto Vec = Builder.CreateVectorSplat(VecSize, *Range.first);
  unsigned Index = 1;
  for (++Range.first; Range.first != Range.second; ++Range.first, ++Index)
    Vec = Builder.CreateInsertElement(Vec, *Range.first,
        ConstantInt::get(Type::getInt32Ty(InsPos->getContext()), Index, false));
  return Vec;
}

void
makeVector(Instruction *InsPos, std::vector<Value *> &Ops,
    ValueVecRange Range) {
  auto Vec = addVector(InsPos, Range);
  Ops.erase(Range.first, Range.second);
  Ops.push_back(Vec);
}

void
expandVector(Instruction *InsPos, std::vector<Value *> &Ops,
    size_t VecPos) {
  auto Vec = Ops[VecPos];
  auto VT = Vec->getType();
  if (!VT->isVectorTy())
    return;
  size_t N = VT->getVectorNumElements();
  IRBuilder<> Builder(InsPos);
  for (size_t I = 0; I != N; ++I)
    Ops.insert(Ops.begin() + VecPos + I, Builder.CreateExtractElement(Vec,
        ConstantInt::get(Type::getInt32Ty(InsPos->getContext()), I, false)));
  Ops.erase(Ops.begin() + VecPos + N);
}

Constant *
castToInt8Ptr(Constant *V, unsigned Addr = 0) {
  return ConstantExpr::getBitCast(V, Type::getInt8PtrTy(V->getContext(), Addr));
}

PointerType *
getInt8PtrTy(PointerType *T) {
  return Type::getInt8PtrTy(T->getContext(), T->getAddressSpace());
}

Value *
castToInt8Ptr(Value *V, Instruction *Pos) {
  return CastInst::CreatePointerCast(V, getInt8PtrTy(
      cast<PointerType>(V->getType())), "", Pos);
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
      InsPos, nullptr, InstName);
}

IntegerType* getSizetType(Module *M) {
  return IntegerType::getIntNTy(M->getContext(),
    M->getDataLayout()->getPointerSizeInBits(0));
}

Type *
getVoidFuncType(Module *M) {
  return FunctionType::get(Type::getVoidTy(M->getContext()), false);
}

Type *
getVoidFuncPtrType(Module *M, unsigned AddrSpace) {
  return PointerType::get(getVoidFuncType(M), AddrSpace);
}

ConstantInt *
getInt64(Module *M, int64_t value) {
  return ConstantInt::get(Type::getInt64Ty(M->getContext()), value, true);
}

Constant *getFloat32(Module *M, float value) {
  return ConstantFP::get(Type::getFloatTy(M->getContext()), value);
}

ConstantInt *
getInt32(Module *M, int value) {
  return ConstantInt::get(Type::getInt32Ty(M->getContext()), value, true);
}

ConstantInt *
getUInt32(Module *M, unsigned value) {
  return ConstantInt::get(Type::getInt32Ty(M->getContext()), value, false);
}

ConstantInt *
getUInt16(Module *M, unsigned short value) {
  return ConstantInt::get(Type::getInt16Ty(M->getContext()), value, false);
}

std::vector<Value *> getInt32(Module *M, const std::vector<int> &value) {
  std::vector<Value *> V;
  for (auto &I:value)
    V.push_back(getInt32(M, I));
  return V;
}

ConstantInt *
getSizet(Module *M, uint64_t value) {
  return ConstantInt::get(getSizetType(M), value, false);
}

///////////////////////////////////////////////////////////////////////////////
//
// Functions for getting metadata
//
///////////////////////////////////////////////////////////////////////////////
int
getMDOperandAsInt(MDNode* N, unsigned I) {
  return mdconst::dyn_extract<ConstantInt>(N->getOperand(I))->getZExtValue();
}

std::string
getMDOperandAsString(MDNode* N, unsigned I) {
  Metadata* Op = N->getOperand(I);

  if (!Op)
    return "";
  if (MDString* Str = dyn_cast<MDString>(Op)) {
    return Str->getString().str();
  }
  return "";
}

Type*
getMDOperandAsType(MDNode* N, unsigned I) {
  return cast<ValueAsMetadata>(N->getOperand(I))->getType();
}

std::set<std::string>
getNamedMDAsStringSet(Module *M, const std::string &MDName) {
  NamedMDNode *NamedMD = M->getNamedMetadata(MDName);
  std::set<std::string> StrSet;
  if (!NamedMD)
    return std::move(StrSet);

  assert(NamedMD->getNumOperands() > 0 && "Invalid SPIR");

  for (unsigned I = 0, E = NamedMD->getNumOperands(); I != E; ++I) {
    MDNode *MD = NamedMD->getOperand(I);
    if (!MD || MD->getNumOperands() == 0)
      continue;
    assert(MD->getNumOperands() == 1 && "Invalid SPIR");
    auto S = getMDOperandAsString(MD, 0);
    SmallVector<StringRef, 10> Exts;
    StringRef(S).split(Exts, " ", -1, false);
    for (auto S:Exts)
      StrSet.insert(std::move(S.str()));
  }

  return std::move(StrSet);
}

std::tuple<unsigned, unsigned, std::string>
getSPIRVSource(Module *M) {
  std::tuple<unsigned, unsigned, std::string> Tup;
  if (auto N = SPIRVMDWalker(*M).getNamedMD(kSPIRVMD::Source).nextOp())
    N.get(std::get<0>(Tup))
     .get(std::get<1>(Tup))
     .setQuiet(true)
     .get(std::get<2>(Tup));
  return Tup;
}

ConstantInt *mapUInt(Module *M, ConstantInt *I,
    std::function<unsigned(unsigned)> F) {
  return ConstantInt::get(I->getType(), F(I->getZExtValue()), false);
}

ConstantInt *mapSInt(Module *M, ConstantInt *I,
    std::function<int(int)> F) {
  return ConstantInt::get(I->getType(), F(I->getSExtValue()), true);
}

bool
isDecoratedSPIRVFunc(const Function *F, std::string *UndecoratedName) {
  if (!F->hasName() || !F->getName().startswith(kSPIRVName::Prefix))
    return false;
  if (UndecoratedName)
    *UndecoratedName = undecorateSPIRVFunction(F->getName());
  return true;
}

/// Get TypePrimitiveEnum for special OpenCL type except opencl.block.
SPIR::TypePrimitiveEnum
getOCLTypePrimitiveEnum(StringRef TyName) {
  return StringSwitch<SPIR::TypePrimitiveEnum>(TyName)
    .Case("opencl.image1d_t",         SPIR::PRIMITIVE_IMAGE_1D_T)
    .Case("opencl.image1d_array_t",   SPIR::PRIMITIVE_IMAGE_1D_ARRAY_T)
    .Case("opencl.image1d_buffer_t",  SPIR::PRIMITIVE_IMAGE_1D_BUFFER_T)
    .Case("opencl.image2d_t",         SPIR::PRIMITIVE_IMAGE_2D_T)
    .Case("opencl.image2d_array_t",   SPIR::PRIMITIVE_IMAGE_2D_ARRAY_T)
    .Case("opencl.image3d_t",         SPIR::PRIMITIVE_IMAGE_3D_T)
    .Case("opencl.image2d_msaa_t",    SPIR::PRIMITIVE_IMAGE_2D_MSAA_T)
    .Case("opencl.image2d_array_msaa_t",        SPIR::PRIMITIVE_IMAGE_2D_ARRAY_MSAA_T)
    .Case("opencl.image2d_msaa_depth_t",        SPIR::PRIMITIVE_IMAGE_2D_MSAA_DEPTH_T)
    .Case("opencl.image2d_array_msaa_depth_t",  SPIR::PRIMITIVE_IMAGE_2D_ARRAY_MSAA_DEPTH_T)
    .Case("opencl.image2d_depth_t",             SPIR::PRIMITIVE_IMAGE_2D_DEPTH_T)
    .Case("opencl.image2d_array_depth_t",       SPIR::PRIMITIVE_IMAGE_2D_ARRAY_DEPTH_T)
    .Case("opencl.event_t",           SPIR::PRIMITIVE_EVENT_T)
    .Case("opencl.pipe_t",            SPIR::PRIMITIVE_PIPE_T)
    .Case("opencl.reserve_id_t",      SPIR::PRIMITIVE_RESERVE_ID_T)
    .Case("opencl.queue_t",           SPIR::PRIMITIVE_QUEUE_T)
    .Case("opencl.clk_event_t",       SPIR::PRIMITIVE_CLK_EVENT_T)
    .Case("opencl.sampler_t",         SPIR::PRIMITIVE_SAMPLER_T)
    .Case("struct.ndrange_t",         SPIR::PRIMITIVE_NDRANGE_T)
    .Default(                         SPIR::PRIMITIVE_NONE);
}
/// Translates LLVM type to descriptor for mangler.
/// \param Signed indicates integer type should be translated as signed.
/// \param VoidPtr indicates i8* should be translated as void*.
static SPIR::RefParamType
transTypeDesc(Type *Ty, const BuiltinArgTypeMangleInfo &Info) {
  bool Signed = Info.IsSigned;
  unsigned Attr = Info.Attr;
  bool VoidPtr = Info.IsVoidPtr;
  if (Info.IsEnum)
    return SPIR::RefParamType(new SPIR::PrimitiveType(Info.Enum));
  if (Info.IsSampler)
    return SPIR::RefParamType(new SPIR::PrimitiveType(
        SPIR::PRIMITIVE_SAMPLER_T));
  if (Info.IsAtomic && !Ty->isPointerTy()) {
    BuiltinArgTypeMangleInfo DTInfo = Info;
    DTInfo.IsAtomic = false;
    return SPIR::RefParamType(new SPIR::AtomicType(
        transTypeDesc(Ty, DTInfo)));
  }
  if(auto *IntTy = dyn_cast<IntegerType>(Ty)) {
    switch(IntTy->getBitWidth()) {
    case 1:
      return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_BOOL));
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
    if (Name.empty()) {
      std::ostringstream OS;
      OS << reinterpret_cast<size_t>(Ty);
      Name = std::string("struct_") + OS.str();
    }
    return SPIR::RefParamType(new SPIR::UserDefinedType(Name));
  }

  if (Ty->isPointerTy()) {
    auto ET = Ty->getPointerElementType();
    SPIR::ParamType *EPT = nullptr;
    if (auto FT = dyn_cast<FunctionType>(ET)) {
      assert(isVoidFuncTy(FT) && "Not supported");
      EPT = new SPIR::BlockType;
    } else if (auto StructTy = dyn_cast<StructType>(ET)) {
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

      auto Prim = getOCLTypePrimitiveEnum(TyName);
      if (StructTy->isOpaque()) {
        if (TyName == "opencl.block") {
          auto BlockTy = new SPIR::BlockType;
          // Handle block with local memory arguments according to OpenCL 2.0 spec.
          if(Info.IsLocalArgBlock) {
            SPIR::RefParamType VoidTyRef(new SPIR::PrimitiveType(SPIR::PRIMITIVE_VOID));
            auto VoidPtrTy = new SPIR::PointerType(VoidTyRef);
            VoidPtrTy->setAddressSpace(SPIR::ATTR_LOCAL);
            // "__local void *"
            BlockTy->setParam(0, SPIR::RefParamType(VoidPtrTy));
            // "..."
            BlockTy->setParam(1, SPIR::RefParamType(
              new SPIR::PrimitiveType(SPIR::PRIMITIVE_VAR_ARG)));
          }
          EPT = BlockTy;
        } else if (Prim != SPIR::PRIMITIVE_NONE) {
          if (Prim == SPIR::PRIMITIVE_PIPE_T) {
            SPIR::RefParamType OpaqueTyRef(new SPIR::PrimitiveType(Prim));
            auto OpaquePtrTy = new SPIR::PointerType(OpaqueTyRef);
            OpaquePtrTy->setAddressSpace(getOCLOpaqueTypeAddrSpace(Prim));
            EPT = OpaquePtrTy;
          }
          else {
            EPT = new SPIR::PrimitiveType(Prim);
          }
        }
      } else if (Prim == SPIR::PRIMITIVE_NDRANGE_T)
        // ndrange_t is not opaque type
        EPT = new SPIR::PrimitiveType(SPIR::PRIMITIVE_NDRANGE_T);
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

Value *
getScalarOrArray(Value *V, unsigned Size, Instruction *Pos) {
  if (!V->getType()->isPointerTy())
    return V;
  assert((isa<ConstantExpr>(V) || isa<GetElementPtrInst>(V)) &&
         "unexpected value type");
  auto GEP = cast<User>(V);
  assert(GEP->getNumOperands() == 3 && "must be a GEP from an array");
  auto P = GEP->getOperand(0);
  assert(P->getType()->getPointerElementType()->getArrayNumElements() == Size);
  auto Index0 = GEP->getOperand(1);
  assert(dyn_cast<ConstantInt>(Index0)->getZExtValue() == 0);
  auto Index1 = GEP->getOperand(2);
  assert(dyn_cast<ConstantInt>(Index1)->getZExtValue() == 0);
  return new LoadInst(P, "", Pos);
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
getSPIRVSampledImageType(Module *M, Type *ImageType) {
  StringRef ImgTyName;
  if (isOCLImageType(ImageType, &ImgTyName))
    return getOrCreateOpaquePtrType(M,
        std::string(kSPIRVTypeName::SampledImg)
          + kSPIRVTypeName::Delimiter + ImgTyName.str()
          + kSPIRVTypeName::Delimiter + kAccessQualName::ReadOnly);
  llvm_unreachable("Invalid image type");
  return nullptr;
}

bool
eraseIfNoUse(Function *F) {
  bool changed = false;
  if (!F)
    return changed;
  if (!GlobalValue::isInternalLinkage(F->getLinkage()) &&
      !F->isDeclaration())
    return changed;

  dumpUsers(F, "[eraseIfNoUse] ");
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
    DEBUG(dbgs() << "Erase ";
          F->printAsOperand(dbgs());
          dbgs() << '\n');
    F->eraseFromParent();
    changed = true;
  }
  return changed;
}

void
eraseIfNoUse(Value *V) {
  if (!V->use_empty())
    return;
  if (Constant *C = dyn_cast<Constant>(V)) {
    C->destroyConstant();
    return;
  }
  if (Instruction *I = dyn_cast<Instruction>(V)) {
    if (!I->mayHaveSideEffects())
      I->eraseFromParent();
  }
  eraseIfNoUse(dyn_cast<Function>(V));
}

bool
eraseUselessFunctions(Module *M) {
  bool changed = false;
  for (auto I = M->begin(), E = M->end(); I != E;)
    changed |= eraseIfNoUse(I++);
  return changed;
}


std::string
mangleBuiltin(const std::string &UniqName,
    ArrayRef<Type*> ArgTypes, BuiltinFuncMangleInfo* BtnInfo) {
  if (!BtnInfo)
    return UniqName;
  BtnInfo->init(UniqName);
  std::string MangledName;
  DEBUG(dbgs() << "[mangle] " << UniqName << " => ");
  SPIR::NameMangler Mangler(SPIR::SPIR20);
  SPIR::FunctionDescriptor FD;
  FD.name = BtnInfo->getUnmangledName();
  bool BIVarArgNegative = BtnInfo->getVarArg() < 0;

  if (ArgTypes.empty()) {
    // Function signature cannot be ()(void, ...) so if there is an ellipsis
    // it must be ()(...)
    if(BIVarArgNegative) {
      FD.parameters.emplace_back(SPIR::RefParamType(new SPIR::PrimitiveType(
        SPIR::PRIMITIVE_VOID)));
    }
  } else {
    for (unsigned I = 0, 
         E = BIVarArgNegative ? ArgTypes.size() : (unsigned)BtnInfo->getVarArg();
         I != E; ++I) {
      auto T = ArgTypes[I];
      FD.parameters.emplace_back(transTypeDesc(T, BtnInfo->getTypeMangleInfo(I)));
    }
  }
  // Ellipsis must be the last argument of any function
  if(!BIVarArgNegative) {
    assert((unsigned)BtnInfo->getVarArg() <= ArgTypes.size()
           && "invalid index of an ellipsis");
    FD.parameters.emplace_back(SPIR::RefParamType(new SPIR::PrimitiveType(
        SPIR::PRIMITIVE_VAR_ARG)));
  }
  Mangler.mangle(FD, MangledName);
  DEBUG(dbgs() << MangledName << '\n');
  return MangledName;
}

}
