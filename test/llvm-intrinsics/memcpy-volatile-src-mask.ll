; With two memory operand masks, the second applies to Source and must keep Volatile.
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-max-version=1.4 -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc --spirv-max-version=1.4 -o %t.spv
; RUN: spirv-val %t.spv

; Mask 3 = Volatile | Aligned.
; CHECK-SPIRV: CopyMemorySized [[#]] [[#]] [[#]] 3 8 3 4{{ *$}}

target triple = "spir64-unknown-unknown"

define spir_kernel void @k(ptr addrspace(1) %d, ptr addrspace(1) %s) {
  call void @llvm.memcpy.p1.p1.i64(ptr addrspace(1) align 8 %d, ptr addrspace(1) align 4 %s, i64 16, i1 true)
  ret void
}
