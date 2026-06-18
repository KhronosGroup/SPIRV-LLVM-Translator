; Regression for assertion `Id is not in map' in SPIRVModuleImpl::getEntry
; (https://github.com/intel/llvm/issues/22308): when SPV_KHR_poison_freeze
; is disabled, the writer ignores `freeze` by reusing its operand without
; rewriting IR users of the FreezeInst. If a phi back-edge references the
; freeze result (the freeze is defined after the phi in program order),
; the SPIR-V phi forward-references an unmapped id and the writer hits
; the assert at module serialization. The freeze must be stripped (and
; users rewritten) in regularize before SPIR-V emission.
;
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-NOEXT
;
; RUN: llvm-spirv %s -o %t.ext.spv --spirv-ext=+SPV_KHR_poison_freeze
; RUN: spirv-val %t.ext.spv
; RUN: llvm-spirv %t.ext.spv -to-text -o %t.ext.spt
; RUN: FileCheck < %t.ext.spt %s --check-prefix=CHECK-EXT

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; Without the extension, regularize strips the freeze from the IR and
; rewrites its users (the phi below), so no FreezeKHR is emitted.
; CHECK-NOEXT-NOT: Capability PoisonFreezeKHR
; CHECK-NOEXT-NOT: Extension "SPV_KHR_poison_freeze"
; CHECK-NOEXT-NOT: FreezeKHR

; With the extension, the freeze survives as OpFreezeKHR and the phi's
; back-edge operand references it, matching the source IR.
; CHECK-EXT-DAG: Capability PoisonFreezeKHR
; CHECK-EXT-DAG: Extension "SPV_KHR_poison_freeze"
; CHECK-EXT: Phi [[#]] [[#PHI:]] [[#]] [[#]] [[#FR:]] [[#]]
; CHECK-EXT: FreezeKHR [[#]] [[#FR]] [[#PHI]]

define spir_func void @f(i64 %n) {
entry:
  br label %loop
loop:
  %prev = phi i64 [ 0, %entry ], [ %fr, %loop ]
  %fr = freeze i64 %prev
  %c = icmp slt i64 %fr, %n
  br i1 %c, label %loop, label %exit
exit:
  ret void
}