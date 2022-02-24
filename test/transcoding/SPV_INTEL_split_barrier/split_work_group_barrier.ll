;; kernel void test(global uint* dst)
;; {
;;     intel_work_group_barrier_arrive(CLK_LOCAL_MEM_FENCE);
;;     intel_work_group_barrier_wait(CLK_LOCAL_MEM_FENCE);
;;     intel_work_group_barrier_arrive(CLK_GLOBAL_MEM_FENCE);
;;     intel_work_group_barrier_wait(CLK_GLOBAL_MEM_FENCE);
;;     intel_work_group_barrier_arrive(CLK_IMAGE_MEM_FENCE);
;;     intel_work_group_barrier_wait(CLK_IMAGE_MEM_FENCE);
;;
;;     intel_work_group_barrier_arrive(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
;;     intel_work_group_barrier_wait(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
;;     intel_work_group_barrier_arrive(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE | CLK_IMAGE_MEM_FENCE);
;;     intel_work_group_barrier_wait(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE | CLK_IMAGE_MEM_FENCE);
;;
;;     intel_work_group_barrier_arrive(CLK_LOCAL_MEM_FENCE, memory_scope_work_item);
;;     intel_work_group_barrier_wait(CLK_LOCAL_MEM_FENCE, memory_scope_work_item);
;;     intel_work_group_barrier_arrive(CLK_LOCAL_MEM_FENCE, memory_scope_work_group);
;;     intel_work_group_barrier_wait(CLK_LOCAL_MEM_FENCE, memory_scope_work_group);
;;     intel_work_group_barrier_arrive(CLK_LOCAL_MEM_FENCE, memory_scope_device);
;;     intel_work_group_barrier_wait(CLK_LOCAL_MEM_FENCE, memory_scope_device);
;;     intel_work_group_barrier_arrive(CLK_LOCAL_MEM_FENCE, memory_scope_all_svm_devices);
;;     intel_work_group_barrier_wait(CLK_LOCAL_MEM_FENCE, memory_scope_all_svm_devices);
;;     intel_work_group_barrier_arrive(CLK_LOCAL_MEM_FENCE, memory_scope_sub_group);
;;     intel_work_group_barrier_wait(CLK_LOCAL_MEM_FENCE, memory_scope_sub_group);
;;}

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_INTEL_split_barrier
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spv -o %t.rev.bc -r
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; RUN: not llvm-spirv %t.bc 2>&1 | FileCheck %s --check-prefix=CHECK-ERROR
; CHECK-ERROR: RequiresExtension: Feature requires the following SPIR-V extension:
; CHECK-ERROR-NEXT: SPV_INTEL_split_barrier

; ModuleID = 'split_barrier.cl'
source_filename = "split_barrier.cl"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64"

; CHECK-SPIRV: Capability SplitBarrierINTEL
; CHECK-SPIRV: Extension "SPV_INTEL_split_barrier"
; CHECK-SPIRV: Name [[TEST_FUNC:[0-9]+]] "test"
; CHECK-SPIRV: TypeInt [[UINT:[0-9]+]] 32 0
;
; Scopes:
; CHECK-SPIRV-DAG: Constant [[UINT]] [[SCOPE_WORK_GROUP:[0-9]+]] 2
; CHECK-SPIRV-DAG: Constant [[UINT]] [[SCOPE_INVOCATION:[0-9]+]] 4
; CHECK-SPIRV-DAG: Constant [[UINT]] [[SCOPE_DEVICE:[0-9]+]] 1
; CHECK-SPIRV-DAG: Constant [[UINT]] [[SCOPE_CROSS_DEVICE:[0-9]+]] 0
; CHECK-SPIRV-DAG: Constant [[UINT]] [[SCOPE_SUBGROUP:[0-9]+]] 3
;
; Memory Semantics:
; 0x10 SequentiallyConsistent + 0x100 WorkgroupMemory
; CHECK-SPIRV-DAG: Constant [[UINT]] [[LOCAL:[0-9]+]] 272
; 0x10 SequentiallyConsistent + 0x200 CrossWorkgroupMemory
; CHECK-SPIRV-DAG: Constant [[UINT]] [[GLOBAL:[0-9]+]] 528
; 0x10 SequentiallyConsistent + 0x800 ImageMemory
; CHECK-SPIRV-DAG: Constant [[UINT]] [[IMAGE:[0-9]+]] 2064
; 0x10 SequentiallyConsistent + 0x100 WorkgroupMemory + 0x200 CrossWorkgroupMemory
; CHECK-SPIRV-DAG: Constant [[UINT]] [[LOCAL_GLOBAL:[0-9]+]] 784
; 0x10 SequentiallyConsistent + 0x100 WorkgroupMemory + 0x200 CrossWorkgroupMemory + 0x800 ImageMemory
; CHECK-SPIRV-DAG: Constant [[UINT]] [[LOCAL_GLOBAL_IMAGE:[0-9]+]] 2832
;
; CHECK-SPIRV: Function {{[0-9]+}} [[TEST_FUNC]]
; CHECK-SPIRV: ControlBarrierArriveINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierWaitINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierArriveINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[GLOBAL]]
; CHECK-SPIRV: ControlBarrierWaitINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[GLOBAL]]
; CHECK-SPIRV: ControlBarrierArriveINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[IMAGE]]
; CHECK-SPIRV: ControlBarrierWaitINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[IMAGE]]
;
; CHECK-SPIRV: ControlBarrierArriveINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[LOCAL_GLOBAL]]
; CHECK-SPIRV: ControlBarrierWaitINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[LOCAL_GLOBAL]]
; CHECK-SPIRV: ControlBarrierArriveINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[LOCAL_GLOBAL_IMAGE]]
; CHECK-SPIRV: ControlBarrierWaitINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[LOCAL_GLOBAL_IMAGE]]
;
; CHECK-SPIRV: ControlBarrierArriveINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_INVOCATION]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierWaitINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_INVOCATION]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierArriveINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierWaitINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_WORK_GROUP]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierArriveINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_DEVICE]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierWaitINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_DEVICE]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierArriveINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_CROSS_DEVICE]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierWaitINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_CROSS_DEVICE]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierArriveINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_SUBGROUP]] [[LOCAL]]
; CHECK-SPIRV: ControlBarrierWaitINTEL [[SCOPE_WORK_GROUP]] [[SCOPE_SUBGROUP]] [[LOCAL]]

