; REQUIRES: spirv-dis
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-dis --raw-id %t.spv | FileCheck --check-prefix CHECK-SPIRV %s
; RUN: spirv-val %t.spv

; The intrinsics are translated inline, so allowing unknown intrinsics to be
; emitted as calls must not leave an imported declaration behind.
; RUN: llvm-spirv -spirv-allow-unknown-intrinsics %t.bc -o %t.unknown.spv
; RUN: spirv-dis --raw-id %t.unknown.spv | FileCheck --check-prefix CHECK-SPIRV %s
; RUN: spirv-dis --raw-id %t.unknown.spv | FileCheck --check-prefix CHECK-NO-IMPORT %s
; RUN: spirv-val %t.unknown.spv

; CHECK-NO-IMPORT-NOT: LinkageAttributes "llvm.

; CHECK-SPIRV:          [[opencl:%[0-9]+]] = OpExtInstImport "OpenCL.std"
; CHECK-SPIRV-DAG:      [[i64:%[0-9]+]] = OpTypeInt 64 0
; CHECK-SPIRV-DAG:      [[f32:%[0-9]+]] = OpTypeFloat 32
; CHECK-SPIRV-DAG:      [[f64:%[0-9]+]] = OpTypeFloat 64
; CHECK-SPIRV-DAG:      [[v4f32:%[0-9]+]] = OpTypeVector [[f32]] 4
; CHECK-SPIRV-DAG:      [[v4i64:%[0-9]+]] = OpTypeVector [[i64]] 4
; CHECK-SPIRV:      [[rounded_f32:%[0-9]+]] = OpExtInst [[f32]] [[opencl]] round
; CHECK-SPIRV:                        OpConvertFToS [[i64]] [[rounded_f32]]
; CHECK-SPIRV:      [[rounded_f64:%[0-9]+]] = OpExtInst [[f64]] [[opencl]] round
; CHECK-SPIRV:                        OpConvertFToS [[i64]] [[rounded_f64]]
; CHECK-SPIRV:    [[rounded_v4f32:%[0-9]+]] = OpExtInst [[v4f32]] [[opencl]] round
; CHECK-SPIRV:                        OpConvertFToS [[v4i64]] [[rounded_v4f32]]

target triple = "spir64-unknown-unknown"

define spir_func i64 @test_0(float %arg0) {
entry:
  %0 = call i64 @llvm.llround.i64.f32(float %arg0)
  ret i64 %0
}

define spir_func i64 @test_1(double %arg0) {
entry:
  %0 = call i64 @llvm.llround.i64.f64(double %arg0)
  ret i64 %0
}

define spir_func <4 x i64> @test_2(<4 x float> %arg0) {
entry:
  %0 = call <4 x i64> @llvm.llround.v4i64.v4f32(<4 x float> %arg0)
  ret <4 x i64> %0
}

declare i64 @llvm.llround.i64.f32(float)
declare i64 @llvm.llround.i64.f64(double)
declare <4 x i64> @llvm.llround.v4i64.v4f32(<4 x float>)
