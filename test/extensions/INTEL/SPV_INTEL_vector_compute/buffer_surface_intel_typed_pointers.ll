; RUN: llvm-as -opaque-pointers=0 %s -o %t.bc
; RUN: llvm-spirv %t.bc -opaque-pointers=0 -o %t.spv --spirv-ext=+SPV_INTEL_vector_compute
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc --spirv-target-env=SPV-IR
; RUN: llvm-dis -opaque-pointers=0 %t.rev.bc -o - | FileCheck %s

target triple = "spir"

%intel.buffer_ro_t = type opaque

; CHECK: %intel.buffer_ro_t = type opaque
; CHECK: define spir_kernel void @test(%intel.buffer_ro_t addrspace(1)* %buffer)
define spir_kernel void @test(%intel.buffer_ro_t addrspace(1)* %buffer) #0 {
  ret void
}

attributes #0 = { "VCFunction" }
