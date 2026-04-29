; Negative test: llvm.debugtrap should NOT produce OpAbortKHR.
; Only llvm.trap and llvm.ubsantrap are translated to OpAbortKHR. The
; debugtrap variant is currently dropped (return nullptr). This test ensures
; it doesn't accidentally trigger the abort path.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_abort -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; ---- debugtrap: no AbortKHR, unreachable still present ----
; CHECK-SPIRV-NOT: AbortKHR
; CHECK-SPIRV: Function
; CHECK-SPIRV: Label
; CHECK-SPIRV: Unreachable
; CHECK-SPIRV: FunctionEnd

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func void @uses_debugtrap() {
entry:
  call void @llvm.debugtrap()
  unreachable
}

declare void @llvm.debugtrap() #0

attributes #0 = { cold noreturn nounwind }
