; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_fp_max_error --spirv-allow-unknown-intrinsics=llvm.fpbuiltin -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r -emit-opaque-pointers %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: Capability FPMaxErrorINTEL
; CHECK-SPIRV: Extension "SPV_INTEL_fp_max_error"

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define void @test_fp_max_error_decoration(float %f1, float %f2, float %f3) {
entry:
  %t1 = call float @llvm.fpbuiltin.fadd.f32(float %f1, float %f2)
  %t2 = call float @llvm.fpbuiltin.fsub.f32(float %f1, float %f2)
  %t3 = call float @llvm.fpbuiltin.fmul.f32(float %f1, float %f2) #0
  %t4 = call float @llvm.fpbuiltin.fdiv.f32(float %f1, float %f2) #1
  %t5 = call float @llvm.fpbuiltin.frem.f32(float %f1, float %f2) #1

  %t6 = call float @llvm.fpbuiltin.sin.f32(float %f1) #2
  %t7 = call float @llvm.fpbuiltin.cos.f32(float %f1) #2
  %t8 = call float @llvm.fpbuiltin.tan.f32(float %f1) #2

  %t9 = call float @llvm.fpbuiltin.sinh.f32(float %f1) #2
  %t10 = call float @llvm.fpbuiltin.cosh.f32(float %f1) #2
  %t11 = call float @llvm.fpbuiltin.tanh.f32(float %f1) #2

  %t12 = call float @llvm.fpbuiltin.asin.f32(float %f1) #2
  %t13 = call float @llvm.fpbuiltin.acos.f32(float %f1) #2
  %t14 = call float @llvm.fpbuiltin.atan.f32(float %f1) #2

  %t15 = call float @llvm.fpbuiltin.asinh.f32(float %f1) #2
  %t16 = call float @llvm.fpbuiltin.acosh.f32(float %f1) #2
  %t17 = call float @llvm.fpbuiltin.atanh.f32(float %f1) #2

  %t18 = call float @llvm.fpbuiltin.exp.f32(float %f1) #2
  %t19 = call float @llvm.fpbuiltin.exp2.f32(float %f1) #2
  %t20 = call float @llvm.fpbuiltin.exp10.f32(float %f1) #2
  %t21 = call float @llvm.fpbuiltin.expm1.f32(float %f1) #2

  %t22 = call float @llvm.fpbuiltin.log.f32(float %f1) #2
  %t23 = call float @llvm.fpbuiltin.log2.f32(float %f1) #2
  %t24 = call float @llvm.fpbuiltin.log10.f32(float %f1) #2
  %t25 = call float @llvm.fpbuiltin.log1p.f32(float %f1) #2

  %t26 = call float @llvm.fpbuiltin.sqrt.f32(float %f1) #2
  %t27 = call float @llvm.fpbuiltin.rsqrt.f32(float %f1) #2
  %t28 = call float @llvm.fpbuiltin.erf.f32(float %f1) #2
  %t29 = call float @llvm.fpbuiltin.erfc.f32(float %f1) #2

  %t30 = call float @llvm.fpbuiltin.atan2.f32(float %f1, float %f2) #3
  %t31 = call float @llvm.fpbuiltin.ldexp.f32(float %f1, float %f2) #3
  %t32 = call float @llvm.fpbuiltin.pow.f32(float %f1, float %f2) #3
  %t33 = call float @llvm.fpbuiltin.hypot.f32(float %f1, float %f2) #3

  %t34 = call float @llvm.fpbuiltin.sincos.f32(float %f1, float %f2, float %f3) #4
  ret void
}

declare float @llvm.fpbuiltin.fadd.f32(float, float)
declare float @llvm.fpbuiltin.fsub.f32(float, float)
declare float @llvm.fpbuiltin.fmul.f32(float, float)
declare float @llvm.fpbuiltin.fdiv.f32(float, float)
declare float @llvm.fpbuiltin.frem.f32(float, float)

declare float @llvm.fpbuiltin.sin.f32(float)
declare float @llvm.fpbuiltin.cos.f32(float)
declare float @llvm.fpbuiltin.tan.f32(float)
declare float @llvm.fpbuiltin.sinh.f32(float)
declare float @llvm.fpbuiltin.cosh.f32(float)
declare float @llvm.fpbuiltin.tanh.f32(float)
declare float @llvm.fpbuiltin.asin.f32(float)
declare float @llvm.fpbuiltin.acos.f32(float)
declare float @llvm.fpbuiltin.atan.f32(float)
declare float @llvm.fpbuiltin.asinh.f32(float)
declare float @llvm.fpbuiltin.acosh.f32(float)
declare float @llvm.fpbuiltin.atanh.f32(float)
declare float @llvm.fpbuiltin.exp.f32(float)
declare float @llvm.fpbuiltin.exp2.f32(float)
declare float @llvm.fpbuiltin.exp10.f32(float)
declare float @llvm.fpbuiltin.expm1.f32(float)
declare float @llvm.fpbuiltin.log.f32(float)
declare float @llvm.fpbuiltin.log2.f32(float)
declare float @llvm.fpbuiltin.log10.f32(float)
declare float @llvm.fpbuiltin.log1p.f32(float)
declare float @llvm.fpbuiltin.sqrt.f32(float)
declare float @llvm.fpbuiltin.rsqrt.f32(float)
declare float @llvm.fpbuiltin.erf.f32(float)
declare float @llvm.fpbuiltin.erfc.f32(float)

declare float @llvm.fpbuiltin.atan2.f32(float, float)
declare float @llvm.fpbuiltin.hypot.f32(float, float)
declare float @llvm.fpbuiltin.pow.f32(float, float)
declare float @llvm.fpbuiltin.ldexp.f32(float, float)

declare float @llvm.fpbuiltin.sincos.f32(float, float, float)

attributes #0 = { "fpbuiltin-max-error"="0.5" }
attributes #1 = { "fpbuiltin-max-error"="1.0" }
attributes #2 = { "fpbuiltin-max-error"="2.5" }
attributes #3 = { "fpbuiltin-max-error"="4.0" }
attributes #4 = { "fpbuiltin-max-error"="4096.0" }
