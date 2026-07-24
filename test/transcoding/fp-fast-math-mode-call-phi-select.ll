; Verify that FPFastMathMode decorations are emitted for call, phi, and select
; instructions only when SPV_KHR_float_controls2 is enabled. Base SPIR-V 1.6
; extended FPFastMathMode to FNeg/FCmp/ExtInst, but Call/PHI/Select require FC2.

; RUN: llvm-as %s -o %t.bc

; Without FC2: no decorations on call/phi/select
; RUN: llvm-spirv -spirv-text %t.bc --spirv-max-version=1.5 -o - | FileCheck %s --check-prefix=CHECK-NO-DECO
; RUN: llvm-spirv -spirv-text %t.bc -o - | FileCheck %s --check-prefix=CHECK-NO-DECO

; With FC2: decorations emitted
; RUN: llvm-spirv -spirv-text %t.bc --spirv-ext=+SPV_KHR_float_controls2 -o - | FileCheck %s --check-prefix=CHECK-FC2

; Roundtrip with FC2
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_float_controls2 -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-RT

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; User-defined function — translates to OpFunctionCall, not ExtInst.
define internal float @helper(float %x) {
  %r = fmul float %x, %x
  ret float %r
}

; CHECK-NO-DECO-NOT: FPFastMathMode

; CHECK-FC2: {{[0-9]+}} Name [[#CALL:]] "call_fast"
; CHECK-FC2: {{[0-9]+}} Name [[#SEL:]] "sel_fast"
; CHECK-FC2: {{[0-9]+}} Name [[#PHI:]] "phi_fast"
; CHECK-FC2-DAG: Decorate [[#CALL]] FPFastMathMode 458767
; CHECK-FC2-DAG: Decorate [[#SEL]] FPFastMathMode 458767
; CHECK-FC2-DAG: Decorate [[#PHI]] FPFastMathMode 458767

define spir_kernel void @test(float %a, float %b, i1 %cond) {
entry:
  %tmp = alloca float, align 4

  ; CHECK-RT: %call_fast = call reassoc nnan ninf nsz arcp contract spir_func float @helper(float %a)
  %call_fast = call fast float @helper(float %a)
  store volatile float %call_fast, ptr %tmp, align 4

  ; CHECK-RT: %sel_fast = select reassoc nnan ninf nsz arcp contract i1 %cond, float %a, float %b
  %sel_fast = select fast i1 %cond, float %a, float %b
  store volatile float %sel_fast, ptr %tmp, align 4

  br i1 %cond, label %left, label %right

left:
  %val_left = fadd float %a, %b
  br label %merge

right:
  %val_right = fsub float %a, %b
  br label %merge

merge:
  ; CHECK-RT: %phi_fast = phi reassoc nnan ninf nsz arcp contract float
  %phi_fast = phi fast float [ %val_left, %left ], [ %val_right, %right ]
  store volatile float %phi_fast, ptr %tmp, align 4

  ret void
}
