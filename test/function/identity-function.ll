; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; CHECK: Name [[#FN_ID:]] "identity" 
; CHECK: Name [[#ARG_ID:]] "value" 

; CHECK: TypeInt [[#I32_TY:]] 32 0 
; CHECK: TypeFunction [[#FUN_TY:]] [[#I32_TY]] [[#I32_TY]] 

; CHECK: Function [[#I32_TY]] [[#FN_ID]] 0 [[#FUN_TY]] 
; CHECK: FunctionParameter [[#I32_TY]] [[#ARG_ID]] 
; CHECK: Label [[#LBL:]] 
; CHECK: ReturnValue [[#ARG_ID]] 
; CHECK: FunctionEnd

define i32 @identity(i32 %value) {
  ret i32 %value
}
