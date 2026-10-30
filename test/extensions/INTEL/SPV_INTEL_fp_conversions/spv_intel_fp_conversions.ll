; This tests checks if FP4 and FP8 conversions specified by
; __builtin_spirv_* external function calls translated correctly.
; This test is for Stochastic*, ClampStochastic* conversions.
; Packed and vector conversions are tested for general case, this test is only
; for scalar

; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_EXT_float8,+SPV_EXT_ocp_microscaling_types,+SPV_INTEL_int4,+SPV_KHR_bfloat16,+SPV_INTEL_fp_conversions
; TODO: re-enable spirv-val once it recognizes the FloatConversionsFtoFINTEL capability (6215)
; RUNx: spirv-val %t.spv
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spv -o %t.rev.bc -r
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: Capability Int4TypeINTEL
; CHECK-SPIRV-DAG: Capability Float8EXT
; CHECK-SPIRV-DAG: Capability Float4EXT
; CHECK-SPIRV-DAG: Capability FloatConversionsFtoFINTEL
; CHECK-SPIRV-DAG: Capability FloatConversionsFtoSINTEL

; CHECK-SPIRV-DAG: Extension "SPV_INTEL_int4"
; CHECK-SPIRV-DAG: Extension "SPV_EXT_float8"
; CHECK-SPIRV-DAG: Extension "SPV_EXT_ocp_microscaling_types"
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_fp_conversions"

