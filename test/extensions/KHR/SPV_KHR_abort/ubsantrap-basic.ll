; Test: llvm.ubsantrap translates to OpAbortKHR with the i8 failure-kind
; argument zero-extended to a 32-bit integer Message operand. The reverse
; translation produces the SPIR-V friendly call to __spirv_AbortKHR followed
; by an `unreachable` terminator.

; --- Positive: extension enabled ---
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_abort -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; Round-trip: SPIR-V binary -> LLVM IR
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; Round-trip with explicit SPV-IR target environment
; RUN: llvm-spirv -r %t.spv -o %t.rev.spv-ir.bc --spirv-target-env=SPV-IR
; RUN: llvm-dis < %t.rev.spv-ir.bc | FileCheck %s --check-prefix=CHECK-LLVM

; FIXME: enable the following run when the translator CI is updated to a new
; verion of the SPIR-V Tools that includes the support for the SPV_KHR_abort
; extension.
; RUN: not spirv-val %t.spv

; --- Negative: extension not enabled ---
; RUN: llvm-spirv %t.bc -spirv-text -o %t.noext.spt
; RUN: FileCheck < %t.noext.spt %s --check-prefix=CHECK-NO-EXT

; ---- SPIR-V text: extension, capability, and instruction present ----
; CHECK-SPIRV-DAG: Extension "SPV_KHR_abort"
; CHECK-SPIRV-DAG: Capability AbortKHR
; CHECK-SPIRV: TypeInt [[#I32Ty:]] 32
; The i8 failure-kind operand (7) is forwarded as a 32-bit zero-extended
; constant Message operand to OpAbortKHR.
; CHECK-SPIRV: Constant [[#I32Ty]] [[#MsgId:]] 7
; CHECK-SPIRV: Function
; CHECK-SPIRV: Label
; CHECK-SPIRV: AbortKHR [[#I32Ty]] [[#MsgId]]
; CHECK-SPIRV: FunctionEnd

; ---- Round-trip recovers a SPIR-V friendly call + unreachable ----
; CHECK-LLVM: call spir_func void @{{.*__spirv_AbortKHR.*}}(i32 7){{.*}}#[[#ATTR:]]
; CHECK-LLVM-NEXT: unreachable
; CHECK-LLVM: attributes #[[#ATTR]] = {{{.*}}noreturn{{.*}}}

; ---- Without extension: no AbortKHR emitted ----
; CHECK-NO-EXT-NOT: AbortKHR

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func void @ubsantrap_simple() {
entry:
  call void @llvm.ubsantrap(i8 7)
  unreachable
}

declare void @llvm.ubsantrap(i8) #0

attributes #0 = { cold noreturn nounwind }
