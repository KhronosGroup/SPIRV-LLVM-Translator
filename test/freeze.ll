;; Test to check that freeze instruction does not cause a crash
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o - -spirv-text | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define spir_kernel void @testfunction(i32 %val) {
   %1 = freeze i32 %val
   ret void
}

; Check there is an entrypoint to ensure llvm-spirv did not crash
; CHECK-SPIRV: EntryPoint 6 [[#]] "testfunction"