; CHECK-SPIRV-DAG: Name [[#hf16_hf8_clamp:]] "hf16_hf8_clamp"
; CHECK-SPIRV-DAG: Name [[#hf16_bf8_clamp:]] "hf16_bf8_clamp"
; CHECK-SPIRV-DAG: Name [[#bf16_hf8_clamp:]] "bf16_hf8_clamp"
; CHECK-SPIRV-DAG: Name [[#bf16_bf8_clamp:]] "bf16_bf8_clamp"
; CHECK-SPIRV-DAG: Name [[#hf16_int4_clamp:]] "hf16_int4_clamp"
; CHECK-SPIRV-DAG: Name [[#bf16_int4_clamp:]] "bf16_int4_clamp"

; CHECK-SPIRV-DAG: Name [[#hf16_bf8_stochastic:]] "hf16_bf8_stochastic"
; CHECK-SPIRV-DAG: Name [[#hf16_hf8_stochastic:]] "hf16_hf8_stochastic"
; CHECK-SPIRV-DAG: Name [[#bf16_bf8_stochastic:]] "bf16_bf8_stochastic"
; CHECK-SPIRV-DAG: Name [[#bf16_hf8_stochastic:]] "bf16_hf8_stochastic"
; CHECK-SPIRV-DAG: Name [[#hf16_fp4e2m1_stochastic:]] "hf16_fp4e2m1_stochastic"
; CHECK-SPIRV-DAG: Name [[#bf16_fp4e2m1_stochastic:]] "bf16_fp4e2m1_stochastic"
; CHECK-SPIRV-DAG: Name [[#hf16_int4_stochastic:]] "hf16_int4_stochastic"
; CHECK-SPIRV-DAG: Name [[#bf16_int4_stochastic:]] "bf16_int4_stochastic"
; CHECK-SPIRV-DAG: Name [[#hf16_bf8_clamp_stochastic:]] "hf16_bf8_clamp_stochastic"
; CHECK-SPIRV-DAG: Name [[#bf16_bf8_clamp_stochastic:]] "bf16_bf8_clamp_stochastic"
; CHECK-SPIRV-DAG: Name [[#hf16_hf8_clamp_stochastic:]] "hf16_hf8_clamp_stochastic"
; CHECK-SPIRV-DAG: Name [[#bf16_hf8_clamp_stochastic:]] "bf16_hf8_clamp_stochastic"

; CHECK-SPIRV-DAG: Name [[#hf16_bf8_stochastic_last_seed:]] "hf16_bf8_stochastic_last_seed"
; CHECK-SPIRV-DAG: Name [[#hf16_int4_stochastic_last_seed:]] "hf16_int4_stochastic_last_seed"
; CHECK-SPIRV-DAG: Name [[#hf16_bf8_clamp_stochastic_last_seed:]] "hf16_bf8_clamp_stochastic_last_seed"
; CHECK-SPIRV-DAG: Name [[#fp32_hf8_clamp:]] "fp32_hf8_clamp"
; CHECK-SPIRV-DAG: Name [[#fp32_bf8_clamp:]] "fp32_bf8_clamp"
; CHECK-SPIRV-DAG: Name [[#fp32_int4_clamp:]] "fp32_int4_clamp"
; CHECK-SPIRV-DAG: Name [[#fp32_bf8_stochastic:]] "fp32_bf8_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp32_hf8_stochastic:]] "fp32_hf8_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp32_fp4e2m1_stochastic:]] "fp32_fp4e2m1_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp32_int4_stochastic:]] "fp32_int4_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp32_bf8_clamp_stochastic:]] "fp32_bf8_clamp_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp32_hf8_clamp_stochastic:]] "fp32_hf8_clamp_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp64_hf8_clamp:]] "fp64_hf8_clamp"
; CHECK-SPIRV-DAG: Name [[#fp64_bf8_clamp:]] "fp64_bf8_clamp"
; CHECK-SPIRV-DAG: Name [[#fp64_int4_clamp:]] "fp64_int4_clamp"
; CHECK-SPIRV-DAG: Name [[#fp64_bf8_stochastic:]] "fp64_bf8_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp64_hf8_stochastic:]] "fp64_hf8_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp64_fp4e2m1_stochastic:]] "fp64_fp4e2m1_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp64_int4_stochastic:]] "fp64_int4_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp64_bf8_clamp_stochastic:]] "fp64_bf8_clamp_stochastic"
; CHECK-SPIRV-DAG: Name [[#fp64_hf8_clamp_stochastic:]] "fp64_hf8_clamp_stochastic"

; CHECK-SPIRV: Decorate [[#SatHfE4M3:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatHfE5M2:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatBfE4M3:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatBfE5M2:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatF32E4M3:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatF32E5M2:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatF64E4M3:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatF64E5M2:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatStHfE5M2:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatStBfE5M2:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatStHfE4M3:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatStBfE4M3:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatStF32E5M2:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatStF32E4M3:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatStF64E5M2:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatStF64E4M3:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV: Decorate [[#SatStHfE5M2LS:]] SaturatedToLargestFloat8NormalConversionEXT

; CHECK-SPIRV-DAG: TypeInt [[#Int8Ty:]] 8 0
; CHECK-SPIRV-DAG: TypeInt [[#Int32Ty:]] 32 0
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Int32Const:]] 1
; CHECK-SPIRV-DAG: TypeInt [[#Int4Ty:]] 4 0

; CHECK-SPIRV-DAG: TypeFloat [[#E2M1Ty:]] 4 4225
; CHECK-SPIRV-DAG: TypeFloat [[#HFloat8Ty:]] 8 4214
; CHECK-SPIRV-DAG: TypeFloat [[#BFloat8Ty:]] 8 4215

; CHECK-SPIRV-DAG: TypeFloat [[#HFloat16Ty:]] 16 {{$}}
; CHECK-SPIRV-DAG: Constant [[#HFloat16Ty]] [[#HalfConst:]] 15360

; CHECK-SPIRV-DAG: TypeFloat [[#FloatTy:]] 32 {{$}}
; CHECK-SPIRV-DAG: Constant [[#FloatTy]] [[#FloatConst:]] 1065353216

; CHECK-SPIRV-DAG: TypeFloat [[#DoubleTy:]] 64 {{$}}
; CHECK-SPIRV-DAG: Constant [[#DoubleTy]] [[#DoubleConst:]] 0 1072693248

; CHECK-SPIRV-DAG: TypeFloat [[#BFloat16Ty:]] 16 0
; CHECK-SPIRV-DAG: Constant [[#BFloat16Ty]] [[#BfloatConst:]] 16256

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Followings tests are for clamp rounding

; CHECK-SPIRV: Function [[#]] [[#hf16_hf8_clamp]] [[#]]
; CHECK-SPIRV: FConvert [[#HFloat8Ty]] [[#SatHfE4M3]] [[#HalfConst]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatHfE4M3]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: hf16_hf8_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP16ToE4M3INTELDh(half 1.000000e+00)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @hf16_hf8_clamp() {
entry:
  %0 = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP16ToE4M3INTELDh(half 1.0)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z43__builtin_spirv_ClampConvertFP16ToE4M3INTELDh(half)

; CHECK-SPIRV: Function [[#]] [[#hf16_bf8_clamp]] [[#]]
; CHECK-SPIRV: FConvert [[#BFloat8Ty]] [[#SatHfE5M2]] [[#HalfConst]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatHfE5M2]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: hf16_bf8_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP16ToE5M2INTELDh(half 1.000000e+00)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @hf16_bf8_clamp() {
entry:
  %0 = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP16ToE5M2INTELDh(half 1.0)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z43__builtin_spirv_ClampConvertFP16ToE5M2INTELDh(half)

; CHECK-SPIRV: Function [[#]] [[#bf16_hf8_clamp]] [[#]]
; CHECK-SPIRV: FConvert [[#HFloat8Ty]] [[#SatBfE4M3]] [[#BfloatConst]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatBfE4M3]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: bf16_hf8_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z43__builtin_spirv_ClampConvertBF16ToE4M3INTELDF16b(bfloat 1.000000e+00)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @bf16_hf8_clamp() {
entry:
  %0 = call spir_func i8 @_Z43__builtin_spirv_ClampConvertBF16ToE4M3INTELDF16b(bfloat 1.0)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z43__builtin_spirv_ClampConvertBF16ToE4M3INTELDF16b(bfloat)

; CHECK-SPIRV: Function [[#]] [[#bf16_bf8_clamp]] [[#]]
; CHECK-SPIRV: FConvert [[#BFloat8Ty]] [[#SatBfE5M2]] [[#BfloatConst]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatBfE5M2]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: bf16_bf8_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z43__builtin_spirv_ClampConvertBF16ToE5M2INTELDF16b(bfloat 1.000000e+00)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @bf16_bf8_clamp() {
entry:
  %0 = call spir_func i8 @_Z43__builtin_spirv_ClampConvertBF16ToE5M2INTELDF16b(bfloat 1.0)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z43__builtin_spirv_ClampConvertBF16ToE5M2INTELDF16b(bfloat)

; CHECK-SPIRV: Function [[#]] [[#fp32_hf8_clamp]] [[#]]
; CHECK-SPIRV: FConvert [[#HFloat8Ty]] [[#SatF32E4M3]] [[#FloatConst]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatF32E4M3]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp32_hf8_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE4M3INTELf(float 1.000000e+00)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp32_hf8_clamp() {
entry:
  %0 = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE4M3INTELf(float 1.0)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE4M3INTELf(float)

; CHECK-SPIRV: Function [[#]] [[#fp32_bf8_clamp]] [[#]]
; CHECK-SPIRV: FConvert [[#BFloat8Ty]] [[#SatF32E5M2]] [[#FloatConst]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatF32E5M2]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp32_bf8_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE5M2INTELf(float 1.000000e+00)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp32_bf8_clamp() {
entry:
  %0 = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE5M2INTELf(float 1.0)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE5M2INTELf(float)

; CHECK-SPIRV: Function [[#]] [[#fp64_hf8_clamp]] [[#]]
; CHECK-SPIRV: FConvert [[#HFloat8Ty]] [[#SatF64E4M3]] [[#DoubleConst]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatF64E4M3]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp64_hf8_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP64ToE4M3INTELd(double 1.000000e+00)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp64_hf8_clamp() {
entry:
  %0 = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP64ToE4M3INTELd(double 1.0)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z43__builtin_spirv_ClampConvertFP64ToE4M3INTELd(double)

; CHECK-SPIRV: Function [[#]] [[#fp64_bf8_clamp]] [[#]]
; CHECK-SPIRV: FConvert [[#BFloat8Ty]] [[#SatF64E5M2]] [[#DoubleConst]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatF64E5M2]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp64_bf8_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP64ToE5M2INTELd(double 1.000000e+00)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp64_bf8_clamp() {
entry:
  %0 = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP64ToE5M2INTELd(double 1.0)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z43__builtin_spirv_ClampConvertFP64ToE5M2INTELd(double)

; CHECK-SPIRV: Function [[#]] [[#hf16_bf8_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#BFloat8Ty]] [[#Conv:]] [[#HalfConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: hf16_bf8_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP16ToE5M2INTELDhi(half 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @hf16_bf8_stochastic() {
entry:
  %0 = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP16ToE5M2INTELDhi(half 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP16ToE5M2INTELDhi(half, i32)

; CHECK-SPIRV: Function [[#]] [[#hf16_hf8_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#HFloat8Ty]] [[#Conv:]] [[#HalfConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: hf16_hf8_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP16ToE4M3INTELDhi(half 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @hf16_hf8_stochastic() {
entry:
  %0 = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP16ToE4M3INTELDhi(half 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP16ToE4M3INTELDhi(half, i32)

; CHECK-SPIRV: Function [[#]] [[#bf16_bf8_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#BFloat8Ty]] [[#Conv:]] [[#BfloatConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: bf16_bf8_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundBF16ToE5M2INTELDF16bi(bfloat 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @bf16_bf8_stochastic() {
entry:
  %0 = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundBF16ToE5M2INTELDF16bi(bfloat 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z46__builtin_spirv_StochasticRoundBF16ToE5M2INTELDF16bi(bfloat, i32)

; CHECK-SPIRV: Function [[#]] [[#bf16_hf8_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#HFloat8Ty]] [[#Conv:]] [[#BfloatConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: bf16_hf8_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundBF16ToE4M3INTELDF16bi(bfloat 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @bf16_hf8_stochastic() {
entry:
  %0 = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundBF16ToE4M3INTELDF16bi(bfloat 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z46__builtin_spirv_StochasticRoundBF16ToE4M3INTELDF16bi(bfloat, i32)

; CHECK-SPIRV: Function [[#]] [[#hf16_fp4e2m1_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#E2M1Ty]] [[#Conv:]] [[#HalfConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int4Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: hf16_fp4e2m1_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z46__builtin_spirv_StochasticRoundFP16ToE2M1INTELDhi(half 1.000000e+00, i32 1)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @hf16_fp4e2m1_stochastic() {
entry:
  %0 = call spir_func i4 @_Z46__builtin_spirv_StochasticRoundFP16ToE2M1INTELDhi(half 1.0, i32 1)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z46__builtin_spirv_StochasticRoundFP16ToE2M1INTELDhi(half, i32)

; CHECK-SPIRV: Function [[#]] [[#bf16_fp4e2m1_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#E2M1Ty]] [[#Conv:]] [[#BfloatConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int4Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: bf16_fp4e2m1_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z46__builtin_spirv_StochasticRoundBF16ToE2M1INTELDF16bi(bfloat 1.000000e+00, i32 1)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @bf16_fp4e2m1_stochastic() {
entry:
  %0 = call spir_func i4 @_Z46__builtin_spirv_StochasticRoundBF16ToE2M1INTELDF16bi(bfloat 1.0, i32 1)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z46__builtin_spirv_StochasticRoundBF16ToE2M1INTELDF16bi(bfloat, i32)

; CHECK-SPIRV: Function [[#]] [[#fp32_bf8_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#BFloat8Ty]] [[#Conv:]] [[#FloatConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp32_bf8_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP32ToE5M2INTELfi(float 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp32_bf8_stochastic() {
entry:
  %0 = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP32ToE5M2INTELfi(float 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP32ToE5M2INTELfi(float, i32)

; CHECK-SPIRV: Function [[#]] [[#fp32_hf8_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#HFloat8Ty]] [[#Conv:]] [[#FloatConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp32_hf8_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP32ToE4M3INTELfi(float 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp32_hf8_stochastic() {
entry:
  %0 = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP32ToE4M3INTELfi(float 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP32ToE4M3INTELfi(float, i32)

; CHECK-SPIRV: Function [[#]] [[#fp32_fp4e2m1_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#E2M1Ty]] [[#Conv:]] [[#FloatConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int4Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp32_fp4e2m1_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z46__builtin_spirv_StochasticRoundFP32ToE2M1INTELfi(float 1.000000e+00, i32 1)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @fp32_fp4e2m1_stochastic() {
entry:
  %0 = call spir_func i4 @_Z46__builtin_spirv_StochasticRoundFP32ToE2M1INTELfi(float 1.0, i32 1)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z46__builtin_spirv_StochasticRoundFP32ToE2M1INTELfi(float, i32)

; CHECK-SPIRV: Function [[#]] [[#fp64_bf8_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#BFloat8Ty]] [[#Conv:]] [[#DoubleConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp64_bf8_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP64ToE5M2INTELdi(double 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp64_bf8_stochastic() {
entry:
  %0 = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP64ToE5M2INTELdi(double 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP64ToE5M2INTELdi(double, i32)

; CHECK-SPIRV: Function [[#]] [[#fp64_hf8_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#HFloat8Ty]] [[#Conv:]] [[#DoubleConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp64_hf8_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP64ToE4M3INTELdi(double 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp64_hf8_stochastic() {
entry:
  %0 = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP64ToE4M3INTELdi(double 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP64ToE4M3INTELdi(double, i32)

; CHECK-SPIRV: Function [[#]] [[#fp64_fp4e2m1_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#E2M1Ty]] [[#Conv:]] [[#DoubleConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int4Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp64_fp4e2m1_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z46__builtin_spirv_StochasticRoundFP64ToE2M1INTELdi(double 1.000000e+00, i32 1)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @fp64_fp4e2m1_stochastic() {
entry:
  %0 = call spir_func i4 @_Z46__builtin_spirv_StochasticRoundFP64ToE2M1INTELdi(double 1.0, i32 1)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z46__builtin_spirv_StochasticRoundFP64ToE2M1INTELdi(double, i32)

; CHECK-SPIRV: Function [[#]] [[#hf16_int4_clamp]] [[#]]
; CHECK-SPIRV: ClampConvertFToSINTEL [[#Int4Ty]] [[#Conv:]] [[#HalfConst]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: hf16_int4_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z43__builtin_spirv_ClampConvertFP16ToInt4INTELDh(half 1.000000e+00)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @hf16_int4_clamp() {
entry:
  %0 = call spir_func i4 @_Z43__builtin_spirv_ClampConvertFP16ToInt4INTELDh(half 1.0)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z43__builtin_spirv_ClampConvertFP16ToInt4INTELDh(half)

; CHECK-SPIRV: Function [[#]] [[#bf16_int4_clamp]] [[#]]
; CHECK-SPIRV: ClampConvertFToSINTEL [[#Int4Ty]] [[#Conv:]] [[#BfloatConst]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: bf16_int4_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z43__builtin_spirv_ClampConvertBF16ToInt4INTELDF16b(bfloat 1.000000e+00)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @bf16_int4_clamp() {
entry:
  %0 = call spir_func i4 @_Z43__builtin_spirv_ClampConvertBF16ToInt4INTELDF16b(bfloat 1.0)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z43__builtin_spirv_ClampConvertBF16ToInt4INTELDF16b(bfloat)

; CHECK-SPIRV: Function [[#]] [[#fp32_int4_clamp]] [[#]]
; CHECK-SPIRV: ClampConvertFToSINTEL [[#Int4Ty]] [[#Conv:]] [[#FloatConst]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: fp32_int4_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z43__builtin_spirv_ClampConvertFP32ToInt4INTELf(float 1.000000e+00)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @fp32_int4_clamp() {
entry:
  %0 = call spir_func i4 @_Z43__builtin_spirv_ClampConvertFP32ToInt4INTELf(float 1.0)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z43__builtin_spirv_ClampConvertFP32ToInt4INTELf(float)

; CHECK-SPIRV: Function [[#]] [[#fp64_int4_clamp]] [[#]]
; CHECK-SPIRV: ClampConvertFToSINTEL [[#Int4Ty]] [[#Conv:]] [[#DoubleConst]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: fp64_int4_clamp
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z43__builtin_spirv_ClampConvertFP64ToInt4INTELd(double 1.000000e+00)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @fp64_int4_clamp() {
entry:
  %0 = call spir_func i4 @_Z43__builtin_spirv_ClampConvertFP64ToInt4INTELd(double 1.0)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z43__builtin_spirv_ClampConvertFP64ToInt4INTELd(double)

; CHECK-SPIRV: Function [[#]] [[#hf16_int4_stochastic]] [[#]]
; CHECK-SPIRV: ClampStochasticRoundFToSINTEL [[#Int4Ty]] [[#Conv:]] [[#HalfConst]] [[#Int32Const]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: hf16_int4_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToInt4INTELDhi(half 1.000000e+00, i32 1)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @hf16_int4_stochastic() {
entry:
  %0 = call spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToInt4INTELhs(half 1.0, i32 1)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToInt4INTELhs(half, i32)

; CHECK-SPIRV: Function [[#]] [[#bf16_int4_stochastic]] [[#]]
; CHECK-SPIRV: ClampStochasticRoundFToSINTEL [[#Int4Ty]] [[#Conv:]] [[#BfloatConst]] [[#Int32Const]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: bf16_int4_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundBF16ToInt4INTELDF16bi(bfloat 1.000000e+00, i32 1)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @bf16_int4_stochastic() {
entry:
  %0 = call spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundBF16ToInt4INTELDF16bi(bfloat 1.0, i32 1)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundBF16ToInt4INTELDF16bi(bfloat, i32)

; CHECK-SPIRV: Function [[#]] [[#fp32_int4_stochastic]] [[#]]
; CHECK-SPIRV: ClampStochasticRoundFToSINTEL [[#Int4Ty]] [[#Conv:]] [[#FloatConst]] [[#Int32Const]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: fp32_int4_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP32ToInt4INTELfi(float 1.000000e+00, i32 1)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @fp32_int4_stochastic() {
entry:
  %0 = call spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP32ToInt4INTELfi(float 1.0, i32 1)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP32ToInt4INTELfi(float, i32)

; CHECK-SPIRV: Function [[#]] [[#fp64_int4_stochastic]] [[#]]
; CHECK-SPIRV: ClampStochasticRoundFToSINTEL [[#Int4Ty]] [[#Conv:]] [[#DoubleConst]] [[#Int32Const]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: fp64_int4_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP64ToInt4INTELdi(double 1.000000e+00, i32 1)
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @fp64_int4_stochastic() {
entry:
  %0 = call spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP64ToInt4INTELdi(double 1.0, i32 1)
  ret i4 %0
}

declare dso_local spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP64ToInt4INTELdi(double, i32)

; CHECK-SPIRV: Function [[#]] [[#hf16_bf8_clamp_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#BFloat8Ty]] [[#SatStHfE5M2]] [[#HalfConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatStHfE5M2]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: hf16_bf8_clamp_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToE5M2INTELDhi(half 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @hf16_bf8_clamp_stochastic() {
entry:
  %0 = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToE5M2INTELDhi(half 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToE5M2INTELDhi(half, i32)

; CHECK-SPIRV: Function [[#]] [[#bf16_bf8_clamp_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#BFloat8Ty]] [[#SatStBfE5M2]] [[#BfloatConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatStBfE5M2]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: bf16_bf8_clamp_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundBF16ToE5M2INTELDF16bi(bfloat 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @bf16_bf8_clamp_stochastic() {
entry:
  %0 = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundBF16ToE5M2INTELDF16bi(bfloat 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundBF16ToE5M2INTELDF16bi(bfloat, i32)

; CHECK-SPIRV: Function [[#]] [[#hf16_hf8_clamp_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#HFloat8Ty]] [[#SatStHfE4M3]] [[#HalfConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatStHfE4M3]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: hf16_hf8_clamp_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToE4M3INTELDhi(half 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @hf16_hf8_clamp_stochastic() {
entry:
  %0 = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToE4M3INTELDhi(half 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToE4M3INTELDhi(half, i32)

; CHECK-SPIRV: Function [[#]] [[#bf16_hf8_clamp_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#HFloat8Ty]] [[#SatStBfE4M3]] [[#BfloatConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatStBfE4M3]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: bf16_hf8_clamp_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundBF16ToE4M3INTELDF16bi(bfloat 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @bf16_hf8_clamp_stochastic() {
entry:
  %0 = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundBF16ToE4M3INTELDF16bi(bfloat 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundBF16ToE4M3INTELDF16bi(bfloat, i32)

; CHECK-SPIRV: Function [[#]] [[#fp32_bf8_clamp_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#BFloat8Ty]] [[#SatStF32E5M2]] [[#FloatConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatStF32E5M2]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp32_bf8_clamp_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP32ToE5M2INTELfi(float 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp32_bf8_clamp_stochastic() {
entry:
  %0 = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP32ToE5M2INTELfi(float 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP32ToE5M2INTELfi(float, i32)

; CHECK-SPIRV: Function [[#]] [[#fp32_hf8_clamp_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#HFloat8Ty]] [[#SatStF32E4M3]] [[#FloatConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatStF32E4M3]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp32_hf8_clamp_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP32ToE4M3INTELfi(float 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp32_hf8_clamp_stochastic() {
entry:
  %0 = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP32ToE4M3INTELfi(float 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP32ToE4M3INTELfi(float, i32)

; CHECK-SPIRV: Function [[#]] [[#fp64_bf8_clamp_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#BFloat8Ty]] [[#SatStF64E5M2]] [[#DoubleConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatStF64E5M2]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp64_bf8_clamp_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP64ToE5M2INTELdi(double 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp64_bf8_clamp_stochastic() {
entry:
  %0 = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP64ToE5M2INTELdi(double 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP64ToE5M2INTELdi(double, i32)

; CHECK-SPIRV: Function [[#]] [[#fp64_hf8_clamp_stochastic]] [[#]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#HFloat8Ty]] [[#SatStF64E4M3]] [[#DoubleConst]] [[#Int32Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatStF64E4M3]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: fp64_hf8_clamp_stochastic
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP64ToE4M3INTELdi(double 1.000000e+00, i32 1)
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @fp64_hf8_clamp_stochastic() {
entry:
  %0 = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP64ToE4M3INTELdi(double 1.0, i32 1)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP64ToE4M3INTELdi(double, i32)

; CHECK-SPIRV: Function [[#]] [[#hf16_bf8_stochastic_last_seed]] [[#]]
; CHECK-SPIRV: Variable [[#]] [[#Ptr:]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#BFloat8Ty]] [[#Conv:]] [[#HalfConst]] [[#Int32Const]] [[#Ptr]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: hf16_bf8_stochastic_last_seed
; CHECK-LLVM: %[[#Ptr:]] = alloca i32
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP16ToE5M2INTELDhiPi(half 1.000000e+00, i32 1, ptr %[[#Ptr]])
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @hf16_bf8_stochastic_last_seed() {
entry:
  %0 = alloca i32
  %1 = call spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP16ToE5M2INTELDhiPi(half 1.0, i32 1, ptr %0)
  ret i8 %1
}

declare dso_local spir_func i8 @_Z46__builtin_spirv_StochasticRoundFP16ToE5M2INTELDhiPi(half, i32, ptr)

; CHECK-SPIRV: Function [[#]] [[#hf16_int4_stochastic_last_seed]] [[#]]
; CHECK-SPIRV: Variable [[#]] [[#Ptr:]]
; CHECK-SPIRV: ClampStochasticRoundFToSINTEL [[#Int4Ty]] [[#Conv:]] [[#HalfConst]] [[#Int32Const]] [[#Ptr]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: hf16_int4_stochastic_last_seed
; CHECK-LLVM: %[[#Ptr:]] = alloca i32
; CHECK-LLVM: %[[#Call:]] = call spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToInt4INTELDhiPi(half 1.000000e+00, i32 1, ptr %[[#Ptr]])
; CHECK-LLVM: ret i4 %[[#Call]]

define spir_func i4 @hf16_int4_stochastic_last_seed() {
entry:
  %0 = alloca i32
  %1 = call spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToInt4INTELhiPi(half 1.0, i32 1, ptr %0)
  ret i4 %1
}

declare dso_local spir_func i4 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToInt4INTELhiPi(half, i32, ptr)

; CHECK-SPIRV: Function [[#]] [[#hf16_bf8_clamp_stochastic_last_seed]] [[#]]
; CHECK-SPIRV: Variable [[#]] [[#Ptr:]]
; CHECK-SPIRV: StochasticRoundFToFINTEL [[#BFloat8Ty]] [[#SatStHfE5M2LS]] [[#HalfConst]] [[#Int32Const]] [[#Ptr]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast:]] [[#SatStHfE5M2LS]]
; CHECK-SPIRV: ReturnValue [[#Cast]]

; CHECK-LLVM-LABEL: hf16_bf8_clamp_stochastic_last_seed
; CHECK-LLVM: %[[#Ptr:]] = alloca i32
; CHECK-LLVM: %[[#Call:]] = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToE5M2INTELDhiPi(half 1.000000e+00, i32 1, ptr %[[#Ptr]])
; CHECK-LLVM: ret i8 %[[#Call]]

define spir_func i8 @hf16_bf8_clamp_stochastic_last_seed() {
entry:
  %0 = alloca i32
  %1 = call spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToE5M2INTELDhiPi(half 1.0, i32 1, ptr %0)
  ret i8 %1
}

declare dso_local spir_func i8 @_Z51__builtin_spirv_ClampStochasticRoundFP16ToE5M2INTELDhiPi(half, i32, ptr)
