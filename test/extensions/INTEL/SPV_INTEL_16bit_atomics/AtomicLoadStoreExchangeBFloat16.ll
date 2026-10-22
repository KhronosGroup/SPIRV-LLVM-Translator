; RUN: llvm-spirv %s --spirv-ext=+SPV_INTEL_16bit_atomics,+SPV_KHR_bfloat16 -o %t.spv
; RUN: llvm-spirv -to-text %t.spv -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv --spirv-target-env=SPV-IR -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM-SPV

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG: Capability AtomicBFloat16LoadStoreINTEL
; CHECK-SPIRV-DAG: Capability BFloat16TypeKHR
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_16bit_atomics"
; CHECK-SPIRV-DAG: Extension "SPV_KHR_bfloat16"

; CHECK-SPIRV: TypeFloat [[BFLOAT:[0-9]+]] 16 0

define dso_local spir_func bfloat @test_AtomicLoad_bfloat(ptr addrspace(1) %Arg) {
entry:
  ; CHECK-SPIRV: AtomicLoad [[BFLOAT]]
  ; CHECK-LLVM-SPV: call spir_func bfloat @_Z18__spirv_AtomicLoadPU3AS1DF16bii(
  %ret = tail call spir_func bfloat @_Z18__spirv_AtomicLoadPU3AS1DF16bii(ptr addrspace(1) %Arg, i32 1, i32 896)
  ret bfloat %ret
}

define dso_local spir_func void @test_AtomicStore_bfloat(ptr addrspace(1) %Arg) {
entry:
  ; CHECK-SPIRV: AtomicStore
  ; CHECK-LLVM-SPV: call spir_func void @_Z19__spirv_AtomicStorePU3AS1DF16biiDF16b(
  tail call spir_func void @_Z19__spirv_AtomicStorePU3AS1DF16biiDF16b(ptr addrspace(1) %Arg, i32 1, i32 896, bfloat 1.000000e+00)
  ret void
}

define dso_local spir_func bfloat @test_AtomicExchange_bfloat(ptr addrspace(1) %Arg) {
entry:
  ; CHECK-SPIRV: AtomicExchange [[BFLOAT]]
  ; CHECK-LLVM-SPV: call spir_func bfloat @_Z22__spirv_AtomicExchangePU3AS1DF16biiDF16b(
  %ret = tail call spir_func bfloat @_Z22__spirv_AtomicExchangePU3AS1DF16biiDF16b(ptr addrspace(1) %Arg, i32 1, i32 896, bfloat 1.000000e+00)
  ret bfloat %ret
}

declare dso_local spir_func bfloat @_Z18__spirv_AtomicLoadPU3AS1DF16bii(ptr addrspace(1), i32, i32)
declare dso_local spir_func void @_Z19__spirv_AtomicStorePU3AS1DF16biiDF16b(ptr addrspace(1), i32, i32, bfloat)
declare dso_local spir_func bfloat @_Z22__spirv_AtomicExchangePU3AS1DF16biiDF16b(ptr addrspace(1), i32, i32, bfloat)
