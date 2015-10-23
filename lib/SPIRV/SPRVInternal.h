//===- LLVMSPRVInternal.h -  SPIR-V internal header file --------*- C++ -*-===//
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
/// This file declares classes and functions shared by SPIR-V reader/writer.
///
//===----------------------------------------------------------------------===//
#ifndef LLVMSPRVINTERNAL_HPP_
#define LLVMSPRVINTERNAL_HPP_

#include "libSPIRV/SPRVUtil.h"
#include "libSPIRV/SPRVEnum.h"
#include "libSPIRV/SPRVError.h"
#include "libSPIRV/SPRVType.h"
#include "NameMangleAPI.h"

#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/SPIRV.h"

#include <utility>
#include <functional>

using namespace SPRV;
using namespace llvm;

namespace SPRV{

#define SPCV_TARGET_LLVM_IMAGE_TYPE_ENCODE_ACCESS_QUAL 0
// Workaround for SPIR 2 producer bug about kernel function calling convention.
// This workaround checks metadata to determine if a function is kernel.
#define SPCV_RELAX_KERNEL_CALLING_CONV 1

// Ad hoc function used by LLVM/SPIRV converter for type casting
#define SPCV_CAST "spcv.cast"
#define LLVM_MEMCPY "llvm.memcpy"

namespace kOCLTypeQualifierName {
  const static char *Const      = "const";
  const static char *Volatile   = "volatile";
  const static char *Restrict   = "restrict";
  const static char *Pipe       = "pipe";
}

template<> inline void
SPRVMap<unsigned, Op>::init() {
#define _SPRV_OP(x,y) add(Instruction::x, Op##y);
  /* Casts */
    _SPRV_OP(ZExt, UConvert)
    _SPRV_OP(SExt, SConvert)
    _SPRV_OP(Trunc, UConvert)
    _SPRV_OP(FPToUI, ConvertFToU)
    _SPRV_OP(FPToSI, ConvertFToS)
    _SPRV_OP(UIToFP, ConvertUToF)
    _SPRV_OP(SIToFP, ConvertSToF)
    _SPRV_OP(FPTrunc, FConvert)
    _SPRV_OP(FPExt, FConvert)
    _SPRV_OP(PtrToInt, ConvertPtrToU)
    _SPRV_OP(IntToPtr, ConvertUToPtr)
    _SPRV_OP(BitCast, Bitcast)
    _SPRV_OP(GetElementPtr, AccessChain)
  /*Binary*/
    _SPRV_OP(And, BitwiseAnd)
    _SPRV_OP(Or, BitwiseOr)
    _SPRV_OP(Xor, BitwiseXor)
    _SPRV_OP(Add, IAdd)
    _SPRV_OP(FAdd, FAdd)
    _SPRV_OP(Sub, ISub)
    _SPRV_OP(FSub, FSub)
    _SPRV_OP(Mul, IMul)
    _SPRV_OP(FMul, FMul)
    _SPRV_OP(UDiv, UDiv)
    _SPRV_OP(SDiv, SDiv)
    _SPRV_OP(FDiv, FDiv)
    _SPRV_OP(SRem, SRem)
    _SPRV_OP(FRem, FRem)
    _SPRV_OP(URem, UMod)
    _SPRV_OP(Shl, ShiftLeftLogical)
    _SPRV_OP(LShr, ShiftRightLogical)
    _SPRV_OP(AShr, ShiftRightArithmetic)
#undef _SPRV_OP
}
typedef SPRVMap<unsigned, Op> OpCodeMap;

template<> inline void
SPRVMap<CmpInst::Predicate, Op>::init() {
#define _SPRV_OP(x,y) add(CmpInst::x, Op##y);
    _SPRV_OP(FCMP_OEQ, FOrdEqual)
    _SPRV_OP(FCMP_OGT, FOrdGreaterThan)
    _SPRV_OP(FCMP_OGE, FOrdGreaterThanEqual)
    _SPRV_OP(FCMP_OLT, FOrdLessThan)
    _SPRV_OP(FCMP_OLE, FOrdLessThanEqual)
    _SPRV_OP(FCMP_ONE, FOrdNotEqual)
    _SPRV_OP(FCMP_ORD, Ordered)
    _SPRV_OP(FCMP_UNO, Unordered)
    _SPRV_OP(FCMP_UEQ, FUnordEqual)
    _SPRV_OP(FCMP_UGT, FUnordGreaterThan)
    _SPRV_OP(FCMP_UGE, FUnordGreaterThanEqual)
    _SPRV_OP(FCMP_ULT, FUnordLessThan)
    _SPRV_OP(FCMP_ULE, FUnordLessThanEqual)
    _SPRV_OP(FCMP_UNE, FUnordNotEqual)
    _SPRV_OP(ICMP_EQ, IEqual)
    _SPRV_OP(ICMP_NE, INotEqual)
    _SPRV_OP(ICMP_UGT, UGreaterThan)
    _SPRV_OP(ICMP_UGE, UGreaterThanEqual)
    _SPRV_OP(ICMP_ULT, ULessThan)
    _SPRV_OP(ICMP_ULE, ULessThanEqual)
    _SPRV_OP(ICMP_SGT, SGreaterThan)
    _SPRV_OP(ICMP_SGE, SGreaterThanEqual)
    _SPRV_OP(ICMP_SLT, SLessThan)
    _SPRV_OP(ICMP_SLE, SLessThanEqual)
#undef _SPRV_OP
}
typedef SPRVMap<CmpInst::Predicate, Op> CmpMap;

class IntBoolOpMapId;
template<> inline void
SPRVMap<Op, Op, IntBoolOpMapId>::init() {
  add(OpIEqual,      OpLogicalEqual);
  add(OpINotEqual,   OpLogicalNotEqual);
  add(OpNot,         OpLogicalNot);
  add(OpBitwiseAnd,  OpLogicalAnd);
  add(OpBitwiseOr,   OpLogicalOr);
  add(OpBitwiseXor,  OpLogicalNotEqual);
}
typedef SPRVMap<Op, Op, IntBoolOpMapId> IntBoolOpMap;

#define SPIR_TARGETTRIPLE32 "spir-unknown-unknown"
#define SPIR_TARGETTRIPLE64 "spir64-unknown-unknown"
#define SPIR_DATALAYOUT32 "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32"\
                          "-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32"\
                          "-v32:32:32-v48:64:64-v64:64:64-v96:128:128"\
                          "-v128:128:128-v192:256:256-v256:256:256"\
                          "-v512:512:512-v1024:1024:1024"
#define SPIR_DATALAYOUT64 "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32"\
                          "-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32"\
                          "-v32:32:32-v48:64:64-v64:64:64-v96:128:128"\
                          "-v128:128:128-v192:256:256-v256:256:256"\
                          "-v512:512:512-v1024:1024:1024"

enum SPIRAddressSpace {
  SPIRAS_Private,
  SPIRAS_Global,
  SPIRAS_Constant,
  SPIRAS_Local,
  SPIRAS_Generic,
  SPIRAS_Count,
};

template<> inline void
SPRVMap<SPIRAddressSpace, SPRVStorageClassKind>::init() {
  add(SPIRAS_Private, StorageClassFunction);
  add(SPIRAS_Global, StorageClassWorkgroupGlobal);
  add(SPIRAS_Constant, StorageClassUniformConstant);
  add(SPIRAS_Local, StorageClassWorkgroupLocal);
  add(SPIRAS_Generic, StorageClassGeneric);
}
typedef SPRVMap<SPIRAddressSpace, SPRVStorageClassKind> SPIRSPRVAddrSpaceMap;

// Maps OCL builtin function to SPIRV builtin variable.
template<> inline void
SPRVMap<std::string, SPRVAccessQualifierKind>::init() {
  add("read_only", AccessQualifierReadOnly);
  add("write_only", AccessQualifierWriteOnly);
  add("read_write", AccessQualifierReadWrite);
}
typedef SPRVMap<std::string, SPRVAccessQualifierKind> SPIRSPRVAccessQualifierMap;

template<> inline void
SPRVMap<GlobalValue::LinkageTypes, SPRVLinkageTypeKind>::init() {
  add(GlobalValue::ExternalLinkage, LinkageTypeExport);
  add(GlobalValue::AvailableExternallyLinkage, LinkageTypeImport);
  add(GlobalValue::PrivateLinkage, LinkageTypeInternal);
  add(GlobalValue::LinkOnceODRLinkage, LinkageTypeInternal);
  add(GlobalValue::CommonLinkage, LinkageTypeInternal);
  add(GlobalValue::InternalLinkage, LinkageTypeInternal);
}
typedef SPRVMap<GlobalValue::LinkageTypes, SPRVLinkageTypeKind>
  SPIRSPRVLinkageTypeMap;

template<> inline void
SPRVMap<Attribute::AttrKind, SPRVFuncParamAttrKind>::init() {
  add(Attribute::ZExt, FunctionParameterAttributeZext);
  add(Attribute::SExt, FunctionParameterAttributeSext);
  add(Attribute::ByVal, FunctionParameterAttributeByVal);
  add(Attribute::StructRet, FunctionParameterAttributeSret);
  add(Attribute::NoAlias, FunctionParameterAttributeNoAlias);
  add(Attribute::NoCapture, FunctionParameterAttributeNoCapture);
}
typedef SPRVMap<Attribute::AttrKind, SPRVFuncParamAttrKind>
  SPIRSPRVFuncParamAttrMap;

template<> inline void
SPRVMap<Attribute::AttrKind, SPRVFunctionControlMaskKind>::init() {
  add(Attribute::ReadNone, FunctionControlPureMask);
  add(Attribute::ReadOnly, FunctionControlConstMask);
  add(Attribute::AlwaysInline, FunctionControlInlineMask);
  add(Attribute::NoInline, FunctionControlDontInlineMask);
}
typedef SPRVMap<Attribute::AttrKind, SPRVFunctionControlMaskKind>
  SPIRSPRVFuncCtlMaskMap;

class SPRVExtSetShortName;
template<> inline void
SPRVMap<SPRVExtInstSetKind, std::string, SPRVExtSetShortName>::init() {
  add(SPRVEIS_OpenCL, "ocl");
}
typedef SPRVMap<SPRVExtInstSetKind, std::string, SPRVExtSetShortName>
  SPRVExtSetShortNameMap;


#define SPIR_MD_KERNELS                     "opencl.kernels"
#define SPIR_MD_ENABLE_FP_CONTRACT          "opencl.enable.FP_CONTRACT"
#define SPIR_MD_SPIR_VERSION                "opencl.spir.version"
#define SPIR_MD_OCL_VERSION                 "opencl.ocl.version"
#define SPIR_MD_USED_EXTENSIONS             "opencl.used.extensions"
#define SPIR_MD_USED_OPTIONAL_CORE_FEATURES "opencl.used.optional.core.features"
#define SPIR_MD_COMPILER_OPTIONS            "opencl.compiler.options"
#define SPIR_MD_REQD_WORK_GROUP_SIZE        "reqd_work_group_size"
#define SPIR_MD_WORK_GROUP_SIZE_HINT        "work_group_size_hint"
#define SPIR_MD_VEC_TYPE_HINT               "vec_type_hint"
#define SPIR_MD_KERNEL_ARG_ADDR_SPACE       "kernel_arg_addr_space"
#define SPIR_MD_KERNEL_ARG_ACCESS_QUAL      "kernel_arg_access_qual"
#define SPIR_MD_KERNEL_ARG_TYPE             "kernel_arg_type"
#define SPIR_MD_KERNEL_ARG_BASE_TYPE        "kernel_arg_base_type"
#define SPIR_MD_KERNEL_ARG_TYPE_QUAL        "kernel_arg_type_qual"
#define SPIR_MD_KERNEL_ARG_NAME             "kernel_arg_name"

#define OCL_TYPE_NAME_SAMPLER_T             "sampler_t"
#define SPIR_TYPE_NAME_EVENT_T              "opencl.event_t"
#define SPIR_TYPE_NAME_CLK_EVENT_T          "opencl.clk_event_t"
#define SPIR_TYPE_NAME_PIPE_T               "opencl.pipe_t"
#define SPIR_TYPE_NAME_BLOCK_T              "opencl.block"
#define SPIR_INTRINSIC_BLOCK_BIND           "spir_block_bind"
#define SPIR_INTRINSIC_GET_BLOCK_INVOKE     "spir_get_block_invoke"
#define SPIR_INTRINSIC_GET_BLOCK_CONTEXT    "spir_get_block_context"
#define SPIR_TEMP_NAME_PREFIX_BLOCK         "block"
#define SPIR_TEMP_NAME_PREFIX_CALL          "call"

namespace kLLVMTypeName {
  const static char StructPrefix[] = "struct.";
}

namespace kSPRVTypeName {
  const static char Delimiter   = '.';
  const static char SampledImg[] = "spirv.sampled_image_t";
}

namespace kSPR2TypeName {
  const static char Delimiter   = '.';
  const static char OCLPrefix[]   = "opencl.";
  const static char ImagePrefix[] = "opencl.image";
  const static char Sampler[]     = "opencl.sampler_t";
  const static char Event[]       = "opencl.event_t";
}

namespace kAccessQualName {
  const static char ReadOnly[]    = "read_only";
  const static char WriteOnly[]   = "write_only";
  const static char ReadWrite[]   = "read_write";
}

namespace kMangledName {
  const static char Sampler[]               = "11ocl_sampler";
  const static char AtomicPrefixIncoming[]  = "U7_Atomic";
  const static char AtomicPrefixInternal[]  = "atomic_";
}

namespace kSPRVName {
  const static char GroupPrefix[]            = "group_";
  const static char Prefix[]                 = "__spirv_";
  const static char Postfix[]                = "__";
  const static char ImageQuerySize[]         = "ImageQuerySize";
  const static char ImageQuerySizeLod[]      = "ImageQuerySizeLod";
  const static char ImageSampleExplicitLod[] = "ImageSampleExplicitLod";
  const static char ReservedPrefix[]         = "reserved_";
  const static char SampledImage[]           = "SampledImage";
  const static char TempSampledImage[]       = "TempSampledImage";
}

namespace kSPRVPostfix {
  const static char Sat[]       = "sat";
  const static char Rtz[]       = "rtz";
  const static char Rte[]       = "rte";
  const static char Rtp[]       = "rtp";
  const static char Rtn[]       = "rtn";
  const static char Rt[]        = "rt";
}

enum Spir2SamplerKind {
  CLK_ADDRESS_NONE            = 0x0000,
  CLK_ADDRESS_CLAMP           = 0x0004,
  CLK_ADDRESS_CLAMP_TO_EDGE   = 0x0002,
  CLK_ADDRESS_REPEAT          = 0x0006,
  CLK_ADDRESS_MIRRORED_REPEAT = 0x0008,
  CLK_NORMALIZED_COORDS_FALSE = 0x0000,
  CLK_NORMALIZED_COORDS_TRUE  = 0x0001,
  CLK_FILTER_NEAREST          = 0x0010,
  CLK_FILTER_LINEAR           = 0x0020,
};


/// Additional information for mangling a function argument type.
struct BuiltinArgTypeMangleInfo {
  bool IsSigned;
  bool IsVoidPtr;
  bool IsEnum;
  bool IsSampler;
  bool IsAtomic;
  SPIR::TypePrimitiveEnum Enum;
  unsigned Attr;
  BuiltinArgTypeMangleInfo():IsSigned(true), IsVoidPtr(false), IsEnum(false),
      IsSampler(false), IsAtomic(false), Enum(SPIR::PRIMITIVE_NONE), Attr(0){}
};

/// Information for mangling builtin function.
class BuiltinFuncMangleInfo {
public:
  /// Translate builtin function name and set
  /// argument attributes and unsigned args.
  BuiltinFuncMangleInfo(const std::string &UniqName = "") {
    if (!UniqName.empty())
      init(UniqName);
  }
  virtual ~BuiltinFuncMangleInfo(){}
  const std::string &getUnmangledName() const { return UnmangledName;}
  void addUnsignedArg(int Ndx) { UnsignedArgs.insert(Ndx);}
  void addVoidPtrArg(int Ndx) { VoidPtrArgs.insert(Ndx);}
  void addSamplerArg(int Ndx) { SamplerArgs.insert(Ndx);}
  void addAtomicArg(int Ndx) { AtomicArgs.insert(Ndx);}
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
  bool isArgAtomic(int Ndx) {
    return AtomicArgs.count(Ndx);}
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
  BuiltinArgTypeMangleInfo getTypeMangleInfo(int Ndx) {
    BuiltinArgTypeMangleInfo Info;
    Info.IsSigned = !isArgUnsigned(Ndx);
    Info.IsVoidPtr = isArgVoidPtr(Ndx);
    Info.IsEnum = isArgEnum(Ndx, &Info.Enum);
    Info.IsSampler = isArgSampler(Ndx);
    Info.IsAtomic = isArgAtomic(Ndx);
    Info.Attr = getArgAttr(Ndx);
    return Info;
  }
  virtual void init(const std::string &UniqUnmangledName){
    UnmangledName = UniqUnmangledName;
  }
protected:
  std::string UnmangledName;
  std::set<int> UnsignedArgs; // unsigned arguments, or -1 if all are unsigned
  std::set<int> VoidPtrArgs;  // void pointer arguments, or -1 if all are void
                              // pointer
  std::set<int> SamplerArgs;  // sampler arguments
  std::set<int> AtomicArgs;   // atomic arguments
  std::map<int, SPIR::TypePrimitiveEnum> EnumArgs; // enum arguments
  std::map<int, unsigned> Attrs;                   // argument attributes
};

/// \returns a vector of types for a collection of values.
template<class T>
std::vector<Type *>
getTypes(T V) {
  std::vector<Type *> Tys;
  for (auto &I:V)
    Tys.push_back(I->getType());
  return Tys;
}

/// Move elements of std::vector from [begin, end) to target.
template <typename T>
void move(std::vector<T>& V, size_t begin, size_t end, size_t target) {
  assert(begin < end && end <= V.size() && target <= V.size() &&
      !(begin < target && target < end));
  if (begin <= target && target <= end)
    return;
  auto B = V.begin() + begin, E = V.begin() + end;
  if (target > V.size())
    target = V.size();
  if (target > end)
    target -= (end - begin);
  std::vector<T> Segment(B, E);
  V.erase(B, E);
  V.insert(V.begin() + target, Segment.begin(), Segment.end());
}

/// Find position of first pointer type value in a vector.
inline size_t findFirstPtr(const std::vector<Value *> &Args) {
  auto PtArg = std::find_if(Args.begin(), Args.end(), [](Value *V){
    return V->getType()->isPointerTy();
  });
  return PtArg - Args.begin();
}

void removeFnAttr(LLVMContext *Context, CallInst *Call,
    Attribute::AttrKind Attr);
void addFnAttr(LLVMContext *Context, CallInst *Call,
    Attribute::AttrKind Attr);
void saveLLVMModule(Module *M, const std::string &OutputFile);
std::string mapSPRVTypeToOCLType(SPRVType* Ty, bool Signed);
std::string mapLLVMTypeToOCLType(Type* Ty, bool Signed);
SPRVDecorate *mapPostfixToDecorate(StringRef Postfix, SPRVEntry *Target);

PointerType *getOrCreateOpaquePtrType(Module *M, const std::string &Name,
    unsigned AddrSpace = SPIRAS_Global);
void getFunctionTypeParameterTypes(llvm::FunctionType* FT,
    std::vector<Type*>& ArgTys);
Function *getOrCreateFunction(Module *M, Type *RetTy,
    ArrayRef<Type *> ArgTypes, StringRef Name,
    BuiltinFuncMangleInfo *Mangle = nullptr,
    AttributeSet *Attrs = nullptr, bool takeName = true);

/// Get function call arguments.
/// \param Start Starting index.
/// \param End Ending index.
std::vector<Value *> getArguments(CallInst* CI, unsigned Start = 0,
    unsigned End = 0);

/// Get constant function call argument as an integer.
/// \param I argument index.
uint64_t getArgAsInt(CallInst *CI, unsigned I);

/// Get constant function call argument as a Scope enum.
/// \param I argument index.
Scope getArgAsScope(CallInst *CI, unsigned I);

/// Get constant function call argument as a Decoration enum.
/// \param I argument index.
Decoration getArgAsDecoration(CallInst *CI, unsigned I);

bool isPointerToOpaqueStructType(llvm::Type* Ty);
bool isPointerToOpaqueStructType(llvm::Type* Ty, const std::string &Name);

/// Check if a type is OCL image type.
/// \return type name without "opencl." prefix.
bool isOCLImageType(llvm::Type* Ty, StringRef *Name = nullptr);

/// Decorate a function name as __spirv_{Name}_
std::string decorateSPRVFunction(const std::string &S);

/// Remove prefix/postfix from __spirv_{Name}_
std::string undecorateSPRVFunction(const std::string &S);

/// Check if a function has decorated name as __spirv_{Name}_
/// and get the original name.
bool isDecoratedSPRVFunc(const Function *F, std::string *UndecName = nullptr);

/// Get a canonical function name for a SPIR-V op code.
std::string getSPRVFuncName(Op OC, StringRef PostFix = "");

/// Get a canonical function name for a SPIR-V extended instruction
std::string getSPRVExtFuncName(SPRVExtInstSetKind Set, unsigned ExtOp,
    StringRef PostFix = "");

/// Get SPIR-V op code given the canonical function name.
/// Assume \param Name is either IA64 mangled or unmangled, and the unmangled
/// name takes the __spirv_{OpName}_{Postfixes} format.
/// \return op code if the unmangled function name is a valid op code name,
///   otherwise return OpNop.
/// \param Dec contains decorations decoded from function name if it is
///   not nullptr.
Op getSPRVFuncOC(const std::string& Name,
    SmallVectorImpl<std::string> *Dec = nullptr);

/// Get SPIR-V builtin variable enum given the canonical builtin name
/// Assume \param Name is in format __spirv_BuiltIn{Name}
/// \return spv::BuiltInCount if \param Name is not a valid builtin name.
spv::BuiltIn getSPRVBuiltin(const std::string &Name);

/// \param Name LLVM function name
/// \param OpenCLVer version of OpenCL source file. Suppotred values are 12, 20
/// and 21.
/// \param DemangledName demanged name of the OpenCL built-in function
/// \returns true if Name is the name of the OpenCL built-in function,
/// false for other functions
bool oclIsBuiltin(const StringRef& Name, unsigned SrcLangVer = 12,
    std::string* DemangledName = nullptr, bool isCPP = false);

/// Check if a function type is void(void).
bool isVoidFuncTy(FunctionType *FT);

/// \returns true if \p T is a function pointer type.
bool isFunctionPointerType(Type *T);

/// \returns true if function \p F has function pointer type argument.
/// \param AI points to the function pointer type argument if returns true.
bool hasFunctionPointerArg(Function *F, Function::arg_iterator& AI);

/// \returns true if function \p F has array type argument.
bool hasArrayArg(Function *F);

/// Mutates function call instruction by changing the arguments.
/// \param ArgMutate mutates the function arguments.
/// \return mutated call instruction.
CallInst *mutateCallInst(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    BuiltinFuncMangleInfo *Mangle = nullptr, AttributeSet *Attrs = nullptr,
    bool takeName = false);

/// Mutates function call instruction by changing the arguments and return
/// value.
/// \param ArgMutate mutates the function arguments.
/// \param RetMutate mutates the return value.
/// \return mutated instruction.
Instruction *mutateCallInst(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &,
        Type *&RetTy)> ArgMutate,
    std::function<Instruction *(CallInst *)> RetMutate,
    BuiltinFuncMangleInfo *Mangle = nullptr, AttributeSet *Attrs = nullptr,
    bool takeName = false);

