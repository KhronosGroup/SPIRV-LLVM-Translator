; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_INTEL_16bit_atomics
; RUN: llvm-spirv -to-text %t.spv -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r --spirv-target-env=CL2.0 %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc 
; RUN: FileCheck < %t.rev.ll %s --check-prefixes=CHECK-LLVM

; RUN: llvm-spirv -r --spirv-target-env="SPV-IR" %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc 
; RUN: FileCheck < %t.rev.ll %s --check-prefixes=CHECK-LLVM-SPV-IR

; CHECK-SPIRV: Capability Int16
; CHECK-SPIRV: Capability AtomicInt16CompareExchangeINTEL
; CHECK-SPIRV: Capability Int16AtomicsINTEL
; CHECK-SPIRV: AtomicOr

; CHECK-LLVM: call spir_func i16 @_Z24atomic_fetch_or_explicitPU3AS4VU7_Atomicss12memory_order12memory_scope
; CHECK-LLVM-SPV-IR: call spir_func i16 @_Z16__spirv_AtomicOrPU3AS1siis

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64"

@ui = common dso_local addrspace(1) global i16 0, align 4

define dso_local spir_func void @test() {
entry:
  %0 = atomicrmw or ptr addrspace(1) @ui, i16 42 release
  ret void
}
