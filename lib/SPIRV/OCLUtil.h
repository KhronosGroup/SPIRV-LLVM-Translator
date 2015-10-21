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
#include "SPRVInternal.h"

#include <utility>
#include <tuple>
#include <functional>
using namespace SPRV;
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

typedef SPRVMap<OCLMemFenceKind, MemorySemanticsMask>
  OCLMemFenceMap;

typedef SPRVMap<OCLMemOrderKind, unsigned, MemorySemanticsMask>
  OCLMemOrderMap;

typedef SPRVMap<OCLScopeKind, Scope>
  OCLMemScopeMap;

typedef SPRVMap<std::string, SPRVGroupOperationKind>
  SPIRSPRVGroupOperationMap;

typedef SPRVMap<std::string, SPRVFPRoundingModeKind>
  SPIRSPRVFPRoundingModeMap;

typedef SPRVMap<std::string, Op, SPRVInstruction>
  OCLSPRVBuiltinMap;

typedef SPRVMap<std::string, SPRVBuiltinVariableKind>
  SPIRSPRVBuiltinVariableMap;

/// Tuple of literals for atomic_work_item_fence (flag, order, scope)
typedef std::tuple<unsigned, OCLMemOrderKind, OCLScopeKind>
  AtomicWorkItemFenceLiterals;

/// Tuple of literals for work_group_barrier (flag, mem_scope, exec_scope)
typedef std::tuple<unsigned, OCLScopeKind, OCLScopeKind>
  WorkGroupBarrierLiterals;

/// Information for translating OCL builtin.
struct OCLBuiltinTransInfo {
  std::string UniqName;
  std::string MangledName;
  /// Postprocessor of operands
  std::function<void(std::vector<Value *>&)> PostProc;
  OCLBuiltinTransInfo(){
    PostProc = [](std::vector<Value *>&){};
  }
};

///////////////////////////////////////////////////////////////////////////////
//
// Constants
//
///////////////////////////////////////////////////////////////////////////////
namespace kOCLBuiltinName {
  const static char AsyncWorkGroupCopy[]        = "async_work_group_copy";
  const static char AsyncWorkGroupStridedCopy[] = "async_work_group_strided_copy";
  const static char AtomPrefix[]         = "atom_";
  const static char AtomCmpXchg[]        = "atom_cmpxchg";
  const static char AtomicPrefix[]       = "atomic_";
  const static char AtomicCmpXchg[]      = "atomic_cmpxchg";
  const static char AtomicCmpXchgStrong[] = "atomic_compare_exchange_strong";
  const static char AtomicInit[]         = "atomic_init";
  const static char AtomicWorkItemFence[] = "atomic_work_item_fence";
  const static char Barrier[]            = "barrier";
  const static char ConvertPrefix[]      = "convert_";
  const static char EnqueueKernel[]      = "enqueue_kernel";
  const static char GetFence[]           = "get_fence";
  const static char GetImageArraySize[]  = "get_image_array_size";
  const static char GetImageDepth[]      = "get_image_depth";
  const static char GetImageDim[]        = "get_image_dim";
  const static char GetImageHeight[]     = "get_image_height";
  const static char GetImageWidth[]      = "get_image_width";
  const static char MemFence[]           = "mem_fence";
  const static char NDRangePrefix[]      = "ndrange_";
  const static char Pipe[]               = "pipe";
  const static char ToGlobal[]           = "to_global";
  const static char ToLocal[]            = "to_local";
  const static char ToPrivate[]          = "to_private";
  const static char ReadImage[]          = "read_image";
  const static char ReadPipe[]           = "read_pipe";
  const static char Sampled[]            = "sampled_";
  const static char SampledReadImage[]   = "sampled_read_image";
  const static char SubGroupPrefix[]     = "sub_group_";
  const static char SubPrefix[]          = "sub_";
  const static char VLoadPrefix[]        = "vload";
  const static char VStorePrefix[]       = "vstore";
  const static char WaitGroupEvent[]     = "wait_group_events";
  const static char WriteImage[]         = "write_image";
  const static char WorkGroupBarrier[]   = "work_group_barrier";
  const static char WritePipe[]          = "write_pipe";
  const static char WorkGroupPrefix[]    = "work_group_";
  const static char WorkPrefix[]         = "work_";
}

