; This test checks that OCL builtins preserve the type information for opaque
; pointer parameters in their mangling even when untyped pointers extension is enabled.
; Also check for the cases where the pointer parameter is used indirectly to emulate real-life usage.

; Instructions from OpenCL.std extended instruction set that have pointer arguments:
; Math extended instructions: fract, frexp, lgamma_r, modf, remquo, sincos
; Misc instructions: printf, prefetch (covered by separate tests)

; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_KHR_untyped_pointers
; TODO: enable back once spirv-tools are updated
; RUNx: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spirv64-unknown-unknown"

; CHECK-LLVM-LABEL: define spir_func void @fract()
; CHECK-LLVM-COUNT-2: @_Z5fractfPf
; CHECK-LLVM-LABEL: ret void
define spir_func void @fract() {
entry:
  %ptr = alloca float
  %p = bitcast ptr %ptr to ptr
  %res = call spir_func float @_Z17__spirv_ocl_fractfPU3AS1f(float 1.250000e+00, ptr %ptr)
  %res1 = call spir_func float @_Z17__spirv_ocl_fractfPU3AS1f(float 1.250000e+00, ptr %p)
  ret void
}

declare spir_func float @_Z17__spirv_ocl_fractfPU3AS1f(float, ptr)

; CHECK-LLVM-LABEL: define spir_func void @modf()
; CHECK-LLVM-COUNT-2: @_Z4modffPf
; CHECK-LLVM-LABEL: ret void
define spir_func void @modf() {
entry:
  %iptr = alloca float
  %p = bitcast ptr %iptr to ptr
  %res = call spir_func float @_Z16__spirv_ocl_modffPU3AS1f(float 1.250000e+00, ptr %iptr)
  %res1 = call spir_func float @_Z16__spirv_ocl_modffPU3AS1f(float 1.250000e+00, ptr %p)
  ret void
}

declare spir_func float @_Z16__spirv_ocl_modffPU3AS1f(float, ptr)

; CHECK-LLVM-LABEL: define spir_func void @sincos()
; CHECK-LLVM-COUNT-2: @_Z6sincosfPf
; CHECK-LLVM-LABEL: ret void
define spir_func void @sincos() {
entry:
  %cosval = alloca float
  %p = bitcast ptr %cosval to ptr
  %res = call spir_func float @_Z18__spirv_ocl_sincosfPU3AS1f(float 1.250000e+00, ptr %cosval)
  %res1 = call spir_func float @_Z18__spirv_ocl_sincosfPU3AS1f(float 1.250000e+00, ptr %p)
  ret void
}

declare spir_func float @_Z18__spirv_ocl_sincosfPU3AS1f(float, ptr)

; CHECK-LLVM-LABEL: define spir_func void @frexp()
; CHECK-LLVM-COUNT-2: @_Z5frexpfPi
; CHECK-LLVM-LABEL: ret void
define spir_func void @frexp() {
entry:
  %exp = alloca i32
  %p = bitcast ptr %exp to ptr
  %res = call spir_func float @_Z17__spirv_ocl_frexpfPU3AS1i(float 1.250000e+00, ptr %exp)
  %res1 = call spir_func float @_Z17__spirv_ocl_frexpfPU3AS1i(float 1.250000e+00, ptr %p)
  ret void
}

declare spir_func float @_Z17__spirv_ocl_frexpfPU3AS1i(float, ptr)

; CHECK-LLVM-LABEL: define spir_func void @lgamma_r()
; CHECK-LLVM-COUNT-2: @_Z8lgamma_rfPi
; CHECK-LLVM-LABEL: ret void
define spir_func void @lgamma_r() {
entry:
  %signp = alloca i32
  %p = bitcast ptr %signp to ptr
  %res = call spir_func float @_Z20__spirv_ocl_lgamma_rfPU3AS1i(float 1.250000e+00, ptr %signp)
  %res1 = call spir_func float @_Z20__spirv_ocl_lgamma_rfPU3AS1i(float 1.250000e+00, ptr %p)
  ret void
}

declare spir_func float @_Z20__spirv_ocl_lgamma_rfPU3AS1i(float, ptr)

; CHECK-LLVM-LABEL: define spir_func void @remquo()
; CHECK-LLVM-COUNT-2: @_Z6remquoffPi
; CHECK-LLVM-LABEL: ret void
define spir_func void @remquo() {
entry:
  %quo = alloca i32
  %p = bitcast ptr %quo to ptr
  %res = call spir_func float @_Z18__spirv_ocl_remquoffPU3AS1i(float 1.250000e+00, float 1.250000e+00, ptr %quo)
  %res1 = call spir_func float @_Z18__spirv_ocl_remquoffPU3AS1i(float 1.250000e+00, float 1.250000e+00, ptr %p)
  ret void
}

declare spir_func float @_Z18__spirv_ocl_remquoffPU3AS1i(float, float, ptr)
