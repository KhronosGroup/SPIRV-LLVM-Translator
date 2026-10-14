; RUN: llvm-as %s -o %t.bc
; RUN: not llvm-spirv %t.bc -o %t.spv 2>&1 | FileCheck %s

; CHECK: InvalidFunctionCall: Unexpected llvm intrinsic:
; CHECK-NEXT: i1 operands are not supported.

target triple = "spir64-unknown-unknown"

define spir_func { i1, i1 } @sadd_i1(i1 %a, i1 %b) {
entry:
  %r = call { i1, i1 } @llvm.sadd.with.overflow.i1(i1 %a, i1 %b)
  ret { i1, i1 } %r
}
