; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_fp_max_error --spirv-allow-unknown-intrinsics=llvm.fpbuiltin -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r -emit-opaque-pointers %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: Capability FPMaxErrorINTEL
; CHECK-SPIRV: Extension "SPV_INTEL_fp_max_error"

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define void @test_scalar_1_0(half %h, float %f, double %d) {
entry:
; NO-CHECK-LLVM: %t1 = call float @llvm.fpbuiltin.sin.f32(float %f) #[[#ATTR_ID:]]
  %t1 = call float @llvm.fpbuiltin.sin.f32(float %f) #1
; NO-CHECK-LLVM: %t1 = call float @llvm.fpbuiltin.cos.f32(float %f) #[[#ATTR_ID:]]
  %t2 = call float @llvm.fpbuiltin.cos.f32(float %f) #1
  ret void
}

; Function Attrs: nounwind readnone
define spir_func i1 @TestIsConstantF32_True() local_unnamed_addr #0 {
entry:
  %0 = tail call i1 @Isconstant.f32(float 0.5)
  ret i1 %0
}

declare float @llvm.fpbuiltin.sin.f32(float)
declare float @llvm.fpbuiltin.cos.f32(float)
declare i1 @Isconstant.f32(float)

attributes #1 = { "fpbuiltin-max-error"="0.5" }


