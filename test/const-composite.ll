; This test is to ensure that OpConstantComposite reuses a constant when it's
; already created and available in the same machine function. In this test case
; it's `1` that is passed implicitly as a part of the `foo` function argument
; and also takes part in a composite constant creation.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s 
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir"

; CHECK-DAG: TypeInt [[#type_int32:]] 32 0
; CHECK-DAG: Constant [[#type_int32]] [[#const1:]] 1
; CHECK-DAG: TypeArray [[#]] [[#]] [[#const1]]
; CHECK-DAG: Constant [[#type_int32]] [[#const0:]] 0
; CHECK-DAG: ConstantComposite [[#]] [[#]] [[#const0]] [[#const1]]

%struct = type { [1 x i64] }
define spir_kernel void @foo(ptr noundef byval(%struct) %arg) {
entry:
  call spir_func void @bar(<2 x i32> noundef <i32 0, i32 1>)
  ret void
}

define spir_func void @bar(<2 x i32> noundef) {
entry:
  ret void
}
