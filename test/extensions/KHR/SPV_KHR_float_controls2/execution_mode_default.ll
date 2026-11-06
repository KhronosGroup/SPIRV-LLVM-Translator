; RUN: llvm-spirv --spirv-ext=+SPV_KHR_float_controls2 -spirv-text %s -o - | FileCheck %s --check-prefix=SPIRV
; RUN: llvm-spirv --spirv-ext=+SPV_KHR_float_controls2 %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=IR

; By default, FPFastMathDefault with no flags is set for all float types.
; As a sanity check, we still reverse-translate and check the IR.
; 6028 is FPFastMathDefault
; SPIRV: Capability FloatControls2
; SPIRV: Extension "SPV_KHR_float_controls2"
; SPIRV: EntryPoint {{[0-9]+}} [[#FOO:]] "foo"
; SPIRV-DAG: TypeFloat [[#HALF:]] 16
; SPIRV-DAG: TypeFloat [[#FLOAT:]] 32
; SPIRV-DAG: TypeFloat [[#DOUBLE:]] 64
; SPIRV-DAG: Constant {{[0-9]+}} [[#ZERO:]] 0
; SPIRV-DAG: ExecutionModeId [[#FOO]] 6028 [[#HALF]] [[#ZERO]]
; SPIRV-DAG: ExecutionModeId [[#FOO]] 6028 [[#FLOAT]] [[#ZERO]]
; SPIRV-DAG: ExecutionModeId [[#FOO]] 6028 [[#DOUBLE]] [[#ZERO]]
; SPIRV-DAG: Decorate [[#RH:]] FPFastMathMode 65536
; SPIRV-DAG: Decorate [[#RF:]] FPFastMathMode 65536
; SPIRV-DAG: Decorate [[#RD:]] FPFastMathMode 65536
; SPIRV-DAG: FAdd [[#HALF]] [[#RH]]
; SPIRV-DAG: FAdd [[#FLOAT]] [[#RF]]
; SPIRV-DAG: FAdd [[#DOUBLE]] [[#RD]]

target triple = "spirv-unknown-unknown"

define spir_kernel void @foo(half %ah, half %bh, float %af, float %bf, double %ad, double %bd) {
entry:
  ; IR-LABEL: define {{.*}} @foo
  ; IR-NEXT: entry:
  ; IR-NEXT:   %{{.*}} = fadd contract half %{{.*}}, %{{.*}}
  ; IR-NEXT:   %{{.*}} = fadd contract float %{{.*}}, %{{.*}}
  ; IR-NEXT:   %{{.*}} = fadd contract double %{{.*}}, %{{.*}}
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
  ; IR-NEXT:   %{{.*}} = fadd contract half %{{.*}}, %{{.*}}
  ; IR-NEXT:   %{{.*}} = fadd contract float %{{.*}}, %{{.*}}
  ; IR-NEXT:   %{{.*}} = fadd contract double %{{.*}}, %{{.*}}
  %rh = fadd contract half %ah, %bh
  %rf = fadd contract float %af, %bf
  %rd = fadd contract double %ad, %bd
  ret void
}
