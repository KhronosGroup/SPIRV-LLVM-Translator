; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; CHECK: Name [[#BAR_ID:]] "bar" 
; CHECK: Name [[#FOO_ID:]] "foo" 
; CHECK: Name [[#GOO_ID:]] "goo" 

; CHECK: TypeInt [[#I32:]] 32 0 
; CHECK: TypeFunction [[#FTY_BARFOO:]] [[#I32]] [[#I32]] 
; CHECK: TypePointer [[#PTR:]] [[#]] [[#I32]] 
; CHECK: TypePointer [[#PTR_FUNC:]] [[#]] [[#]] 
; CHECK: TypeFunction [[#FTY_GOO:]] [[#I32]] [[#I32]] [[#PTR_FUNC]] 

define i32 @bar(i32 %a) {
  %p = alloca i32
  store i32 %a, i32* %p
  %b = load i32, i32* %p
  ret i32 %b
}
; CHECK: Function [[#I32]] [[#]] 0 [[#FTY_BARFOO]] 
; CHECK: FunctionParameter [[#I32]] [[#BAR_ARG:]] 
; CHECK: Label [[#]] 
; CHECK: Variable [[#PTR]] [[#BAR_VAR:]] [[#]] 
; CHECK: Store [[#BAR_VAR]] [[#BAR_ARG]] 2 4 
; CHECK: Load [[#I32]] [[#BAR_LOAD:]] [[#BAR_VAR]] 2 4 
; CHECK: ReturnValue [[#BAR_LOAD]] 
; CHECK: FunctionEnd 

define i32 @foo(i32 %a) {
  %p = alloca i32
  store volatile i32 %a, i32* %p
  %b = load volatile i32, i32* %p
  ret i32 %b
}

; CHECK: Function [[#I32]] [[#]] 0 [[#FTY_BARFOO]] 
; CHECK: FunctionParameter [[#I32]] [[#FOO_ARG:]] 
; CHECK: Label [[#]] 
; CHECK: Variable [[#PTR]] [[#FOO_VAR:]] [[#]] 
; CHECK: Store [[#FOO_VAR]] [[#FOO_ARG]] 3 4 
; CHECK: Load [[#I32]] [[#FOO_LOAD:]] [[#FOO_VAR]] 3 4 
; CHECK: ReturnValue [[#FOO_LOAD]] 
; CHECK: FunctionEnd 

;; Test load and store in global address space.
define i32 @goo(i32 %a, ptr addrspace(1) %p) {
  store i32 %a, i32 addrspace(1)* %p
  %b = load i32, i32 addrspace(1)* %p
  ret i32 %b
}

; CHECK: Function [[#I32]] [[#]] 0 [[#FTY_GOO]] 
; CHECK: FunctionParameter [[#I32]] [[#GOO_ARG:]] 
; CHECK: FunctionParameter [[#PTR_FUNC]] [[#GOO_PTR:]] 
; CHECK: Label [[#]] 
; CHECK: Store [[#GOO_PTR]] [[#GOO_ARG]] 2 4 
; CHECK: Load [[#I32]] [[#GOO_LOAD:]] [[#GOO_PTR]] 2 4 
; CHECK: ReturnValue [[#GOO_LOAD]] 
; CHECK: FunctionEnd
