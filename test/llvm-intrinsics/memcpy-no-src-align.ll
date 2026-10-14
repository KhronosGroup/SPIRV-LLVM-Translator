; A source pointer without an align attribute is 1-byte aligned.
; RUN: llvm-spirv %s --spirv-max-version=1.3 -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV-13
; RUN: llvm-spirv %s --spirv-max-version=1.4 -o %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV-14
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-13: CopyMemorySized [[#]] [[#]] [[#]] 2 1{{ *$}}
; CHECK-SPIRV-14: CopyMemorySized [[#]] [[#]] [[#]] 2 4 2 1{{ *$}}
; CHECK-LLVM: call void @llvm.memcpy.p1.p1.i64(ptr addrspace(1) align 4 %d, ptr addrspace(1) align 1 %s, i64 16, i1 false)

target triple = "spir64-unknown-unknown"

define spir_kernel void @k(ptr addrspace(1) %d, ptr addrspace(1) %s) {
  call void @llvm.memcpy.p1.p1.i64(ptr addrspace(1) align 4 %d, ptr addrspace(1) %s, i64 16, i1 false)
  ret void
}
