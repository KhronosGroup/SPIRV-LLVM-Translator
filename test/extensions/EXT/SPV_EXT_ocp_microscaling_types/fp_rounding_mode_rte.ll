; A FPRoundingMode decoration on a conversion to Float4E2M1EXT must land on
; the FConvert result, not on the bitcast inserted to bridge back to i4 --
; regardless of which rounding mode is requested.

; RUN: llvm-spirv %s -spirv-ext=+SPV_EXT_ocp_microscaling_types,+SPV_INTEL_int4 -o %t.spv
; RUN: llvm-spirv %t.spv --to-text -o - | FileCheck %s
; RUN: llvm-spirv -r --spirv-target-env=SPV-IR %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK: Decorate [[#CONV:]] FPRoundingMode 0
; CHECK: FConvert [[#]] [[#CONV]] [[#]]
; CHECK-NEXT: Bitcast [[#]] [[#]] [[#CONV]]

; CHECK-LLVM: call spir_func i4 @_Z36__builtin_spirv_ConvertFP16ToE2M1EXTDh(half
; CHECK-LLVM-SAME: !spirv.Decorations ![[#DECO:]]
; CHECK-LLVM: ![[#DECO]] = !{![[#RTE:]]}
; CHECK-LLVM: ![[#RTE]] = !{i32 39, i32 0}

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024"
target triple = "spir64-unknown-unknown"

declare dso_local spir_func i64 @_Z13get_global_idj(i32)
declare dso_local spir_func i4 @_Z36__builtin_spirv_ConvertFP16ToE2M1EXTDh(half)

define spir_kernel void @FP16_to_E2M1_rte_scalar(half addrspace(1)* %input, i8 addrspace(1)* %output) {
  %gid = call i64 @_Z13get_global_idj(i32 0)
  %inPtr = getelementptr half, half addrspace(1)* %input, i64 %gid
  %val = load half, half addrspace(1)* %inPtr, align 2
  %conv = call i4 @_Z36__builtin_spirv_ConvertFP16ToE2M1EXTDh(half %val), !spirv.Decorations !1
  %v0 = insertelement <2 x i4> undef, i4 %conv, i32 0
  %v1 = insertelement <2 x i4> %v0, i4 0, i32 1
  %outPtr = getelementptr i8, i8 addrspace(1)* %output, i64 %gid
  %cast = bitcast i8 addrspace(1)* %outPtr to <2 x i4> addrspace(1)*
  store <2 x i4> %v1, <2 x i4> addrspace(1)* %cast, align 1
  ret void
}

!1 = !{!2}
!2 = !{i32 39, i32 0}
