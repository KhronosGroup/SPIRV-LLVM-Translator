; RUN: llvm-spirv -spirv-text %s -o - | FileCheck %s
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv
;
; CHECK: Name [[#CMP:]] "oltRes"
; CHECK-DAG: FOrdLessThan [[#BOOL:]] [[#CMP]]
; CHECK-DAG: Decorate [[#CMP]] FPFastMathMode 1
; CHECK-NOT: Decorate [[#CMP]] FPFastMathMode 16

target triple = "spirv-unknown-unknown"

define void @foo(float %1, float %2) {
  entry:
    %oltRes = fcmp nnan olt float %1,  %2, !spirv.Decorations !1
    ret void
}

!1 = !{!2}
!2 = !{i32 40, i32 16} ; 40 is FPFastMathMode
