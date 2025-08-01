; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define void @test_switch_with_unreachable_block(i1 %a) {
  %value = zext i1 %a to i32
; CHECK:      Switch [[#]] [[#UNREACHABLE:]] 0 [[#REACHABLE:]] 1 [[#REACHABLE:]]
  switch i32 %value, label %unreachable [
    i32 0, label %reachable
    i32 1, label %reachable
  ]

; CHECK: Label [[#REACHABLE]]
reachable:
; CHECK: Return
  ret void

; CHECK: Label [[#UNREACHABLE]]
; CHECK: Unreachable
unreachable:
  unreachable
}
