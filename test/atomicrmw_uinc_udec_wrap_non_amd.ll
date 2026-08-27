; Translating uinc_wrap/udec_wrap into an imported helper call is an AMD internal
; spirv builtin. On any other vendor the atomicrmw must reach the writer and be
; reported as unsupported (positive case: atomicrmw_uinc_udec_wrap.ll).
;
; The writer stops at the first unsupported instruction, so each operation/triple
; combination is translated from its own copy of the module.

; RUN: sed -e 's/OP/uinc_wrap/' -e 's/TRIPLE/spirv64-unknown-unknown/' %s > %t.ll
; RUN: not llvm-spirv %t.ll -o %t.spv 2>&1 | FileCheck %s --check-prefix=CHECK-UINC

; RUN: sed -e 's/OP/udec_wrap/' -e 's/TRIPLE/spirv64-unknown-unknown/' %s > %t.ll
; RUN: not llvm-spirv %t.ll -o %t.spv 2>&1 | FileCheck %s --check-prefix=CHECK-UDEC

; RUN: sed -e 's/OP/uinc_wrap/' -e 's/TRIPLE/spir64-unknown-unknown/' %s > %t.ll
; RUN: not llvm-spirv %t.ll -o %t.spv 2>&1 | FileCheck %s --check-prefix=CHECK-UINC

; RUN: sed -e 's/OP/udec_wrap/' -e 's/TRIPLE/spir64-unknown-unknown/' %s > %t.ll
; RUN: not llvm-spirv %t.ll -o %t.spv 2>&1 | FileCheck %s --check-prefix=CHECK-UDEC

; CHECK-UINC: Atomic uinc_wrap is not supported in SPIR-V!
; CHECK-UDEC: Atomic udec_wrap is not supported in SPIR-V!

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "TRIPLE"

@ui = common dso_local addrspace(1) global i32 0, align 4

define spir_func void @test_non_amd() {
entry:
  %r = atomicrmw OP ptr addrspace(1) @ui, i32 42 seq_cst
  ret void
}
