; RUN: llvm-spirv %s --spirv-ext=+SPV_KHR_cooperative_matrix,+SPV_INTEL_joint_matrix -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: Capability CooperativeMatrixKHR
; CHECK-SPIRV-DAG: Capability PackedCooperativeMatrixINTEL
; CHECK-SPIRV-DAG: Capability CooperativeMatrixCheckedInstructionsINTEL
; CHECK-SPIRV-DAG: Extension "SPV_KHR_cooperative_matrix"
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_joint_matrix"
; CHECK-SPIRV-DAG: TypeInt [[#Int32Ty:]] 32 0
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const2:]] 2

; CHECK-SPIRV: CooperativeMatrixLoadKHR [[#]] [[#]] [[#]] [[#Const2]]
; CHECK-SPIRV: CooperativeMatrixLoadKHR [[#]] [[#]] [[#]] [[#Const2]]
; CHECK-SPIRV: CooperativeMatrixStoreKHR [[#]] [[#]] [[#Const2]]
; CHECK-SPIRV: CooperativeMatrixLoadCheckedINTEL [[#]] [[#]] [[#]] [[#]] [[#]] [[#Const2]]
; CHECK-SPIRV: CooperativeMatrixLoadCheckedINTEL [[#]] [[#]] [[#]] [[#]] [[#]] [[#Const2]]
; CHECK-SPIRV: CooperativeMatrixStoreCheckedINTEL [[#]] [[#]] [[#]] [[#]] [[#Const2]]

; CHECK-LLVM: call spir_func target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z26__spirv_CompositeConstructi(i32 %_arg_Initvalue)
; CHECK-LLVM: call spir_func target("spirv.CooperativeMatrixKHR", i8, 3, 12, 48, 0) @_Z86__spirv_CooperativeMatrixLoadKHR_RPU3AS144__spirv_CooperativeMatrixKHR__char_3_12_48_0PU3AS1cili
; CHECK-LLVM: call spir_func target("spirv.CooperativeMatrixKHR", i8, 2, 48, 12, 1) @_Z86__spirv_CooperativeMatrixLoadKHR_RPU3AS144__spirv_CooperativeMatrixKHR__char_2_48_12_1PU3AS1cil
; CHECK-LLVM: call spir_func target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z34__spirv_CooperativeMatrixMulAddKHRPU3AS144__spirv_CooperativeMatrixKHR__char_3_12_48_0PU3AS144__spirv_CooperativeMatrixKHR__char_2_48_12_1PU3AS144__spirv_CooperativeMatrixKHR__uint_3_12_12_2i
; CHECK-LLVM: call spir_func void @_Z33__spirv_CooperativeMatrixStoreKHRPU3AS1cPU3AS144__spirv_CooperativeMatrixKHR__uint_3_12_12_2ili

; CHECK-LLVM: call spir_func target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z46__spirv_CooperativeMatrixConstructCheckedINTELiiiii(i32 4, i32 4, i32 12, i32 12, i32 %_arg_Initvalue)
; CHECK-LLVM: call spir_func target("spirv.CooperativeMatrixKHR", i8, 3, 12, 48, 0) @_Z95__spirv_CooperativeMatrixLoadCheckedINTEL_RPU3AS144__spirv_CooperativeMatrixKHR__char_3_12_48_0PU3AS1ciiiiili
; CHECK-LLVM: call spir_func target("spirv.CooperativeMatrixKHR", i8, 2, 48, 12, 1) @_Z95__spirv_CooperativeMatrixLoadCheckedINTEL_RPU3AS144__spirv_CooperativeMatrixKHR__char_2_48_12_1PU3AS1ciiiiil
; CHECK-LLVM: call spir_func target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z34__spirv_CooperativeMatrixMulAddKHRPU3AS144__spirv_CooperativeMatrixKHR__char_3_12_48_0PU3AS144__spirv_CooperativeMatrixKHR__char_2_48_12_1PU3AS144__spirv_CooperativeMatrixKHR__uint_3_12_12_2i
; CHECK-LLVM: call spir_func void @_Z42__spirv_CooperativeMatrixStoreCheckedINTELPU3AS1ciiPU3AS144__spirv_CooperativeMatrixKHR__uint_3_12_12_2iiili

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define weak_odr dso_local spir_kernel void @_ZTSZZ15matrix_multiply(ptr addrspace(1) noundef align 1 %_arg_accA, ptr addrspace(1) noundef align 1 %_arg_accB, ptr addrspace(1) noundef align 1 %_arg_accC, i64 noundef %_arg_N, i64 noundef %_arg_K, i32 noundef %_arg_Initvalue) {
entry:
  %matrixC = tail call spir_func target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z26__spirv_CompositeConstruct(i32 %_arg_Initvalue)
  %matrixA = tail call spir_func noundef target("spirv.CooperativeMatrixKHR", i8, 3, 12, 48, 0) @_Z32__spirv_CooperativeMatrixLoadKHR_1(ptr addrspace(1) noundef %_arg_accA, i32 noundef 2, i64 noundef %_arg_K, i32 noundef 1)
  %matrixB = tail call spir_func noundef target("spirv.CooperativeMatrixKHR", i8, 2, 48, 12, 1) @_Z32__spirv_CooperativeMatrixLoadKHR_2(ptr addrspace(1) noundef %_arg_accB, i32 noundef 2, i64 noundef %_arg_K)
  %res = tail call spir_func noundef target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z34__spirv_CooperativeMatrixMulAddKHR(target("spirv.CooperativeMatrixKHR", i8, 3, 12, 48, 0) noundef %matrixA, target("spirv.CooperativeMatrixKHR", i8, 2, 48, 12, 1) noundef %matrixB, target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) noundef %matrixC, i32 noundef 12)
  tail call spir_func void @_Z33__spirv_CooperativeMatrixStoreKHR(ptr addrspace(1) noundef %_arg_accC, target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) noundef %res, i32 noundef 2, i64 noundef %_arg_N, i32 noundef 1)
  ret void
}

define weak_odr dso_local spir_kernel void @_ZTSZZ23matrix_multiply_checked(ptr addrspace(1) noundef align 1 %_arg_accA, ptr addrspace(1) noundef align 1 %_arg_accB, ptr addrspace(1) noundef align 1 %_arg_accC, i64 noundef %_arg_N, i64 noundef %_arg_K, i32 noundef %_arg_Initvalue) {
entry:
  %matrixC = tail call spir_func noundef target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z46__spirv_CooperativeMatrixConstructCheckedINTEL(i32 noundef 4, i32 noundef 4, i32 noundef 12, i32 noundef 12, i32 noundef %_arg_Initvalue)
  %matrixA = tail call spir_func noundef target("spirv.CooperativeMatrixKHR", i8, 3, 12, 48, 0) @_Z41__spirv_CooperativeMatrixLoadCheckedINTEL_1(ptr addrspace(1) noundef %_arg_accA, i32 noundef 0, i32 noundef 0, i32 noundef 2, i32 noundef 12, i32 noundef 48, i64 noundef %_arg_K, i32 noundef 1)
  %matrixB = tail call spir_func noundef target("spirv.CooperativeMatrixKHR", i8, 2, 48, 12, 1) @_Z41__spirv_CooperativeMatrixLoadCheckedINTEL_2(ptr addrspace(1) noundef %_arg_accB, i32 noundef 0, i32 noundef 0, i32 noundef 2, i32 noundef 48, i32 noundef 12, i64 noundef %_arg_K)
  %res = tail call spir_func noundef target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z34__spirv_CooperativeMatrixMulAddKHR(target("spirv.CooperativeMatrixKHR", i8, 3, 12, 48, 0) noundef %matrixA, target("spirv.CooperativeMatrixKHR", i8, 2, 48, 12, 1) noundef %matrixB, target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) noundef %matrixC, i32 noundef 12)
  tail call spir_func void @_Z42__spirv_CooperativeMatrixStoreCheckedINTEL(ptr addrspace(1) noundef %_arg_accC, i32 noundef 0, i32 noundef 0, target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) noundef %res, i32 noundef 2, i32 noundef 12, i32 noundef 12, i64 noundef %_arg_N, i32 noundef 1)
  ret void
}

declare dso_local spir_func target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z26__spirv_CompositeConstruct(i32)

declare dso_local spir_func noundef target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z46__spirv_CooperativeMatrixConstructCheckedINTEL(i32 noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef)

declare dso_local spir_func noundef target("spirv.CooperativeMatrixKHR", i8, 3, 12, 48, 0) @_Z41__spirv_CooperativeMatrixLoadCheckedINTEL_1(ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef, i64 noundef, i32 noundef)

declare dso_local spir_func noundef target("spirv.CooperativeMatrixKHR", i8, 2, 48, 12, 1) @_Z41__spirv_CooperativeMatrixLoadCheckedINTEL_2(ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef, i64 noundef)

declare dso_local spir_func noundef target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) @_Z34__spirv_CooperativeMatrixMulAddKHR(target("spirv.CooperativeMatrixKHR", i8, 3, 12, 48, 0) noundef, target("spirv.CooperativeMatrixKHR", i8, 2, 48, 12, 1) noundef, target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) noundef, i32 noundef)

declare dso_local spir_func void @_Z42__spirv_CooperativeMatrixStoreCheckedINTEL(ptr addrspace(1) noundef, i32 noundef, i32 noundef, target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2) noundef, i32 noundef, i32 noundef, i32 noundef, i64 noundef, i32 noundef)

declare dso_local spir_func target("spirv.CooperativeMatrixKHR", i8, 3, 12, 48, 0) @_Z32__spirv_CooperativeMatrixLoadKHR_1(ptr addrspace(1), i32, i64, i32)

declare dso_local spir_func target("spirv.CooperativeMatrixKHR", i8, 2, 48, 12, 1) @_Z32__spirv_CooperativeMatrixLoadKHR_2(ptr addrspace(1), i32, i64)

declare dso_local spir_func void @_Z33__spirv_CooperativeMatrixStoreKHR(ptr addrspace(1), target("spirv.CooperativeMatrixKHR", i32, 3, 12, 12, 2), i32, i64, i32)
