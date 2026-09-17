; Check that scope value survives the round-trip and aligns with the triple.
; Covers every syncscope reachable on the forward path. Device- and subgroup-level
; scopes are respelled per triple; the rest are triple-independent (CHECK).

; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv

; RUN: llvm-spirv -r --spirv-target-triple=amdgcn-amd-amdhsa %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefixes=CHECK,CHECK-AMDGCN

; SPV-IR mode: representation independent.
; RUN: llvm-spirv -r --spirv-target-env=SPV-IR --spirv-target-triple=amdgcn-amd-amdhsa %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefixes=CHECK,CHECK-AMDGCN

; AMD vendor but not AMDGCN arch: lowered, generic names.
; RUN: llvm-spirv -r --spirv-target-triple=spirv64-amd-amdhsa %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefixes=CHECK,CHECK-DEFAULT

; Non-AMD target: the helper calls are left alone.
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-NOLOWER --implicit-check-not=atomicrmw
; RUN: llvm-spirv -r --spirv-target-triple=spirv64-unknown-unknown %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-NOLOWER --implicit-check-not=atomicrmw

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv64-amd-amdhsa"

@ui = common dso_local addrspace(1) global i32 0, align 4

; CHECK-AMDGCN: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("agent") seq_cst
; CHECK-AMDGCN-NEXT: ret i32 %[[#R]]
; CHECK-DEFAULT: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("device") seq_cst
; CHECK-DEFAULT-NEXT: ret i32 %[[#R]]
; CHECK-NOLOWER: %r = call {{.*}}@__translate_spirv_atomic_uinc_wrap_p1_i32
; CHECK-NOLOWER-NEXT: ret i32 %r
define spir_func i32 @test_uinc_wrap_device_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("device") seq_cst
  ret i32 %r
}

; CHECK-AMDGCN: %[[#R:]] = atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("wavefront") seq_cst
; CHECK-AMDGCN-NEXT: ret i32 %[[#R]]
; CHECK-DEFAULT: %[[#R:]] = atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("subgroup") seq_cst
; CHECK-DEFAULT-NEXT: ret i32 %[[#R]]
; CHECK-NOLOWER: %r = call {{.*}}@__translate_spirv_atomic_udec_wrap_p1_i32
; CHECK-NOLOWER-NEXT: ret i32 %r
define spir_func i32 @test_udec_wrap_subgroup_scope() {
entry:
  %r = atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("subgroup") seq_cst
  ret i32 %r
}

; agent maps onto Device.
; CHECK-AMDGCN: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("agent") seq_cst
; CHECK-AMDGCN-NEXT: ret i32 %[[#R]]
; CHECK-DEFAULT: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("device") seq_cst
; CHECK-DEFAULT-NEXT: ret i32 %[[#R]]
define spir_func i32 @test_uinc_wrap_agent_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("agent") seq_cst
  ret i32 %r
}

; wavefront maps onto Subgroup.
; CHECK-AMDGCN: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("wavefront") seq_cst
; CHECK-AMDGCN-NEXT: ret i32 %[[#R]]
; CHECK-DEFAULT: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("subgroup") seq_cst
; CHECK-DEFAULT-NEXT: ret i32 %[[#R]]
define spir_func i32 @test_uinc_wrap_wavefront_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("wavefront") seq_cst
  ret i32 %r
}

; cluster is SCOPE_SE: between workgroup and agent. No SPIR-V equivalent, so it
; widens to Device and comes back as agent. Conservative, never unsafe.
; CHECK-AMDGCN: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("agent") seq_cst
; CHECK-AMDGCN-NEXT: ret i32 %[[#R]]
; CHECK-DEFAULT: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("device") seq_cst
; CHECK-DEFAULT-NEXT: ret i32 %[[#R]]
define spir_func i32 @test_uinc_wrap_cluster_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("cluster") seq_cst
  ret i32 %r
}

; Same scope on both triples from here on.

; System is the default scope, so it round-trips unspelled.
; CHECK: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 seq_cst
; CHECK-NEXT: ret i32 %[[#R]]
define spir_func i32 @test_uinc_wrap_system_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 seq_cst
  ret i32 %r
}

; CHECK: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("singlethread") seq_cst
; CHECK-NEXT: ret i32 %[[#R]]
define spir_func i32 @test_uinc_wrap_singlethread_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("singlethread") seq_cst
  ret i32 %r
}

; work_item aliases Invocation, so it comes back spelled singlethread.
; CHECK: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("singlethread") seq_cst
; CHECK-NEXT: ret i32 %[[#R]]
define spir_func i32 @test_uinc_wrap_work_item_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("work_item") seq_cst
  ret i32 %r
}

; CHECK: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("workgroup") seq_cst
; CHECK-NEXT: ret i32 %[[#R]]
define spir_func i32 @test_uinc_wrap_workgroup_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("workgroup") seq_cst
  ret i32 %r
}

; all_svm_devices aliases CrossDevice, so it comes back as system.
; CHECK: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 seq_cst
; CHECK-NEXT: ret i32 %[[#R]]
define spir_func i32 @test_uinc_wrap_all_svm_devices_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("all_svm_devices") seq_cst
  ret i32 %r
}

; Unrecognized names fall back to CrossDevice. "system" is not an AMDGPU scope
; spelling (system is the unnamed default), so it takes this path.
; CHECK: %[[#R:]] = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 seq_cst
; CHECK-NEXT: ret i32 %[[#R]]
define spir_func i32 @test_uinc_wrap_unknown_scope() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 syncscope("system") seq_cst
  ret i32 %r
}
