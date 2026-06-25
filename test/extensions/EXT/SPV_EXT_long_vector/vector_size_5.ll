; RUN: llvm-spirv %s --spirv-ext=+SPV_EXT_long_vector -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s

; CHECK-DAG: Capability LongVectorEXT
; CHECK-DAG: Extension "SPV_EXT_long_vector"
; CHECK-DAG: TypeFloat [[#F32:]] 32
; CHECK-DAG: TypeVector [[#]] [[#F32]] 5

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func void @test_vec5(<5 x float> %v) {
entry:
  ret void
}
