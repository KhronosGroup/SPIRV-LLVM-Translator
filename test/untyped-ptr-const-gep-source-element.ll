; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_KHR_untyped_pointers
; RUN: llvm-spirv %s -spirv-text -o - --spirv-ext=+SPV_KHR_untyped_pointers | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s
; RUN: llvm-spirv %s -o %t.noext.spv
; RUN: llvm-spirv -r %t.noext.spv -o %t.noext.rev.bc

; CHECK-SPIRV: Capability UntypedPointersKHR
; CHECK-SPIRV-DAG: Name [[#A_VAR:]] "a_var"
; CHECK-SPIRV-DAG: Name [[#P_VAR:]] "p_var"
; CHECK-SPIRV: TypeInt [[#CHAR:]] 8 0
; CHECK-SPIRV-DAG: Constant [[#]] [[#OFFSET4:]] 4 0
; CHECK-SPIRV: TypeUntypedPointerKHR [[#CHARPTR:]] [[#]]
; CHECK-SPIRV: Variable [[#]] [[#A_VAR]] [[#]] [[#]]
; CHECK-SPIRV: SpecConstantOp [[#CHARPTR]] [[#A_VAR_CAST:]] 124 [[#A_VAR]]
; CHECK-SPIRV: SpecConstantOp [[#CHARPTR]] [[#P_VAR_INIT:]] 4423 [[#CHAR]] [[#A_VAR_CAST]] [[#OFFSET4]]
; CHECK-SPIRV: UntypedVariableKHR [[#CHARPTR]] [[#P_VAR]] [[#]] [[#CHARPTR]] [[#P_VAR_INIT]]

; CHECK: @p_var = addrspace(1) global ptr addrspace(1) getelementptr (i8, ptr addrspace(1) @a_var, i64 4), align 8

source_filename = "untyped-ptr-const-gep-source-element.ll"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir64"

@a_var = addrspace(1) global [2 x i32] [i32 1, i32 1], align 4
@p_var = addrspace(1) global ptr addrspace(1) getelementptr (i8, ptr addrspace(1) @a_var, i64 4), align 8
