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

; CHECK-SPIRV: 4 TypeInt [[#INT:]] 32 0
; CHECK-SPIRV: 3 TypeUntypedPointerKHR [[#FLOATPTR:]] 7
; CHECK-SPIRV: 3 TypeFloat [[#FLOAT:]] 32

; Function Attrs: nounwind
define spir_kernel void @foo() {
; CHECK-SPIRV: 5 UntypedVariableKHR [[#FLOATPTR]] [[#IPTR:]] 7 [[#INT]]
; CHECK-SPIRV: 5 UntypedVariableKHR [[#FLOATPTR]] [[#FPTR:]] 7 [[#FLOAT]]
; CHECK-SPIRV: Store [[#IPTR]] [[#]]
; CHECK-SPIRV: Load [[#INT]] [[#LOAD:]] [[#IPTR]]
; CHECK-SPIRV: 4 Bitcast [[#FLOAT]] [[#BITCAST:]] [[#LOAD]]
; CHECK-SPIRV: Store [[#FPTR]] [[#BITCAST]]
entry:
  %iptr = alloca i32, align 4
  %fptr = alloca float, align 4
  store i32 0, ptr %iptr, align 4
  %0 = load i32, ptr %iptr, align 4
  %1 = bitcast i32 %0 to float
  store float %1, ptr %fptr, align 4
  ret void
}
