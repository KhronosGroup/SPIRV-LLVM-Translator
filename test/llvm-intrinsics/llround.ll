; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

; CHECK: ExtInstImport [[#Ext:]] "OpenCL.std"
; CHECK-DAG: TypeInt [[#I64:]] 64 0
; CHECK-DAG: TypeFloat [[#F32:]] 32
; CHECK-DAG: TypeFloat [[#F64:]] 64
; CHECK: ExtInst [[#F32]] [[#R0:]] [[#Ext]] round
; CHECK: ConvertFToS [[#I64]] [[#]] [[#R0]]
; CHECK: ExtInst [[#F64]] [[#R1:]] [[#Ext]] round
; CHECK: ConvertFToS [[#I64]] [[#]] [[#R1]]

target triple = "spir64-unknown-unknown"

define spir_func i64 @llround_f32(float %x) {
  %r = call i64 @llvm.llround.i64.f32(float %x)
  ret i64 %r
}

define spir_func i64 @llround_f64(double %x) {
  %r = call i64 @llvm.llround.i64.f64(double %x)
  ret i64 %r
}
