; Check that an SPV-IR round trip does not duplicate postfix decorations.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r --spirv-target-env=SPV-IR %t.spv -o %t.rev.bc
; RUN: llvm-spirv %t.rev.bc -spirv-text -o - | FileCheck %s --implicit-check-not=SaturatedConversion --implicit-check-not=FPRoundingMode
; RUN: llvm-spirv %t.rev.bc -o %t.rt.spv
; RUN: spirv-val %t.rt.spv

; CHECK: Decorate [[#F:]] FPRoundingMode 1
; CHECK: Decorate [[#G:]] SaturatedConversion
; CHECK: Decorate [[#G]] FPRoundingMode 0
; CHECK: FConvert [[#]] [[#F]]
; CHECK: ConvertFToS [[#]] [[#G]]

target triple = "spir64-unknown-unknown"

define spir_func float @f(double %x) {
  %r = call spir_func float @_Z27__spirv_FConvert_Rfloat_rtzd(double %x)
  ret float %r
}

define spir_func i32 @g(float %x) {
  %r = call spir_func i32 @_Z32__spirv_ConvertFToS_Rint_sat_rtef(float %x)
  ret i32 %r
}

declare spir_func float @_Z27__spirv_FConvert_Rfloat_rtzd(double)
declare spir_func i32 @_Z32__spirv_ConvertFToS_Rint_sat_rtef(float)
