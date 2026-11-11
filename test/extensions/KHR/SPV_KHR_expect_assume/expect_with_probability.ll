; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_expect_assume -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV-NO-EXT
; RUN: llvm-spirv %t.bc -o %t.noext.spv
; RUN: spirv-val %t.noext.spv

; OpExpectKHR has no probability operand, the hint is kept only if the
; probability is above 0.5.

; CHECK-SPIRV: Capability ExpectAssumeKHR
; CHECK-SPIRV: Function
; CHECK-SPIRV: ExpectKHR
; CHECK-SPIRV: FunctionEnd
; CHECK-SPIRV: Function
; CHECK-SPIRV-NOT: ExpectKHR
; CHECK-SPIRV: FunctionEnd
; CHECK-SPIRV: Function
; CHECK-SPIRV-NOT: ExpectKHR
; CHECK-SPIRV: FunctionEnd

; CHECK-LLVM-LABEL: @high_prob(
; CHECK-LLVM: call i64 @llvm.expect.i64(i64 %x, i64 1)
; CHECK-LLVM-LABEL: @low_prob(
; CHECK-LLVM-NOT: @llvm.expect
; CHECK-LLVM-LABEL: @half_prob(
; CHECK-LLVM-NOT: @llvm.expect

; CHECK-SPIRV-NO-EXT-NOT: ExpectKHR

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func i1 @high_prob(i64 %x) {
  %e = call i64 @llvm.expect.with.probability.i64(i64 %x, i64 1, double 8.000000e-01)
  %c = icmp eq i64 %e, 0
  ret i1 %c
}

define spir_func i1 @low_prob(i64 %x) {
  %e = call i64 @llvm.expect.with.probability.i64(i64 %x, i64 1, double 1.000000e-01)
  %c = icmp eq i64 %e, 0
  ret i1 %c
}

define spir_func i1 @half_prob(i64 %x) {
  %e = call i64 @llvm.expect.with.probability.i64(i64 %x, i64 1, double 5.000000e-01)
  %c = icmp eq i64 %e, 0
  ret i1 %c
}

declare i64 @llvm.expect.with.probability.i64(i64, i64, double)
