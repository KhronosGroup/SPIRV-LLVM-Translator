; bfloat16 is not a valid type for atomic compare-exchange.

; RUN: not llvm-spirv %s --spirv-ext=+SPV_INTEL_16bit_atomics,+SPV_KHR_bfloat16 -o %t.spv 2>&1 | FileCheck %s

; CHECK: InvalidInstruction: Can't translate llvm instruction:
; CHECK-NEXT: AtomicCompareExchange
; CHECK-NEXT: bfloat16 is not a supported type for this atomic instruction

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define dso_local spir_func bfloat @test_AtomicCompareExchange_bfloat(ptr addrspace(1) %Arg) {
entry:
  %ret = tail call spir_func bfloat @_Z29__spirv_AtomicCompareExchangePU3AS1DF16biiiDF16bDF16b(ptr addrspace(1) %Arg, i32 1, i32 896, i32 896, bfloat 1.000000e+00, bfloat 2.000000e+00)
  ret bfloat %ret
}

declare dso_local spir_func bfloat @_Z29__spirv_AtomicCompareExchangePU3AS1DF16biiiDF16bDF16b(ptr addrspace(1), i32, i32, i32, bfloat, bfloat)
