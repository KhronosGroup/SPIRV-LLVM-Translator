;; Check that llvm.bitreverse.* intrinsics are lowered to emulation functions for
;; 2/4-bit types.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -spirv-ext=+SPV_INTEL_arbitrary_precision_integers -spirv-text %t.bc -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -spirv-ext=+SPV_INTEL_arbitrary_precision_integers %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; There is no validation for SPV_INTEL_arbitrary_precision_integers implemented in
; SPIRV-Tools. TODO: spirv-val %t.spv

; SPV_KHR_bit_instructions extension was not enabled so BitReverse must not be generated
; CHECK-SPIRV-NOT: BitReverse

; Check for expected bitreverse lowerings

; call-sites
; CHECK-LLVM: i2 @llvm_bitreverse_i2
; CHECK-LLVM: i4 @llvm_bitreverse_i4

; definitions
; CHECK-LLVM: define spir_func {{.*}} @llvm_bitreverse_i2
; CHECK-LLVM: define spir_func {{.*}} @llvm_bitreverse_i4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: convergent nounwind writeonly
define spir_kernel void @testBitRev() {
entry:
  %call2 = call i2 @llvm.bitreverse.i2(i2 0)
  %call4 = call i4 @llvm.bitreverse.i4(i4 0)
  ret void
}

declare i2 @llvm.bitreverse.i2(i2)
declare i4 @llvm.bitreverse.i4(i4)

