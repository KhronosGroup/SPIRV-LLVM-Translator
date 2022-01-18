; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_INTEL_function_pointers
; RUN: llvm-spirv -r %t.spv -o %t.bc --override-program-address-space=3
; RUN: llvm-dis %t.bc -o %t.ll
; RUN: FileCheck %s --input-file %t.ll

; ModuleID = 'tmp_back.bc'
; CHECK: target datalayout
; CHECK-SAME: P3

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: @test
; CHECK-SAME: addrspace(3)
; CHECK: %p
; CHECK-SAME: addrspace(3)

define spir_kernel void @test() {
entry:
  %p = alloca void () *, align 8
  store void () * @test, void () ** %p, align 8
  ret void
}

