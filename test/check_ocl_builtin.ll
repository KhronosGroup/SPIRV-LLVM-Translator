; Test that user defined/declared functions are not wrongly identified as OpenCL builtins.

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: Name [[fname1:[0-9]+]] "_Z27atomic_fetch_and_add_uint32Pii"
; CHECK-SPIRV-DAG: Name [[fname2:[0-9]+]] "_Z27atomic_fetch_and_sub_uint32Pii"
; CHECK-SPIRV-DAG: FunctionCall {{[0-9]+}} {{[0-9]+}} [[fname2]] {{[0-9]+}} {{[0-9]+}}
; CHECK-SPIRV-DAG: FunctionCall {{[0-9]+}} {{[0-9]+}} [[fname1]] {{[0-9]+}} {{[0-9]+}}

; CHECK-LLVM: call spir_func i32 @_Z27atomic_fetch_and_sub_uint32Pii
; CHECK-LLVM-DAG: call spir_func i32 @_Z27atomic_fetch_and_add_uint32Pii

; Function Attrs: mustprogress norecurse nounwind
define weak_odr dso_local spir_kernel void @_ZTSN4test_ocl_builtin(ptr addrspace(4) noundef %arrayidx.i311) {
entry:
     %call.i312 = call spir_func noundef i32 @_Z27atomic_fetch_and_sub_uint32Pii(ptr addrspace(4) noundef %arrayidx.i311, i32 noundef 1)
     %call.i313 = call spir_func noundef i32 @_Z27atomic_fetch_and_add_uint32Pii(ptr addrspace(4) noundef %arrayidx.i311, i32 noundef 1)
     ret void
}

; Function Attrs: convergent inlinehint mustprogress norecurse nounwind
define linkonce_odr dso_local spir_func noundef i32 @_Z27atomic_fetch_and_sub_uint32Pii(ptr addrspace(4) noundef %p, i32 noundef %x) {
entry:
  %call.i.i.i.i.i.i = tail call spir_func noundef ptr addrspace(1) @_Z41__spirv_GenericCastToPtrExplicit_ToGlobalPvi(ptr addrspace(4) noundef %p, i32 noundef 5)
  %0 = addrspacecast ptr addrspace(1) %call.i.i.i.i.i.i to ptr addrspace(4)
  call spir_func void @__itt_offload_atomic_op_start(ptr addrspace(4) %0, i32 2, i32 0)
  %call3.i.i = tail call spir_func noundef i32 @_Z18__spirv_AtomicISubPU3AS1iN5__spv5Scope4FlagENS1_19MemorySemanticsMask4FlagEi(ptr addrspace(1) noundef %call.i.i.i.i.i.i, i32 noundef 1, i32 noundef 896, i32 noundef %x)
  %1 = addrspacecast ptr addrspace(1) %call.i.i.i.i.i.i to ptr addrspace(4)
  call spir_func void @__itt_offload_atomic_op_finish(ptr addrspace(4) %1, i32 2, i32 0)
  ret i32 %call3.i.i
}

declare dso_local spir_func noundef i32 @_Z27atomic_fetch_and_add_uint32Pii(ptr addrspace(4) noundef %p, i32 noundef %x)

declare dso_local spir_func noundef ptr addrspace(1) @_Z41__spirv_GenericCastToPtrExplicit_ToGlobalPvi(ptr addrspace(4) noundef, i32 noundef)

declare dso_local spir_func void @__itt_offload_atomic_op_start(ptr addrspace(4) noundef %object, i32 noundef %op_type, i32 noundef %mem_order)

declare dso_local spir_func noundef i32 @_Z18__spirv_AtomicISubPU3AS1iN5__spv5Scope4FlagENS1_19MemorySemanticsMask4FlagEi(ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef)

declare dso_local spir_func void @__itt_offload_atomic_op_finish(ptr addrspace(4) noundef %object, i32 noundef %op_type, i32 noundef %mem_order)

!opencl.spir.version = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!spirv.Source = !{!1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1}

!0 = !{i32 1, i32 2}
!1 = !{i32 4, i32 100000}
