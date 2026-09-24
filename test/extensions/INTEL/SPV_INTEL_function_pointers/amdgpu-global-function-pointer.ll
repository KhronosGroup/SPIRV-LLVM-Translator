; REQUIRES: spirv-backend
; RUN: llc -mtriple=spirv64-amd-amdhsa -O0 -filetype=obj --spirv-ext=+SPV_INTEL_function_pointers %s -o %t.spv
; RUN: llvm-spirv -r --spirv-target-triple=amdgpu9.42-amd-amdhsa %t.spv -o %t.bc
; RUN: opt -passes=verify %t.bc -disable-output
; RUN: llvm-dis %t.bc -o - | FileCheck %s
; RUN: llc -mtriple=spirv64-amd-amdhsa -O0 -filetype=obj --spirv-ext=+SPV_INTEL_function_pointers,+SPV_KHR_untyped_pointers %s -o %t.untyped.spv
; RUN: llvm-spirv -r --spirv-target-triple=amdgpu9.42-amd-amdhsa %t.untyped.spv -o %t.untyped.bc
; RUN: opt -passes=verify %t.untyped.bc -disable-output
; RUN: llvm-dis %t.untyped.bc -o - | FileCheck %s
;
; A device-global callback holds a flat function pointer, not a private pointer.
; CHECK: @callback_ptr = addrspace(1) global ptr @callback
; CHECK-NOT: addrspacecast (ptr @callback to ptr addrspace(5))
; CHECK: define spir_func i32 @callback(i32
; CHECK: define spir_kernel void @kernel(
; CHECK: load ptr, ptr addrspace(1) @callback_ptr
; CHECK: call spir_func i32

target datalayout = "e-i64:64-n32:64-G1-P4"
target triple = "spirv64-amd-amdhsa"

@callback_ptr = addrspace(1) global ptr addrspace(4) @callback

define spir_func i32 @callback(i32 %value) addrspace(4) {
  ret i32 %value
}

define spir_kernel void @kernel(ptr addrspace(1) %output) addrspace(4) {
  %fn = load ptr addrspace(4), ptr addrspace(1) @callback_ptr
  %value = call spir_func addrspace(4) i32 %fn(i32 42)
  store i32 %value, ptr addrspace(1) %output
  ret void
}