/// Mutate call instruction to call SPIR-V builtin function.
CallInst *
mutateCallInstSPRV(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    AttributeSet *Attrs = nullptr);

/// Mutate call instruction to call SPIR-V builtin function.
Instruction *
mutateCallInstSPRV(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &,
        Type *&RetTy)> ArgMutate,
    std::function<Instruction *(CallInst *)> RetMutate,
    AttributeSet *Attrs = nullptr);

/// Mutate function by change the arguments.
/// \param ArgMutate mutates the function arguments.
/// \param TakeName Take the original function's name if a new function with
///   different type needs to be created.
void mutateFunction(Function *F,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    BuiltinFuncMangleInfo *Mangle = nullptr, AttributeSet *Attrs = nullptr,
    bool TakeName = true);

/// Add a call instruction at \p Pos.
CallInst *addCallInst(Module *M, StringRef FuncName, Type *RetTy,
    ArrayRef<Value *> Args, AttributeSet *Attrs, Instruction *Pos,
    BuiltinFuncMangleInfo *Mangle = nullptr,
    StringRef InstName = SPIR_TEMP_NAME_PREFIX_CALL,
    bool TakeFuncName = true);

/// Add a call instruction for SPIR-V builtin function.
CallInst *
addCallInstSPRV(Module *M, StringRef FuncName, Type *RetTy,
    ArrayRef<Value *> Args,
    AttributeSet *Attrs, Instruction *Pos, StringRef InstName);

