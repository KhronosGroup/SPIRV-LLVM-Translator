; RUN: llvm-spirv --spirv-ext=+SPV_KHR_float_controls2 -spirv-text %s -o - | FileCheck %s --check-prefix=SPIRV
; RUN: llvm-spirv --spirv-ext=+SPV_KHR_float_controls2 %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=IR

; SPIRV: EntryPoint {{[0-9]+}} [[#foo:]] "foo"
; SPIRV-DAG: Name [[#bar:]] "bar"
;
; SPIRV-DAG: Constant {{[0-9]+}} [[#zero:]] 0
;
; SPIRV-DAG: TypeFloat [[#half:]] 16
; SPIRV-DAG: TypeFloat [[#float:]] 32
; SPIRV-DAG: TypeFloat [[#double:]] 64
;
; 6028 is FPFastMathDefault 
; SPIRV-DAG: ExecutionModeId [[#foo]] 6028 [[#half]] [[#zero]]
; SPIRV-DAG: ExecutionModeId [[#foo]] 6028 [[#float]] [[#zero]]
; SPIRV-DAG: ExecutionModeId [[#foo]] 6028 [[#double]] [[#zero]]
; SPIRV-NOT: ExecutionModeId [[#bar]] 6028

target triple = "spirv-unknown-unknown"

define spir_kernel void @foo(half %ah, half %bh, float %af, float %bf, double %ad, double %bd) {
entry:
  ; IR-LABEL: define {{.*}} @foo
  ; IR-NEXT: entry:
  ; IR-NEXT:   %rh = fadd contract half %ah, %bh
  ; IR-NEXT:   %rf = fadd contract float %af, %bf
  ; IR-NEXT:   %rd = fadd contract double %ad, %bd
  ; IR-NEXT    call void @bar(half %rh, half %bh, float %rf, float %bf, double %rd, double %bd)
  %rh = fadd contract half %ah, %bh
  %rf = fadd contract float %af, %bf
  %rd = fadd contract double %ad, %bd
  call void @bar(half %rh, half %bh, float %rf, float %bf, double %rd, double %bd)
  ret void
}

define internal void @bar(half %ah, half %bh, float %af, float %bf, double %ad, double %bd) {
entry:
  ; IR-LABEL: define {{.*}} @bar
  ; IR-NEXT: entry:
  ; IR-NEXT:   %rh = fadd contract half %ah, %bh
  ; IR-NEXT:   %rf = fadd contract float %af, %bf
  ; IR-NEXT:   %rd = fadd contract double %ad, %bd
  %rh = fadd contract half %ah, %bh
  %rf = fadd contract float %af, %bf
  %rd = fadd contract double %ad, %bd
  ret void
}
