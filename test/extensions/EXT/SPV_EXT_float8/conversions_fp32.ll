; FP32 <-> FP8 conversions: the __builtin_spirv_*FP32* names map to OpFConvert
; with a 32-bit float operand and round-trip back to the same builtin names.

; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_EXT_float8
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.spv --to-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spv -r -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: Capability Float8EXT
; CHECK-SPIRV-DAG: Extension "SPV_EXT_float8"

; CHECK-SPIRV-DAG: TypeInt [[#Int8Ty:]] 8 0
; CHECK-SPIRV-DAG: TypeFloat [[#FloatTy:]] 32 {{$}}
; CHECK-SPIRV-DAG: TypeFloat [[#E4M3Ty:]] 8 4214
; CHECK-SPIRV-DAG: TypeFloat [[#E5M2Ty:]] 8 4215

; CHECK-SPIRV-DAG: Decorate [[#ClampE4M3:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV-DAG: Decorate [[#ClampE5M2:]] SaturatedToLargestFloat8NormalConversionEXT

; CHECK-SPIRV: FunctionParameter [[#FloatTy]] [[#F:]]
; CHECK-SPIRV: FunctionParameter [[#Int8Ty]] [[#X:]]
; CHECK-SPIRV: FConvert [[#E4M3Ty]] [[#]] [[#F]]
; CHECK-SPIRV: FConvert [[#E4M3Ty]] [[#ClampE4M3]] [[#F]]
; CHECK-SPIRV: Bitcast [[#E4M3Ty]] [[#E4M3Src:]] [[#X]]
; CHECK-SPIRV: FConvert [[#FloatTy]] [[#]] [[#E4M3Src]]
; CHECK-SPIRV: FConvert [[#E5M2Ty]] [[#]] [[#F]]
; CHECK-SPIRV: FConvert [[#E5M2Ty]] [[#ClampE5M2]] [[#F]]
; CHECK-SPIRV: Bitcast [[#E5M2Ty]] [[#E5M2Src:]] [[#X]]
; CHECK-SPIRV: FConvert [[#FloatTy]] [[#]] [[#E5M2Src]]

; CHECK-LLVM: call spir_func i8 @_Z36__builtin_spirv_ConvertFP32ToE4M3EXTf(float
; CHECK-LLVM: call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE4M3INTELf(float
; CHECK-LLVM: call spir_func float @_Z36__builtin_spirv_ConvertE4M3ToFP32EXTc(i8
; CHECK-LLVM: call spir_func i8 @_Z36__builtin_spirv_ConvertFP32ToE5M2EXTf(float
; CHECK-LLVM: call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE5M2INTELf(float
; CHECK-LLVM: call spir_func float @_Z36__builtin_spirv_ConvertE5M2ToFP32EXTc(i8

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func void @test(float %f, i8 %x) {
entry:
  %e4m3 = call spir_func i8 @_Z36__builtin_spirv_ConvertFP32ToE4M3EXTf(float %f)
  %clamp_e4m3 = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE4M3INTELf(float %f)
  %f_e4m3 = call spir_func float @_Z36__builtin_spirv_ConvertE4M3ToFP32EXTc(i8 %x)
  %e5m2 = call spir_func i8 @_Z36__builtin_spirv_ConvertFP32ToE5M2EXTf(float %f)
  %clamp_e5m2 = call spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE5M2INTELf(float %f)
  %f_e5m2 = call spir_func float @_Z36__builtin_spirv_ConvertE5M2ToFP32EXTc(i8 %x)
  store i8 %e4m3, ptr addrspace(1) null
  store i8 %clamp_e4m3, ptr addrspace(1) null
  store float %f_e4m3, ptr addrspace(1) null
  store i8 %e5m2, ptr addrspace(1) null
  store i8 %clamp_e5m2, ptr addrspace(1) null
  store float %f_e5m2, ptr addrspace(1) null
  ret void
}

declare spir_func i8 @_Z36__builtin_spirv_ConvertFP32ToE4M3EXTf(float)
declare spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE4M3INTELf(float)
declare spir_func float @_Z36__builtin_spirv_ConvertE4M3ToFP32EXTc(i8)
declare spir_func i8 @_Z36__builtin_spirv_ConvertFP32ToE5M2EXTf(float)
declare spir_func i8 @_Z43__builtin_spirv_ClampConvertFP32ToE5M2INTELf(float)
declare spir_func float @_Z36__builtin_spirv_ConvertE5M2ToFP32EXTc(i8)
