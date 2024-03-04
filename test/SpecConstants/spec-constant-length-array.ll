; RUN: llvm-as %s -o - | llvm-spirv %t.bc -spirv-text -o %t
; RUN: FileCheck < %t %s

; CHECK: Decorate [[#I64_CONST:]] SpecId [[#]]
; CHECK: Decorate [[#I32_CONST:]] SpecId [[#]]
; CHECK: Decorate [[#I8_CONST:]] SpecId [[#]]
; CHECK: Decorate [[#SCLA_0:]] Alignment 4
; CHECK: Decorate [[#SCLA_1:]] Alignment 2
; CHECK: Decorate [[#SCLA_2:]] Alignment 16

; CHECK: TypeInt [[#I64_TY:]] 64
; CHECK: TypeInt [[#I32_TY:]] 32
; CHECK: TypeInt [[#I8_TY:]] 8

; CHECK: SpecConstant [[#I64_TY]] [[#LENGTH_0:]]
; CHECK: SpecConstant [[#I32_TY]] [[#LENGTH_1:]]
; CHECK: SpecConstant [[#I8_TY]] [[#LENGTH_2:]]

; CHECK: TypeFloat [[#FLOAT_TY:]] 32
; CHECK: TypePointer [[#FLOAT_PTR_TY:]] [[#FUNCTION_SC:]] [[#FLOAT_TY]]
; CHECK: TypeArray [[#ARR_TY_0:]] [[#FLOAT_TY]] [[#LENGTH_0]]
; CHECK: TypePointer [[#ARR_PTR_TY_0:]] [[#FUNCTION_SC]] [[#ARR_TY_0]]
; CHECK: TypePointer [[#I8_PTR_TY:]] [[#FUNCTION_SC]] [[#I8_TY]]
; CHECK: TypeArray [[#ARR_TY_1:]] [[#I8_TY]] [[#LENGTH_1]]
; CHECK: TypePointer [[#ARR_PTR_TY_1:]] [[#FUNCTION_SC]] [[#ARR_TY_1]]
; CHECK: TypeFloat [[#DOUBLE_TY:]] 64
; CHECK: TypeStruct [[#STR_TY:]] [[#DOUBLE_TY]] [[#DOUBLE_TY]]
; CHECK: TypePointer [[#STR_PTR_TY:]] [[#FUNCTION_SC]] [[#STR_TY]]
; CHECK: TypeArray [[#ARR_TY_2:]] [[#STR_TY]] [[#LENGTH_2]]
; CHECK: TypePointer [[#ARR_PTR_TY_2:]] [[#FUNCTION_SC]] [[#ARR_TY_2:]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%struct_type = type { double, double }

define spir_kernel void @test() {
 entry:
  %length0 = call i64 @_Z20__spirv_SpecConstantix(i32 0, i64 1), !SYCL_SPEC_CONST_SYM_ID !0
  %length1 = call i32 @_Z20__spirv_SpecConstantii(i32 1, i32 2), !SYCL_SPEC_CONST_SYM_ID !1
  %length2 = call i8 @_Z20__spirv_SpecConstantic(i32 2, i8 4), !SYCL_SPEC_CONST_SYM_ID !2

  ; CHECK: Variable [[#ARR_PTR_TY_0]] [[#SCLA_0]] [[#FUNCTION_SC]]
  ; CHECK: Bitcast [[#FLOAT_PTR_TY]] [[#]] [[#SCLA_0]]
  %scla0 = alloca float, i64 %length0, align 4

  ; CHECK: Variable [[#ARR_PTR_TY_1]] [[#SCLA_1]] [[#FUNCTION_SC]]
  ; CHECK: Bitcast [[#I8_PTR_TY]] [[#]] [[#SCLA_1]]
  %scla1 = alloca i8, i32 %length1, align 2

  ; CHECK: Variable [[#ARR_PTR_TY_2]] [[#SCLA_2]] [[#FUNCTION_SC]]
  ; CHECK: Bitcast [[#STR_PTR_TY]] [[#]] [[#SCLA_2]]
  %scla2 = alloca %struct_type, i8 %length2, align 16
  ret void
}

declare i8 @_Z20__spirv_SpecConstantic(i32, i8)
declare i32 @_Z20__spirv_SpecConstantii(i32, i32)
declare i64 @_Z20__spirv_SpecConstantix(i32, i64)

!0 = !{!"i64_spec_const", i32 0}
!1 = !{!"i32_spec_const", i32 1}
!2 = !{!"i8_spec_const", i32 2}