/// Add a call of spir_block_bind function.
CallInst *
addBlockBind(Module *M, Function *InvokeFunc, Value *BlkCtx, Value *CtxLen,
    Value *CtxAlign, Instruction *InsPos,
    StringRef InstName = SPIR_TEMP_NAME_PREFIX_BLOCK);

/// Get size_t type.
IntegerType *getSizetType(Module *M);

/// Get void(void) function type.
Type *getVoidFuncType(Module *M);

/// Get void(void) function pointer type.
Type *getVoidFuncPtrType(Module *M, unsigned AddrSpace = 0);

/// Get a 64 bit integer constant.
ConstantInt *getInt64(Module *M, int64_t value);

/// Get a 32 bit integer constant.
ConstantInt *getInt32(Module *M, int value);

/// Get a 32 bit integer constant vector.
std::vector<Value *> getInt32(Module *M, const std::vector<int> &value);

/// Get a size_t type constant.
ConstantInt *getSizet(Module *M, uint64_t value);

/// Map an unsigned integer constant by applying a function.
ConstantInt *mapUInt(Module *M, ConstantInt *I,
    std::function<unsigned(unsigned)> F);

/// Map a signed integer constant by applying a function.
ConstantInt *mapSInt(Module *M, ConstantInt *I,
    std::function<int(int)> F);

