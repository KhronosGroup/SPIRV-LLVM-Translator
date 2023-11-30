; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_brain_float16 -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM

source_filename = "bfloat16.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spirv64-unknown-unknown"

; CHECK-SPIRV-DAG: Capability BrainFloat16KHR
; CHECK-SPIRV-DAG: Extension "SPV_KHR_brain_float16"
; CHECK-SPIRV: 4 TypeFloat [[BFLOAT:[0-9]+]] 16 1
; CHECK-SPIRV: 4 TypeVector [[VBFLOAT:[0-9]+]] [[BFLOAT]] 2

; CHECK-LLVM: %addr = alloca bfloat
; CHECK-LLVM: %addr2 = alloca <2 x bfloat>
; CHECK-LLVM: %data = load bfloat, ptr %addr
; CHECK-LLVM: %data2 = load <2 x bfloat>, ptr %addr2

define spir_kernel void @test() {
entry:
  %addr = alloca bfloat
  %addr2 = alloca <2 x bfloat>
  %data = load bfloat, ptr %addr
  %data2 = load <2 x bfloat>, ptr %addr2
  ret void
}
