//===- OCLUtil.h - OCL Utilities declarations -------------------*- C++ -*-===//
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
// This file declares OCL utility functions.
//
//===----------------------------------------------------------------------===//
#include "SPIRVInternal.h"

#include <utility>
#include <tuple>
#include <functional>
using namespace SPIRV;
using namespace llvm;
using namespace spv;

namespace OCLUtil {

///////////////////////////////////////////////////////////////////////////////
//
// Enums
//
///////////////////////////////////////////////////////////////////////////////

enum OCLMemFenceKind {
  OCLMF_Local = 1,
  OCLMF_Global = 2,
  OCLMF_Image = 4,
};

enum OCLScopeKind {
  OCLMS_work_item,
  OCLMS_work_group,
  OCLMS_device,
  OCLMS_all_svm_devices,
  OCLMS_sub_group,
};

enum OCLMemOrderKind {
  OCLMO_relaxed,
  OCLMO_acquire,
  OCLMO_release,
  OCLMO_acq_rel,
  OCLMO_seq_cst
};

///////////////////////////////////////////////////////////////////////////////
//
// Types
//
///////////////////////////////////////////////////////////////////////////////

typedef SPIRVMap<OCLMemFenceKind, MemorySemanticsMask>
  OCLMemFenceMap;

typedef SPIRVMap<OCLMemOrderKind, unsigned, MemorySemanticsMask>
  OCLMemOrderMap;

typedef SPIRVMap<OCLScopeKind, Scope>
  OCLMemScopeMap;

typedef SPIRVMap<std::string, SPIRVGroupOperationKind>
  SPIRSPIRVGroupOperationMap;

typedef SPIRVMap<std::string, SPIRVFPRoundingModeKind>
  SPIRSPIRVFPRoundingModeMap;

typedef SPIRVMap<std::string, Op, SPIRVInstruction>
  OCLSPIRVBuiltinMap;

typedef SPIRVMap<std::string, SPIRVBuiltinVariableKind>
  SPIRSPIRVBuiltinVariableMap;

/// Tuple of literals for atomic_work_item_fence (flag, order, scope)
typedef std::tuple<unsigned, OCLMemOrderKind, OCLScopeKind>
  AtomicWorkItemFenceLiterals;

/// Tuple of literals for work_group_barrier (flag, mem_scope, exec_scope)
typedef std::tuple<unsigned, OCLScopeKind, OCLScopeKind>
  WorkGroupBarrierLiterals;

class OCLOpaqueType;
typedef SPIRVMap<std::string, Op, OCLOpaqueType>
  BuiltinOpaqueGenericTypeOpCodeMap;

/// Information for translating OCL builtin.
struct OCLBuiltinTransInfo {
  std::string UniqName;
  std::string MangledName;
  std::string Postfix;      // Postfix to be added
  /// Postprocessor of operands
  std::function<void(std::vector<Value *>&)> PostProc;
  Type* RetTy;              // Return type of the translated function
  bool isRetSigned;         // When RetTy is int, determines if extensions
                            // on it should be a sext or zet.
  OCLBuiltinTransInfo() : RetTy(nullptr), isRetSigned(false) {
    PostProc = [](std::vector<Value *>&){};
  }
};

///////////////////////////////////////////////////////////////////////////////
//
// Constants
//
///////////////////////////////////////////////////////////////////////////////
namespace kOCLBuiltinName {
  const static char All[]                       = "all";
  const static char Any[]                       = "any";
  const static char AsyncWorkGroupCopy[]        = "async_work_group_copy";
  const static char AsyncWorkGroupStridedCopy[] = "async_work_group_strided_copy";
  const static char AtomPrefix[]         = "atom_";
  const static char AtomCmpXchg[]        = "atom_cmpxchg";
  const static char AtomicPrefix[]       = "atomic_";
  const static char AtomicCmpXchg[]      = "atomic_cmpxchg";
  const static char AtomicCmpXchgStrong[] = "atomic_compare_exchange_strong";
  const static char AtomicCmpXchgWeak[]   = "atomic_compare_exchange_weak";
  const static char AtomicInit[]          = "atomic_init";
  const static char AtomicWorkItemFence[] = "atomic_work_item_fence";
  const static char Barrier[]            = "barrier";
  const static char Clamp[]              = "clamp";
  const static char ConvertPrefix[]      = "convert_";
  const static char Dot[]                = "dot";
  const static char EnqueueKernel[]      = "enqueue_kernel";
  const static char FMax[]               = "fmax";
  const static char FMin[]               = "fmin";
  const static char GetFence[]           = "get_fence";
  const static char GetImageArraySize[]  = "get_image_array_size";
  const static char GetImageDepth[]      = "get_image_depth";
  const static char GetImageDim[]        = "get_image_dim";
  const static char GetImageHeight[]     = "get_image_height";
  const static char GetImageWidth[]      = "get_image_width";
  const static char IsFinite[]           = "isfinite";
  const static char IsNan[]              = "isnan";
  const static char IsNormal[]           = "isnormal";
  const static char IsInf[]              = "isinf";
  const static char Max[]                = "max";
  const static char MemFence[]           = "mem_fence";
  const static char Min[]                = "min";
  const static char Mix[]                = "mix";
  const static char NDRangePrefix[]      = "ndrange_";
  const static char Pipe[]               = "pipe";
  const static char ReadImage[]          = "read_image";
  const static char ReadPipe[]           = "read_pipe";
  const static char RoundingPrefix[]     = "_r";
  const static char Sampled[]            = "sampled_";
  const static char SampledReadImage[]   = "sampled_read_image";
  const static char Signbit[]            = "signbit";
  const static char SmoothStep[]         = "smoothstep";
  const static char Step[]               = "step";
  const static char SubGroupPrefix[]     = "sub_group_";
  const static char SubPrefix[]          = "sub_";
  const static char ToGlobal[]           = "to_global";
  const static char ToLocal[]            = "to_local";
  const static char ToPrivate[]          = "to_private";
  const static char VLoadPrefix[]        = "vload";
  const static char VLoadAPrefix[]       = "vloada";
  const static char VLoadHalf[]          = "vload_half";
  const static char VStorePrefix[]       = "vstore";
  const static char VStoreAPrefix[]      = "vstorea";
  const static char WaitGroupEvent[]     = "wait_group_events";
  const static char WriteImage[]         = "write_image";
  const static char WorkGroupBarrier[]   = "work_group_barrier";
  const static char WritePipe[]          = "write_pipe";
  const static char WorkGroupPrefix[]    = "work_group_";
  const static char WorkGroupAll[]       = "work_group_all";
  const static char WorkGroupAny[]       = "work_group_any";
  const static char SubGroupAll[]        = "sub_group_all";
  const static char SubGroupAny[]        = "sub_group_any";
  const static char WorkPrefix[]         = "work_";
}

/// OCL 1.x atomic memory order when translated to 2.0 atomics.
const OCLMemOrderKind OCLLegacyAtomicMemOrder = OCLMO_seq_cst;

/// OCL 1.x atomic memory scope when translated to 2.0 atomics.
const OCLScopeKind OCLLegacyAtomicMemScope = OCLMS_device;

namespace kOCLVer {
  const unsigned CL12 = 102000;
  const unsigned CL20 = 200000;
  const unsigned CL21 = 201000;
}

namespace OclExt {
enum Kind {
#define _SPIRV_OP(x) x,
  _SPIRV_OP(cl_images)
  _SPIRV_OP(cl_doubles)
  _SPIRV_OP(cl_khr_int64_base_atomics)
  _SPIRV_OP(cl_khr_int64_extended_atomics)
  _SPIRV_OP(cl_khr_fp16)
  _SPIRV_OP(cl_khr_gl_sharing)
  _SPIRV_OP(cl_khr_gl_event)
  _SPIRV_OP(cl_khr_d3d10_sharing)
  _SPIRV_OP(cl_khr_media_sharing)
  _SPIRV_OP(cl_khr_d3d11_sharing)
  _SPIRV_OP(cl_khr_global_int32_base_atomics)
  _SPIRV_OP(cl_khr_global_int32_extended_atomics)
  _SPIRV_OP(cl_khr_local_int32_base_atomics)
  _SPIRV_OP(cl_khr_local_int32_extended_atomics)
  _SPIRV_OP(cl_khr_byte_addressable_store)
  _SPIRV_OP(cl_khr_3d_image_writes)
  _SPIRV_OP(cl_khr_gl_msaa_sharing)
  _SPIRV_OP(cl_khr_depth_images)
  _SPIRV_OP(cl_khr_gl_depth_images)
  _SPIRV_OP(cl_khr_subgroups)
  _SPIRV_OP(cl_khr_mipmap_image)
  _SPIRV_OP(cl_khr_mipmap_image_writes)
  _SPIRV_OP(cl_khr_egl_event)
  _SPIRV_OP(cl_khr_srgb_image_writes)
#undef _SPIRV_OP
};
}


///////////////////////////////////////////////////////////////////////////////
//
// Functions
//
///////////////////////////////////////////////////////////////////////////////

/// Get instruction index for SPIR-V extended instruction for OpenCL.std
///   extended instruction set.
/// \param MangledName The mangled name of OpenCL builtin function.
/// \param DemangledName The demangled name of OpenCL builtin function if
///   not empty.
/// \return instruction index of extended instruction if the OpenCL builtin
///   function is translated to an extended instruction, otherwise ~0U.
unsigned getExtOp(StringRef MangledName,
    const std::string &DemangledName = "");

/// Get an empty SPIR-V instruction.
std::unique_ptr<SPIRVEntry>
getSPIRVInst(const OCLBuiltinTransInfo &Info);

/// Get literal arguments of call of atomic_work_item_fence.
AtomicWorkItemFenceLiterals getAtomicWorkItemFenceLiterals(CallInst* CI);

/// Get literal arguments of call of work_group_barrier.
WorkGroupBarrierLiterals getWorkGroupBarrierLiterals(CallInst* CI);

/// Get number of memory order arguments for atomic builtin function.
size_t getAtomicBuiltinNumMemoryOrderArgs(StringRef Name);

/// Get OCL version from metadata opencl.ocl.version.
/// \param AllowMulti Allows multiple operands if true.
/// \return OCL version encoded as Major*10^5+Minor*10^3+Rev,
/// e.g. 201000 for OCL 2.1, 200000 for OCL 2.0, 102000 for OCL 1.2,
/// 0 if metadata not found.
/// If there are multiple operands, check they are identical.
unsigned getOCLVersion(Module *M, bool AllowMulti = false);

/// Encode OpenCL version as Major*10^5+Minor*10^3+Rev.
unsigned
encodeOCLVer(unsigned short Major,
    unsigned char Minor, unsigned char Rev);

/// Decode OpenCL version which is encoded as Major*10^5+Minor*10^3+Rev
std::tuple<unsigned short, unsigned char, unsigned char>
decodeOCLVer(unsigned Ver);

/// Decode a MDNode assuming it contains three integer constants.
void decodeMDNode(MDNode* N, unsigned& X, unsigned& Y, unsigned& Z);

/// Decode OpenCL vector type hint MDNode and encode it as SPIR-V execution
/// mode VecTypeHint.
unsigned transVecTypeHint(MDNode* Node);

/// Decode SPIR-V encoding of vector type hint execution mode.
Type *decodeVecTypeHint(LLVMContext &C, unsigned code);

SPIRAddressSpace getOCLOpaqueTypeAddrSpace(Op OpCode);
SPIR::TypeAttributeEnum getOCLOpaqueTypeAddrSpace(SPIR::TypePrimitiveEnum prim);

inline unsigned mapOCLMemSemanticToSPIRV(unsigned MemFenceFlag,
    OCLMemOrderKind Order) {
  return OCLMemOrderMap::map(Order) |
      mapBitMask<OCLMemFenceMap>(MemFenceFlag);
}

inline unsigned mapOCLMemFenceFlagToSPIRV(unsigned MemFenceFlag) {
  return mapBitMask<OCLMemFenceMap>(MemFenceFlag);
}

inline std::pair<unsigned, OCLMemOrderKind>
mapSPIRVMemSemanticToOCL(unsigned Sema) {
  return std::make_pair(rmapBitMask<OCLMemFenceMap>(Sema),
    OCLMemOrderMap::rmap(extractSPIRVMemOrderSemantic(Sema)));
}

inline OCLMemOrderKind
mapSPIRVMemOrderToOCL(unsigned Sema) {
  return OCLMemOrderMap::rmap(extractSPIRVMemOrderSemantic(Sema));
}

/// Mutate call instruction to call OpenCL builtin function.
CallInst *
mutateCallInstOCL(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    AttributeSet *Attrs = nullptr);

/// Mutate call instruction to call OpenCL builtin function.
Instruction *
mutateCallInstOCL(Module *M, CallInst *CI,
    std::function<std::string (CallInst *, std::vector<Value *> &,
        Type *&RetTy)> ArgMutate,
    std::function<Instruction *(CallInst *)> RetMutate,
    AttributeSet *Attrs = nullptr);

/// Mutate a function to OpenCL builtin function.
void
mutateFunctionOCL(Function *F,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    AttributeSet *Attrs = nullptr);
} // namespace OCLUtil

