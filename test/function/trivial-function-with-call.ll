; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; CHECK: Name [[#BAR_ID:]] "bar" 
; CHECK: Name [[#FOO_ID:]] "foo" 
; CHECK: TypeInt [[#I32_TY:]] 32 0 
; CHECK: TypeFunction [[#BAR_FUNC_TY:]] [[#I32_TY]] [[#I32_TY]] 
; CHECK: TypeVoid [[#VOID_TY:]] 
; CHECK: TypeFunction [[#FOO_FUNC_TY:]] [[#VOID_TY]] [[#I32_TY]] 
;; Function decl:
; CHECK: Function [[#I32_TY]] [[#BAR_ID]] 0 [[#BAR_FUNC_TY]] 
; CHECK: FunctionParameter [[#I32_TY]] [[#]] 
; CHECK: FunctionEnd 

; CHECK: Function [[#VOID_TY]] [[#FOO_ID]] 0 [[#FOO_FUNC_TY]] 
; CHECK: FunctionParameter [[#I32_TY]] [[#X_ID:]] 
; CHECK: Label [[#LBL:]] 
; CHECK: FunctionCall [[#I32_TY]] [[#]] [[#BAR_ID]] [[#X_ID]] 
; CHECK: Return 
; CHECK-NOT: Label
; CHECK: FunctionEnd

declare i32 @bar(i32 %x)

define spir_func void @foo(i32 %x) {
  %call1 = call spir_func i32 @bar(i32 %x)
  ret void
}
