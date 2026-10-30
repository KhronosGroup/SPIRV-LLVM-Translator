; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s
; RUN: spirv-val %t.spv

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; CHECK: Name [[test_smul:[0-9]+]] "test_smul"
; CHECK: Name [[test_umul_scale0:[0-9]+]] "test_umul_scale0"
; CHECK: Name [[test_umul_full:[0-9]+]] "test_umul_full"
; CHECK: Name [[test_smul_vec:[0-9]+]] "test_smul_vec"

; CHECK-DAG: TypeInt [[i32:[0-9]+]] 32 0
; CHECK-DAG: TypeInt [[i64:[0-9]+]] 64 0
; CHECK-DAG: Constant [[i32]] [[three:[0-9]+]] 3
; CHECK-DAG: Constant [[i32]] [[twentynine:[0-9]+]] 29
; CHECK-DAG: TypeStruct [[i32x2:[0-9]+]] [[i32]] [[i32]]
; CHECK-DAG: TypeVector [[v4i64:[0-9]+]] [[i64]] 4
; CHECK-DAG: TypeStruct [[v4i64x2:[0-9]+]] [[v4i64]] [[v4i64]]
; CHECK-DAG: Constant [[i64]] [[five_s:[0-9]+]] 5 0
; CHECK-DAG: Constant [[i64]] [[fiftynine_s:[0-9]+]] 59 0
; CHECK-DAG: ConstantComposite [[v4i64]] [[five:[0-9]+]] [[five_s]] [[five_s]] [[five_s]] [[five_s]]
; CHECK-DAG: ConstantComposite [[v4i64]] [[fiftynine:[0-9]+]] [[fiftynine_s]] [[fiftynine_s]] [[fiftynine_s]] [[fiftynine_s]]

define spir_func i32 @test_smul(i32 %a, i32 %b) {
  %r = call i32 @llvm.smul.fix.i32(i32 %a, i32 %b, i32 3)
  ret i32 %r
}

; CHECK: Function [[i32]] [[test_smul]]
; CHECK-NEXT: FunctionParameter [[i32]] [[a:[0-9]+]]
; CHECK-NEXT: FunctionParameter [[i32]] [[b:[0-9]+]]
; CHECK-EMPTY:
; CHECK-NEXT: Label
; CHECK-NEXT: SMulExtended [[i32x2]] [[mul:[0-9]+]] [[a]] [[b]]
; CHECK-NEXT: CompositeExtract [[i32]] [[hi:[0-9]+]] [[mul]] 1
; CHECK-NEXT: CompositeExtract [[i32]] [[lo:[0-9]+]] [[mul]] 0
; CHECK-NEXT: ShiftRightLogical [[i32]] [[lobits:[0-9]+]] [[lo]] [[three]]
; CHECK-NEXT: ShiftLeftLogical [[i32]] [[hibits:[0-9]+]] [[hi]] [[twentynine]]
; CHECK-NEXT: BitwiseOr [[i32]] [[res:[0-9]+]] [[hibits]] [[lobits]]
; CHECK-NEXT: ReturnValue [[res]]

define spir_func i32 @test_umul_scale0(i32 %a, i32 %b) {
  %r = call i32 @llvm.umul.fix.i32(i32 %a, i32 %b, i32 0)
  ret i32 %r
}

; CHECK: Function [[i32]] [[test_umul_scale0]]
; CHECK-NEXT: FunctionParameter [[i32]] [[a:[0-9]+]]
; CHECK-NEXT: FunctionParameter [[i32]] [[b:[0-9]+]]
; CHECK-EMPTY:
; CHECK-NEXT: Label
; CHECK-NEXT: IMul [[i32]] [[res:[0-9]+]] [[a]] [[b]]
; CHECK-NEXT: ReturnValue [[res]]

define spir_func i32 @test_umul_full(i32 %a, i32 %b) {
  %r = call i32 @llvm.umul.fix.i32(i32 %a, i32 %b, i32 32)
  ret i32 %r
}

; CHECK: Function [[i32]] [[test_umul_full]]
; CHECK-NEXT: FunctionParameter [[i32]] [[a:[0-9]+]]
; CHECK-NEXT: FunctionParameter [[i32]] [[b:[0-9]+]]
; CHECK-EMPTY:
; CHECK-NEXT: Label
; CHECK-NEXT: UMulExtended [[i32x2]] [[mul:[0-9]+]] [[a]] [[b]]
; CHECK-NEXT: CompositeExtract [[i32]] [[hi:[0-9]+]] [[mul]] 1
; CHECK-NEXT: ReturnValue [[hi]]

define spir_func <4 x i64> @test_smul_vec(<4 x i64> %a, <4 x i64> %b) {
  %r = call <4 x i64> @llvm.smul.fix.v4i64(<4 x i64> %a, <4 x i64> %b, i32 5)
  ret <4 x i64> %r
}

; CHECK: Function [[v4i64]] [[test_smul_vec]]
; CHECK-NEXT: FunctionParameter [[v4i64]] [[a:[0-9]+]]
; CHECK-NEXT: FunctionParameter [[v4i64]] [[b:[0-9]+]]
; CHECK-EMPTY:
; CHECK-NEXT: Label
; CHECK-NEXT: SMulExtended [[v4i64x2]] [[mul:[0-9]+]] [[a]] [[b]]
; CHECK-NEXT: CompositeExtract [[v4i64]] [[hi:[0-9]+]] [[mul]] 1
; CHECK-NEXT: CompositeExtract [[v4i64]] [[lo:[0-9]+]] [[mul]] 0
; CHECK-NEXT: ShiftRightLogical [[v4i64]] [[lobits:[0-9]+]] [[lo]] [[five]]
; CHECK-NEXT: ShiftLeftLogical [[v4i64]] [[hibits:[0-9]+]] [[hi]] [[fiftynine]]
; CHECK-NEXT: BitwiseOr [[v4i64]] [[res:[0-9]+]] [[hibits]] [[lobits]]
; CHECK-NEXT: ReturnValue [[res]]
