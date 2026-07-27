; Multiplication of two boolean values must be translated to OpLogicalAnd,
; since OpIMul requires integer operands and OpTypeBool is not an integer type.
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-NOT: IMul

define spir_func i1 @bool_mul(i1 %a, i1 %b) {
  %c = mul i1 %a, %b
  ret i1 %c
}
; CHECK-SPIRV: LogicalAnd
; CHECK-LLVM: define spir_func i1 @bool_mul(i1 %a, i1 %b)
; CHECK-LLVM: and i1 %a, %b

define spir_func i1 @bool_mul_nsw(i1 %a, i1 %b) {
  %c = mul nsw i1 %a, %b
  ret i1 %c
}
; CHECK-SPIRV: LogicalAnd
; CHECK-LLVM: define spir_func i1 @bool_mul_nsw(i1 %a, i1 %b)
; CHECK-LLVM: and i1 %a, %b

define spir_func i1 @bool_mul_nuw(i1 %a, i1 %b) {
  %c = mul nuw i1 %a, %b
  ret i1 %c
}
; CHECK-SPIRV: LogicalAnd
; CHECK-LLVM: define spir_func i1 @bool_mul_nuw(i1 %a, i1 %b)
; CHECK-LLVM: and i1 %a, %b

define spir_func <4 x i1> @vec_bool_mul(<4 x i1> %a, <4 x i1> %b) {
  %c = mul <4 x i1> %a, %b
  ret <4 x i1> %c
}
; CHECK-SPIRV: LogicalAnd
; CHECK-LLVM: define spir_func <4 x i1> @vec_bool_mul(<4 x i1> %a, <4 x i1> %b)
; CHECK-LLVM: and <4 x i1> %a, %b
