; An FP16 conversion builtin called with an FP64 operand.
; The builtin name fixes the IEEE754 operand width, so the forward translator
; must reject a call whose operand type does not match it.

; RUN: llvm-as %s -o %t.bc
; RUN: not llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_EXT_float8 2>&1 | FileCheck %s

; CHECK: Floating-point conversion builtin name does not match the operand types
; CHECK: call spir_func i8 @_Z36__builtin_spirv_ConvertFP16ToE4M3EXTd(double

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_func i8 @test(double %a) {
entry:
  %c = call spir_func i8 @_Z36__builtin_spirv_ConvertFP16ToE4M3EXTd(double %a)
  ret i8 %c
}

declare spir_func i8 @_Z36__builtin_spirv_ConvertFP16ToE4M3EXTd(double)