/// OCL 1.x atomic memory order when translated to 2.0 atomics.
const OCLMemOrderKind OCLLegacyAtomicMemOrder = OCLMO_seq_cst;

/// OCL 1.x atomic memory scope when translated to 2.0 atomics.
const OCLScopeKind OCLLegacyAtomicMemScope = OCLMS_device;

namespace OclExt {
enum Kind {
#define _SPRV_OP(x) x,
  _SPRV_OP(cl_images)
  _SPRV_OP(cl_doubles)
  _SPRV_OP(cl_khr_int64_base_atomics)
  _SPRV_OP(cl_khr_int64_extended_atomics)
  _SPRV_OP(cl_khr_fp16)
  _SPRV_OP(cl_khr_gl_sharing)
  _SPRV_OP(cl_khr_gl_event)
  _SPRV_OP(cl_khr_d3d10_sharing)
  _SPRV_OP(cl_khr_media_sharing)
  _SPRV_OP(cl_khr_d3d11_sharing)
  _SPRV_OP(cl_khr_global_int32_base_atomics)
  _SPRV_OP(cl_khr_global_int32_extended_atomics)
  _SPRV_OP(cl_khr_local_int32_base_atomics)
  _SPRV_OP(cl_khr_local_int32_extended_atomics)
  _SPRV_OP(cl_khr_byte_addressable_store)
  _SPRV_OP(cl_khr_3d_image_writes)
  _SPRV_OP(cl_khr_gl_msaa_sharing)
  _SPRV_OP(cl_khr_depth_images)
  _SPRV_OP(cl_khr_gl_depth_images)
  _SPRV_OP(cl_khr_subgroups)
  _SPRV_OP(cl_khr_mipmap_image)
  _SPRV_OP(cl_khr_mipmap_image_writes)
  _SPRV_OP(cl_khr_egl_event)
  _SPRV_OP(cl_khr_srgb_image_writes)
#undef _SPRV_OP
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
std::unique_ptr<SPRVEntry>
getSPRVInst(const OCLBuiltinTransInfo &Info);

/// Get literal arguments of call of atomic_work_item_fence.
AtomicWorkItemFenceLiterals getAtomicWorkItemFenceLiterals(CallInst* CI);

/// Get literal arguments of call of work_group_barrier.
WorkGroupBarrierLiterals getWorkGroupBarrierLiterals(CallInst* CI);

/// Get number of memory order arguments for atomic builtin function.
size_t getAtomicBuiltinNumMemoryOrderArgs(StringRef Name);

/// Get metadata operand as int.
int getMDOperandAsInt(MDNode* N, unsigned I);

/// Get metadata operand as string.
std::string getMDOperandAsString(MDNode* N, unsigned I);

/// Get metadata operand as type.
Type* getMDOperandAsType(MDNode* N, unsigned I);

/// Get OCL version from metadata opencl.ocl.version.
/// \return 20 for OCL 2.0, 12 for OCL 1.2.
unsigned getOCLVersion(Module *M);

SPIRAddressSpace getOCLOpaqueTypeAddrSpace(Op OpCode);

inline unsigned mapOCLMemSemanticToSPRV(unsigned MemFenceFlag,
    OCLMemOrderKind Order) {
  return OCLMemOrderMap::map(Order) |
      mapBitMask<OCLMemFenceMap>(MemFenceFlag);
}

inline unsigned mapOCLMemFenceFlagToSPRV(unsigned MemFenceFlag) {
  return mapBitMask<OCLMemFenceMap>(MemFenceFlag);
}

inline std::pair<unsigned, OCLMemOrderKind>
mapSPRVMemSemanticToOCL(unsigned Sema) {
  return std::make_pair(rmapBitMask<OCLMemFenceMap>(Sema),
    OCLMemOrderMap::rmap(extractSPRVMemOrderSemantic(Sema)));
}

inline OCLMemOrderKind
mapSPRVMemOrderToOCL(unsigned Sema) {
  return OCLMemOrderMap::rmap(extractSPRVMemOrderSemantic(Sema));
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
namespace SPRV {
template<> inline void
SPRVMap<OCLMemFenceKind, MemorySemanticsMask>::init() {
  add(OCLMF_Local, MemorySemanticsWorkgroupLocalMemoryMask);
  add(OCLMF_Global, MemorySemanticsWorkgroupGlobalMemoryMask);
  add(OCLMF_Image, MemorySemanticsImageMemoryMask);
}

template<> inline void
SPRVMap<OCLMemOrderKind, unsigned, MemorySemanticsMask>::init() {
  add(OCLMO_relaxed, MemorySemanticsMaskNone);
  add(OCLMO_acquire, MemorySemanticsAcquireMask);
  add(OCLMO_release, MemorySemanticsReleaseMask);
  add(OCLMO_acq_rel, MemorySemanticsAcquireReleaseMask);
  add(OCLMO_seq_cst, MemorySemanticsSequentiallyConsistentMask);
}

template<> inline void
SPRVMap<OCLScopeKind, Scope>::init() {
  add(OCLMS_work_item, ScopeInvocation);
  add(OCLMS_work_group, ScopeWorkgroup);
  add(OCLMS_device, ScopeDevice);
  add(OCLMS_all_svm_devices, ScopeCrossDevice);
  add(OCLMS_sub_group, ScopeSubgroup);
}

template<> inline void
SPRVMap<std::string, SPRVGroupOperationKind>::init() {
  add("reduce", GroupOperationReduce);
  add("scan_inclusive", GroupOperationInclusiveScan);
  add("scan_exclusive", GroupOperationExclusiveScan);
}

template<> inline void
SPRVMap<std::string, SPRVFPRoundingModeKind>::init() {
  add("rte", FPRoundingModeRTE);
  add("rtz", FPRoundingModeRTZ);
  add("rtp", FPRoundingModeRTP);
  add("rtn", FPRoundingModeRTN);
}

template<> inline void
SPRVMap<OclExt::Kind, std::string>::init() {
#define _SPRV_OP(x) add(OclExt::x, #x);
  _SPRV_OP(cl_images)
  _SPRV_OP(cl_doubles)
  _SPRV_OP(cl_khr_int64_base_atomics)
  _SPRV_OP(cl_khr_int64_extended_atomics)
  _SPRV_OP(cl_khr_fp16)
  _SPRV_OP(cl_khr_gl_sharing)
  _SPRV_OP(cl_khr_gl_event)
  _SPRV_OP(cl_khr_d3d10_sharing)
  _SPRV_OP(cl_khr_media_sharing)
  _SPRV_OP(cl_khr_d3d11_sharing)
  _SPRV_OP(cl_khr_global_int32_base_atomics)
  _SPRV_OP(cl_khr_global_int32_extended_atomics)
  _SPRV_OP(cl_khr_local_int32_base_atomics)
  _SPRV_OP(cl_khr_local_int32_extended_atomics)
  _SPRV_OP(cl_khr_byte_addressable_store)
  _SPRV_OP(cl_khr_3d_image_writes)
  _SPRV_OP(cl_khr_gl_msaa_sharing)
  _SPRV_OP(cl_khr_depth_images)
  _SPRV_OP(cl_khr_gl_depth_images)
  _SPRV_OP(cl_khr_subgroups)
  _SPRV_OP(cl_khr_mipmap_image)
  _SPRV_OP(cl_khr_mipmap_image_writes)
  _SPRV_OP(cl_khr_egl_event)
  _SPRV_OP(cl_khr_srgb_image_writes)
#undef _SPRV_OP
}

template<> inline void
SPRVMap<OclExt::Kind, SPRVCapabilityKind>::init() {
  add(OclExt::cl_images, CapabilityImageBasic);
  add(OclExt::cl_doubles, CapabilityFloat64);
  add(OclExt::cl_khr_int64_base_atomics, CapabilityInt64Atomics);
  add(OclExt::cl_khr_int64_extended_atomics, CapabilityInt64Atomics);
  add(OclExt::cl_khr_fp16, CapabilityFloat16);
  add(OclExt::cl_khr_gl_sharing, CapabilityNone);
  add(OclExt::cl_khr_gl_event, CapabilityNone);
  add(OclExt::cl_khr_d3d10_sharing, CapabilityNone);
  add(OclExt::cl_khr_media_sharing, CapabilityNone);
  add(OclExt::cl_khr_d3d11_sharing, CapabilityNone);
  add(OclExt::cl_khr_global_int32_base_atomics, CapabilityNone);
  add(OclExt::cl_khr_global_int32_extended_atomics, CapabilityNone);
  add(OclExt::cl_khr_local_int32_base_atomics, CapabilityNone);
  add(OclExt::cl_khr_local_int32_extended_atomics, CapabilityNone);
  add(OclExt::cl_khr_byte_addressable_store, CapabilityNone);
  add(OclExt::cl_khr_3d_image_writes, CapabilityNone);
  add(OclExt::cl_khr_gl_msaa_sharing, CapabilityNone);
  add(OclExt::cl_khr_depth_images, CapabilityNone);
  add(OclExt::cl_khr_gl_depth_images, CapabilityNone);
  add(OclExt::cl_khr_subgroups, CapabilityGroups);
  add(OclExt::cl_khr_mipmap_image, CapabilityImageMipmap);
  add(OclExt::cl_khr_mipmap_image_writes, CapabilityImageMipmap);
  add(OclExt::cl_khr_egl_event, CapabilityNone);
  add(OclExt::cl_khr_srgb_image_writes, CapabilityImageSRGBWrite);
}

/// Map OpenCL work functions to SPIR-V builtin variables.
template<> inline void
SPRVMap<std::string, SPRVBuiltinVariableKind>::init() {
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
  add("get_local_linear_id", BuiltInWorkgroupLinearId);
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
class SPRVInstruction;
template<> inline void
SPRVMap<std::string, Op, SPRVInstruction>::init() {
#define _SPRV_OP(x,y) add("atom_"#x, OpAtomic##y);
// cl_khr_int64_base_atomics builtins
_SPRV_OP(add, IAdd)
_SPRV_OP(sub, ISub)
_SPRV_OP(xchg, Exchange)
_SPRV_OP(dec, IDecrement)
_SPRV_OP(inc, IIncrement)
_SPRV_OP(cmpxchg, CompareExchange)
// cl_khr_int64_extended_atomics builtins
_SPRV_OP(min, SMin)
_SPRV_OP(max, SMax)
_SPRV_OP(and, And)
_SPRV_OP(or, Or)
_SPRV_OP(xor, Xor)
#undef _SPRV_OP
#define _SPRV_OP(x,y) add("atomic_"#x, Op##y);
// CL 2.0 atomic builtins
_SPRV_OP(flag_test_and_set_explicit, AtomicFlagTestAndSet)
_SPRV_OP(flag_clear_explicit, AtomicFlagClear)
_SPRV_OP(load_explicit, AtomicLoad)
_SPRV_OP(store_explicit, AtomicStore)
_SPRV_OP(exchange_explicit, AtomicExchange)
_SPRV_OP(compare_exchange_strong_explicit, AtomicCompareExchange)
_SPRV_OP(compare_exchange_weak_explicit, AtomicCompareExchangeWeak)
_SPRV_OP(inc, AtomicIIncrement)
_SPRV_OP(dec, AtomicIDecrement)
_SPRV_OP(fetch_add_explicit, AtomicIAdd)
_SPRV_OP(fetch_sub_explicit, AtomicISub)
_SPRV_OP(fetch_umin_explicit, AtomicUMin)
_SPRV_OP(fetch_umax_explicit, AtomicUMax)
_SPRV_OP(fetch_min_explicit, AtomicSMin)
_SPRV_OP(fetch_max_explicit, AtomicSMax)
_SPRV_OP(fetch_and_explicit, AtomicAnd)
_SPRV_OP(fetch_or_explicit, AtomicOr)
_SPRV_OP(fetch_xor_explicit, AtomicXor)
#undef _SPRV_OP
#define _SPRV_OP(x,y) add(#x, Op##y);
_SPRV_OP(dot, Dot)
_SPRV_OP(async_work_group_copy, AsyncGroupCopy)
_SPRV_OP(async_work_group_strided_copy, AsyncGroupCopy)
_SPRV_OP(wait_group_events, WaitGroupEvents)
_SPRV_OP(isequal, FOrdEqual)
_SPRV_OP(isnotequal, FUnordNotEqual)
_SPRV_OP(isgreater, FOrdGreaterThan)
_SPRV_OP(isgreaterequal, FOrdGreaterThanEqual)
_SPRV_OP(isless, FOrdLessThan)
_SPRV_OP(islessequal, FOrdLessThanEqual)
_SPRV_OP(islessgreater, LessOrGreater)
_SPRV_OP(isordered, Ordered)
_SPRV_OP(isunordered, Unordered)
_SPRV_OP(isfinite, IsFinite)
_SPRV_OP(isinf, IsInf)
_SPRV_OP(isnan, IsNan)
_SPRV_OP(isnormal, IsNormal)
_SPRV_OP(signbit, SignBitSet)
_SPRV_OP(any, Any)
_SPRV_OP(all, All)
_SPRV_OP(get_fence, GenericPtrMemSemantics)
// CL 2.0 kernel enqueue builtins
_SPRV_OP(enqueue_marker, EnqueueMarker)
_SPRV_OP(enqueue_kernel, EnqueueKernel)
_SPRV_OP(get_kernel_ndrange_subgroup_count, GetKernelNDrangeSubGroupCount)
_SPRV_OP(get_kernel_ndrange_max_subgroup_count, GetKernelNDrangeMaxSubGroupSize)
_SPRV_OP(get_kernel_work_group_size, GetKernelWorkGroupSize)
_SPRV_OP(get_kernel_preferred_work_group_size_multiple, GetKernelPreferredWorkGroupSizeMultiple)
_SPRV_OP(retain_event, RetainEvent)
_SPRV_OP(release_event, ReleaseEvent)
_SPRV_OP(create_user_event, CreateUserEvent)
_SPRV_OP(is_valid_event, IsValidEvent)
_SPRV_OP(set_user_event_status, SetUserEventStatus)
_SPRV_OP(capture_event_profiling_info, CaptureEventProfilingInfo)
_SPRV_OP(get_default_queue, GetDefaultQueue)
_SPRV_OP(ndrange_1D, BuildNDRange)
_SPRV_OP(ndrange_2D, BuildNDRange)
_SPRV_OP(ndrange_3D, BuildNDRange)
// Generic Address Space Casts
_SPRV_OP(to_global, GenericCastToPtr)
_SPRV_OP(to_local, GenericCastToPtr)
_SPRV_OP(to_private, GenericCastToPtr)
_SPRV_OP(work_group_barrier, ControlBarrier)
// CL 2.0 pipe builtins
_SPRV_OP(read_pipe, ReadPipe)
_SPRV_OP(write_pipe, WritePipe)
_SPRV_OP(reserved_read_pipe, ReservedReadPipe)
_SPRV_OP(reserved_write_pipe, ReservedWritePipe)
_SPRV_OP(reserve_read_pipe, ReserveReadPipePackets)
_SPRV_OP(reserve_write_pipe, ReserveWritePipePackets)
_SPRV_OP(commit_read_pipe, CommitReadPipe)
_SPRV_OP(commit_write_pipe, CommitWritePipe)
_SPRV_OP(is_valid_reserve_id, IsValidReserveId)
_SPRV_OP(group_reserve_read_pipe, GroupReserveReadPipePackets)
_SPRV_OP(group_reserve_write_pipe, GroupReserveWritePipePackets)
_SPRV_OP(group_commit_read_pipe, GroupCommitReadPipe)
_SPRV_OP(group_commit_write_pipe, GroupCommitWritePipe)
_SPRV_OP(get_pipe_num_packets, GetNumPipePackets)
_SPRV_OP(get_pipe_max_packets, GetMaxPipePackets)
// CL 2.0 workgroup builtins
_SPRV_OP(group_all, GroupAll)
_SPRV_OP(group_any, GroupAny)
_SPRV_OP(group_broadcast, GroupBroadcast)
_SPRV_OP(group_iadd, GroupIAdd)
_SPRV_OP(group_fadd, GroupFAdd)
_SPRV_OP(group_fmin, GroupFMin)
_SPRV_OP(group_umin, GroupUMin)
_SPRV_OP(group_smin, GroupSMin)
_SPRV_OP(group_fmax, GroupFMax)
_SPRV_OP(group_umax, GroupUMax)
_SPRV_OP(group_smax, GroupSMax)
// CL image builtins
_SPRV_OP(SampledImage, SampledImage)
_SPRV_OP(ImageSampleExplicitLod, ImageSampleExplicitLod)
_SPRV_OP(read_image, ImageRead)
_SPRV_OP(write_image, ImageWrite)
_SPRV_OP(get_image_channel_data_type, ImageQueryFormat)
_SPRV_OP(get_image_channel_order, ImageQueryOrder)
_SPRV_OP(get_image_num_mip_levels, ImageQueryLevels)
_SPRV_OP(get_image_num_samples, ImageQuerySamples)
#undef _SPRV_OP
}

} // namespace SPRV
