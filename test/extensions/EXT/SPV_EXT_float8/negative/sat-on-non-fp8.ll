; The _sat suffix on the producer-side __builtin_spirv_Convert*EXT name
; only applies to conversions whose result is Float8E4M3EXT or
; Float8E5M2EXT. Using it on a conversion to Int4 must be rejected.

; RUN: not llvm-spirv %s --spirv-ext=+SPV_EXT_float8,+SPV_INTEL_int4 2>&1 \
; RUN: | FileCheck %s --check-prefix=CHECK-ERROR

; CHECK-ERROR: InvalidInstruction
; CHECK-ERROR: _sat suffix is only valid on conversions whose result is Float8E4M3EXT or Float8E5M2EXT.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func i8 @fp16_int4_sat() {
entry:
  %0 = call spir_func i8 @_Z42__builtin_spirv_ConvertFP16ToInt4INTEL_satDh(half 0.0)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z42__builtin_spirv_ConvertFP16ToInt4INTEL_satDh(half)
