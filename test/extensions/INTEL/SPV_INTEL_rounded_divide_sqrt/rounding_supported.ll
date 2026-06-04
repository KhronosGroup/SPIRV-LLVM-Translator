; Verifies that FPRoundingMode decorations on OpFDiv and sqrt (OpenCL.std
; extended instruction) trigger the RoundedDivideSqrtINTEL capability and the
; SPV_INTEL_rounded_divide_sqrt extension.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_INTEL_rounded_divide_sqrt
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck %s --input-file %t.spt --check-prefix=CHECK-SPIRV

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-SPIRV: Capability RoundedDivideSqrtINTEL
; CHECK-SPIRV: Extension "SPV_INTEL_rounded_divide_sqrt"

; CHECK-SPIRV-DAG: TypeFloat [[#HALF:]] 16
; CHECK-SPIRV-DAG: TypeFloat [[#FLOAT:]] 32
; CHECK-SPIRV-DAG: TypeFloat [[#DOUBLE:]] 64

; CHECK-SPIRV-DAG: TypeVector [[#HALFV:]] [[#HALF]] 2
; CHECK-SPIRV-DAG: TypeVector [[#FLOATV:]] [[#FLOAT]] 4
; CHECK-SPIRV-DAG: TypeVector [[#DOUBLEV:]] [[#DOUBLE]] 3

; All four rounding modes on the scalar-typed divides.
; CHECK-SPIRV-DAG: Decorate [[#H_RTE:]] FPRoundingMode 0
; CHECK-SPIRV-DAG: Decorate [[#F_RTZ:]] FPRoundingMode 1
; CHECK-SPIRV-DAG: Decorate [[#D_RTP:]] FPRoundingMode 2
; CHECK-SPIRV-DAG: Decorate [[#D_RTN:]] FPRoundingMode 3
; CHECK-SPIRV-DAG: FDiv [[#HALF]] [[#H_RTE]]
; CHECK-SPIRV-DAG: FDiv [[#FLOAT]] [[#F_RTZ]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLE]] [[#D_RTP]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLE]] [[#D_RTN]]
define spir_kernel void @test_fdiv_scalar(half %h0, half %h1, float %f0, float %f1, double %d0, double %d1) {
entry:
  %h_rte = call half @llvm.experimental.constrained.fdiv.f16(half %h0, half %h1, metadata !"round.tonearest", metadata !"fpexcept.strict")
  %f_rtz = call float @llvm.experimental.constrained.fdiv.f32(float %f0, float %f1, metadata !"round.towardzero", metadata !"fpexcept.strict")
  %d_rtp = call double @llvm.experimental.constrained.fdiv.f64(double %d0, double %d1, metadata !"round.upward", metadata !"fpexcept.strict")
  %d_rtn = call double @llvm.experimental.constrained.fdiv.f64(double %d0, double %d1, metadata !"round.downward", metadata !"fpexcept.strict")
  ret void
}

; All four rounding modes on the vector-typed divides.
; CHECK-SPIRV-DAG: Decorate [[#HV_RTE:]] FPRoundingMode 0
; CHECK-SPIRV-DAG: Decorate [[#FV_RTZ:]] FPRoundingMode 1
; CHECK-SPIRV-DAG: Decorate [[#DV_RTP:]] FPRoundingMode 2
; CHECK-SPIRV-DAG: Decorate [[#DV_RTN:]] FPRoundingMode 3
; CHECK-SPIRV-DAG: FDiv [[#HALFV]] [[#HV_RTE]]
; CHECK-SPIRV-DAG: FDiv [[#FLOATV]] [[#FV_RTZ]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLEV]] [[#DV_RTP]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLEV]] [[#DV_RTN]]
define spir_kernel void @test_fdiv_vector(<2 x half> %h0, <2 x half> %h1, <4 x float> %f0, <4 x float> %f1, <3 x double> %d0, <3 x double> %d1) {
entry:
  %h_rte = call <2 x half> @llvm.experimental.constrained.fdiv.v2f16(<2 x half> %h0, <2 x half> %h1, metadata !"round.tonearest", metadata !"fpexcept.strict")
  %f_rtz = call <4 x float> @llvm.experimental.constrained.fdiv.v4f32(<4 x float> %f0, <4 x float> %f1, metadata !"round.towardzero", metadata !"fpexcept.strict")
  %d_rtp = call <3 x double> @llvm.experimental.constrained.fdiv.v3f64(<3 x double> %d0, <3 x double> %d1, metadata !"round.upward", metadata !"fpexcept.strict")
  %d_rtn = call <3 x double> @llvm.experimental.constrained.fdiv.v3f64(<3 x double> %d0, <3 x double> %d1, metadata !"round.downward", metadata !"fpexcept.strict")
  ret void
}

; All four rounding modes on regular fdiv instructions carrying an
; FPRoundingMode (decoration 39) via spirv.Decorations metadata.
; CHECK-SPIRV-DAG: Decorate [[#M_RTE:]] FPRoundingMode 0
; CHECK-SPIRV-DAG: Decorate [[#M_RTZ:]] FPRoundingMode 1
; CHECK-SPIRV-DAG: Decorate [[#M_RTP:]] FPRoundingMode 2
; CHECK-SPIRV-DAG: Decorate [[#M_RTN:]] FPRoundingMode 3
; CHECK-SPIRV-DAG: FDiv [[#HALF]] [[#M_RTE]]
; CHECK-SPIRV-DAG: FDiv [[#FLOAT]] [[#M_RTZ]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLE]] [[#M_RTP]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLE]] [[#M_RTN]]
define spir_kernel void @test_fdiv_metadata(half %h0, half %h1, float %f0, float %f1, double %d0, double %d1) {
entry:
  %h_rte = fdiv half %h0, %h1, !spirv.Decorations !0
  %f_rtz = fdiv float %f0, %f1, !spirv.Decorations !1
  %d_rtp = fdiv double %d0, %d1, !spirv.Decorations !2
  %d_rtn = fdiv double %d0, %d1, !spirv.Decorations !3
  ret void
}

; All four rounding modes on vector-typed fdiv instructions carrying an
; FPRoundingMode (decoration 39) via spirv.Decorations metadata.
; CHECK-SPIRV-DAG: Decorate [[#MV_RTE:]] FPRoundingMode 0
; CHECK-SPIRV-DAG: Decorate [[#MV_RTZ:]] FPRoundingMode 1
; CHECK-SPIRV-DAG: Decorate [[#MV_RTP:]] FPRoundingMode 2
; CHECK-SPIRV-DAG: Decorate [[#MV_RTN:]] FPRoundingMode 3
; CHECK-SPIRV-DAG: FDiv [[#HALFV]] [[#MV_RTE]]
; CHECK-SPIRV-DAG: FDiv [[#FLOATV]] [[#MV_RTZ]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLEV]] [[#MV_RTP]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLEV]] [[#MV_RTN]]
define spir_kernel void @test_fdiv_metadata_vector(<2 x half> %h0, <2 x half> %h1, <4 x float> %f0, <4 x float> %f1, <3 x double> %d0, <3 x double> %d1) {
entry:
  %h_rte = fdiv <2 x half> %h0, %h1, !spirv.Decorations !0
  %f_rtz = fdiv <4 x float> %f0, %f1, !spirv.Decorations !1
  %d_rtp = fdiv <3 x double> %d0, %d1, !spirv.Decorations !2
  %d_rtn = fdiv <3 x double> %d0, %d1, !spirv.Decorations !3
  ret void
}

; All four rounding modes on llvm.fpbuiltin.fdiv intrinsics carrying an
; FPRoundingMode (decoration 39) via spirv.Decorations metadata.
; CHECK-SPIRV-DAG: Decorate [[#B_RTE:]] FPRoundingMode 0
; CHECK-SPIRV-DAG: Decorate [[#B_RTZ:]] FPRoundingMode 1
; CHECK-SPIRV-DAG: Decorate [[#B_RTP:]] FPRoundingMode 2
; CHECK-SPIRV-DAG: Decorate [[#B_RTN:]] FPRoundingMode 3
; CHECK-SPIRV-DAG: FDiv [[#HALF]] [[#B_RTE]]
; CHECK-SPIRV-DAG: FDiv [[#FLOAT]] [[#B_RTZ]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLE]] [[#B_RTP]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLE]] [[#B_RTN]]
define spir_kernel void @test_fdiv_fpbuiltin(half %h0, half %h1, float %f0, float %f1, double %d0, double %d1) {
entry:
  %h_rte = call half @llvm.fpbuiltin.fdiv.f16(half %h0, half %h1), !spirv.Decorations !0
  %f_rtz = call float @llvm.fpbuiltin.fdiv.f32(float %f0, float %f1), !spirv.Decorations !1
  %d_rtp = call double @llvm.fpbuiltin.fdiv.f64(double %d0, double %d1), !spirv.Decorations !2
  %d_rtn = call double @llvm.fpbuiltin.fdiv.f64(double %d0, double %d1), !spirv.Decorations !3
  ret void
}

; All four rounding modes on vector-typed llvm.fpbuiltin.fdiv intrinsics
; carrying an FPRoundingMode (decoration 39) via spirv.Decorations metadata.
; CHECK-SPIRV-DAG: Decorate [[#BV_RTE:]] FPRoundingMode 0
; CHECK-SPIRV-DAG: Decorate [[#BV_RTZ:]] FPRoundingMode 1
; CHECK-SPIRV-DAG: Decorate [[#BV_RTP:]] FPRoundingMode 2
; CHECK-SPIRV-DAG: Decorate [[#BV_RTN:]] FPRoundingMode 3
; CHECK-SPIRV-DAG: FDiv [[#HALFV]] [[#BV_RTE]]
; CHECK-SPIRV-DAG: FDiv [[#FLOATV]] [[#BV_RTZ]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLEV]] [[#BV_RTP]]
; CHECK-SPIRV-DAG: FDiv [[#DOUBLEV]] [[#BV_RTN]]
define spir_kernel void @test_fdiv_fpbuiltin_vector(<2 x half> %h0, <2 x half> %h1, <4 x float> %f0, <4 x float> %f1, <3 x double> %d0, <3 x double> %d1) {
entry:
  %h_rte = call <2 x half> @llvm.fpbuiltin.fdiv.v2f16(<2 x half> %h0, <2 x half> %h1), !spirv.Decorations !0
  %f_rtz = call <4 x float> @llvm.fpbuiltin.fdiv.v4f32(<4 x float> %f0, <4 x float> %f1), !spirv.Decorations !1
  %d_rtp = call <3 x double> @llvm.fpbuiltin.fdiv.v3f64(<3 x double> %d0, <3 x double> %d1), !spirv.Decorations !2
  %d_rtn = call <3 x double> @llvm.fpbuiltin.fdiv.v3f64(<3 x double> %d0, <3 x double> %d1), !spirv.Decorations !3
  ret void
}

; One rounding mode per FP type (covers all four modes across the three types).
; CHECK-SPIRV-DAG: Decorate [[#S_RTE:]] FPRoundingMode 0
; CHECK-SPIRV-DAG: Decorate [[#S_RTZ:]] FPRoundingMode 1
; CHECK-SPIRV-DAG: Decorate [[#S_RTP:]] FPRoundingMode 2
; CHECK-SPIRV-DAG: Decorate [[#S_RTN:]] FPRoundingMode 3
; CHECK-SPIRV-DAG: ExtInst [[#HALF]]   [[#S_RTE]] {{[0-9]+}} sqrt
; CHECK-SPIRV-DAG: ExtInst [[#FLOAT]]  [[#S_RTZ]] {{[0-9]+}} sqrt
; CHECK-SPIRV-DAG: ExtInst [[#DOUBLE]] [[#S_RTP]] {{[0-9]+}} sqrt
; CHECK-SPIRV-DAG: ExtInst [[#DOUBLE]] [[#S_RTN]] {{[0-9]+}} sqrt
define spir_kernel void @test_sqrt_scalar(half %h, float %f, double %d) {
entry:
  %h_rte = call half   @llvm.sqrt.f16(half %h),     !spirv.Decorations !0
  %f_rtz = call float  @llvm.sqrt.f32(float %f),    !spirv.Decorations !1
  %d_rtp = call double @llvm.sqrt.f64(double %d),   !spirv.Decorations !2
  %d_rtn = call double @llvm.sqrt.f64(double %d),   !spirv.Decorations !3
  ret void
}

; CHECK-SPIRV-DAG: Decorate [[#SV_RTE:]] FPRoundingMode 0
; CHECK-SPIRV-DAG: Decorate [[#SV_RTZ:]] FPRoundingMode 1
; CHECK-SPIRV-DAG: Decorate [[#SV_RTP:]] FPRoundingMode 2
; CHECK-SPIRV-DAG: Decorate [[#SV_RTN:]] FPRoundingMode 3
; CHECK-SPIRV-DAG: ExtInst [[#HALFV]]   [[#SV_RTE]] {{[0-9]+}} sqrt
; CHECK-SPIRV-DAG: ExtInst [[#FLOATV]]  [[#SV_RTZ]] {{[0-9]+}} sqrt
; CHECK-SPIRV-DAG: ExtInst [[#DOUBLEV]] [[#SV_RTP]] {{[0-9]+}} sqrt
; CHECK-SPIRV-DAG: ExtInst [[#DOUBLEV]] [[#SV_RTN]] {{[0-9]+}} sqrt
define spir_kernel void @test_sqrt_vector(<2 x half> %h, <4 x float> %f, <3 x double> %d) {
entry:
  %h_rte = call <2 x half>   @llvm.sqrt.v2f16(<2 x half> %h),     !spirv.Decorations !0
  %f_rtz = call <4 x float>  @llvm.sqrt.v4f32(<4 x float> %f),    !spirv.Decorations !1
  %d_rtp = call <3 x double> @llvm.sqrt.v3f64(<3 x double> %d),   !spirv.Decorations !2
  %d_rtn = call <3 x double> @llvm.sqrt.v3f64(<3 x double> %d),   !spirv.Decorations !3
  ret void
}

declare half @llvm.fpbuiltin.fdiv.f16(half, half)
declare float @llvm.fpbuiltin.fdiv.f32(float, float)
declare double @llvm.fpbuiltin.fdiv.f64(double, double)

declare <2 x half> @llvm.fpbuiltin.fdiv.v2f16(<2 x half>, <2 x half>)
declare <4 x float> @llvm.fpbuiltin.fdiv.v4f32(<4 x float>, <4 x float>)
declare <3 x double> @llvm.fpbuiltin.fdiv.v3f64(<3 x double>, <3 x double>)

declare half @llvm.experimental.constrained.fdiv.f16(half, half, metadata, metadata)
declare float @llvm.experimental.constrained.fdiv.f32(float, float, metadata, metadata)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata)

declare <2 x half> @llvm.experimental.constrained.fdiv.v2f16(<2 x half>, <2 x half>, metadata, metadata)
declare <4 x float> @llvm.experimental.constrained.fdiv.v4f32(<4 x float>, <4 x float>, metadata, metadata)
declare <3 x double> @llvm.experimental.constrained.fdiv.v3f64(<3 x double>, <3 x double>, metadata, metadata)

declare half   @llvm.sqrt.f16(half)
declare float  @llvm.sqrt.f32(float)
declare double @llvm.sqrt.f64(double)

declare <2 x half>   @llvm.sqrt.v2f16(<2 x half>)
declare <4 x float>  @llvm.sqrt.v4f32(<4 x float>)
declare <3 x double> @llvm.sqrt.v3f64(<3 x double>)

!0 = !{!{i32 39, i32 0}}
!1 = !{!{i32 39, i32 1}}
!2 = !{!{i32 39, i32 2}}
!3 = !{!{i32 39, i32 3}}
