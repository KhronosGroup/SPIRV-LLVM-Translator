; Checks that FP4 (E2M1) conversion builtins with the INTEL postfix are
; translated using the SPV_INTEL_float4 extension: the Float4E2M1INTEL
; encoding (6214) and capability, rather than the Float4E2M1EXT encoding
; from SPV_EXT_ocp_microscaling_types. Round-trips back to the INTEL builtins.

; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_INTEL_float4,+SPV_INTEL_int4,+SPV_KHR_bfloat16
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spv -o %t.rev.bc -r --spirv-target-env=SPV-IR
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: Capability Int4TypeINTEL
; CHECK-SPIRV-DAG: Capability Float4E2M1INTEL
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_float4"
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_int4"

; CHECK-SPIRV-DAG: Name [[#fp4e2m1_hf16_scalar:]] "fp4e2m1_hf16_scalar"
; CHECK-SPIRV-DAG: Name [[#hf16_fp4e2m1_scalar:]] "hf16_fp4e2m1_scalar"
; CHECK-SPIRV-DAG: Name [[#fp4e2m1_fp32_scalar:]] "fp4e2m1_fp32_scalar"
; CHECK-SPIRV-DAG: Name [[#fp32_fp4e2m1_scalar:]] "fp32_fp4e2m1_scalar"
; CHECK-SPIRV-DAG: Name [[#fp4e2m1_fp64_scalar:]] "fp4e2m1_fp64_scalar"
; CHECK-SPIRV-DAG: Name [[#fp64_fp4e2m1_scalar:]] "fp64_fp4e2m1_scalar"

; CHECK-SPIRV-DAG: TypeInt [[#Int4Ty:]] 4 0
; CHECK-SPIRV-DAG: Constant [[#Int4Ty]] [[#Int4Const:]] 1
; CHECK-SPIRV-DAG: TypeFloat [[#HFloat16Ty:]] 16 {{$}}
; CHECK-SPIRV-DAG: TypeFloat [[#FloatTy:]] 32 {{$}}
; CHECK-SPIRV-DAG: TypeFloat [[#DoubleTy:]] 64 {{$}}
; CHECK-SPIRV-DAG: TypeFloat [[#E2M1Ty:]] 4 6214

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_hf16_scalar]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Ty]] [[#Cast:]] [[#Int4Const]]
; CHECK-SPIRV: FConvert [[#HFloat16Ty]] [[#Conv:]] [[#Cast]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: fp4e2m1_hf16_scalar
; CHECK-LLVM: %[[#Call:]] = call spir_func half @_Z38__builtin_spirv_ConvertE2M1ToFP16INTELi(i4 1)
; CHECK-LLVM: ret half %[[#Call]]

define spir_func half @fp4e2m1_hf16_scalar() {
entry:
  %0 = call spir_func half @_Z38__builtin_spirv_ConvertE2M1ToFP16INTELi(i4 1)
  ret half %0
}

declare dso_local spir_func half @_Z38__builtin_spirv_ConvertE2M1ToFP16INTELi(i4)

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_fp32_scalar]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Ty]] [[#Cast:]] [[#Int4Const]]
; CHECK-SPIRV: FConvert [[#FloatTy]] [[#Conv:]] [[#Cast]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: fp4e2m1_fp32_scalar
; CHECK-LLVM: %[[#Call:]] = call spir_func float @_Z38__builtin_spirv_ConvertE2M1ToFP32INTELi(i4 1)
; CHECK-LLVM: ret float %[[#Call]]

define spir_func float @fp4e2m1_fp32_scalar() {
entry:
  %0 = call spir_func float @_Z38__builtin_spirv_ConvertE2M1ToFP32INTELi(i4 1)
  ret float %0
}

declare dso_local spir_func float @_Z38__builtin_spirv_ConvertE2M1ToFP32INTELi(i4)

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_fp64_scalar]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Ty]] [[#Cast:]] [[#Int4Const]]
; CHECK-SPIRV: FConvert [[#DoubleTy]] [[#Conv:]] [[#Cast]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: fp4e2m1_fp64_scalar
; CHECK-LLVM: %[[#Call:]] = call spir_func double @_Z38__builtin_spirv_ConvertE2M1ToFP64INTELi(i4 1)
; CHECK-LLVM: ret double %[[#Call]]

define spir_func double @fp4e2m1_fp64_scalar() {
entry:
  %0 = call spir_func double @_Z38__builtin_spirv_ConvertE2M1ToFP64INTELi(i4 1)
  ret double %0
}

declare dso_local spir_func double @_Z38__builtin_spirv_ConvertE2M1ToFP64INTELi(i4)

; CHECK-SPIRV: Function [[#]] [[#hf16_fp4e2m1_scalar]] [[#]]
; CHECK-SPIRV: FConvert [[#E2M1Ty]] [[#Conv:]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: hf16_fp4e2m1_scalar
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z38__builtin_spirv_ConvertFP16ToE2M1INTELDh(half 1.000000e+00)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @hf16_fp4e2m1_scalar() {
entry:
  %0 = call spir_func i4 @_Z38__builtin_spirv_ConvertFP16ToE2M1INTELDh(half 1.0)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z38__builtin_spirv_ConvertFP16ToE2M1INTELDh(half)

; CHECK-SPIRV: Function [[#]] [[#fp32_fp4e2m1_scalar]] [[#]]
; CHECK-SPIRV: FConvert [[#E2M1Ty]] [[#Conv:]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp32_fp4e2m1_scalar
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z38__builtin_spirv_ConvertFP32ToE2M1INTELf(float 1.000000e+00)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @fp32_fp4e2m1_scalar() {
entry:
  %0 = call spir_func i4 @_Z38__builtin_spirv_ConvertFP32ToE2M1INTELf(float 1.0)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z38__builtin_spirv_ConvertFP32ToE2M1INTELf(float)

; CHECK-SPIRV: Function [[#]] [[#fp64_fp4e2m1_scalar]] [[#]]
; CHECK-SPIRV: FConvert [[#E2M1Ty]] [[#Conv:]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp64_fp4e2m1_scalar
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z38__builtin_spirv_ConvertFP64ToE2M1INTELd(double 1.000000e+00)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @fp64_fp4e2m1_scalar() {
entry:
  %0 = call spir_func i4 @_Z38__builtin_spirv_ConvertFP64ToE2M1INTELd(double 1.0)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z38__builtin_spirv_ConvertFP64ToE2M1INTELd(double)
