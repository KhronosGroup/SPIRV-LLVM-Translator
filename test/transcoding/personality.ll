; Check that an unused personality does not block translation.

; RUN: llvm-spirv %s -spirv-text -o - | FileCheck %s --implicit-check-not=__gxx_personality_v0
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv

; CHECK: Name [[#]] "foo"

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define spir_func void @foo() personality ptr @__gxx_personality_v0 {
  ret void
}

declare i32 @__gxx_personality_v0(...)
