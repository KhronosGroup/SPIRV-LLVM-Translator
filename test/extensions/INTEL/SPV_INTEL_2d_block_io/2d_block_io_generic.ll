; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_INTEL_2d_block_io
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv %t.spv -o %t.rev.bc -r --spirv-target-env=SPV-IR
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; RUN: not llvm-spirv %t.bc 2>&1 | FileCheck %s --check-prefix=CHECK-ERROR
; CHECK-ERROR: RequiresExtension: Feature requires the following SPIR-V extension:
; CHECK-ERROR-NEXT: SPV_INTEL_2d_block_io

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func void @foo(ptr addrspace(1) noundef %base_address, ptr addrspace(1) noundef %dst_base_pointer, i32 noundef %width, i32 noundef %height, i32 noundef %pitch, <2 x i32> noundef %coord, ptr noundef %dst_pointer, ptr noundef %src_pointer) {
entry:
  tail call spir_func void @_Z32__spirv_Subgroup2DBlockLoadINTELjjjjPU3AS1KvjjjDv2_jPv(i32 noundef 1, i32 noundef 32, i32 noundef 1, i32 noundef 1, ptr addrspace(1) noundef %base_address, i32 noundef %width, i32 noundef %height, i32 noundef %pitch, <2 x i32> noundef %coord, ptr noundef %dst_pointer)
  tail call spir_func void @_Z41__spirv_Subgroup2DBlockLoadTransformINTELjjjjPU3AS1KvjjjDv2_jPv(i32 noundef 1, i32 noundef 16, i32 noundef 32, i32 noundef 1, ptr addrspace(1) noundef %base_address, i32 noundef %width, i32 noundef %height, i32 noundef %pitch, <2 x i32> noundef %coord, ptr noundef %dst_pointer)
  tail call spir_func void @_Z41__spirv_Subgroup2DBlockLoadTransposeINTELjjjjPU3AS1KvjjjDv2_jPv(i32 noundef 4, i32 noundef 1, i32 noundef 16, i32 noundef 1, ptr addrspace(1) noundef %base_address, i32 noundef %width, i32 noundef %height, i32 noundef %pitch, <2 x i32> noundef %coord, ptr noundef %dst_pointer)
  tail call spir_func void @_Z36__spirv_Subgroup2DBlockPrefetchINTELjjjjPU3AS1KvjjjDv2_j(i32 noundef 1, i32 noundef 32, i32 noundef 1, i32 noundef 1, ptr addrspace(1) noundef %base_address, i32 noundef %width, i32 noundef %height, i32 noundef %pitch, <2 x i32> noundef %coord)
  tail call spir_func void @_Z33__spirv_Subgroup2DBlockStoreINTELjjjjPKvPU3AS1vjjjDv2_j(i32 noundef 1, i32 noundef 16, i32 noundef 1, i32 noundef 1, ptr noundef %src_pointer, ptr addrspace(1) noundef %dst_base_pointer, i32 noundef %width, i32 noundef %height, i32 noundef %pitch, <2 x i32> noundef %coord)
  ret void
}

declare spir_func void @_Z32__spirv_Subgroup2DBlockLoadINTELjjjjPU3AS1KvjjjDv2_jPv(i32 noundef, i32 noundef, i32 noundef, i32 noundef, ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef, <2 x i32> noundef, ptr noundef)
declare spir_func void @_Z41__spirv_Subgroup2DBlockLoadTransformINTELjjjjPU3AS1KvjjjDv2_jPv(i32 noundef, i32 noundef, i32 noundef, i32 noundef, ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef, <2 x i32> noundef, ptr noundef)
declare spir_func void @_Z41__spirv_Subgroup2DBlockLoadTransposeINTELjjjjPU3AS1KvjjjDv2_jPv(i32 noundef, i32 noundef, i32 noundef, i32 noundef, ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef, <2 x i32> noundef, ptr noundef)
declare spir_func void @_Z36__spirv_Subgroup2DBlockPrefetchINTELjjjjPU3AS1KvjjjDv2_j(i32 noundef, i32 noundef, i32 noundef, i32 noundef, ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef, <2 x i32> noundef)
declare spir_func void @_Z33__spirv_Subgroup2DBlockStoreINTELjjjjPKvPU3AS1vjjjDv2_j(i32 noundef, i32 noundef, i32 noundef, i32 noundef, ptr noundef, ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef, <2 x i32> noundef)

!opencl.spir.version = !{!0}
!spirv.Source = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, i32 0}
!1 = !{i32 4, i32 100000}
!2 = !{!"clang version 17.0.0"}
