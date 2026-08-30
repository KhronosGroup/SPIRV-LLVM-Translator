; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_KHR_untyped_pointers
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s

; RUN: llvm-spirv %s -o %t.noext.spv
; RUN: llvm-spirv -to-text %t.noext.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV-NOEXT
; RUN: llvm-spirv -r %t.noext.spv -o %t.noext.rev.bc
; RUN: llvm-dis %t.noext.rev.bc -o - | FileCheck %s

; CHECK-SPIRV: Capability UntypedPointersKHR
; CHECK-SPIRV-DAG: Name [[#A_VAR:]] "a_var"
; CHECK-SPIRV-DAG: Name [[#P_VAR:]] "p_var"
; CHECK-SPIRV-DAG: TypeInt [[#CHAR_TY:]] 8 0
; CHECK-SPIRV-DAG: Constant [[#]] [[#OFFSET4:]] 4 0
; CHECK-SPIRV-DAG: TypeUntypedPointerKHR [[#CHAR_PTR_TY:]] [[#]]
; CHECK-SPIRV: Variable [[#]] [[#A_VAR]] [[#]] [[#]]
; CHECK-SPIRV: SpecConstantOp [[#CHAR_PTR_TY]] [[#A_VAR_CAST:]] 124 [[#A_VAR]]
; CHECK-SPIRV: SpecConstantOp [[#CHAR_PTR_TY]] [[#P_VAR_INIT:]] 4423 [[#CHAR_TY]] [[#A_VAR_CAST]] [[#OFFSET4]]
; CHECK-SPIRV: UntypedVariableKHR [[#CHAR_PTR_TY]] [[#P_VAR]] [[#]] [[#CHAR_PTR_TY]] [[#P_VAR_INIT]]

; CHECK-SPIRV-NOEXT-NOT: Capability UntypedPointersKHR
; CHECK-SPIRV-NOEXT-NOT: TypeUntypedPointerKHR
; CHECK-SPIRV-NOEXT-DAG: Name [[#A_VAR:]] "a_var"
; CHECK-SPIRV-NOEXT-DAG: Name [[#P_VAR:]] "p_var"
; CHECK-SPIRV-NOEXT-DAG: TypeInt [[#CHAR_TY:]] 8 0
; CHECK-SPIRV-NOEXT-DAG: Constant [[#]] [[#OFFSET4:]] 4 0
; CHECK-SPIRV-NOEXT-DAG: TypeArray [[#ARRAY_TY:]] [[#]] [[#]]
; CHECK-SPIRV-NOEXT-DAG: TypePointer [[#ARRAY_PTR_TY:]] [[#]] [[#ARRAY_TY]]
; CHECK-SPIRV-NOEXT-DAG: TypePointer [[#CHAR_PTR_TY:]] [[#]] [[#CHAR_TY]]
; CHECK-SPIRV-NOEXT-DAG: TypePointer [[#CHAR_PTR_PTR_TY:]] [[#]] [[#CHAR_PTR_TY]]
; CHECK-SPIRV-NOEXT: Variable [[#ARRAY_PTR_TY]] [[#A_VAR]] [[#]] [[#]]
; CHECK-SPIRV-NOEXT: SpecConstantOp [[#CHAR_PTR_TY]] [[#A_VAR_CAST:]] 124 [[#A_VAR]]
; CHECK-SPIRV-NOEXT: SpecConstantOp [[#CHAR_PTR_TY]] [[#P_VAR_INIT:]] 67 [[#A_VAR_CAST]] [[#OFFSET4]]
; CHECK-SPIRV-NOEXT: Variable [[#CHAR_PTR_PTR_TY]] [[#P_VAR]] [[#]] [[#P_VAR_INIT]]

; CHECK: @p_var = addrspace(1) global ptr addrspace(1) getelementptr (i8, ptr addrspace(1) @a_var, i64 4), align 8

source_filename = "transcoding/constant-ugly-gep-src-elem.ll"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir64"

@a_var = addrspace(1) global [2 x i32] [i32 1, i32 1], align 4
@p_var = addrspace(1) global ptr addrspace(1) getelementptr (i8, ptr addrspace(1) @a_var, i64 4), align 8
