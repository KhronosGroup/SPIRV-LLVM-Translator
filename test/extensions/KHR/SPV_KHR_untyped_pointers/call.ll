; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_untyped_pointers -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_untyped_pointers -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; R/UN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-SPIRV: Name [[#CALL:]] "call"
; CHECK-SPIRV: TypeInt [[#INT:]] 32 0
; CHECK-SPIRV: TypeUntypedPointerKHR [[#INTPTR:]] 7
; CHECK-SPIRV: TypeFloat [[#FLOAT:]] 32
; CHECK-SPIRV: TypeFunction [[#CALLTY:]] [[#INTPTR]] [[#INTPTR]]

; Function Attrs: nounwind
define spir_kernel void @foo() {
; CHECK-SPIRV: UntypedVariableKHR [[#INTPTR]] [[#IPTR:]] 7 [[#INT]]
; CHECK-SPIRV: UntypedVariableKHR [[#INTPTR]] [[#FPTR:]] 7 [[#FLOAT]]
; CHECK-SPIRV: FunctionCall [[#INTPTR]] [[#IPTR1:]] [[#CALL]] [[#IPTR]]
; CHECK-SPIRV: Store [[#IPTR1]]
; CHECK-SPIRV: Bitcast [[#INTPTR]] [[#FPTR1:]] [[#FPTR]]
; CHECK-SPIRV: FunctionCall [[#INTPTR]] [[#FPTR2:]] [[#CALL]] [[#FPTR1]]
; CHECK-SPIRV: Bitcast [[#INTPTR]] [[#FPTR3:]] [[#FPTR2]]
; CHECK-SPIRV: Store [[#FPTR3]]
entry:
  %iptr = alloca i32, align 4
  %fptr = alloca float, align 4
  %iptr.call = call spir_func ptr @call(ptr %iptr)
  store i32 0, ptr %iptr.call
  %fptr.call = call spir_func ptr @call(ptr %fptr)
  store float 0.0, ptr %fptr.call
  ret void
}

define spir_func ptr @call(ptr %a) {
  ret ptr %a
}
