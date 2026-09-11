; Check all read-modify-write atomic instructions that require the
; Int16AtomicsINTEL capability when operating on 16-bit integers.

; RUN: llvm-spirv %s --spirv-ext=+SPV_INTEL_16bit_atomics -o %t.spv
; RUN: llvm-spirv -to-text %t.spv -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv --spirv-target-env=SPV-IR -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM-SPV

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG: Capability Int16
; CHECK-SPIRV-DAG: Capability Int16AtomicsINTEL
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_16bit_atomics"

; CHECK-SPIRV: TypeInt [[SHORT:[0-9]+]] 16 0

define dso_local spir_func void @test_i16_rmw(ptr addrspace(1) %Arg) {
entry:
  ; CHECK-SPIRV: AtomicIAdd [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z18__spirv_AtomicIAddPU3AS1siis(
  %a = tail call spir_func i16 @_Z18__spirv_AtomicIAddPU3AS1siis(ptr addrspace(1) %Arg, i32 1, i32 896, i16 42)

  ; CHECK-SPIRV: AtomicISub [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z18__spirv_AtomicISubPU3AS1siis(
  %b = tail call spir_func i16 @_Z18__spirv_AtomicISubPU3AS1siis(ptr addrspace(1) %Arg, i32 1, i32 896, i16 42)

  ; CHECK-SPIRV: AtomicSMin [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z18__spirv_AtomicSMinPU3AS1siis(
  %c = tail call spir_func i16 @_Z18__spirv_AtomicSMinPU3AS1siis(ptr addrspace(1) %Arg, i32 1, i32 896, i16 42)

  ; CHECK-SPIRV: AtomicSMax [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z18__spirv_AtomicSMaxPU3AS1siis(
  %d = tail call spir_func i16 @_Z18__spirv_AtomicSMaxPU3AS1siis(ptr addrspace(1) %Arg, i32 1, i32 896, i16 42)

  ; CHECK-SPIRV: AtomicUMin [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z18__spirv_AtomicUMinPU3AS1tiit(
  %e = tail call spir_func i16 @_Z18__spirv_AtomicUMinPU3AS1tiit(ptr addrspace(1) %Arg, i32 1, i32 896, i16 42)

  ; CHECK-SPIRV: AtomicUMax [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z18__spirv_AtomicUMaxPU3AS1tiit(
  %f = tail call spir_func i16 @_Z18__spirv_AtomicUMaxPU3AS1tiit(ptr addrspace(1) %Arg, i32 1, i32 896, i16 42)

  ; CHECK-SPIRV: AtomicAnd [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z17__spirv_AtomicAndPU3AS1siis(
  %g = tail call spir_func i16 @_Z17__spirv_AtomicAndPU3AS1siis(ptr addrspace(1) %Arg, i32 1, i32 896, i16 42)

  ; CHECK-SPIRV: AtomicOr [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z16__spirv_AtomicOrPU3AS1siis(
  %h = tail call spir_func i16 @_Z16__spirv_AtomicOrPU3AS1siis(ptr addrspace(1) %Arg, i32 1, i32 896, i16 42)

  ; CHECK-SPIRV: AtomicXor [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z17__spirv_AtomicXorPU3AS1siis(
  %i = tail call spir_func i16 @_Z17__spirv_AtomicXorPU3AS1siis(ptr addrspace(1) %Arg, i32 1, i32 896, i16 42)

  ; CHECK-SPIRV: AtomicIIncrement [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z24__spirv_AtomicIIncrementPU3AS1sii(
  %j = tail call spir_func i16 @_Z24__spirv_AtomicIIncrementPU3AS1sii(ptr addrspace(1) %Arg, i32 1, i32 896)

  ; CHECK-SPIRV: AtomicIDecrement [[SHORT]]
  ; CHECK-LLVM-SPV: call spir_func i16 @_Z24__spirv_AtomicIDecrementPU3AS1sii(
  %k = tail call spir_func i16 @_Z24__spirv_AtomicIDecrementPU3AS1sii(ptr addrspace(1) %Arg, i32 1, i32 896)

  ret void
}

declare dso_local spir_func i16 @_Z18__spirv_AtomicIAddPU3AS1siis(ptr addrspace(1), i32, i32, i16)
declare dso_local spir_func i16 @_Z18__spirv_AtomicISubPU3AS1siis(ptr addrspace(1), i32, i32, i16)
declare dso_local spir_func i16 @_Z18__spirv_AtomicSMinPU3AS1siis(ptr addrspace(1), i32, i32, i16)
declare dso_local spir_func i16 @_Z18__spirv_AtomicSMaxPU3AS1siis(ptr addrspace(1), i32, i32, i16)
declare dso_local spir_func i16 @_Z18__spirv_AtomicUMinPU3AS1tiit(ptr addrspace(1), i32, i32, i16)
declare dso_local spir_func i16 @_Z18__spirv_AtomicUMaxPU3AS1tiit(ptr addrspace(1), i32, i32, i16)
declare dso_local spir_func i16 @_Z17__spirv_AtomicAndPU3AS1siis(ptr addrspace(1), i32, i32, i16)
declare dso_local spir_func i16 @_Z16__spirv_AtomicOrPU3AS1siis(ptr addrspace(1), i32, i32, i16)
declare dso_local spir_func i16 @_Z17__spirv_AtomicXorPU3AS1siis(ptr addrspace(1), i32, i32, i16)
declare dso_local spir_func i16 @_Z24__spirv_AtomicIIncrementPU3AS1sii(ptr addrspace(1), i32, i32)
declare dso_local spir_func i16 @_Z24__spirv_AtomicIDecrementPU3AS1sii(ptr addrspace(1), i32, i32)
