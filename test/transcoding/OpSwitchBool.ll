; A switch on an i1, which InstCombine can leave behind when it narrows a
; switch's condition. OpSwitch takes an integer selector, so the boolean
; condition is converted to a 32-bit integer.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: TypeInt [[#I32:]] 32 0
; CHECK-SPIRV-DAG: TypeBool [[#BOOL:]]
; CHECK-SPIRV-DAG: Constant [[#I32]] [[#ONE:]] 1
; CHECK-SPIRV-DAG: Constant [[#I32]] [[#ZERO:]] 0
; CHECK-SPIRV: FunctionParameter [[#BOOL]] [[#COND:]]
; CHECK-SPIRV: Select [[#I32]] [[#SEL:]] [[#COND]] [[#ONE]] [[#ZERO]]
; CHECK-SPIRV: Switch [[#SEL]] [[#]] 0 [[#]] 1 [[#]]

; CHECK-LLVM: %[[#SEL:]] = select i1 %c, i32 1, i32 0
; CHECK-LLVM: switch i32 %[[#SEL]], label %{{.*}} [
; CHECK-LLVM-NEXT: i32 0, label %{{.*}}
; CHECK-LLVM-NEXT: i32 1, label %{{.*}}

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %p, i1 %c) {
entry:
  switch i1 %c, label %default [
    i1 false, label %false
    i1 true, label %true
  ]
false:
  store i32 1, ptr addrspace(1) %p
  ret void
true:
  store i32 2, ptr addrspace(1) %p
  ret void
default:
  ret void
}
