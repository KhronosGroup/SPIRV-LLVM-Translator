; Check that bfloat16 atomic load/store/exchange requires SPV_KHR_bfloat16.

; RUN: not llvm-spirv %s --spirv-ext=+SPV_INTEL_16bit_atomics -o %t.nobf.spv 2>&1 | FileCheck %s --check-prefix=CHECK-NO-BF

; For now, expect that compilation will succeed without declaring any
; capabilities or extensions when the 16-bit atomics extension is not enabled.
; RUN: llvm-spirv %s --spirv-ext=+SPV_KHR_bfloat16 -o %t.noatom.spv
; Note: This is not a valid SPIR-V module!
; RUN: llvm-spirv -to-text %t.noatom.spv -o %t.noatom.spt
; RUN: FileCheck < %t.noatom.spt %s --check-prefix=CHECK-NO-ATOM

; CHECK-NO-BF: RequiresExtension: Feature requires the following SPIR-V extension:
; CHECK-NO-BF-NEXT: SPV_KHR_bfloat16
; CHECK-NO-BF-NEXT: NOTE: LLVM module contains bfloat type, translation of which requires this extension

; CHECK-NO-ATOM: Capability BFloat16TypeKHR
; CHECK-NO-ATOM-NOT: Capability AtomicBFloat16LoadStoreINTEL
; CHECK-NO-ATOM-NOT: Capability Int16AtomicsINTEL
; CHECK-NO-ATOM-NOT: Extension "SPV_INTEL_16bit_atomics"

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define dso_local spir_func bfloat @test_AtomicLoad_bfloat(ptr addrspace(1) %Arg) {
entry:
  %ret = tail call spir_func bfloat @_Z18__spirv_AtomicLoadPU3AS1DF16bii(ptr addrspace(1) %Arg, i32 1, i32 896)
  ret bfloat %ret
}

declare dso_local spir_func bfloat @_Z18__spirv_AtomicLoadPU3AS1DF16bii(ptr addrspace(1), i32, i32)
