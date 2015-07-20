//===- LLVMSPRVInternal.h –  SPIR-V internal header file --------*- C++ -*-===//
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

#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/SPIRV.h"

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
SPRVMap<unsigned, SPRVOpCode>::init() {
#define _SPRV_OP(x,y) add(Instruction::x, SPRVOC_Op##y);
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
typedef SPRVMap<unsigned, SPRVOpCode> OpCodeMap;

template<> inline void
SPRVMap<CmpInst::Predicate, SPRVOpCode>::init() {
#define _SPRV_OP(x,y) add(CmpInst::x, SPRVOC_Op##y);
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
typedef SPRVMap<CmpInst::Predicate, SPRVOpCode> CmpMap;

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

enum SPIRMemFenceFlagKind {
#define _SPRV_OP(x,y) SPIRMFF_##x = y,
_SPRV_OP(Local, 1)
_SPRV_OP(Global, 2)
_SPRV_OP(Image, 4)
#undef _SPRV_OP
};

enum SPIRMemScopeKind {
  SPIRMS_work_item,
  SPIRMS_work_group,
  SPIRMS_device,
  SPIRMS_all_svm_devices,
  SPIRMS_sub_group,
  SPIRMS_Count,
};

template<> inline void
SPRVMap<SPIRAddressSpace, SPRVStorageClassKind>::init() {
#define _SPRV_OP(x,y) add(SPIRAS_##x, SPRVSC_##y);
    _SPRV_OP(Private, Private)
    _SPRV_OP(Global, WorkgroupGlobal)
    _SPRV_OP(Constant, UniformConstant)
    _SPRV_OP(Local, WorkgroupLocal)
    _SPRV_OP(Generic, Generic)
#undef _SPRV_OP
}
typedef SPRVMap<SPIRAddressSpace, SPRVStorageClassKind> SPIRSPRVAddrSpaceMap;

// Maps OCL builtin function to SPIRV builtin variable.
template<> inline void
SPRVMap<std::string, SPRVAccessQualifierKind>::init() {
#define _SPRV_OP(x,y) add(#x, SPRVAC_##y);
    _SPRV_OP(read_only, ReadOnly)
    _SPRV_OP(write_only, WriteOnly)
    _SPRV_OP(read_write, ReadWrite)
#undef _SPRV_OP
}
typedef SPRVMap<std::string, SPRVAccessQualifierKind> SPIRSPRVAccessQualifierMap;

template<> inline void
SPRVMap<std::string, SPRVOpCode>::init() {
#define _SPRV_OP(x,y) add(#x, SPRVOC_OpType##y);
    _SPRV_OP(opencl.event_t, Event)
    _SPRV_OP(opencl.pipe_t, Pipe)
    _SPRV_OP(opencl.clk_event_t, DeviceEvent)
    _SPRV_OP(opencl.reserve_id_t, ReserveId)
    _SPRV_OP(opencl.queue_t, Queue)
#undef _SPRV_OP
}
typedef SPRVMap<std::string, SPRVOpCode> BuiltinOpaqueGenericTypeOpCodeMap;

template<> inline void
SPRVMap<std::string, SPRVBuiltinVariableKind>::init() {
#define _SPRV_OP(x,y) add(#x, SPRVBI_##y);
_SPRV_OP(get_work_dim, WorkDim)
_SPRV_OP(get_global_size, GlobalSize)
_SPRV_OP(get_global_id, GlobalInvocationId)
_SPRV_OP(get_global_offset, GlobalOffset)
_SPRV_OP(get_local_size, WorkgroupSize)
_SPRV_OP(get_enqueued_local_size, EnqueuedWorkgroupSize)
_SPRV_OP(get_local_id, LocalInvocationId)
_SPRV_OP(get_num_groups, NumWorkgroups)
_SPRV_OP(get_group_id, WorkgroupId)
_SPRV_OP(get_global_linear_id, GlobalLinearId)
_SPRV_OP(get_local_linear_id, WorkgroupLinearId)
_SPRV_OP(get_sub_group_size, SubgroupSize)
_SPRV_OP(get_max_sub_group_size, SubgroupMaxSize)
_SPRV_OP(get_num_sub_groups, NumSubgroups)
_SPRV_OP(get_enqueued_num_sub_groups, NumEnqueuedSubgroups)
_SPRV_OP(get_sub_group_id, SubgroupId)
_SPRV_OP(get_sub_group_local_id, SubgroupLocalInvocationId)
#undef _SPRV_OP
}

typedef SPRVMap<std::string, SPRVBuiltinVariableKind> SPIRSPRVBuiltinVariableMap;

// Maps uniqued OCL builtin function name to SPIRV instruction.
// A uniqued OCL builtin function name may be different from the real
// OCL builtin function name. e.g. instead of atomic_min, atomic_umin
// is used for atomic_min with unsigned integer parameter.
// work_group_ and sub_group_ functions are unified as group_ functions
// except work_group_barrier.
class SPRVInstruction;
template<> inline void
SPRVMap<std::string, SPRVOpCode, SPRVInstruction>::init() {
#define _SPRV_OP(x,y) add("atom_"#x, SPRVOC_OpAtomic##y);
// cl_khr_int64_base_atomics builtins
_SPRV_OP(add, IAdd)
_SPRV_OP(sub, ISub)
_SPRV_OP(xchg, Exchange)
_SPRV_OP(dec, IDecrement)
_SPRV_OP(inc, IIncrement)
_SPRV_OP(cmpxchg, CompareExchange)
// cl_khr_int64_extended_atomics builtins
_SPRV_OP(min, IMin)
_SPRV_OP(max, IMax)
_SPRV_OP(and, And)
_SPRV_OP(or, Or)
_SPRV_OP(xor, Xor)
#undef _SPRV_OP
#define _SPRV_OP(x,y) add("atomic_"#x, SPRVOC_OpAtomic##y);
// CL 2.0 atomic builtins
_SPRV_OP(init, Init)
_SPRV_OP(load, Load)
_SPRV_OP(store, Store)
_SPRV_OP(xchg, Exchange)
_SPRV_OP(cmpxchg, CompareExchange)
_SPRV_OP(inc, IIncrement)
_SPRV_OP(dec, IDecrement)
_SPRV_OP(add, IAdd)
_SPRV_OP(sub, ISub)
_SPRV_OP(umin, UMin)
_SPRV_OP(umax, UMax)
_SPRV_OP(min, IMin)
_SPRV_OP(max, IMax)
_SPRV_OP(and, And)
_SPRV_OP(or, Or)
_SPRV_OP(xor, Xor)
#undef _SPRV_OP
#define _SPRV_OP(x,y) add(#x, SPRVOC_Op##y);
_SPRV_OP(dot, Dot)
_SPRV_OP(async_work_group_copy, AsyncGroupCopy)
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
#undef _SPRV_OP
}
typedef SPRVMap<std::string, SPRVOpCode, SPRVInstruction>
  SPIRSPRVBuiltinInstMap;

template<> inline void
SPRVMap<GlobalValue::LinkageTypes, SPRVLinkageTypeKind>::init() {
#define _SPRV_OP(x,y) add(GlobalValue::x, SPRVLT_##y);
_SPRV_OP(ExternalLinkage, Export)
_SPRV_OP(AvailableExternallyLinkage, Import)
_SPRV_OP(PrivateLinkage, Count)
_SPRV_OP(LinkOnceODRLinkage, Count)
_SPRV_OP(InternalLinkage, Count)
#undef _SPRV_OP
}
typedef SPRVMap<GlobalValue::LinkageTypes, SPRVLinkageTypeKind>
  SPIRSPRVLinkageTypeMap;

template<> inline void
SPRVMap<Attribute::AttrKind, SPRVFuncParamAttrKind>::init() {
#define _SPRV_OP(x,y) add(Attribute::x, SPRVFPA_##y);
_SPRV_OP(ZExt, Zext)
_SPRV_OP(SExt, Sext)
_SPRV_OP(ByVal, ByVal)
_SPRV_OP(StructRet, Sret)
_SPRV_OP(NoAlias, NoAlias)
_SPRV_OP(NoCapture, NoCapture)
#undef _SPRV_OP
}
typedef SPRVMap<Attribute::AttrKind, SPRVFuncParamAttrKind>
  SPIRSPRVFuncParamAttrMap;

template<> inline void
SPRVMap<Attribute::AttrKind, SPRVFunctionControlMaskKind>::init() {
#define _SPRV_OP(x,y) add(Attribute::x, SPRVFCM_##y);
_SPRV_OP(ReadNone, Pure)
_SPRV_OP(ReadOnly, Const)
_SPRV_OP(AlwaysInline, Inline)
_SPRV_OP(NoInline, NoInline)
#undef _SPRV_OP
}
typedef SPRVMap<Attribute::AttrKind, SPRVFunctionControlMaskKind>
  SPIRSPRVFuncCtlMaskMap;

template<> inline void
SPRVMap<SPIRMemFenceFlagKind, SPRVMemorySemanticsMaskKind>::init() {
#define _SPRV_OP(x,y) add(SPIRMFF_##x, SPRVMSM_##y);
_SPRV_OP(Local, WorkgroupLocalMemory)
_SPRV_OP(Global, WorkgroupGlobalMemory)
_SPRV_OP(Image, ImageMemory)
#undef _SPRV_OP
}
typedef SPRVMap<SPIRMemFenceFlagKind, SPRVMemorySemanticsMaskKind>
  SPIRSPRVMemFenceFlagMap;

template<> inline void
SPRVMap<SPIRMemScopeKind, SPRVMemoryScopeKind>::init() {
#define _SPRV_OP(x,y) add(SPIRMS_##x, SPRVMS_##y);
  _SPRV_OP(work_item, Invocation)
  _SPRV_OP(work_group, Workgroup)
  _SPRV_OP(device, Device)
  _SPRV_OP(all_svm_devices, CrossDevice)
  _SPRV_OP(sub_group, Subgroup)
#undef _SPRV_OP
}
typedef SPRVMap<SPIRMemScopeKind, SPRVMemoryScopeKind>
  SPIRSPRVMemScopeMap;

template<> inline void
SPRVMap<std::string, SPRVTypeSamplerDescriptor>::init() {
#define _SPRV_OP(x,...) {SPRVTypeSamplerDescriptor S(__VA_ARGS__); \
  add("opencl."#x, S);}
_SPRV_OP(image1d_t,                  0, 1, 0, 0, 0)
_SPRV_OP(image1d_buffer_t,           5, 1, 0, 0, 0)
_SPRV_OP(image1d_array_t,            0, 1, 1, 0, 0)
_SPRV_OP(image2d_t,                  1, 1, 0, 0, 0)
_SPRV_OP(image2d_array_t,            1, 1, 1, 0, 0)
_SPRV_OP(image2d_depth_t,            1, 1, 0, 1, 0)
_SPRV_OP(image2d_array_depth_t,      1, 1, 1, 1, 0)
_SPRV_OP(image2d_msaa_t,             1, 1, 0, 0, 1)
_SPRV_OP(image2d_array_msaa_t,       1, 1, 1, 0, 1)
_SPRV_OP(image2d_msaa_depth_t,       1, 1, 0, 1, 1)
_SPRV_OP(image2d_array_msaa_depth_t, 1, 1, 1, 1, 1)
_SPRV_OP(image3d_t,                  2, 1, 0, 0, 0)
_SPRV_OP(sampler_t,                  0, 2, 0, 0, 0)
#undef _SPRV_OP
}
typedef SPRVMap<std::string, SPRVTypeSamplerDescriptor>
  SPIRSPRVImageSamplerTypeMap;

template<> inline void
SPRVMap<std::string, SPRVFPRoundingModeKind>::init() {
#define _SPRV_OP(x,y) add("rt"#x, SPRVFRM_RT##y);
_SPRV_OP(e, E)
_SPRV_OP(z, Z)
_SPRV_OP(p, P)
_SPRV_OP(n, N)
#undef _SPRV_OP
}
typedef SPRVMap<std::string, SPRVFPRoundingModeKind>
  SPIRSPRVFPRoundingModeMap;

namespace kLLVMTypeName {
  const static char *StructPrefix = "struct.";
}

#define SPRV_BUILTIN_PREFIX                 "__spirv_"
#define SPRV_BUILTIN_POSTFIX                "__"
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
#define SPIR_TYPE_NAME_SAMPLER_T            "opencl.sampler_t"
#define SPIR_TYPE_NAME_EVENT_T              "opencl.event_t"
#define SPIR_TYPE_NAME_CLK_EVENT_T          "opencl.clk_event_t"
#define SPIR_TYPE_NAME_PIPE_T               "opencl.pipe_t"
#define SPIR_TYPE_NAME_PREFIX_IMAGE_T       "opencl.image"
#define SPIR_TYPE_NAME_BLOCK_T              "opencl.block"
#define SPIR_TYPE_NAME_PREFIX               "opencl."
#define SPIR_TYPE_NAME_DELIMITER            '.'
#define SPIR_INTRINSIC_BLOCK_BIND           "spir_block_bind"
#define SPIR_INTRINSIC_GET_BLOCK_INVOKE     "spir_get_block_invoke"
#define SPIR_INTRINSIC_GET_BLOCK_CONTEXT    "spir_get_block_context"
#define SPIR_TEMP_NAME_PREFIX_BLOCK         "block"
#define SPIR_TEMP_NAME_PREFIX_CALL          "call"

#define OCL_MANGLED_TYPE_NAME_SAMPLER       "ocl_sampler"

namespace kOCLBuiltinName {
  const static char *Barrier            = "barrier";
  const static char *EnqueueKernel      = "enqueue_kernel";
  const static char *GetFence           = "get_fence";
  const static char *NDRangePrefix      = "ndrange_";
  const static char *ToGlobal           = "to_global";
  const static char *ToLocal            = "to_local";
  const static char *ToPrivate          = "to_private";
  const static char *ReadImage          = "read_image";
  const static char *ReadPipe           = "read_pipe";
  const static char *WriteImage         = "write_image";
  const static char *WorkGroupBarrier   = "work_group_barrier";
  const static char *WritePipe          = "write_pipe";
  const static char *WorkGroupPrefix    = "work_group_";
  const static char *SubGroupPrefix     = "sub_group_";
  const static char *WorkPrefix         = "work_";
  const static char *SubPrefix          = "sub_";
}

namespace kSPRVFuncName {
  const static char *ReservedPrefix     = "reserved_";
  const static char *GroupPrefix        = "group_";
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

/// \returns a vector of types for a collection of values.
template<class T>
std::vector<Type *>
getTypes(T V) {
  std::vector<Type *> Tys;
  for (auto &I:V)
    Tys.push_back(I->getType());

  return Tys;
}

void removeFnAttr(LLVMContext *Context, CallInst *Call,
    Attribute::AttrKind Attr);
void addFnAttr(LLVMContext *Context, CallInst *Call,
    Attribute::AttrKind Attr);
void saveLLVMModule(Module *M, const std::string &OutputFile);
std::string mapSPRVTypeToOpenCLType(SPRVType* Ty, bool Signed);
std::string mapLLVMTypeToOpenCLType(Type* Ty, bool Signed);

PointerType *getOrCreateOpaquePtrType(Module *M, const std::string &Name,
    unsigned AddrSpace = SPIRAS_Global);
void getFunctionTypeParameterTypes(llvm::FunctionType* FT,
    std::vector<Type*>& ArgTys);
Function *getOrCreateFunction(Module *M, Type *RetTy,
    ArrayRef<Type *> ArgTypes, StringRef Name, bool Mangle = false,
    AttributeSet *Attrs = nullptr, bool takeName = true);
std::vector<Value *> getArguments(CallInst* CI);
bool isPointerToOpaqueStructType(llvm::Type* Ty);
bool isPointerToOpaqueStructType(llvm::Type* Ty, const std::string &Name);

std::string decorateSPRVFunction(const std::string &S);
std::string undecorateSPRVFunction(const std::string &S);
bool isSPRVFunction(const Function *F, std::string *UndecName = nullptr);

/// \param Name LLVM function name
/// \param OpenCLVer version of OpenCL source file. Suppotred values are 12, 20
/// and 21.
/// \param DemangledName demanged name of the OpenCL built-in function
/// \returns true if Name is the name of the OpenCL built-in function,
/// false for other functions
bool oclIsBuiltin(const StringRef& Name, unsigned SrcLangVer = 12,
    std::string* DemangledName = nullptr);

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
    bool Mangle = false, AttributeSet *Attrs = nullptr, bool takeName = true);

/// Mutate function by change the arguments.
/// \param ArgMutate mutates the function arguments.
void mutateFunction(Function *F,
    std::function<std::string (CallInst *, std::vector<Value *> &)>ArgMutate,
    bool Mangle = false, AttributeSet *Attrs = nullptr, bool takeName = true);

/// Add a call instruction at \p Pos.
CallInst *addCallInst(Module *M, StringRef FuncName, Type *RetTy,
    ArrayRef<Value *> Args, AttributeSet *Attrs, Instruction *Pos,
    bool Mangle = false, StringRef InstName = SPIR_TEMP_NAME_PREFIX_CALL,
    bool TakeFuncName = true);

/// Add a call of spir_block_bind function.
CallInst *
addBlockBind(Module *M, Function *InvokeFunc, Value *BlkCtx, Value *CtxLen,
    Value *CtxAlign, Instruction *InsPos,
    StringRef InstName = SPIR_TEMP_NAME_PREFIX_BLOCK);

/// Get a 64 bit integer constant.
ConstantInt *getInt64(Module *M, int64_t value);

/// Get a 32 bit integer constant.
ConstantInt *getInt32(Module *M, int value);


void mangle(SPRVExtInstSetKind BuiltinSet, const std::string &UnmangledName,
    ArrayRef<Type*> ArgTypes, std::string &MangledName);

SPIRAddressSpace getOCLOpaqueTypeAddrSpace(SPRVOpCode OpCode);

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

}
namespace llvm {

void initializeRegularizeOCL20Pass(PassRegistry&);

ModulePass *createRegularizeOCL20();

}
#endif
