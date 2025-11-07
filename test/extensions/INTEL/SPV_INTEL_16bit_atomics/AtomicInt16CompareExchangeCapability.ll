; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_INTEL_16bit_atomics
; RUN: llvm-spirv -to-text %t.spv -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r --spirv-target-env=CL2.0 %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc 
; RUN: FileCheck < %t.rev.ll %s --check-prefixes=CHECK-LLVM

; CHECK-SPIRV: Capability Int16
; CHECK-SPIRV: Capability AtomicInt16CompareExchangeINTEL
; CHECK-SPIRV-NOT: Capability Int16AtomicsINTEL

; CHECK-SPIRV-DAG: Constant [[#]] [[#CrossDeviceScope:]] 0
; CHECK-SPIRV-DAG: Constant [[#]] [[#Release:]] 4
; CHECK-SPIRV-DAG: Constant [[#]] [[#SequentiallyConsistent:]] 16
; CHECK-SPIRV-DAG: Constant [[#]] [[#Acquire:]] 2

; CHECK-LLVM: call spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicss12memory_order12memory_scope
; CHECK-LLVM: call spir_func i16 @_Z20atomic_load_explicitPU3AS4VU7_Atomics12memory_order12memory_scope
; CHECK-LLVM: call spir_func i16 @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicss12memory_order12memory_scope
; CHECK-LLVM: call spir_func i1 @_Z39atomic_compare_exchange_strong_explicitPU3AS4VU7_AtomicsPU3AS4ss12memory_orderS4_12memory_scope

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64"

@ui = common dso_local addrspace(1) global i16 0, align 4
; Function Attrs: nounwind
define dso_local spir_func void @test() {
entry:
; CHECK-SPIRV: {{(Variable|UntypedVariableKHR)}} [[#]] [[#PTR:]] 7
  %0 = alloca i16
; CHECK-SPIRV: AtomicStore [[#PTR]] [[#CrossDeviceScope]] [[#Release]] [[#]]
  store atomic i16 0, ptr %0 release, align 4
; CHECK-SPIRV: AtomicLoad [[#]] [[#]] [[#PTR]] [[#CrossDeviceScope]] [[#Acquire]]
  %2 = load atomic i16, ptr %0 acquire, align 4
; CHECK-SPIRV: AtomicExchange [[#]] [[#]] [[#]] [[#CrossDeviceScope]] [[#]] {{.+}}
  %4 = atomicrmw xchg ptr addrspace(1) @ui, i16 42 acq_rel
; CHECK-SPIRV: AtomicCompareExchange [[#]] [[#]] [[#]] [[#CrossDeviceScope]] [[#SequentiallyConsistent]] [[#Acquire]] {{.+}}
  %5 = cmpxchg ptr %0, i16 128, i16 456 seq_cst acquire

  ret void
}
