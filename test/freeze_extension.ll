;; Test to check that freeze extension can preserve freeze instruction
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-ext=+SPV_KHR_freeze -o %t.spv
; RUN: llvm-spirv %t.spv -o - -to-text | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define spir_func i32 @testfunction(i32 %val_parameter) {
   %1 = freeze i32 %val_parameter
   ret i32 %1
}

; CHECK-SPIRV: 2 Capability FreezeKHR
; CHECK-SPIRV: 5 Extension "SPV_KHR_freeze"
; CHECK-SPIRV-DAG: [[#]] Name [[#val_parameter:]] "val_parameter"
; CHECK-SPIRV-DAG: 4 TypeInt [[#TInt32:]] 32 0
; CHECK-SPIRV: 4 FreezeKHR [[#TInt32]] [[#]] [[#val_parameter]]

; CHECK-LLVM: [[FREEZE_RESULT:%.*]] = freeze i32 %val_parameter
; CHECK-LLVM-NEXT: ret i32 [[FREEZE_RESULT]]