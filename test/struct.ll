; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%struct.ST = type { i32, i32, i32 }

; CHECK-DAG:  Name [[#STRUCT_TYPE_ID:]] "struct.ST"
; CHECK: TypeInt [[#INT_TYPE:]] 32 0
; CHECK: Constant [[#INT_TYPE]] [[#CONST_0:]] 0
; CHECK: Constant [[#INT_TYPE]] [[#CONST_1:]] 1
; CHECK: Constant [[#INT_TYPE]] [[#CONST_2:]] 2
; CHECK: Constant [[#INT_TYPE]] [[#CONST_3:]] 3
; CHECK: TypeStruct [[#STRUCT_TYPE_ID]] [[#INT_TYPE]] [[#INT_TYPE]] [[#INT_TYPE]]
; CHECK: TypePointer [[#PTR_STRUCT_TYPE_ID:]] 7 [[#STRUCT_TYPE_ID]]
; CHECK: TypePointer [[#PTR_INT_TYPE_ID:]] 7 [[#INT_TYPE]]

; CHECK: Function [[#]] [[#]] 0 [[#]]
; CHECK: Label 5
; CHECK: Variable [[#PTR_STRUCT_TYPE_ID]] [[#ST_VAR_ID:]] 7
; CHECK: InBoundsPtrAccessChain [[#PTR_INT_TYPE_ID]] [[#A_ID:]] [[#ST_VAR_ID]] [[#CONST_0]] [[#CONST_0]]
; CHECK: Store [[#A_ID]] 12 2 4
; CHECK: InBoundsPtrAccessChain [[#PTR_INT_TYPE_ID]] [[#B_ID:]] [[#ST_VAR_ID]] [[#CONST_0]] [[#CONST_1]]
; CHECK: Store [[#B_ID]] 14 2 4
; CHECK: InBoundsPtrAccessChain [[#PTR_INT_TYPE_ID]] [[#C_ID:]] [[#ST_VAR_ID]] [[#CONST_0]] [[#CONST_2]]
; CHECK: Store [[#C_ID]] 16 2 4
; CHECK: InBoundsPtrAccessChain [[#PTR_INT_TYPE_ID]] [[#A1_ID:]] [[#ST_VAR_ID]] [[#CONST_0]] [[#CONST_0]]
; CHECK: Load [[#INT_TYPE]] [[#A1_LOAD_ID:]] [[#A1_ID]] 2 4
; CHECK: InBoundsPtrAccessChain [[#PTR_INT_TYPE_ID]] [[#B2_ID:]] [[#ST_VAR_ID]] [[#CONST_0]] [[#CONST_1]]
; CHECK: Load [[#INT_TYPE]] [[#B2_LOAD_ID:]] [[#B2_ID]] 2 4
; CHECK: IAdd [[#INT_TYPE]] [[#ADD_ID:]] [[#A1_LOAD_ID]] [[#B2_LOAD_ID]]
; CHECK: InBoundsPtrAccessChain [[#PTR_INT_TYPE_ID]] [[#C3_ID:]] [[#ST_VAR_ID]] [[#CONST_0]] [[#CONST_2]]
; CHECK: Load [[#INT_TYPE]] [[#C3_LOAD_ID:]] [[#C3_ID]] 2 4
; CHECK: IAdd [[#INT_TYPE]] [[#]] [[#ADD_ID]] [[#C3_LOAD_ID]]

; CHECK-LLVM: %a = getelementptr inbounds %struct.ST, ptr %st, i32 0, i32 0
; CHECK-LLVM: %b = getelementptr inbounds %struct.ST, ptr %st, i32 0, i32 1
; CHECK-LLVM: %c = getelementptr inbounds %struct.ST, ptr %st, i32 0, i32 2
; CHECK-LLVM: %a1 = getelementptr inbounds %struct.ST, ptr %st, i32 0, i32 0
; CHECK-LLVM: %b2 = getelementptr inbounds %struct.ST, ptr %st, i32 0, i32 1
; CHECK-LLVM: %c3 = getelementptr inbounds %struct.ST, ptr %st, i32 0, i32 2

define dso_local spir_func i32 @func() {
entry:

  %st = alloca %struct.ST, align 4
  %a = getelementptr inbounds %struct.ST, %struct.ST* %st, i32 0, i32 0
  store i32 1, i32* %a, align 4
  %b = getelementptr inbounds %struct.ST, %struct.ST* %st, i32 0, i32 1
  store i32 2, i32* %b, align 4
  %c = getelementptr inbounds %struct.ST, %struct.ST* %st, i32 0, i32 2
  store i32 3, i32* %c, align 4
  %a1 = getelementptr inbounds %struct.ST, %struct.ST* %st, i32 0, i32 0
  %0 = load i32, i32* %a1, align 4
  %b2 = getelementptr inbounds %struct.ST, %struct.ST* %st, i32 0, i32 1
  %1 = load i32, i32* %b2, align 4
  %add = add nsw i32 %0, %1
  %c3 = getelementptr inbounds %struct.ST, %struct.ST* %st, i32 0, i32 2
  %2 = load i32, i32* %c3, align 4
  %add4 = add nsw i32 %add, %2
  ret i32 %add4
}
