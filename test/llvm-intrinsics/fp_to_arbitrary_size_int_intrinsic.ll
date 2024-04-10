;; Ensure @llvm.fptosi.sat.* and @llvm.fptoui.sat.* intrinsics are translated

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_arbitrary_precision_integers -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_arbitrary_precision_integers -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV: Capability Kernel
; CHECK-SPIRV: Decorate [[SAT1:[0-9]+]] SaturatedConversion
; CHECK-SPIRV: Decorate [[SAT2:[0-9]+]] SaturatedConversion
; CHECK-SPIRV: Decorate [[SAT3:[0-9]+]] SaturatedConversion
; CHECK-SPIRV: Decorate [[SAT4:[0-9]+]] SaturatedConversion

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; signed output
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; float input
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;; output i2
; CHECK-SPIRV: ConvertFToS {{[0-9]+}} [[SAT1]]
; CHECK-LLVM: define spir_kernel
; CHECK-LLVM: llvm.fptosi.sat.i2.f32(float %input)
define spir_kernel void @testfunction_float_to_signed_i2(float %input) {
entry:
   %0 = call i2 @llvm.fptosi.sat.i2.f32(float %input)
   ret void
}
declare i2 @llvm.fptosi.sat.i2.f32(float)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; double input
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;; output i2
; CHECK-SPIRV: ConvertFToS {{[0-9]+}} [[SAT2]]
; CHECK-LLVM: define spir_kernel
; CHECK-LLVM: llvm.fptosi.sat.i2.f64(double %input)
define spir_kernel void @testfunction_double_to_signed_i2(double %input) {
entry:
   %0 = call i2 @llvm.fptosi.sat.i2.f64(double %input)
   ret void
}
declare i2 @llvm.fptosi.sat.i2.f64(double)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned output
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; float input
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;; output i2
; CHECK-SPIRV: ConvertFToU {{[0-9]+}} [[SAT3]]
; CHECK-LLVM: define spir_kernel
; CHECK-LLVM: llvm.fptoui.sat.i2.f32(float %input)
define spir_kernel void @testfunction_float_to_unsigned_i2(float %input) {
entry:
   %0 = call i2 @llvm.fptoui.sat.i2.f32(float %input)
   ret void
}
declare i2 @llvm.fptoui.sat.i2.f32(float)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; double input
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;; output i2
; CHECK-SPIRV: ConvertFToU {{[0-9]+}} [[SAT4]]
; CHECK-LLVM: define spir_kernel
; CHECK-LLVM: llvm.fptoui.sat.i2.f64(double %input)
define spir_kernel void @testfunction_double_to_unsigned_i2(double %input) {
entry:
   %0 = call i2 @llvm.fptoui.sat.i2.f64(double %input)
   ret void
}
declare i2 @llvm.fptoui.sat.i2.f64(double)