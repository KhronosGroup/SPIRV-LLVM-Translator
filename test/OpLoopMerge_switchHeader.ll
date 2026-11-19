; OpLoopMerge and OpLoopControlINTEL must immediately precede an OpBranch or
; OpBranchConditional, so a loop whose header ends in a switch gets neither,
; and loses its loop control.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s

; RUN: llvm-spirv %t.bc -o %t.intel.spv --spirv-ext=+SPV_INTEL_unstructured_loop_controls
; RUN: spirv-val %t.intel.spv
; RUN: llvm-spirv --to-text %t.intel.spv -o - | FileCheck %s

; CHECK-NOT: LoopMerge
; CHECK-NOT: LoopControlINTEL
; CHECK: Switch
; CHECK-NOT: LoopMerge
; CHECK-NOT: LoopControlINTEL
; CHECK: Switch
; CHECK-NOT: LoopMerge
; CHECK-NOT: LoopControlINTEL

target triple = "spir64"

; The latch ends in a conditional branch.
define spir_kernel void @cond_latch(ptr addrspace(1) %dst, i32 %n) {
entry:
  br label %header
header:
  %i = phi i32 [ 0, %entry ], [ %i.next, %latch ]
  switch i32 %i, label %latch [
    i32 1, label %one
  ]
one:
  store i32 1, ptr addrspace(1) %dst, align 4
  br label %latch
latch:
  %i.next = add i32 %i, 1
  %cmp = icmp slt i32 %i.next, %n
  br i1 %cmp, label %header, label %exit, !llvm.loop !0
exit:
  ret void
}

; The latch ends in an unconditional branch.
define spir_kernel void @uncond_latch(ptr addrspace(1) %dst) {
entry:
  br label %header
header:
  %i = phi i32 [ 0, %entry ], [ %i.next, %latch ]
  switch i32 %i, label %latch [
    i32 8, label %exit
  ]
latch:
  store i32 %i, ptr addrspace(1) %dst, align 4
  %i.next = add i32 %i, 1
  br label %header, !llvm.loop !1
exit:
  ret void
}

!0 = distinct !{!0, !2}
!1 = distinct !{!1, !2}
!2 = !{!"llvm.loop.unroll.disable"}
