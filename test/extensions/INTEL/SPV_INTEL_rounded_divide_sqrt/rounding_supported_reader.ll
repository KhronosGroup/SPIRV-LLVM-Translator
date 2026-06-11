; Verifies reverse translation (SPIR-V -> LLVM IR) of OpFDiv and the sqrt
; OpenCL.std extended instruction decorated with FPRoundingMode under the
; SPV_INTEL_rounded_divide_sqrt extension.

; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_INTEL_rounded_divide_sqrt

; OCL/default path: there is no OCL representation for the rounding mode on
; fdiv/sqrt, so it is dropped (plain fdiv, plain sqrt builtin). The
; --implicit-check-not flags assert no rounding info leaks anywhere.
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM-OCL\
; RUN:   --implicit-check-not=FPRoundingMode --implicit-check-not=spirv.Decorations

; SPV-IR path: the rounding mode is preserved as an !spirv.Decorations
; FPRoundingMode (Decoration 39) attached to the fdiv/sqrt.
; RUN: llvm-spirv -r %t.spv --spirv-target-env=SPV-IR -o %t.rev.spvir.bc
; RUN: llvm-dis %t.rev.spvir.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM-SPV

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; OCL/default: rounding mode has no OCL representation, so fdiv is plain and
; sqrt maps to the plain OpenCL builtin with no rounding.
; CHECK-LLVM-OCL-LABEL: @test_fdiv_scalar
; CHECK-LLVM-OCL: fdiv half
; CHECK-LLVM-OCL: fdiv float
; CHECK-LLVM-OCL: fdiv double
; CHECK-LLVM-OCL: fdiv double
; CHECK-LLVM-OCL-LABEL: @test_sqrt_scalar
; CHECK-LLVM-OCL: call spir_func half @_Z4sqrtDh(
; CHECK-LLVM-OCL: call spir_func float @_Z4sqrtf(
; CHECK-LLVM-OCL: call spir_func double @_Z4sqrtd(
; CHECK-LLVM-OCL: call spir_func double @_Z4sqrtd(

; SPV-IR: rounding mode is preserved as an !spirv.Decorations metadata
; FPRoundingMode (Decoration 39) on both fdiv and the __spirv_ocl_sqrt builtin.
; The same metadata node is shared per rounding mode across fdiv and sqrt.
; CHECK-LLVM-SPV-LABEL: @test_fdiv_scalar
; CHECK-LLVM-SPV: fdiv half %{{.*}}, !spirv.Decorations [[RTE:![0-9]+]]
; CHECK-LLVM-SPV: fdiv float %{{.*}}, !spirv.Decorations [[RTZ:![0-9]+]]
; CHECK-LLVM-SPV: fdiv double %{{.*}}, !spirv.Decorations [[RTP:![0-9]+]]
; CHECK-LLVM-SPV: fdiv double %{{.*}}, !spirv.Decorations [[RTN:![0-9]+]]
; CHECK-LLVM-SPV-LABEL: @test_sqrt_scalar
; CHECK-LLVM-SPV: call spir_func half @_Z16__spirv_ocl_sqrtDh(half %{{.*}}!spirv.Decorations [[RTE]]
; CHECK-LLVM-SPV: call spir_func float @_Z16__spirv_ocl_sqrtf(float %{{.*}}!spirv.Decorations [[RTZ]]
; CHECK-LLVM-SPV: call spir_func double @_Z16__spirv_ocl_sqrtd(double %{{.*}}!spirv.Decorations [[RTP]]
; CHECK-LLVM-SPV: call spir_func double @_Z16__spirv_ocl_sqrtd(double %{{.*}}!spirv.Decorations [[RTN]]
; CHECK-LLVM-SPV-DAG: [[RTE]] = !{[[RTEX:![0-9]+]]}
; CHECK-LLVM-SPV-DAG: [[RTEX]] = !{i32 39, i32 0}
; CHECK-LLVM-SPV-DAG: [[RTZ]] = !{[[RTZX:![0-9]+]]}
; CHECK-LLVM-SPV-DAG: [[RTZX]] = !{i32 39, i32 1}
; CHECK-LLVM-SPV-DAG: [[RTP]] = !{[[RTPX:![0-9]+]]}
; CHECK-LLVM-SPV-DAG: [[RTPX]] = !{i32 39, i32 2}
; CHECK-LLVM-SPV-DAG: [[RTN]] = !{[[RTNX:![0-9]+]]}
; CHECK-LLVM-SPV-DAG: [[RTNX]] = !{i32 39, i32 3}

define spir_kernel void @test_fdiv_scalar(half %h0, half %h1, float %f0, float %f1, double %d0, double %d1) {
entry:
  %h_rte = call half @llvm.experimental.constrained.fdiv.f16(half %h0, half %h1, metadata !"round.tonearest", metadata !"fpexcept.strict")
  %f_rtz = call float @llvm.experimental.constrained.fdiv.f32(float %f0, float %f1, metadata !"round.towardzero", metadata !"fpexcept.strict")
  %d_rtp = call double @llvm.experimental.constrained.fdiv.f64(double %d0, double %d1, metadata !"round.upward", metadata !"fpexcept.strict")
  %d_rtn = call double @llvm.experimental.constrained.fdiv.f64(double %d0, double %d1, metadata !"round.downward", metadata !"fpexcept.strict")
  ret void
}

define spir_kernel void @test_sqrt_scalar(half %h, float %f, double %d) {
entry:
  %h_rte = call half   @llvm.experimental.constrained.sqrt.f16(half %h,   metadata !"round.tonearest", metadata !"fpexcept.strict")
  %f_rtz = call float  @llvm.experimental.constrained.sqrt.f32(float %f,  metadata !"round.towardzero", metadata !"fpexcept.strict")
  %d_rtp = call double @llvm.experimental.constrained.sqrt.f64(double %d, metadata !"round.upward",     metadata !"fpexcept.strict")
  %d_rtn = call double @llvm.experimental.constrained.sqrt.f64(double %d, metadata !"round.downward",   metadata !"fpexcept.strict")
  ret void
}

declare half @llvm.experimental.constrained.fdiv.f16(half, half, metadata, metadata)
declare float @llvm.experimental.constrained.fdiv.f32(float, float, metadata, metadata)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata)

declare half   @llvm.experimental.constrained.sqrt.f16(half, metadata, metadata)
declare float  @llvm.experimental.constrained.sqrt.f32(float, metadata, metadata)
declare double @llvm.experimental.constrained.sqrt.f64(double, metadata, metadata)
