; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_cooperative_matrix,+SPV_INTEL_joint_matrix -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: not llvm-spirv %t.bc --spirv-ext=+SPV_KHR_cooperative_matrix 2>&1 \
; RUN: | FileCheck %s --check-prefix=CHECK-ERROR

; CHECK-ERROR: RequiresExtension: Feature requires the following SPIR-V extension
; CHECK-ERROR-NEXT: SPV_INTEL_joint_matrix

; CHECK-SPIRV-DAG: Capability CooperativeMatrixKHR
; CHECK-SPIRV-DAG: Extension "SPV_KHR_cooperative_matrix"
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_joint_matrix"
; CHECK-SPIRV-DAG: Capability CooperativeMatrixBFloat16ComponentTypeINTEL
; 64 stays for MatrixAAndBBFloat16ComponentsINTEL (0x40)
; CHECK-SPIRV: CooperativeMatrixMulAddKHR [[#]] [[#]] [[#]] [[#]] [[#]] 64

; CHECK-LLVM: call spir_func target("spirv.CooperativeMatrixKHR", float, 3, 12, 12, 2) @_Z34__spirv_CooperativeMatrixMulAddKHRPU3AS145__spirv_CooperativeMatrixKHR__short_3_12_48_0PU3AS145__spirv_CooperativeMatrixKHR__short_2_48_12_1PU3AS145__spirv_CooperativeMatrixKHR__float_3_12_12_2i({{.*}}, i32 64)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "spir64-unknown-unknown"

define spir_kernel void @matrix_multiply(ptr addrspace(1) noundef align 1 %_arg_accA, ptr addrspace(1) noundef align 1 %_arg_accB, ptr addrspace(1) noundef align 1 %_arg_accC, i64 noundef %_arg_N, i64 noundef %_arg_K, i32 noundef %_arg_Initvalue) {
entry:
  %matrixC = tail call spir_func target("spirv.CooperativeMatrixKHR", float, 3, 12, 12, 2) @_Z26__spirv_CompositeConstruct(float 0.0)
  %matrixA = tail call spir_func noundef target("spirv.CooperativeMatrixKHR", i16, 3, 12, 48, 0) @_Z32__spirv_CooperativeMatrixLoadKHR_1(ptr addrspace(1) noundef %_arg_accA, i32 noundef 0, i64 noundef %_arg_K, i32 noundef 1)
  %matrixB = tail call spir_func noundef target("spirv.CooperativeMatrixKHR", i16, 2, 48, 12, 1) @_Z32__spirv_CooperativeMatrixLoadKHR_2(ptr addrspace(1) noundef %_arg_accB, i32 noundef 1, i64 noundef %_arg_K)
  %res = tail call spir_func noundef target("spirv.CooperativeMatrixKHR", float, 3, 12, 12, 2) @_Z34__spirv_CooperativeMatrixMulAddKHR(target("spirv.CooperativeMatrixKHR", i16, 3, 12, 48, 0) noundef %matrixA, target("spirv.CooperativeMatrixKHR", i16, 2, 48, 12, 1) noundef %matrixB, target("spirv.CooperativeMatrixKHR", float, 3, 12, 12, 2) noundef %matrixC, i32 noundef 64)
  tail call spir_func void @_Z33__spirv_CooperativeMatrixStoreKHR(ptr addrspace(1) noundef %_arg_accC, target("spirv.CooperativeMatrixKHR", float, 3, 12, 12, 2) noundef %res, i32 noundef 0, i64 noundef %_arg_N, i32 noundef 1)
  ret void
}

declare dso_local spir_func noundef target("spirv.CooperativeMatrixKHR", float, 3, 12, 12, 2) @_Z26__spirv_CompositeConstruct(float noundef)

declare dso_local spir_func noundef target("spirv.CooperativeMatrixKHR", float, 3, 12, 12, 2) @_Z34__spirv_CooperativeMatrixMulAddKHR(target("spirv.CooperativeMatrixKHR", i16, 3, 12, 48, 0) noundef, target("spirv.CooperativeMatrixKHR", i16, 2, 48, 12, 1) noundef, target("spirv.CooperativeMatrixKHR", float, 3, 12, 12, 2) noundef, i32 noundef)

declare dso_local spir_func target("spirv.CooperativeMatrixKHR", i16, 3, 12, 48, 0) @_Z32__spirv_CooperativeMatrixLoadKHR_1(ptr addrspace(1), i32, i64, i32)

declare dso_local spir_func target("spirv.CooperativeMatrixKHR", i16, 2, 48, 12, 1) @_Z32__spirv_CooperativeMatrixLoadKHR_2(ptr addrspace(1), i32, i64)

declare dso_local spir_func void @_Z33__spirv_CooperativeMatrixStoreKHR(ptr addrspace(1), target("spirv.CooperativeMatrixKHR", float, 3, 12, 12, 2), i32, i64, i32)
