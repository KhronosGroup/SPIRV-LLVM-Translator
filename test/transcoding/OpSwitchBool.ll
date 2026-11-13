; Check that a switch on an i1 is lowered to a conditional branch, since
; OpSwitch cannot take an OpTypeBool selector.

; RUN: llvm-spirv %s -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-NOT: Switch
; CHECK-SPIRV: TypeBool [[#BOOL:]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; The default is also a case target, so the phi loses one of its two incoming
; values from the entry block.
; CHECK-SPIRV: FunctionParameter [[#BOOL]] [[#C1:]]
; CHECK-SPIRV: BranchConditional [[#C1]] [[#]] [[#]]
; CHECK-LLVM-LABEL: define spir_kernel void @both_cases
; CHECK-LLVM: br i1 %c, label %true, label %false
; CHECK-LLVM: phi i32 [ 1, %false ], [ 2, %entry ]
define spir_kernel void @both_cases(ptr addrspace(1) %p, i1 %c) {
entry:
  switch i1 %c, label %true [
    i1 false, label %false
    i1 true, label %true
  ]
false:
  br label %true
true:
  %r = phi i32 [ 2, %entry ], [ 2, %entry ], [ 1, %false ]
  store i32 %r, ptr addrspace(1) %p
  ret void
}

; CHECK-SPIRV: FunctionParameter [[#BOOL]] [[#C2:]]
; CHECK-SPIRV: BranchConditional [[#C2]] [[#]] [[#]]
; CHECK-LLVM-LABEL: define spir_kernel void @false_case
; CHECK-LLVM: br i1 %c, label %default, label %false
define spir_kernel void @false_case(ptr addrspace(1) %p, i1 %c) {
entry:
  switch i1 %c, label %default [
    i1 false, label %false
  ]
false:
  store i32 1, ptr addrspace(1) %p
  br label %default
default:
  ret void
}

; The loop control (DontUnroll) on the latch is kept.
; CHECK-SPIRV: FunctionParameter [[#BOOL]] [[#C3:]]
; CHECK-SPIRV: LoopMerge [[#]] [[#]] 2
; CHECK-SPIRV-NEXT: BranchConditional [[#C3]] [[#]] [[#]]
; CHECK-SPIRV-NOT: Switch
define spir_kernel void @loop_latch(ptr addrspace(1) %p, i1 %c) {
entry:
  br label %loop
loop:
  store i32 1, ptr addrspace(1) %p
  switch i1 %c, label %exit [
    i1 true, label %loop
  ], !llvm.loop !0
exit:
  ret void
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
