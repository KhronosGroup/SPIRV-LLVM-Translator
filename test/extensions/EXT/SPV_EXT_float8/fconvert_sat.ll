; Saturated FP16 -> FP8 conversions: producer-side _sat suffix on the
; __builtin_spirv_Convert*EXT name maps to OpFConvert decorated with
; SaturatedToLargestFloat8NormalConversionEXT, and round-trips back.

; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_EXT_float8
; RUN: llvm-spirv %t.spv --to-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spv -r -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: Capability Float16Buffer
; CHECK-SPIRV-DAG: Capability Float8EXT
; CHECK-SPIRV-DAG: Extension "SPV_EXT_float8"

; CHECK-SPIRV-DAG: TypeFloat [[#HalfTy:]] 16 {{$}}
; CHECK-SPIRV-DAG: TypeFloat [[#E4M3Ty:]] 8 4214
; CHECK-SPIRV-DAG: TypeFloat [[#E5M2Ty:]] 8 4215

; CHECK-SPIRV-DAG: Decorate [[#E4M3Conv:]] SaturatedToLargestFloat8NormalConversionEXT
; CHECK-SPIRV-DAG: Decorate [[#E5M2Conv:]] SaturatedToLargestFloat8NormalConversionEXT

; CHECK-SPIRV: FunctionParameter [[#HalfTy]] [[#H:]]
; CHECK-SPIRV: FConvert [[#E4M3Ty]] [[#E4M3Conv]] [[#H]]
; CHECK-SPIRV: FConvert [[#E5M2Ty]] [[#E5M2Conv]] [[#H]]

; CHECK-LLVM: call spir_func i8 @_Z40__builtin_spirv_ConvertFP16ToE4M3EXT_satDh(half
; CHECK-LLVM: call spir_func i8 @_Z40__builtin_spirv_ConvertFP16ToE5M2EXT_satDh(half

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func void @test(half %h) {
entry:
  %e4m3 = call spir_func i8 @_Z40__builtin_spirv_ConvertFP16ToE4M3EXT_satDh(half %h)
  %e5m2 = call spir_func i8 @_Z40__builtin_spirv_ConvertFP16ToE5M2EXT_satDh(half %h)
  store i8 %e4m3, ptr addrspace(1) null
  store i8 %e5m2, ptr addrspace(1) null
  ret void
}

declare spir_func i8 @_Z40__builtin_spirv_ConvertFP16ToE4M3EXT_satDh(half)
declare spir_func i8 @_Z40__builtin_spirv_ConvertFP16ToE5M2EXT_satDh(half)
