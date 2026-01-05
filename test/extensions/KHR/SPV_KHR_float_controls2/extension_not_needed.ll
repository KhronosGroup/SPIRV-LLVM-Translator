; RUN: llvm-spirv --spirv-ext=+SPV_KHR_float_controls2 -spirv-text %s -o - | FileCheck %s --check-prefix=SPIRV
; RUN: llvm-spirv --spirv-ext=+SPV_KHR_float_controls2 %s -o %t.spv
; RUN: spirv-val %t.spv

; Do not add extension if no floating-point type is used in this module.

; SPIRV-NOT: Capability FloatControls2
; SPIRV-NOT: Extension "SPV_KHR_float_controls2"
; SPIRV-NOT: ExecutionModeId {{.*}} 6028

target triple = "spirv-unknown-unknown"

define spir_kernel void @foo() {
entry:
  ret void
}