///////////////////////////////////////////////////////////////////////////////
//
// Map definitions
//
///////////////////////////////////////////////////////////////////////////////

using namespace OCLUtil;
namespace SPIRV {
template<> inline void
SPIRVMap<OCLMemFenceKind, MemorySemanticsMask>::init() {
  add(OCLMF_Local, MemorySemanticsWorkgroupMemoryMask);
  add(OCLMF_Global, MemorySemanticsCrossWorkgroupMemoryMask);
  add(OCLMF_Image, MemorySemanticsImageMemoryMask);
}

template<> inline void
SPIRVMap<OCLMemOrderKind, unsigned, MemorySemanticsMask>::init() {
  add(OCLMO_relaxed, MemorySemanticsMaskNone);
  add(OCLMO_acquire, MemorySemanticsAcquireMask);
  add(OCLMO_release, MemorySemanticsReleaseMask);
  add(OCLMO_acq_rel, MemorySemanticsAcquireReleaseMask);
  add(OCLMO_seq_cst, MemorySemanticsSequentiallyConsistentMask);
}

template<> inline void
SPIRVMap<OCLScopeKind, Scope>::init() {
  add(OCLMS_work_item, ScopeInvocation);
  add(OCLMS_work_group, ScopeWorkgroup);
  add(OCLMS_device, ScopeDevice);
  add(OCLMS_all_svm_devices, ScopeCrossDevice);
  add(OCLMS_sub_group, ScopeSubgroup);
}

template<> inline void
SPIRVMap<std::string, SPIRVGroupOperationKind>::init() {
  add("reduce", GroupOperationReduce);
  add("scan_inclusive", GroupOperationInclusiveScan);
  add("scan_exclusive", GroupOperationExclusiveScan);
}

template<> inline void
SPIRVMap<std::string, SPIRVFPRoundingModeKind>::init() {
  add("rte", FPRoundingModeRTE);
  add("rtz", FPRoundingModeRTZ);
  add("rtp", FPRoundingModeRTP);
  add("rtn", FPRoundingModeRTN);
}

template<> inline void
SPIRVMap<OclExt::Kind, std::string>::init() {
#define _SPIRV_OP(x) add(OclExt::x, #x);
  _SPIRV_OP(cl_images)
  _SPIRV_OP(cl_doubles)
  _SPIRV_OP(cl_khr_int64_base_atomics)
  _SPIRV_OP(cl_khr_int64_extended_atomics)
  _SPIRV_OP(cl_khr_fp16)
  _SPIRV_OP(cl_khr_gl_sharing)
  _SPIRV_OP(cl_khr_gl_event)
  _SPIRV_OP(cl_khr_d3d10_sharing)
  _SPIRV_OP(cl_khr_media_sharing)
  _SPIRV_OP(cl_khr_d3d11_sharing)
  _SPIRV_OP(cl_khr_global_int32_base_atomics)
  _SPIRV_OP(cl_khr_global_int32_extended_atomics)
  _SPIRV_OP(cl_khr_local_int32_base_atomics)
  _SPIRV_OP(cl_khr_local_int32_extended_atomics)
  _SPIRV_OP(cl_khr_byte_addressable_store)
  _SPIRV_OP(cl_khr_3d_image_writes)
  _SPIRV_OP(cl_khr_gl_msaa_sharing)
  _SPIRV_OP(cl_khr_depth_images)
  _SPIRV_OP(cl_khr_gl_depth_images)
  _SPIRV_OP(cl_khr_subgroups)
  _SPIRV_OP(cl_khr_mipmap_image)
  _SPIRV_OP(cl_khr_mipmap_image_writes)
  _SPIRV_OP(cl_khr_egl_event)
  _SPIRV_OP(cl_khr_srgb_image_writes)
#undef _SPIRV_OP
}

template<> inline void
SPIRVMap<OclExt::Kind, SPIRVCapabilityKind>::init() {
  add(OclExt::cl_images, CapabilityImageBasic);
  add(OclExt::cl_doubles, CapabilityFloat64);
  add(OclExt::cl_khr_int64_base_atomics, CapabilityInt64Atomics);
  add(OclExt::cl_khr_int64_extended_atomics, CapabilityInt64Atomics);
  add(OclExt::cl_khr_fp16, CapabilityFloat16);
  add(OclExt::cl_khr_subgroups, CapabilityGroups);
  add(OclExt::cl_khr_mipmap_image, CapabilityImageMipmap);
  add(OclExt::cl_khr_mipmap_image_writes, CapabilityImageMipmap);
}

/// Map OpenCL work functions to SPIR-V builtin variables.
template<> inline void
SPIRVMap<std::string, SPIRVBuiltinVariableKind>::init() {
  add("get_work_dim", BuiltInWorkDim);
  add("get_global_size", BuiltInGlobalSize);
  add("get_global_id", BuiltInGlobalInvocationId);
  add("get_global_offset", BuiltInGlobalOffset);
  add("get_local_size", BuiltInWorkgroupSize);
  add("get_enqueued_local_size", BuiltInEnqueuedWorkgroupSize);
  add("get_local_id", BuiltInLocalInvocationId);
  add("get_num_groups", BuiltInNumWorkgroups);
  add("get_group_id", BuiltInWorkgroupId);
  add("get_global_linear_id", BuiltInGlobalLinearId);
  add("get_local_linear_id", BuiltInLocalInvocationIndex);
  add("get_sub_group_size", BuiltInSubgroupSize);
  add("get_max_sub_group_size", BuiltInSubgroupMaxSize);
  add("get_num_sub_groups", BuiltInNumSubgroups);
  add("get_enqueued_num_sub_groups", BuiltInNumEnqueuedSubgroups);
  add("get_sub_group_id", BuiltInSubgroupId);
  add("get_sub_group_local_id", BuiltInSubgroupLocalInvocationId);
}

// Maps uniqued OCL builtin function name to SPIR-V op code.
// A uniqued OCL builtin function name may be different from the real
// OCL builtin function name. e.g. instead of atomic_min, atomic_umin
// is used for atomic_min with unsigned integer parameter.
// work_group_ and sub_group_ functions are unified as group_ functions
// except work_group_barrier.
class SPIRVInstruction;
template<> inline void
SPIRVMap<std::string, Op, SPIRVInstruction>::init() {
#define _SPIRV_OP(x,y) add("atom_"#x, OpAtomic##y);
// cl_khr_int64_base_atomics builtins
_SPIRV_OP(add, IAdd)
_SPIRV_OP(sub, ISub)
_SPIRV_OP(xchg, Exchange)
_SPIRV_OP(dec, IDecrement)
_SPIRV_OP(inc, IIncrement)
_SPIRV_OP(cmpxchg, CompareExchange)
// cl_khr_int64_extended_atomics builtins
_SPIRV_OP(min, SMin)
_SPIRV_OP(max, SMax)
_SPIRV_OP(and, And)
_SPIRV_OP(or, Or)
_SPIRV_OP(xor, Xor)
#undef _SPIRV_OP
#define _SPIRV_OP(x,y) add("atomic_"#x, Op##y);
// CL 2.0 atomic builtins
_SPIRV_OP(flag_test_and_set_explicit, AtomicFlagTestAndSet)
_SPIRV_OP(flag_clear_explicit, AtomicFlagClear)
_SPIRV_OP(load_explicit, AtomicLoad)
_SPIRV_OP(store_explicit, AtomicStore)
_SPIRV_OP(exchange_explicit, AtomicExchange)
_SPIRV_OP(compare_exchange_strong_explicit, AtomicCompareExchange)
_SPIRV_OP(compare_exchange_weak_explicit, AtomicCompareExchangeWeak)
_SPIRV_OP(inc, AtomicIIncrement)
_SPIRV_OP(dec, AtomicIDecrement)
_SPIRV_OP(fetch_add_explicit, AtomicIAdd)
_SPIRV_OP(fetch_sub_explicit, AtomicISub)
_SPIRV_OP(fetch_umin_explicit, AtomicUMin)
_SPIRV_OP(fetch_umax_explicit, AtomicUMax)
_SPIRV_OP(fetch_min_explicit, AtomicSMin)
_SPIRV_OP(fetch_max_explicit, AtomicSMax)
_SPIRV_OP(fetch_and_explicit, AtomicAnd)
_SPIRV_OP(fetch_or_explicit, AtomicOr)
_SPIRV_OP(fetch_xor_explicit, AtomicXor)
#undef _SPIRV_OP
#define _SPIRV_OP(x,y) add(#x, Op##y);
_SPIRV_OP(dot, Dot)
_SPIRV_OP(async_work_group_copy, GroupAsyncCopy)
_SPIRV_OP(async_work_group_strided_copy, GroupAsyncCopy)
_SPIRV_OP(wait_group_events, GroupWaitEvents)
_SPIRV_OP(isequal, FOrdEqual)
_SPIRV_OP(isnotequal, FUnordNotEqual)
_SPIRV_OP(isgreater, FOrdGreaterThan)
_SPIRV_OP(isgreaterequal, FOrdGreaterThanEqual)
_SPIRV_OP(isless, FOrdLessThan)
_SPIRV_OP(islessequal, FOrdLessThanEqual)
_SPIRV_OP(islessgreater, LessOrGreater)
_SPIRV_OP(isordered, Ordered)
_SPIRV_OP(isunordered, Unordered)
_SPIRV_OP(isfinite, IsFinite)
_SPIRV_OP(isinf, IsInf)
_SPIRV_OP(isnan, IsNan)
_SPIRV_OP(isnormal, IsNormal)
_SPIRV_OP(signbit, SignBitSet)
_SPIRV_OP(any, Any)
_SPIRV_OP(all, All)
_SPIRV_OP(get_fence, GenericPtrMemSemantics)
// CL 2.0 kernel enqueue builtins
_SPIRV_OP(enqueue_marker, EnqueueMarker)
_SPIRV_OP(enqueue_kernel, EnqueueKernel)
_SPIRV_OP(get_kernel_ndrange_subgroup_count, GetKernelNDrangeSubGroupCount)
_SPIRV_OP(get_kernel_ndrange_max_subgroup_count, GetKernelNDrangeMaxSubGroupSize)
_SPIRV_OP(get_kernel_work_group_size, GetKernelWorkGroupSize)
_SPIRV_OP(get_kernel_preferred_work_group_size_multiple, GetKernelPreferredWorkGroupSizeMultiple)
_SPIRV_OP(retain_event, RetainEvent)
_SPIRV_OP(release_event, ReleaseEvent)
_SPIRV_OP(create_user_event, CreateUserEvent)
_SPIRV_OP(is_valid_event, IsValidEvent)
_SPIRV_OP(set_user_event_status, SetUserEventStatus)
_SPIRV_OP(capture_event_profiling_info, CaptureEventProfilingInfo)
_SPIRV_OP(get_default_queue, GetDefaultQueue)
_SPIRV_OP(ndrange_1D, BuildNDRange)
_SPIRV_OP(ndrange_2D, BuildNDRange)
_SPIRV_OP(ndrange_3D, BuildNDRange)
// Generic Address Space Casts
_SPIRV_OP(to_global, GenericCastToPtrExplicit)
_SPIRV_OP(to_local, GenericCastToPtrExplicit)
_SPIRV_OP(to_private, GenericCastToPtrExplicit)
_SPIRV_OP(work_group_barrier, ControlBarrier)
// CL 2.0 pipe builtins
_SPIRV_OP(read_pipe, ReadPipe)
_SPIRV_OP(write_pipe, WritePipe)
_SPIRV_OP(reserved_read_pipe, ReservedReadPipe)
_SPIRV_OP(reserved_write_pipe, ReservedWritePipe)
_SPIRV_OP(reserve_read_pipe, ReserveReadPipePackets)
_SPIRV_OP(reserve_write_pipe, ReserveWritePipePackets)
_SPIRV_OP(commit_read_pipe, CommitReadPipe)
_SPIRV_OP(commit_write_pipe, CommitWritePipe)
_SPIRV_OP(is_valid_reserve_id, IsValidReserveId)
_SPIRV_OP(group_reserve_read_pipe, GroupReserveReadPipePackets)
_SPIRV_OP(group_reserve_write_pipe, GroupReserveWritePipePackets)
_SPIRV_OP(group_commit_read_pipe, GroupCommitReadPipe)
_SPIRV_OP(group_commit_write_pipe, GroupCommitWritePipe)
_SPIRV_OP(get_pipe_num_packets, GetNumPipePackets)
_SPIRV_OP(get_pipe_max_packets, GetMaxPipePackets)
// CL 2.0 workgroup builtins
_SPIRV_OP(group_all, GroupAll)
_SPIRV_OP(group_any, GroupAny)
_SPIRV_OP(group_broadcast, GroupBroadcast)
_SPIRV_OP(group_iadd, GroupIAdd)
_SPIRV_OP(group_fadd, GroupFAdd)
_SPIRV_OP(group_fmin, GroupFMin)
_SPIRV_OP(group_umin, GroupUMin)
_SPIRV_OP(group_smin, GroupSMin)
_SPIRV_OP(group_fmax, GroupFMax)
_SPIRV_OP(group_umax, GroupUMax)
_SPIRV_OP(group_smax, GroupSMax)
// CL image builtins
_SPIRV_OP(SampledImage, SampledImage)
_SPIRV_OP(ImageSampleExplicitLod, ImageSampleExplicitLod)
_SPIRV_OP(read_image, ImageRead)
_SPIRV_OP(write_image, ImageWrite)
_SPIRV_OP(get_image_channel_data_type, ImageQueryFormat)
_SPIRV_OP(get_image_channel_order, ImageQueryOrder)
_SPIRV_OP(get_image_num_mip_levels, ImageQueryLevels)
_SPIRV_OP(get_image_num_samples, ImageQuerySamples)
#undef _SPIRV_OP
}

template<> inline void
SPIRVMap<std::string, Op, OCLOpaqueType>::init() {
  add("opencl.event_t", OpTypeEvent);
  add("opencl.pipe_t", OpTypePipe);
  add("opencl.clk_event_t", OpTypeDeviceEvent);
  add("opencl.reserve_id_t", OpTypeReserveId);
  add("opencl.queue_t", OpTypeQueue);
}

} // namespace SPIRV
