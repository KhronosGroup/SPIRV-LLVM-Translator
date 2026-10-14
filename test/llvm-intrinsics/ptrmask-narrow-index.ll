; A mask narrower than the pointer leaves the bits above it unchanged.
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-LLVM: %[[#NOT:]] = xor i32 %m, -1
; CHECK-LLVM: %[[#EXT:]] = zext i32 %[[#NOT]] to i64
; CHECK-LLVM: %[[#MASK:]] = xor i64 %[[#EXT]], -1
; CHECK-LLVM: %[[#INT:]] = ptrtoint ptr addrspace(1) %p to i64
; CHECK-LLVM: %[[#AND:]] = and i64 %[[#INT]], %[[#MASK]]
; CHECK-LLVM: inttoptr i64 %[[#AND]] to ptr addrspace(1)

target datalayout = "e-p1:64:64:64:32"
target triple = "spir64-unknown-unknown"

define spir_func ptr addrspace(1) @narrow(ptr addrspace(1) %p, i32 %m) {
  %r = call ptr addrspace(1) @llvm.ptrmask.p1.i32(ptr addrspace(1) %p, i32 %m)
  ret ptr addrspace(1) %r
}
