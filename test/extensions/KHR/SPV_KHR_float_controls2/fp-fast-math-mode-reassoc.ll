; Verify the 'reassoc' fast-math flag with SPV_KHR_float_controls2 enabled.
;
; The flag has no standalone SPIR-V representation: the extension requires
; AllowTransform together with AllowContract and AllowReassoc, hence 458752.
; Reverse translation therefore yields "reassoc contract"; the original
; spelling is not recoverable. Without the extension the flag is dropped.

; RUN: llvm-spirv %s -o - --spirv-text --spirv-ext=-SPV_KHR_float_controls2 | FileCheck %s --check-prefix=NO-FC2
; RUN: llvm-spirv %s -o - --spirv-text --spirv-ext=+SPV_KHR_float_controls2 | FileCheck %s --check-prefix=SPIRV
; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_KHR_float_controls2
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=IR

target triple = "spirv-unknown-unknown"

; NO-FC2-NOT: FPFastMathMode

; SPIRV: Capability FloatControls2
; SPIRV-DAG: FAdd [[#]] [[#RESULT:]] [[#]] [[#]]
; SPIRV-DAG: Decorate [[#RESULT]] FPFastMathMode 458752

define spir_kernel void @foo(ptr addrspace(1) %out, float %a, float %b) {
entry:
  ; IR-LABEL: define {{.*}} @foo
  ; IR-NEXT: entry:
  ; IR-NEXT: %{{.*}} = fadd reassoc contract float %{{.*}}, %{{.*}}
  ; IR-NEXT: store float {{.*}}, ptr addrspace(1) {{.*}}, align 4
  ; IR-NEXT: ret void
  %r = fadd reassoc float %a, %b
  store float %r, ptr addrspace(1) %out, align 4
  ret void
}