/// Get postfix for given decoration.
/// The returned postfix does not include "_" at the beginning.
std::string getPostfix(Decoration Dec, unsigned Value = 0);

Constant *
getScalarOrVectorConstantInt(Type *T, uint64_t V, bool isSigned = false);

/// Get a constant int or a constant int array.
/// \param T is the type of the constant. It should be an integer type or
//  an integer pointer type.
/// \param Len is the length of the array.
/// \param V is the value to fill the array.
Value *
getScalarOrArrayConstantInt(Instruction *P, Type *T, unsigned Len, uint64_t V,
    bool isSigned = false);

/// Get the array from GEP.
/// \param V is a GEP whose pointer operand is a pointer to an array of size
/// \param Size.
Value *
getScalarOrArray(Value *V, unsigned Size, Instruction *Pos);

void
dumpUsers(Value* V, StringRef Prompt = "");

Type *
getSPRVSampledImageType(Module *M, Type *ImageType);

bool
eraseUselessFunctions(Module *M);

/// Erase a function if it is declaration, has internal linkage and has no use.
bool
eraseIfNoUse(Function *F);

void
eraseIfNoUse(Value *V);

// Check if a mangled type name is unsigned
bool
isMangledTypeUnsigned(char Mangled);

// Check if the last function parameter is signed
bool
isLastFuncParamSigned(const std::string& MangledName);

