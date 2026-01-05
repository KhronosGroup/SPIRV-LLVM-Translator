; RUN: llvm-spirv --spirv-ext=+SPV_KHR_float_controls2 -spirv-text %s -o - | FileCheck %s --check-prefix=SPIRV
; RUN: llvm-spirv --spirv-ext=+SPV_KHR_float_controls2 %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=IR

; SPIRV: Capability FloatControls2
; SPIRV: Extension "SPV_KHR_float_controls2"
;
; SPIRV: EntryPoint {{[0-9]+}} [[#foo:]] "foo"
; SPIRV-DAG: Name [[#bar:]] "bar"
;
; SPIRV-DAG: Constant {{[0-9]+}} [[#zero:]] 0
;
; SPIRV-DAG: TypeFloat [[#float:]] 32
;
; 6028 is FPFastMathDefault 
; SPIRV-DAG: ExecutionModeId [[#foo]] 6028 [[#float]] [[#zero]]
; SPIRV-NOT: ExecutionModeId [[#bar]] 6028

target triple = "spirv-unknown-unknown"

define spir_kernel void @foo(float %af, float %bf) {
entry:
  ; IR-LABEL: define {{.*}} @foo
  ; IR-NEXT: entry:
  ; IR-NEXT:   %rf = fadd nnan float %af, %bf
  ; IR-NEXT    call void @bar(float %rf, float %bf)
  %rf = fadd nnan float %af, %bf
  call void @bar(float %rf, float %bf)
  ret void
}

define internal void @bar(float %af, float %bf) {
entry:
  ; IR-LABEL: define {{.*}} @bar
  ; IR-NEXT: entry:
  ; IR-NEXT:   %rf = fadd nnan float %af, %bf
  %rf = fadd nnan float %af, %bf
  ret void
}
