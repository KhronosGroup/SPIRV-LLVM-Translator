; Only the SPIR-V scope value survives the round-trip, so the input uses the
; generic "device"/"subgroup" names; --spirv-target-triple=amdgcn-amd-amdhsa
; restores them as "agent"/"wavefront".

; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv

; Reverse to an AMDGCN target: scopes use the AMDGPU names.
; RUN: llvm-spirv -r --spirv-target-triple=amdgcn-amd-amdhsa %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-AMDGCN

; Same in SPV-IR mode, proving the restoration is representation independent.
; RUN: llvm-spirv -r --spirv-target-env=SPV-IR --spirv-target-triple=amdgcn-amd-amdhsa %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-AMDGCN

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv64-amd-amdhsa"

@ui = common dso_local addrspace(1) global i32 0, align 4

; CHECK-AMDGCN: atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("agent") seq_cst
define spir_func void @test_uinc_wrap_device_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("device") seq_cst
  ret void
}

; CHECK-AMDGCN: atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("wavefront") seq_cst
define spir_func void @test_udec_wrap_subgroup_scope() {
entry:
  %r = atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("subgroup") seq_cst
  ret void
}