; CHECK-LLVM-LABEL: define spir_kernel void @test
; CHECK-LLVM: call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 1, i32 1)
; CHECK-LLVM: call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 1, i32 1)
; CHECK-LLVM: call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 2, i32 1)
; CHECK-LLVM: call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 2, i32 1)
; CHECK-LLVM: call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 4, i32 1)
; CHECK-LLVM: call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 4, i32 1)
; CHECK-LLVM: call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 3, i32 1)
; CHECK-LLVM: call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 3, i32 1)
; CHECK-LLVM: call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 7, i32 1)
; CHECK-LLVM: call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 7, i32 1)
; CHECK-LLVM: call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 1, i32 0)
; CHECK-LLVM: call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 1, i32 0)
; CHECK-LLVM: call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 1, i32 1)
; CHECK-LLVM: call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 1, i32 1)
; CHECK-LLVM: call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 1, i32 2)
; CHECK-LLVM: call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 1, i32 2)
; CHECK-LLVM: call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 1, i32 3)
; CHECK-LLVM: call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 1, i32 3)
; CHECK-LLVM: call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 1, i32 4)
; CHECK-LLVM: call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 1, i32 4)

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @test(i32 addrspace(1)* nocapture noundef readnone align 4 %0) local_unnamed_addr #0 !kernel_arg_addr_space !4 !kernel_arg_access_qual !5 !kernel_arg_type !6 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 {
  tail call spir_func void @_Z31intel_work_group_barrier_arrivej(i32 noundef 1) #2
  tail call spir_func void @_Z29intel_work_group_barrier_waitj(i32 noundef 1) #2
  tail call spir_func void @_Z31intel_work_group_barrier_arrivej(i32 noundef 2) #2
  tail call spir_func void @_Z29intel_work_group_barrier_waitj(i32 noundef 2) #2
  tail call spir_func void @_Z31intel_work_group_barrier_arrivej(i32 noundef 4) #2
  tail call spir_func void @_Z29intel_work_group_barrier_waitj(i32 noundef 4) #2
  tail call spir_func void @_Z31intel_work_group_barrier_arrivej(i32 noundef 3) #2
  tail call spir_func void @_Z29intel_work_group_barrier_waitj(i32 noundef 3) #2
  tail call spir_func void @_Z31intel_work_group_barrier_arrivej(i32 noundef 7) #2
  tail call spir_func void @_Z29intel_work_group_barrier_waitj(i32 noundef 7) #2
  tail call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 noundef 1, i32 noundef 0) #2
  tail call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 noundef 1, i32 noundef 0) #2
  tail call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 noundef 1, i32 noundef 1) #2
  tail call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 noundef 1, i32 noundef 1) #2
  tail call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 noundef 1, i32 noundef 2) #2
  tail call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 noundef 1, i32 noundef 2) #2
  tail call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 noundef 1, i32 noundef 3) #2
  tail call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 noundef 1, i32 noundef 3) #2
  tail call spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 noundef 1, i32 noundef 4) #2
  tail call spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 noundef 1, i32 noundef 4) #2
  ret void
}

; Function Attrs: convergent
declare dso_local spir_func void @_Z31intel_work_group_barrier_arrivej(i32 noundef) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func void @_Z29intel_work_group_barrier_waitj(i32 noundef) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func void @_Z31intel_work_group_barrier_arrivej12memory_scope(i32 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func void @_Z29intel_work_group_barrier_waitj12memory_scope(i32 noundef, i32 noundef) local_unnamed_addr #1

attributes #0 = { convergent norecurse nounwind "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #1 = { convergent "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { convergent nounwind }

!llvm.module.flags = !{!0, !1}
!opencl.ocl.version = !{!2}
!opencl.spir.version = !{!2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{i32 2, i32 0}
!3 = !{!"clang version 15.0.0 (https://github.com/llvm/llvm-project 861386dbd6ff0d91636b7c674c2abb2eccd9d3f2)"}
!4 = !{i32 1}
!5 = !{!"none"}
!6 = !{!"uint*"}
!7 = !{!""}
