; Check that the default ContractionOff doesn't conflict with execution modes
; set in !spirv.ExecutionMode metadata.

; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --implicit-check-not=ExecutionMode

; RUN: llvm-spirv %s -o %t.fc2.spv --spirv-ext=+SPV_KHR_float_controls2
; RUN: spirv-val %t.fc2.spv
; RUN: llvm-spirv %t.fc2.spv -o %t.fc2.spt --to-text
; RUN: FileCheck < %t.fc2.spt %s --check-prefix=CHECK-FC2 --implicit-check-not=ExecutionMode

; RUN: llvm-spirv %s -o %t.fast.spv --spirv-fp-contract=fast
; RUN: spirv-val %t.fast.spv
; RUN: llvm-spirv %t.fast.spv -o %t.fast.spt --to-text
; RUN: FileCheck < %t.fast.spt %s --check-prefix=CHECK-FAST --implicit-check-not=ExecutionMode

; CHECK: EntryPoint 6 [[#K1:]] "k_contraction_off"
; CHECK: EntryPoint 6 [[#K2:]] "k_signed_zero_inf_nan_preserve"
; CHECK: EntryPoint 6 [[#K3:]] "k_fp_fast_math_default"
; CHECK: EntryPoint 6 [[#K4:]] "k_none"
; CHECK: ExecutionMode [[#K1]] 31
; CHECK: ExecutionMode [[#K2]] 31
; CHECK: ExecutionMode [[#K2]] 4461 32
; CHECK: ExecutionMode [[#K3]] 31
; CHECK: ExecutionMode [[#K4]] 31

; CHECK-FC2: EntryPoint 6 [[#K1:]] "k_contraction_off"
; CHECK-FC2: EntryPoint 6 [[#K2:]] "k_signed_zero_inf_nan_preserve"
; CHECK-FC2: EntryPoint 6 [[#K3:]] "k_fp_fast_math_default"
; CHECK-FC2: EntryPoint 6 [[#K4:]] "k_none"
; CHECK-FC2: ExecutionMode [[#K1]] 6028 [[#HALF:]] [[#ZERO:]]
; CHECK-FC2: ExecutionMode [[#K1]] 6028 [[#FLOAT:]] [[#ZERO]]
; CHECK-FC2: ExecutionMode [[#K2]] 6028 [[#FLOAT]] [[#ZERO]]
; CHECK-FC2: ExecutionMode [[#K3]] 6028 [[#FLOAT]] [[#ALLOW_CONTRACT:]]
; CHECK-FC2: ExecutionMode [[#K4]] 6028 [[#HALF]] [[#ZERO]]
; CHECK-FC2: ExecutionMode [[#K4]] 6028 [[#FLOAT]] [[#ZERO]]
; CHECK-FC2-DAG: Constant [[#]] [[#ZERO]] 0
; CHECK-FC2-DAG: Constant [[#]] [[#ALLOW_CONTRACT]] 65536
; CHECK-FC2-DAG: TypeFloat [[#HALF]] 16
; CHECK-FC2-DAG: TypeFloat [[#FLOAT]] 32

; CHECK-FAST: EntryPoint 6 [[#K1:]] "k_contraction_off"
; CHECK-FAST: EntryPoint 6 [[#K2:]] "k_signed_zero_inf_nan_preserve"
; CHECK-FAST: EntryPoint 6 [[#K3:]] "k_fp_fast_math_default"
; CHECK-FAST: EntryPoint 6 [[#K4:]] "k_none"
; CHECK-FAST: ExecutionMode [[#K1]] 31
; CHECK-FAST: ExecutionMode [[#K2]] 4461 32

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @k_contraction_off(ptr addrspace(1) %p, half %h, float %a, float %b) {
entry:
  %hh = fadd half %h, %h
  store half %hh, ptr addrspace(1) %p
  %mul = fmul float %a, %b
  %add = fadd float %mul, %b
  store float %add, ptr addrspace(1) %p
  ret void
}

define spir_kernel void @k_signed_zero_inf_nan_preserve(ptr addrspace(1) %p, float %a, float %b) {
entry:
  %mul = fmul float %a, %b
  %add = fadd float %mul, %b
  store float %add, ptr addrspace(1) %p
  ret void
}

define spir_kernel void @k_fp_fast_math_default(ptr addrspace(1) %p, float %a, float %b) {
entry:
  %mul = fmul float %a, %b
  %add = fadd float %mul, %b
  store float %add, ptr addrspace(1) %p
  ret void
}

define spir_kernel void @k_none(ptr addrspace(1) %p, float %a, float %b) {
entry:
  %mul = fmul float %a, %b
  %add = fadd float %mul, %b
  store float %add, ptr addrspace(1) %p
  ret void
}

!spirv.ExecutionMode = !{!0, !1, !2}

!0 = !{ptr @k_contraction_off, i32 31}
!1 = !{ptr @k_signed_zero_inf_nan_preserve, i32 4461, i32 32}
!2 = !{ptr @k_fp_fast_math_default, i32 6028, float poison, i32 65536}
