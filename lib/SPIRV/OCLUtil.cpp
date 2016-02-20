//===- OCLUtil.cpp - OCL Utilities ----------------------------------------===//
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
// This file implements OCL utility functions.
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "oclutil"

#include "SPIRVInternal.h"
#include "OCLUtil.h"
#include "SPIRVEntry.h"
#include "SPIRVFunction.h"
#include "SPIRVInstruction.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Pass.h"
#include "llvm/PassSupport.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace SPIRV;

namespace OCLUtil {


#ifndef SPIRV_OCL_SPECIAL_TYPES_DEFAULT_ADDR_SPACE
  #define SPIRV_OCL_SPECIAL_TYPES_DEFAULT_ADDR_SPACE SPIRAS_Private
#endif

#ifndef SPIRV_QUEUE_T_ADDR_SPACE
  #define SPIRV_QUEUE_T_ADDR_SPACE SPIRV_OCL_SPECIAL_TYPES_DEFAULT_ADDR_SPACE
#endif

#ifndef SPIRV_EVENT_T_ADDR_SPACE
  #define SPIRV_EVENT_T_ADDR_SPACE SPIRV_OCL_SPECIAL_TYPES_DEFAULT_ADDR_SPACE
#endif

#ifndef SPIRV_CLK_EVENT_T_ADDR_SPACE
  #define SPIRV_CLK_EVENT_T_ADDR_SPACE SPIRV_OCL_SPECIAL_TYPES_DEFAULT_ADDR_SPACE
#endif

#ifndef SPIRV_RESERVE_ID_T_ADDR_SPACE
  #define SPIRV_RESERVE_ID_T_ADDR_SPACE SPIRV_OCL_SPECIAL_TYPES_DEFAULT_ADDR_SPACE
#endif
// Excerpt from SPIR 2.0 spec.:
//   Pipe objects are represented using pointers to the opaque %opencl.pipe LLVM structure type
//   which reside in the global address space.
#ifndef SPIRV_PIPE_ADDR_SPACE
  #define SPIRV_PIPE_ADDR_SPACE SPIRAS_Global
#endif
// Excerpt from SPIR 2.0 spec.:
//   Note: Images data types reside in global memory and hence should be marked as such in the
//   "kernel arg addr space" metadata.
#ifndef SPIRV_IMAGE_ADDR_SPACE
  #define SPIRV_IMAGE_ADDR_SPACE SPIRAS_Global
#endif

///////////////////////////////////////////////////////////////////////////////
//
// Functions for getting builtin call info
//
///////////////////////////////////////////////////////////////////////////////
AtomicWorkItemFenceLiterals getAtomicWorkItemFenceLiterals(CallInst* CI) {
  return std::make_tuple(getArgAsInt(CI, 0),
    static_cast<OCLMemOrderKind>(getArgAsInt(CI, 1)),
    static_cast<OCLScopeKind>(getArgAsInt(CI, 2)));
}

size_t getAtomicBuiltinNumMemoryOrderArgs(StringRef Name) {
  if (Name.startswith("atomic_compare_exchange"))
    return 2;
  return 1;
}

WorkGroupBarrierLiterals getWorkGroupBarrierLiterals(CallInst* CI){
  auto N = CI->getNumArgOperands();
  assert (N == 1 || N == 3);
  return std::make_tuple(getArgAsInt(CI, 0),
    N == 1 ? OCLMS_work_group : static_cast<OCLScopeKind>(getArgAsInt(CI, 1)),
    OCLMS_work_group);
}

unsigned
getExtOp(StringRef OrigName, const std::string &GivenDemangledName) {
  std::string DemangledName = GivenDemangledName;
  if (!oclIsBuiltin(OrigName, 20,
      DemangledName.empty() ? &DemangledName : nullptr))
    return ~0U;
  DEBUG(dbgs() << "getExtOp: demangled name: " << DemangledName << '\n');
  OCLExtOpKind EOC;
  bool Found = OCLExtOpMap::rfind(DemangledName, &EOC);
  if (!Found) {
    std::string Prefix;
    switch (LastFuncParamType(OrigName)) {
    case ParamType::UNSIGNED:
      Prefix = "u_";
      break;
    case ParamType::SIGNED:
      Prefix = "s_";
      break;
    case ParamType::FLOAT:
      Prefix = "f";
      break;
    default:
      llvm_unreachable("unknown mangling!");
    }
    Found = OCLExtOpMap::rfind(Prefix + DemangledName, &EOC);
  }
  if (Found)
    return EOC;
  else
    return ~0U;
}

std::unique_ptr<SPIRVEntry>
getSPIRVInst(const OCLBuiltinTransInfo &Info) {
  Op OC = OpNop;
  unsigned ExtOp = ~0U;
  SPIRVEntry *Entry = nullptr;
  if (OCLSPIRVBuiltinMap::find(Info.UniqName, &OC))
    Entry = SPIRVEntry::create(OC);
  else if ((ExtOp = getExtOp(Info.MangledName, Info.UniqName)) != ~0U)
    Entry = static_cast<SPIRVEntry*>(
        SPIRVEntry::create_unique(SPIRVEIS_OpenCL, ExtOp).get());
  return std::unique_ptr<SPIRVEntry>(Entry);
}

///////////////////////////////////////////////////////////////////////////////
//
// Functions for getting module info
//
///////////////////////////////////////////////////////////////////////////////

unsigned
encodeOCLVer(unsigned short Major,
    unsigned char Minor, unsigned char Rev) {
  return (Major * 100 + Minor) * 1000 + Rev;
}

std::tuple<unsigned short, unsigned char, unsigned char>
decodeOCLVer(unsigned Ver) {
  unsigned short Major = Ver / 100000;
  unsigned char Minor = (Ver % 100000) / 1000;
  unsigned char Rev = Ver % 1000;
  return std::make_tuple(Major, Minor, Rev);
}

unsigned getOCLVersion(Module *M, bool AllowMulti) {
  NamedMDNode *NamedMD = M->getNamedMetadata(kSPIR2MD::OCLVer);
  if (!NamedMD)
    return 0;
  assert (NamedMD->getNumOperands() > 0 && "Invalid SPIR");
  if (!AllowMulti && NamedMD->getNumOperands() != 1)
    report_fatal_error("Multiple OCL version metadata not allowed");

  // If the module was linked with another module, there may be multiple
  // operands.
  auto getVer = [=](unsigned I) {
    auto MD = NamedMD->getOperand(I);
    return std::make_pair(getMDOperandAsInt(MD, 0), getMDOperandAsInt(MD, 1));
  };
  auto Ver = getVer(0);
  for (unsigned I = 1, E = NamedMD->getNumOperands(); I != E; ++I)
    if (Ver != getVer(I))
      report_fatal_error("OCL version mismatch");

  return encodeOCLVer(Ver.first, Ver.second, 0);
}

void
decodeMDNode(MDNode* N, unsigned& X, unsigned& Y, unsigned& Z) {
  if (N == NULL)
    return;
  X = getMDOperandAsInt(N, 1);
  Y = getMDOperandAsInt(N, 2);
  Z = getMDOperandAsInt(N, 3);
}

/// Encode LLVM type by SPIR-V execution mode VecTypeHint
unsigned
encodeVecTypeHint(Type *Ty){
  if (Ty->isHalfTy())
    return 4;
  if (Ty->isFloatTy())
    return 5;
  if (Ty->isDoubleTy())
    return 6;
  if (IntegerType* intTy = dyn_cast<IntegerType>(Ty)) {
    switch (intTy->getIntegerBitWidth()) {
    case 8:
      return 0;
    case 16:
      return 1;
    case 32:
      return 2;
    case 64:
      return 3;
    default:
      llvm_unreachable("invalid integer type");
    }
  }
  if (VectorType* VecTy = dyn_cast<VectorType>(Ty)) {
    Type* EleTy = VecTy->getElementType();
    unsigned Size = VecTy->getVectorNumElements();
    return Size << 16 | encodeVecTypeHint(EleTy);
  }
  llvm_unreachable("invalid type");
}

Type *
decodeVecTypeHint(LLVMContext &C, unsigned code) {
  unsigned VecWidth = code >> 16;
  unsigned Scalar = code & 0xFFFF;
  Type *ST = nullptr;
  switch(Scalar) {
  case 0:
  case 1:
  case 2:
  case 3:
    ST = IntegerType::get(C, 1 << (3 + Scalar));
    break;
  case 4:
    ST = Type::getHalfTy(C);
    break;
  case 5:
    ST = Type::getFloatTy(C);
    break;
  case 6:
    ST = Type::getDoubleTy(C);
    break;
  default:
    llvm_unreachable("Invalid vec type hint");
  }
  if (VecWidth < 1)
    return ST;
  return VectorType::get(ST, VecWidth);
}

unsigned
transVecTypeHint(MDNode* Node) {
  return encodeVecTypeHint(getMDOperandAsType(Node, 1));
}

SPIRAddressSpace
getOCLOpaqueTypeAddrSpace(Op OpCode) {
  switch (OpCode) {
  case OpTypeQueue:
    return SPIRV_QUEUE_T_ADDR_SPACE;
  case OpTypeEvent:
    return SPIRV_EVENT_T_ADDR_SPACE;
  case OpTypeDeviceEvent:
    return SPIRV_CLK_EVENT_T_ADDR_SPACE;
  case OpTypeReserveId:
    return SPIRV_RESERVE_ID_T_ADDR_SPACE;
  case OpTypePipe:
    return SPIRV_PIPE_ADDR_SPACE;
  case OpTypeImage:
  case OpTypeSampledImage:
    return SPIRV_IMAGE_ADDR_SPACE;
  default:
    assert(false && "No address space is determined for some OCL type");
    return SPIRV_OCL_SPECIAL_TYPES_DEFAULT_ADDR_SPACE;
  }
}

static SPIR::TypeAttributeEnum
mapAddrSpaceEnums(SPIRAddressSpace addrspace)
{
  switch (addrspace) {
  case SPIRAS_Private:
    return SPIR::ATTR_PRIVATE;
  case SPIRAS_Global:
    return SPIR::ATTR_GLOBAL;
  case SPIRAS_Constant:
    return SPIR::ATTR_CONSTANT;
  case SPIRAS_Local:
    return SPIR::ATTR_LOCAL;
  case SPIRAS_Generic:
    return SPIR::ATTR_GENERIC;
  default:
    llvm_unreachable("Invalid addrspace enum member");
  }
}

SPIR::TypeAttributeEnum
getOCLOpaqueTypeAddrSpace(SPIR::TypePrimitiveEnum prim) {
  switch (prim) {
  case SPIR::PRIMITIVE_QUEUE_T:
    return mapAddrSpaceEnums(SPIRV_QUEUE_T_ADDR_SPACE);
  case SPIR::PRIMITIVE_EVENT_T:
    return mapAddrSpaceEnums(SPIRV_EVENT_T_ADDR_SPACE);
  case SPIR::PRIMITIVE_CLK_EVENT_T:
    return mapAddrSpaceEnums(SPIRV_CLK_EVENT_T_ADDR_SPACE);
  case SPIR::PRIMITIVE_RESERVE_ID_T:
    return mapAddrSpaceEnums(SPIRV_RESERVE_ID_T_ADDR_SPACE);
  case SPIR::PRIMITIVE_PIPE_T:
    return mapAddrSpaceEnums(SPIRV_PIPE_ADDR_SPACE);
  case SPIR::PRIMITIVE_IMAGE_1D_T:
  case SPIR::PRIMITIVE_IMAGE_1D_ARRAY_T:
  case SPIR::PRIMITIVE_IMAGE_1D_BUFFER_T:
  case SPIR::PRIMITIVE_IMAGE_2D_T:
  case SPIR::PRIMITIVE_IMAGE_2D_ARRAY_T:
  case SPIR::PRIMITIVE_IMAGE_3D_T:
  case SPIR::PRIMITIVE_IMAGE_2D_MSAA_T:
  case SPIR::PRIMITIVE_IMAGE_2D_ARRAY_MSAA_T:
  case SPIR::PRIMITIVE_IMAGE_2D_MSAA_DEPTH_T:
  case SPIR::PRIMITIVE_IMAGE_2D_ARRAY_MSAA_DEPTH_T:
  case SPIR::PRIMITIVE_IMAGE_2D_DEPTH_T:
  case SPIR::PRIMITIVE_IMAGE_2D_ARRAY_DEPTH_T:
    return mapAddrSpaceEnums(SPIRV_IMAGE_ADDR_SPACE);
  default:
    llvm_unreachable("No address space is determined for a SPIR primitive");
  }
}

// Fetch type of invoke function passed to device execution built-ins
static FunctionType *
getBlockInvokeTy(Function * F, unsigned blockIdx) {
    auto params = F->getFunctionType()->params();
    PointerType * funcPtr = cast<PointerType>(params[blockIdx]);
    return cast<FunctionType>(funcPtr->getElementType());
}

class OCLBuiltinFuncMangleInfo : public SPIRV::BuiltinFuncMangleInfo {
public:
  OCLBuiltinFuncMangleInfo(Function * f) : F(f) {}
  void init(const std::string &UniqName) {
  UnmangledName = UniqName;
  size_t Pos = std::string::npos;

  if (UnmangledName.find("async_work_group") == 0) {
    addUnsignedArg(-1);
    setArgAttr(1, SPIR::ATTR_CONST);
  } else if (UnmangledName.find("write_imageui") == 0)
      addUnsignedArg(2);
  else if (UnmangledName == "prefetch") {
    addUnsignedArg(1);
    setArgAttr(0, SPIR::ATTR_CONST);
  } else if(UnmangledName == "get_kernel_work_group_size" ||
            UnmangledName == "get_kernel_preferred_work_group_size_multiple") {
    assert(F && "lack of necessary information");
    const size_t blockArgIdx = 0;
    FunctionType * InvokeTy = getBlockInvokeTy(F, blockArgIdx);
    if(InvokeTy->getNumParams() > 1) setLocalArgBlock(blockArgIdx);
  } else if (UnmangledName == "enqueue_kernel") {
    assert(F && "lack of necessary information");
    setEnumArg(1, SPIR::PRIMITIVE_KERNEL_ENQUEUE_FLAGS_T);
    addUnsignedArg(3);
    setArgAttr(4, SPIR::ATTR_CONST);
    // If there are arguments other then block context then these are pointers
    // to local memory so this built-in must be mangled accordingly.
    const size_t blockArgIdx = 6;
    FunctionType * InvokeTy = getBlockInvokeTy(F, blockArgIdx);
    if(InvokeTy->getNumParams() > 1) {
       setLocalArgBlock(blockArgIdx);
       addUnsignedArg(blockArgIdx + 1);
       setVarArg(blockArgIdx + 2);
    }
  } else if (UnmangledName.find("get_") == 0 ||
      UnmangledName.find("barrier") == 0 ||
      UnmangledName.find("work_group_barrier") == 0 ||
      UnmangledName == "nan" ||
      UnmangledName == "mem_fence" ||
      UnmangledName.find("shuffle") == 0){
    addUnsignedArg(-1);
    if (UnmangledName.find(kOCLBuiltinName::GetFence) == 0){
      setArgAttr(0, SPIR::ATTR_CONST);
      addVoidPtrArg(0);
    }
  } else if (UnmangledName.find("atomic") == 0) {
    setArgAttr(0, SPIR::ATTR_VOLATILE);
    if (UnmangledName.find("atomic_umax") == 0 ||
        UnmangledName.find("atomic_umin") == 0) {
      addUnsignedArg(0);
      addUnsignedArg(1);
      UnmangledName.erase(7, 1);
    } else if (UnmangledName.find("atomic_fetch_umin") == 0 ||
               UnmangledName.find("atomic_fetch_umax") == 0) {
      addUnsignedArg(0);
      addUnsignedArg(1);
      UnmangledName.erase(13, 1);
    }
    // Don't set atomic property to the first argument of 1.2 atomic built-ins.
    if(UnmangledName.find("atomic_add")  != 0 && UnmangledName.find("atomic_sub") != 0 &&
       UnmangledName.find("atomic_xchg") != 0 && UnmangledName.find("atomic_inc") != 0 &&
       UnmangledName.find("atomic_dec")  != 0 && UnmangledName.find("atomic_cmpxchg") != 0 &&
       UnmangledName.find("atomic_min")  != 0 && UnmangledName.find("atomic_max") != 0 &&
       UnmangledName.find("atomic_and")  != 0 && UnmangledName.find("atomic_or") != 0 &&
       UnmangledName.find("atomic_xor")  != 0 && UnmangledName.find("atom_") != 0) {
      addAtomicArg(0);
    }

  } else if (UnmangledName.find("uconvert_") == 0) {
    addUnsignedArg(0);
    UnmangledName.erase(0, 1);
  } else if (UnmangledName.find("s_") == 0) {
    UnmangledName.erase(0, 2);
  } else if (UnmangledName.find("u_") == 0) {
    addUnsignedArg(-1);
    UnmangledName.erase(0, 2);
  } else if (UnmangledName == "fclamp") {
    UnmangledName.erase(0, 1);
  } else if (UnmangledName == "read_pipe" || UnmangledName == "write_pipe") {
    assert(F && "lack of necessary information");
    // handle [read|write]pipe builtins (plus two i32 literal args
    // required by SPIR 2.0 provisional specification):
    if (F->getArgumentList().size() == 6) {
      // with 4 arguments (plus two i32 literals):
      // int read_pipe (read_only pipe gentype p, reserve_id_t reserve_id, uint index, gentype *ptr)
      // int write_pipe (write_only pipe gentype p, reserve_id_t reserve_id, uint index, const gentype *ptr)
      addUnsignedArg(2);
      addVoidPtrArg(3);
      addUnsignedArg(4);
      addUnsignedArg(5);
    } else if (F->getArgumentList().size() == 4) {
      // with 2 arguments (plus two i32 literals):
      // int read_pipe (read_only pipe gentype p, gentype *ptr)
      // int write_pipe (write_only pipe gentype p, const gentype *ptr)
      addVoidPtrArg(1);
      addUnsignedArg(2);
      addUnsignedArg(3);
    } else {
      llvm_unreachable("read/write pipe builtin with unexpected number of arguments");
    }
  } else if (UnmangledName.find("reserve_read_pipe") != std::string::npos ||
             UnmangledName.find("reserve_write_pipe") != std::string::npos) {
    // process [|work_group|sub_group]reserve[read|write]pipe builtins
    addUnsignedArg(1);
    addUnsignedArg(2);
    addUnsignedArg(3);
  } else if (UnmangledName.find("commit_read_pipe") != std::string::npos ||
             UnmangledName.find("commit_write_pipe") != std::string::npos) {
    // process [|work_group|sub_group]commit[read|write]pipe builtins
    addUnsignedArg(2);
    addUnsignedArg(3);
  } else if (UnmangledName == "capture_event_profiling_info") {
    addVoidPtrArg(2);
    setEnumArg(1, SPIR::PRIMITIVE_CLK_PROFILING_INFO);
  } else if (UnmangledName == "enqueue_marker") {
    setArgAttr(2, SPIR::ATTR_CONST);
    addUnsignedArg(1);
  } else if (UnmangledName.find("vload") == 0) {
    addUnsignedArg(0);
    setArgAttr(1, SPIR::ATTR_CONST);
  } else if (UnmangledName.find("vstore") == 0 ){
    addUnsignedArg(1);
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
// Auxiliarry information, it is expected what it is relevant at the moment
// the init method is called.
Function * F; // SPIRV decorated function
};

CallInst *
mutateCallInstOCL(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    AttributeSet *Attrs) {
  OCLBuiltinFuncMangleInfo BtnInfo(CI->getCalledFunction());
  return mutateCallInst(M, CI, ArgMutate, &BtnInfo, Attrs);
}

Instruction *
mutateCallInstOCL(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &,
        Type *&RetTy)> ArgMutate,
    std::function<Instruction *(CallInst *)> RetMutate,
    AttributeSet *Attrs) {
  OCLBuiltinFuncMangleInfo BtnInfo(CI->getCalledFunction());
  return mutateCallInst(M, CI, ArgMutate, RetMutate, &BtnInfo, Attrs);
}

void
mutateFunctionOCL(Function *F,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    AttributeSet *Attrs) {
  OCLBuiltinFuncMangleInfo BtnInfo(F);
  return mutateFunction(F, ArgMutate, &BtnInfo, Attrs, false);
}

} // namespace OCLUtil

void
llvm::MangleOpenCLBuiltin(const std::string &UniqName,
    ArrayRef<Type*> ArgTypes, std::string &MangledName) {
  OCLUtil::OCLBuiltinFuncMangleInfo BtnInfo(nullptr);
  MangledName = SPIRV::mangleBuiltin(UniqName, ArgTypes, &BtnInfo);
}
