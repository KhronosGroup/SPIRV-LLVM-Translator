; REQUIRES: spirv-dis
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: spirv-dis %t.spv | FileCheck %s

; CHECK: %entry = OpLabel
; CHECK: OpBranchConditional %[[NULL:[0-9]+]] %L815 %L815
; CHECK: %L815 = OpLabel
; CHECK: %v = OpPhi %ulong %ulong_0 %entry

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir64-unknown-unknown"

define spir_kernel void @f() {
entry:
  br i1 undef, label %L815, label %L815

L815:                                             ; preds = %entry, %entry
  %v = phi i64 [ 0, %entry ], [ 0, %entry ]
  ret void
}
