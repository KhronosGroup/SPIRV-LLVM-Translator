; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -spirv-ext=+SPV_INTEL_function_pointers -spirv-text %t.bc -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -spirv-ext=+SPV_INTEL_function_pointers %t.bc -o %t.spv
; RUN: llvm-spirv -r -emit-opaque-pointers %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; Check that aliases are dereferenced and translated to their aliasee values
; when used since they can't be translated directly.

; CHECK-SPIRV-DAG: 3 Name [[#FOO:]] "foo"
; CHECK-SPIRV-DAG: 3 Name [[#BAR:]] "bar"
; CHECK-SPIRV-DAG: 3 Name [[#Y:]] "y"
; CHECK-SPIRV-DAG: 5 Name [[#FOOPTR:]] "foo.alias"
; CHECK-SPIRV-DAG: 5 Decorate [[#FOO]] LinkageAttributes "foo" Export
; CHECK-SPIRV-DAG: 5 Decorate [[#BAR]] LinkageAttributes "bar" Export
; CHECK-SPIRV-DAG: 4 TypeInt [[#I32:]] 32 0
; CHECK-SPIRV-DAG: 4 TypeInt [[#I64:]] 64 0
; CHECK-SPIRV-DAG: 4 TypeFunction [[#FOO_TYPE:]] [[#I32]] [[#I32]]
; CHECK-SPIRV-DAG: 2 TypeVoid [[#VOID:]]
; CHECK-SPIRV-DAG: 4 TypePointer [[#I64PTR:]] 7 [[#I64]]
; CHECK-SPIRV-DAG: 4 TypeFunction [[#BAR_TYPE:]] [[#VOID]] [[#I64PTR]]
; CHECK-SPIRV-DAG: 4 TypePointer [[#FOOPTR_TYPE:]] 7 [[#FOO_TYPE]]
; CHECK-SPIRV-DAG: 4 ConstantFunctionPointerINTEL [[#FOOPTR_TYPE]] [[#FOOPTR]] [[#FOO]]

; CHECK-SPIRV: 5 Function [[#I32]] [[#FOO]] 0 [[#FOO_TYPE]]

; CHECK-SPIRV: 5 Function [[#VOID]] [[#BAR]] 0 [[#BAR_TYPE]]
; CHECK-SPIRV: 3 FunctionParameter [[#I64PTR]] [[#Y]]
; CHECK-SPIRV: 4 ConvertPtrToU [[#I64]] [[#PTRTOINT:]] [[#FOOPTR]]
; CHECK-SPIRV: 5 Store [[#Y]] [[#PTRTOINT]] 2 8

; CHECK-LLVM: define spir_func i32 @foo(i32 %x)

; CHECK-LLVM: define spir_kernel void @bar(ptr %y)
; CHECK-LLVM: [[PTRTOINT:%.*]] = ptrtoint ptr @foo to i64
; CHECK-LLVM: store i64 [[PTRTOINT]], ptr %y, align 8

define spir_func i32 @foo(i32 %x) {
  ret i32 %x
}

@foo.alias = internal alias i32 (i32), i32 (i32)* @foo

define spir_kernel void @bar(i64* %y) {
  store i64 ptrtoint (i32 (i32)* @foo.alias to i64), i64* %y
  ret void
}
