; An FP8 -> FP32 conversion builtin returning FP16.
; The builtin name fixes the IEEE754 result width, so the forward translator
; must reject a call whose result type does not match it.

; RUN: llvm-as %s -o %t.bc
; RUN: not llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_EXT_float8 2>&1 | FileCheck %s

; CHECK: Floating-point conversion builtin name does not match the operand types
; CHECK: call spir_func half @_Z36__builtin_spirv_ConvertE4M3ToFP32EXTc(i8

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func half @test(i8 %a) {
entry:
  %c = call spir_func half @_Z36__builtin_spirv_ConvertE4M3ToFP32EXTc(i8 %a)
  ret half %c
}

declare spir_func half @_Z36__builtin_spirv_ConvertE4M3ToFP32EXTc(i8)
