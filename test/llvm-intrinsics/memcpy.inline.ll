; REQUIRES: spirv-dis
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-dis --raw-id %t.spv | FileCheck --check-prefix CHECK-SPIRV %s
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r -o %t.rev.bc %t.spv
; RUN: llvm-dis -o - %t.rev.bc | FileCheck --check-prefix CHECK-LLVM %s

; llvm.memcpy.inline differs from llvm.memcpy only in guaranteeing that the
; copy is not turned into a call to an external function. OpCopyMemorySized is
; an instruction rather than a call, so the plain memcpy translation already
; satisfies that guarantee.

target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG:  [[ulong:%[a-z0-9_]+]] = OpTypeInt 64 0
; CHECK-SPIRV-DAG:  [[ulong_16:%[a-z0-9_]+]] = OpConstant [[ulong]] 16

define spir_kernel void @copy(ptr addrspace(1) %dst, ptr addrspace(1) %src) {
entry:
  call void @llvm.memcpy.inline.p1.p1.i64(ptr addrspace(1) align 4 %dst, ptr addrspace(1) align 4 %src, i64 16, i1 false)
  ret void
}

; CHECK-SPIRV:  [[dst:%[a-z0-9_]+]] = OpFunctionParameter {{%[a-z0-9_]+}}
; CHECK-SPIRV:  [[src:%[a-z0-9_]+]] = OpFunctionParameter {{%[a-z0-9_]+}}
; CHECK-SPIRV:  OpCopyMemorySized [[dst]] [[src]] [[ulong_16]] Aligned 4

; CHECK-LLVM-LABEL: define spir_kernel void @copy
; CHECK-LLVM:  call void @llvm.memcpy.p1.p1.i64(ptr addrspace(1) align 4 %dst, ptr addrspace(1) align 4 %src, i64 16, i1 false)

; A zero length copy is a no-op: OpCopyMemorySized with a Size of 0 is invalid
; SPIR-V, so nothing at all must be emitted for it.
define spir_kernel void @copy_zero(ptr addrspace(1) %dst, ptr addrspace(1) %src) {
entry:
  call void @llvm.memcpy.inline.p1.p1.i64(ptr addrspace(1) %dst, ptr addrspace(1) %src, i64 0, i1 false)
  ret void
}

; CHECK-SPIRV:  OpFunctionParameter
; CHECK-SPIRV:  OpFunctionParameter
; CHECK-SPIRV:  OpLabel
; CHECK-SPIRV-NEXT:  OpReturn

; CHECK-LLVM-LABEL: define spir_kernel void @copy_zero
; CHECK-LLVM-NEXT:  entry:
; CHECK-LLVM-NEXT:  ret void

declare void @llvm.memcpy.inline.p1.p1.i64(ptr addrspace(1) noalias nocapture writeonly, ptr addrspace(1) noalias nocapture readonly, i64 immarg, i1 immarg)
