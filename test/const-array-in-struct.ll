; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-DAG: TypeInt [[#IntTy:]] 32 0
; CHECK-DAG: Constant [[#IntTy]] [[#Const16:]] 8
; CHECK-DAG: TypeArray [[#ArrayTy:]] [[#IntTy]] [[#Const16]]
; CHECK-DAG: TypeStruct [[#StructTy:]] [[#ArrayTy]]
; CHECK-DAG-COUNT-8: Constant [[#IntTy]] [[#]] {{[1-9]}}
; CHECK-DAG: ConstantComposite [[#ArrayTy]] [[#ConstArray:]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#]]
; CHECK-DAG: ConstantComposite [[#StructTy]] [[#]] [[#ConstArray]]

%struct_array_8i32 = type { [8 x i32] }

@G = private unnamed_addr addrspace(1) constant %struct_array_8i32 { [8 x i32] [i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7] }, align 4

define spir_kernel void @test() {
  ret void
}
