; Check that an SPV-IR round trip does not duplicate FPRoundingMode.

; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv -r --spirv-target-env=SPV-IR %t.spv -o %t.rev.bc
; RUN: llvm-spirv %t.rev.bc -o %t.rt.spv
; RUN: llvm-spirv --to-text %t.rt.spv -o - | FileCheck %s --implicit-check-not=FPRoundingMode
; RUN: spirv-val %t.rt.spv

; CHECK: Decorate [[#]] FPRoundingMode 1

target triple = "spir64-unknown-unknown"

define spir_func float @f(double %x) strictfp {
  %r = call float @llvm.experimental.constrained.fptrunc.f32.f64(double %x, metadata !"round.towardzero", metadata !"fpexcept.strict")
  ret float %r
}

declare float @llvm.experimental.constrained.fptrunc.f32.f64(double, metadata, metadata)
