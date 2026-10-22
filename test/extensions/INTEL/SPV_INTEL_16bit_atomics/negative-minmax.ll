; Check that bfloat16 atomic min/max and load/store/exchange require both
; SPV_INTEL_16bit_atomics and SPV_KHR_bfloat16.

; RUN: not llvm-spirv %s --spirv-ext=+SPV_INTEL_16bit_atomics,+SPV_EXT_shader_atomic_float_min_max -o %t.nobf.spv 2>&1 | FileCheck %s --check-prefix=CHECK-NO-BF
; RUN: not llvm-spirv %s --spirv-ext=+SPV_KHR_bfloat16,+SPV_EXT_shader_atomic_float_min_max -o %t.noatom.spv 2>&1 | FileCheck %s --check-prefix=CHECK-NO-ATOM

; CHECK-NO-BF: RequiresExtension: Feature requires the following SPIR-V extension:
; CHECK-NO-BF-NEXT: SPV_KHR_bfloat16
; CHECK-NO-BF-NEXT: NOTE: LLVM module contains bfloat type, translation of which requires this extension

; CHECK-NO-ATOM: RequiresExtension: Feature requires the following SPIR-V extension:
; CHECK-NO-ATOM-NEXT: SPV_INTEL_16bit_atomics

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define dso_local spir_func bfloat @test_AtomicFMinEXT_bfloat(ptr addrspace(1) %Arg) {
entry:
  %ret = tail call spir_func bfloat @_Z21__spirv_AtomicFMinEXTPU3AS1DF16biiDF16b(ptr addrspace(1) %Arg, i32 1, i32 896, bfloat 1.000000e+00)
  ret bfloat %ret
}

declare dso_local spir_func bfloat @_Z21__spirv_AtomicFMinEXTPU3AS1DF16biiDF16b(ptr addrspace(1), i32, i32, bfloat)
