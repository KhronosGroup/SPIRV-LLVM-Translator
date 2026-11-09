; Check that null entries of llvm.global_ctors stay null.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_function_pointers -o %t.spv
; RUN: llvm-spirv -r %t.spv --spirv-addrspace-map=0:4,1:1,2:2,3:3,4:0 --spirv-function-program-addrspace=0 -o - | llvm-dis | FileCheck %s

; CHECK: @llvm.global_ctors = appending addrspace(1) global [2 x { i32, ptr, ptr addrspace(4) }] zeroinitializer

target triple = "spir64-unknown-unknown"

@llvm.global_ctors = appending addrspace(1) global [2 x { i32, ptr, ptr }] zeroinitializer
