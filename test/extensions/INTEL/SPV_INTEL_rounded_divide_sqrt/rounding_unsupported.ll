; Verifies that FPRoundingMode is NOT emitted for instructions other than
; fdiv and sqrt, and that neither RoundedDivideSqrtINTEL capability nor the
; SPV_INTEL_rounded_divide_sqrt extension is generated as a result.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_INTEL_rounded_divide_sqrt,+SPV_KHR_bfloat16,+SPV_INTEL_bfloat16_arithmetic
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck %s --input-file %t.spt --check-prefix=CHECK-SPIRV

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-SPIRV-NOT: Capability RoundedDivideSqrtINTEL
; CHECK-SPIRV-NOT: Extension "SPV_INTEL_rounded_divide_sqrt"
; CHECK-SPIRV-NOT: FPRoundingMode

; llvm.fpbuiltin.fmul with an explicit FPRoundingMode spirv.Decorations node
; should not produce an FPRoundingMode decoration.
define spir_kernel void @test_fmul_fpbuiltin(float %a, float %b) {
entry:
  %r = call float @llvm.fpbuiltin.fmul.f32(float %a, float %b), !spirv.Decorations !0
  ret void
}

; A plain fsub instruction with an FPRoundingMode spirv.Decorations node
; should likewise not produce an FPRoundingMode decoration.
define spir_kernel void @test_fsub_regular(float %a, float %b) {
entry:
  %r = fsub float %a, %b, !spirv.Decorations !0
  ret void
}

; fdiv on a non-IEEE-754 type (bfloat16) with an FPRoundingMode spirv.Decorations
; node should not produce an FPRoundingMode decoration.
define spir_kernel void @test_fdiv_bfloat16(bfloat %a, bfloat %b) {
entry:
  %r = fdiv bfloat %a, %b, !spirv.Decorations !0
  ret void
}

; TODO: need to also test llvm.experimental.constrained.* intrinsics other than fdiv,
; once we prevent these intrinsics having FPRoundingMode decorated (since they violate the spec)

declare float @llvm.fpbuiltin.fmul.f32(float, float)

!0 = !{!{i32 39, i32 0}}
