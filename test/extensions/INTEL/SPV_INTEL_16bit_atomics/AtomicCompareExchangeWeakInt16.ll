; The translator intentionally emits OpAtomicCompareExchange for
; __spirv_AtomicCompareExchangeWeak, since OpAtomicCompareExchangeWeak is
; deprecated and has identical semantics.

; RUN: llvm-spirv %s --spirv-ext=+SPV_INTEL_16bit_atomics -o %t.spv
; RUN: llvm-spirv -to-text %t.spv -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv --spirv-target-env=SPV-IR -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM-SPV

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG: Capability Int16
; CHECK-SPIRV-DAG: Capability AtomicInt16CompareExchangeINTEL
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_16bit_atomics"
; CHECK-SPIRV-NOT: Capability Int16AtomicsINTEL

; CHECK-SPIRV: TypeInt [[SHORT:[0-9]+]] 16 0

define dso_local spir_func i16 @test_AtomicCompareExchangeWeak_i16(ptr addrspace(1) %Arg) {
entry:
  ; CHECK-SPIRV: AtomicCompareExchange [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z29__spirv_AtomicCompareExchangePU3AS1siiiss(
  %ret = tail call spir_func i16 @_Z33__spirv_AtomicCompareExchangeWeakPU3AS1siiiss(ptr addrspace(1) %Arg, i32 1, i32 896, i32 896, i16 42, i16 128)
  ret i16 %ret
}

declare dso_local spir_func i16 @_Z33__spirv_AtomicCompareExchangeWeakPU3AS1siiiss(ptr addrspace(1), i32, i32, i32, i16, i16)
