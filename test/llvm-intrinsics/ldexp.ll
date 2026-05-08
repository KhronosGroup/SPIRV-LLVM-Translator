; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s
; RUN: spirv-val %t.spv

; CHECK: ExtInstImport [[ExtInstSetId:[0-9]+]] "OpenCL.std"
; CHECK-DAG: TypeFloat [[Half:[0-9]+]] 16
; CHECK-DAG: TypeFloat [[Float:[0-9]+]] 32
; CHECK-DAG: TypeFloat [[Double:[0-9]+]] 64
; CHECK-DAG: TypeInt [[Int32:[0-9]+]] 32 0
; CHECK-DAG: TypeVector [[Float4:[0-9]+]] [[Float]] 4
; CHECK-DAG: TypeVector [[Int32V4:[0-9]+]] [[Int32]] 4

target datalayout = "e-p:64:64-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64"

define spir_func void @test_ldexp(half %h, float %f, double %d, <4 x float> %vf,
                                  i32 %k, <4 x i32> %vk) #0 {
entry:
  %0 = call half @llvm.ldexp.f16.i32(half %h, i32 %k)
  %1 = call float @llvm.ldexp.f32.i32(float %f, i32 %k)
  %2 = call double @llvm.ldexp.f64.i32(double %d, i32 %k)
  %3 = call <4 x float> @llvm.ldexp.v4f32.v4i32(<4 x float> %vf, <4 x i32> %vk)
; CHECK: ExtInst [[Half]] {{[0-9]+}} [[ExtInstSetId]] ldexp
; CHECK: ExtInst [[Float]] {{[0-9]+}} [[ExtInstSetId]] ldexp
; CHECK: ExtInst [[Double]] {{[0-9]+}} [[ExtInstSetId]] ldexp
; CHECK: ExtInst [[Float4]] {{[0-9]+}} [[ExtInstSetId]] ldexp
  ret void
}

declare half @llvm.ldexp.f16.i32(half, i32) #1
declare float @llvm.ldexp.f32.i32(float, i32) #1
declare double @llvm.ldexp.f64.i32(double, i32) #1
declare <4 x float> @llvm.ldexp.v4f32.v4i32(<4 x float>, <4 x i32>) #1

attributes #0 = { noinline nounwind optnone }
attributes #1 = { nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0}
!0 = !{i32 1, !"wchar_size", i32 4}
