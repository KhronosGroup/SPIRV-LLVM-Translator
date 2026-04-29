; Multiple basic blocks: some trap, some don't.
; Verifies that:
;   1. Non-trap blocks are completely unaffected (normal terminators preserved)
;   2. Multiple trap blocks in the same function each get their own OpAbortKHR
;   3. No cross-contamination between blocks

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_abort -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; FIXME: enable the following run when the translator CI is updated to a new
; verion of the SPIR-V Tools that includes the support for the SPV_KHR_abort
; extension.
; RUN: not spirv-val %t.spv

; Round-trip
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; ---- SPIR-V checks ----
; CHECK-SPIRV-DAG: Capability AbortKHR
; CHECK-SPIRV-DAG: Extension "SPV_KHR_abort"

; Function with multiple paths
; CHECK-SPIRV: Function
;
; Entry: conditional branch
; CHECK-SPIRV: BranchConditional
;
; Work block: second conditional branch
; CHECK-SPIRV: BranchConditional
;
; Return block: normal return
; CHECK-SPIRV: ReturnValue
;
; First trap block
; CHECK-SPIRV: AbortKHR
;
; Second trap block
; CHECK-SPIRV: AbortKHR
; CHECK-SPIRV: FunctionEnd

; ---- Round-trip ----
; CHECK-LLVM: define spir_func i32 @multi_trap
; CHECK-LLVM: br i1
; CHECK-LLVM: br i1
; CHECK-LLVM: ret i32
; CHECK-LLVM: call spir_func void @{{.*__spirv_AbortKHR.*}}(i32 -1)
; CHECK-LLVM-NEXT: unreachable
; CHECK-LLVM: call spir_func void @{{.*__spirv_AbortKHR.*}}(i32 -1)
; CHECK-LLVM-NEXT: unreachable

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func i32 @multi_trap(i32 %x) {
entry:
  %cmp1 = icmp sgt i32 %x, 0
  br i1 %cmp1, label %work, label %err1

work:
  %result = mul i32 %x, 42
  %cmp2 = icmp slt i32 %result, 1000
  br i1 %cmp2, label %ret, label %err2

ret:
  ret i32 %result

err1:
  call void @llvm.trap()
  unreachable

err2:
  call void @llvm.trap()
  unreachable
}

declare void @llvm.trap() #0

attributes #0 = { cold noreturn nounwind }
