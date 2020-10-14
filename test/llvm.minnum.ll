; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM


target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV: Function
; CHECK-SPIRV: FunctionParameter {{[0-9]+}} [[x:[0-9]+]]
; CHECK-SPIRV: FunctionParameter {{[0-9]+}} [[y:[0-9]+]]
; CHECK-SPIRV: ExtInst {{[0-9]+}} [[res:[0-9]+]] {{[0-9]+}} fmin [[x]] [[y]]
; CHECK-SPIRV: ReturnValue [[res]]
define spir_func float @TestFloat(float %x, float %y) {
entry:
  ; CHECK-LLVM: call spir_func float @_Z4fminff(float %{{.+}}, float %{{.+}})
  %0 = call float @llvm.minnum.f32(float %x, float %y)
  ret float %0
}
; CHECK-LLVM-DAG: declare spir_func float @_Z4fminff(float, float)

; CHECK-SPIRV: Function
; CHECK-SPIRV: FunctionParameter {{[0-9]+}} [[x:[0-9]+]]
; CHECK-SPIRV: FunctionParameter {{[0-9]+}} [[y:[0-9]+]]
; CHECK-SPIRV: ExtInst {{[0-9]+}} [[res:[0-9]+]] {{[0-9]+}} fmin [[x]] [[y]]
; CHECK-SPIRV: ReturnValue [[res]]
define spir_func double @TestDouble(double %x, double %y) {
entry:
  ; CHECK-LLVM: call spir_func double @_Z4fmindd(double %{{.+}}, double %{{.+}})
  %0 = call double @llvm.minnum.f64(double %x, double %y)
  ret double %0
}
; CHECK-LLVM-DAG: declare spir_func double @_Z4fmindd(double, double)

declare float @llvm.minnum.f32(float, float)
declare double @llvm.minnum.f64(double, double)
