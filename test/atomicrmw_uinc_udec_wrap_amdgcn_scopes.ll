; Check that scope value survives the round-trip and aligns with the triple.

; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv

; RUN: llvm-spirv -r --spirv-target-triple=amdgcn-amd-amdhsa %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-AMDGCN

; SPV-IR mode: representation independent.
; RUN: llvm-spirv -r --spirv-target-env=SPV-IR --spirv-target-triple=amdgcn-amd-amdhsa %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-AMDGCN

; Default + non-AMDGCN override: generic names.
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-DEFAULT
; RUN: llvm-spirv -r --spirv-target-triple=nvptx64-nvidia-cuda %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-DEFAULT

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv64-amd-amdhsa"

@ui = common dso_local addrspace(1) global i32 0, align 4

; CHECK-AMDGCN: atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("agent") seq_cst
; CHECK-DEFAULT: atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("device") seq_cst
define spir_func void @test_uinc_wrap_device_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("device") seq_cst
  ret void
}

; CHECK-AMDGCN: atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("wavefront") seq_cst
; CHECK-DEFAULT: atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("subgroup") seq_cst
define spir_func void @test_udec_wrap_subgroup_scope() {
entry:
  %r = atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("subgroup") seq_cst
  ret void
}
