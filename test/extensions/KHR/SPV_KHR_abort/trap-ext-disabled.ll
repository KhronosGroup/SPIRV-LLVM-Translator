; Negative test: explicitly disabling SPV_KHR_abort with --spirv-ext=-SPV_KHR_abort
; ensures llvm.trap falls back to being dropped (no OpAbortKHR emitted).
;
; Also tests the case where all extensions are enabled EXCEPT SPV_KHR_abort.

; Enable all then disable abort specifically
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+all,-SPV_KHR_abort -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-DISABLED

; Explicit disable
; RUN: llvm-spirv %t.bc --spirv-ext=-SPV_KHR_abort -spirv-text -o %t.spt2
; RUN: FileCheck < %t.spt2 %s --check-prefix=CHECK-DISABLED

; Verify both produce valid SPIR-V
; RUN: llvm-spirv %t.bc --spirv-ext=+all,-SPV_KHR_abort -o %t.spv
; RUN: spirv-val %t.spv

; ---- Extension disabled: no abort capability, extension, or instruction ----
; CHECK-DISABLED-NOT: Capability AbortKHR
; CHECK-DISABLED-NOT: Extension "SPV_KHR_abort"
; CHECK-DISABLED-NOT: AbortKHR

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func void @trap_with_ext_disabled() {
entry:
  call void @llvm.trap()
  unreachable
}

declare void @llvm.trap() #0

attributes #0 = { cold noreturn nounwind }
