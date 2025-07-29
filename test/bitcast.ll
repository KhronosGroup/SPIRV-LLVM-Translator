; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s
; RUN: spirv-val %t.spv

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64"

; CHECK-DAG: TypeInt [[#TyInt32:]] 32 0
; CHECK-DAG: TypeInt [[#TyInt16:]] 16 0
; CHECK-DAG: TypeFloat [[#TyHalf:]] 16
; CHECK-DAG: TypeVector [[#vec4_int_16:]] [[#TyInt16]] 4
; CHECK-DAG: TypeVector [[#vec4_float_16:]] [[#TyHalf]] 4
; CHECK-DAG: FunctionParameter [[#TyInt32]] [[#Arg32:]]
; CHECK-DAG: UConvert [[#TyInt16]] [[#Arg16:]] [[#Arg32]]
; CHECK-DAG: Bitcast [[#TyHalf]] [[#ValHalf:]] [[#Arg16]]
; CHECK-DAG: FMul [[#TyHalf]] [[#ValHalf2:]] [[#ValHalf]] [[#ValHalf]]
; CHECK-DAG: Bitcast [[#TyInt16]] [[#Res16:]] [[#ValHalf2]]
; CHECK-DAG: ReturnValue [[#Res16]]

define i16 @foo(i32 %arg) {
entry:
  %op16 = trunc i32 %arg to i16
  %val = bitcast i16 %op16 to half
  %val2 = fmul half %val, %val
  %res = bitcast half %val2 to i16
  ret i16 %res
}

define <4 x i16> @test_vector_half4(<4 x half> nofpclass(nan inf) %p1) {
entry:
  ; CHECK: FunctionParameter [[#vec4_float_16]] [[#arg0:]]
  ; CHECK: Bitcast [[#vec4_int_16]] [[#Res1:]] [[#arg0]]
  %0 = bitcast <4 x half> %p1 to <4 x i16>
  ; CHECK: ReturnValue [[#Res1]]
  ret <4 x i16> %0
}
