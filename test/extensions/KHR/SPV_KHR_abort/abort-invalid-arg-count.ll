; Negative tests for the SPIR-V translator's handling of `__spirv_AbortKHR`.
; OpAbortKHR takes exactly one Message operand; calls with any other arity must
; be rejected by the translator with a clear diagnostic rather than producing
; ill-formed SPIR-V.

; RUN: split-file %s %t

; RUN: llvm-as %t/no-args.ll -o %t/no-args.bc
; RUN: not llvm-spirv %t/no-args.bc --spirv-ext=+SPV_KHR_abort -o /dev/null 2>&1 | FileCheck %s --check-prefix=CHECK-ARG-COUNT

; RUN: llvm-as %t/two-args.ll -o %t/two-args.bc
; RUN: not llvm-spirv %t/two-args.bc --spirv-ext=+SPV_KHR_abort -o /dev/null 2>&1 | FileCheck %s --check-prefix=CHECK-ARG-COUNT

; CHECK-ARG-COUNT: InvalidInstruction
; CHECK-ARG-COUNT: __spirv_AbortKHR must be called with exactly one Message argument

;--- no-args.ll
target triple = "spir64-unknown-unknown"

define spir_func void @abort_no_args() {
entry:
  call spir_func void @_Z16__spirv_AbortKHRv()
  ret void
}

declare spir_func void @_Z16__spirv_AbortKHRv()

;--- two-args.ll
target triple = "spir64-unknown-unknown"

define spir_func void @abort_two_args(i32 %a, i32 %b) {
entry:
  call spir_func void @_Z16__spirv_AbortKHRii(i32 %a, i32 %b)
  ret void
}

declare spir_func void @_Z16__spirv_AbortKHRii(i32, i32)
