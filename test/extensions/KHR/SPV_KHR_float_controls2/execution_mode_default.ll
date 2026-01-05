; RUN: llvm-spirv --spirv-ext=+SPV_KHR_float_controls2 -spirv-text %s -o - | FileCheck %s --check-prefix=SPIRV
; RUN: llvm-spirv --spirv-ext=+SPV_KHR_float_controls2 %s -o %t.spv
; RUN: spirv-val %t.spv

; SPIRV: 4 EntryPoint {{[0-9]+}} [[#foo:]] "foo"
; SPIRV-DAG: 3 Name [[#bar:]] "bar"
;
; SPIRV-DAG: 4 Constant {{[0-9]+}} [[#zero:]] 0
;
; SPIRV-DAG: 3 TypeFloat [[#half:]] 16
; SPIRV-DAG: 3 TypeFloat [[#float:]] 32
; SPIRV-DAG: 3 TypeFloat [[#double:]] 64
;
; 6028 is FPFastMathDefault 
; SPIRV-DAG: 5 ExecutionModeId [[#foo]] 6028 [[#half]] [[#zero]]
; SPIRV-DAG: 5 ExecutionModeId [[#foo]] 6028 [[#float]] [[#zero]]
; SPIRV-DAG: 5 ExecutionModeId [[#foo]] 6028 [[#double]] [[#zero]]
; SPIRV-NOT: 5 ExecutionModeId [[#bar]] 6028

target triple = "spirv-unknown-unknown"

define spir_kernel void @foo(half %ah, half %bh, float %af, float %bf, double %ad, double %bd) {
entry:
  %rh = fadd contract half %ah, %bh
  %rf = fadd contract float %af, %bf
  %rd = fadd contract double %ad, %bd
  call void @bar(half %rh, half %bh, float %rf, float %bf, double %rd, double %bd)
  ret void
}

define internal void @bar(half %ah, half %bh, float %af, float %bf, double %ad, double %bd) {
entry:
  %rh = fadd contract half %ah, %bh
  %rf = fadd contract float %af, %bf
  %rd = fadd contract double %ad, %bd
  ret void
}
