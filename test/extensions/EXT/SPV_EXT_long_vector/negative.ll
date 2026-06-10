; RUN: llvm-as %s -o %t.bc
; RUN: not llvm-spirv %t.bc 2>&1 | FileCheck %s

; Without SPV_EXT_long_vector, a vector of size 1 cannot be translated.

; CHECK: RequiresExtension: Feature requires the following SPIR-V extension:
; CHECK-NEXT: SPV_EXT_long_vector

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func void @test_no_ext(<1 x float> %v1) {
entry:
  ret void
}
