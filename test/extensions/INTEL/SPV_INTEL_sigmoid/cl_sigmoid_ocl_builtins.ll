; RUN: llvm-as %s -o %t.bc

; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_INTEL_sigmoid

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc --spirv-target-env=CL2.0
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM-CL20

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc --spirv-target-env=SPV-IR
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM-SPV

; CHECK-LLVM-CL20: call spir_func float @_Z13intel_sigmoidf(float
; CHECK-LLVM-CL20: call spir_func <2 x float> @_Z13intel_sigmoidDv2_f(<2 x float>
; CHECK-LLVM-CL20: call spir_func <3 x float> @_Z13intel_sigmoidDv3_f(<3 x float>
; CHECK-LLVM-CL20: call spir_func <4 x float> @_Z13intel_sigmoidDv4_f(<4 x float>
; CHECK-LLVM-CL20: call spir_func <8 x float> @_Z13intel_sigmoidDv8_f(<8 x float>
; CHECK-LLVM-CL20: call spir_func <16 x float> @_Z13intel_sigmoidDv16_f(<16 x float>
; CHECK-LLVM-CL20: call spir_func half @_Z13intel_sigmoidDh(half
; CHECK-LLVM-CL20: call spir_func <2 x half> @_Z13intel_sigmoidDv2_Dh(<2 x half>
; CHECK-LLVM-CL20: call spir_func <3 x half> @_Z13intel_sigmoidDv3_Dh(<3 x half>
; CHECK-LLVM-CL20: call spir_func <4 x half> @_Z13intel_sigmoidDv4_Dh(<4 x half>
; CHECK-LLVM-CL20: call spir_func <8 x half> @_Z13intel_sigmoidDv8_Dh(<8 x half>
; CHECK-LLVM-CL20: call spir_func <16 x half> @_Z13intel_sigmoidDv16_Dh(<16 x half>

; CHECK-LLVM-SPV: call spir_func float @_Z21__spirv_FSigmoidINTELf(float
; CHECK-LLVM-SPV: call spir_func <2 x float> @_Z21__spirv_FSigmoidINTELDv2_f(<2 x float>
; CHECK-LLVM-SPV: call spir_func <3 x float> @_Z21__spirv_FSigmoidINTELDv3_f(<3 x float>
; CHECK-LLVM-SPV: call spir_func <4 x float> @_Z21__spirv_FSigmoidINTELDv4_f(<4 x float>
; CHECK-LLVM-SPV: call spir_func <8 x float> @_Z21__spirv_FSigmoidINTELDv8_f(<8 x float>
; CHECK-LLVM-SPV: call spir_func <16 x float> @_Z21__spirv_FSigmoidINTELDv16_f(<16 x float>
; CHECK-LLVM-SPV: call spir_func half @_Z21__spirv_FSigmoidINTELDh(half
; CHECK-LLVM-SPV: call spir_func <2 x half> @_Z21__spirv_FSigmoidINTELDv2_Dh(<2 x half>
; CHECK-LLVM-SPV: call spir_func <3 x half> @_Z21__spirv_FSigmoidINTELDv3_Dh(<3 x half>
; CHECK-LLVM-SPV: call spir_func <4 x half> @_Z21__spirv_FSigmoidINTELDv4_Dh(<4 x half>
; CHECK-LLVM-SPV: call spir_func <8 x half> @_Z21__spirv_FSigmoidINTELDv8_Dh(<8 x half>
; CHECK-LLVM-SPV: call spir_func <16 x half> @_Z21__spirv_FSigmoidINTELDv16_Dh(<16 x half>

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test_sigmoid_f32(ptr addrspace(1) %in) {
entry:
  %val = load float, ptr addrspace(1) %in, align 4
  %r1 = call spir_func float @_Z13intel_sigmoidf(float %val)

  %val2 = load <2 x float>, ptr addrspace(1) %in, align 8
  %r2 = call spir_func <2 x float> @_Z13intel_sigmoidDv2_f(<2 x float> %val2)

  %val3 = load <3 x float>, ptr addrspace(1) %in, align 16
  %r3 = call spir_func <3 x float> @_Z13intel_sigmoidDv3_f(<3 x float> %val3)

  %val4 = load <4 x float>, ptr addrspace(1) %in, align 16
  %r4 = call spir_func <4 x float> @_Z13intel_sigmoidDv4_f(<4 x float> %val4)

  %val8 = load <8 x float>, ptr addrspace(1) %in, align 32
  %r8 = call spir_func <8 x float> @_Z13intel_sigmoidDv8_f(<8 x float> %val8)

  %val16 = load <16 x float>, ptr addrspace(1) %in, align 64
  %r16 = call spir_func <16 x float> @_Z13intel_sigmoidDv16_f(<16 x float> %val16)

  ret void
}

define spir_kernel void @test_sigmoid_f16(ptr addrspace(1) %in) {
entry:
  %valh = load half, ptr addrspace(1) %in, align 2
  %rh = call spir_func half @_Z13intel_sigmoidDh(half %valh)

  %valh2 = load <2 x half>, ptr addrspace(1) %in, align 4
  %rh2 = call spir_func <2 x half> @_Z13intel_sigmoidDv2_Dh(<2 x half> %valh2)

  %valh3 = load <3 x half>, ptr addrspace(1) %in, align 8
  %rh3 = call spir_func <3 x half> @_Z13intel_sigmoidDv3_Dh(<3 x half> %valh3)

  %valh4 = load <4 x half>, ptr addrspace(1) %in, align 8
  %rh4 = call spir_func <4 x half> @_Z13intel_sigmoidDv4_Dh(<4 x half> %valh4)

  %valh8 = load <8 x half>, ptr addrspace(1) %in, align 16
  %rh8 = call spir_func <8 x half> @_Z13intel_sigmoidDv8_Dh(<8 x half> %valh8)

  %valh16 = load <16 x half>, ptr addrspace(1) %in, align 32
  %rh16 = call spir_func <16 x half> @_Z13intel_sigmoidDv16_Dh(<16 x half> %valh16)

  ret void
}

declare spir_func float @_Z13intel_sigmoidf(float)
declare spir_func <2 x float> @_Z13intel_sigmoidDv2_f(<2 x float>)
declare spir_func <3 x float> @_Z13intel_sigmoidDv3_f(<3 x float>)
declare spir_func <4 x float> @_Z13intel_sigmoidDv4_f(<4 x float>)
declare spir_func <8 x float> @_Z13intel_sigmoidDv8_f(<8 x float>)
declare spir_func <16 x float> @_Z13intel_sigmoidDv16_f(<16 x float>)

declare spir_func half @_Z13intel_sigmoidDh(half)
declare spir_func <2 x half> @_Z13intel_sigmoidDv2_Dh(<2 x half>)
declare spir_func <3 x half> @_Z13intel_sigmoidDv3_Dh(<3 x half>)
declare spir_func <4 x half> @_Z13intel_sigmoidDv4_Dh(<4 x half>)
declare spir_func <8 x half> @_Z13intel_sigmoidDv8_Dh(<8 x half>)
declare spir_func <16 x half> @_Z13intel_sigmoidDv16_Dh(<16 x half>)

!opencl.spir.version = !{!0}
!spirv.Source = !{!1}

!0 = !{i32 1, i32 2}
!1 = !{i32 3, i32 200000}