// Check if a mangled function name contains unsigned atomic type
bool
containsUnsignedAtomicType(StringRef Name);

/// Mangle builtin function name.
/// \return \param UniqName if \param BtnInfo is null pointer, otherwise
///    return IA64 mangled name.
std::string
mangleBuiltin(const std::string &UniqName,
    ArrayRef<Type*> ArgTypes, BuiltinFuncMangleInfo* BtnInfo);

/// Remove cast from a value.
Value *
removeCast(Value *V);

/// Cast a function to a void(void) funtion pointer.
Constant *
castToVoidFuncPtr(Function *F);

}
namespace llvm {

void initializeOCL20ToSPRVPass(PassRegistry&);
void initializeOCL21ToSPRVPass(PassRegistry&);
void initializeSPRVLowerOCLBlocksPass(PassRegistry&);
void initializeSPRVLowerBoolPass(PassRegistry&);
void initializeSPRVToOCL20Pass(PassRegistry&);
void initializeOCL20To12Pass(PassRegistry&);

ModulePass *createOCL20ToSPRV();
ModulePass *createOCL21ToSPRV();
ModulePass *createSPRVLowerOCLBlocks();
ModulePass *createSPRVLowerBool();
ModulePass *createSPRVToOCL20();
ModulePass *createOCL20To12();

}
#endif
