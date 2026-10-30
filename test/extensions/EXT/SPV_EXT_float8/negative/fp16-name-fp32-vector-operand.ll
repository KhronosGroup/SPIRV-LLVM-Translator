; An FP16 conversion builtin called with a vector of FP32 operands.
; The operand width is checked on the element type, so the forward translator
; must reject a vector call whose element type does not match the name.

; RUN: llvm-as %s -o %t.bc
; RUN: not llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_EXT_float8 2>&1 | FileCheck %s

; CHECK: Floating-point conversion builtin name does not match the operand types
; CHECK: call spir_func <8 x i8> @_Z36__builtin_spirv_ConvertFP16ToE4M3EXTDv8_f(<8 x float>

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func <8 x i8> @test(<8 x float> %a) {
entry:
  %c = call spir_func <8 x i8> @_Z36__builtin_spirv_ConvertFP16ToE4M3EXTDv8_f(<8 x float> %a)
  ret <8 x i8> %c
}

declare spir_func <8 x i8> @_Z36__builtin_spirv_ConvertFP16ToE4M3EXTDv8_f(<8 x float>)
