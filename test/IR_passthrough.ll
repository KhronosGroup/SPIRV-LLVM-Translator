; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv -r -ir-passthrough %t.bc -o %t.ir-passthrough.bc
; RUN: llvm-dis %t.ir-passthrough.bc -o %t.ir-passthrough.ll
; RUN: FileCheck %s --input-file %t.ir-passthrough.ll --check-prefix CHECK-LLVM-COPY

; CHECK-LLVM-COPY: source_filename = "souce.cpp"
; CHECK-LLVM-COPY-NEXT: target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
; CHECK-LLVM-COPY-NEXT: target triple = "spir64"

; ModuleID = 'souce.cpp'
source_filename = "souce.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64"

; CHECK-LLVM-COPY: define dso_local i32 @main() #0 {
; CHECK-LLVM-COPY-NEXT: entry:
; CHECK-LLVM-COPY-NEXT: %retval = alloca i32, align 4
; CHECK-LLVM-COPY-NEXT: %pi = alloca double, align 8
; CHECK-LLVM-COPY-NEXT: %r = alloca double, align 8
; CHECK-LLVM-COPY-NEXT: %c = alloca double, align 8
; CHECK-LLVM-COPY-NEXT: store i32 0, i32* %retval, align 4
; CHECK-LLVM-COPY-NEXT: store double 3.140000e+00, double* %pi, align 8
; CHECK-LLVM-COPY-NEXT: store double 2.000000e+00, double* %r, align 8
; CHECK-LLVM-COPY-NEXT: %0 = load double, double* %pi, align 8
; CHECK-LLVM-COPY-NEXT: %1 = load double, double* %r, align 8
; CHECK-LLVM-COPY-NEXT: %mul = fmul double %0, %1
; CHECK-LLVM-COPY-NEXT: %2 = load double, double* %r, align 8
; CHECK-LLVM-COPY-NEXT: %mul1 = fmul double %mul, %2
; CHECK-LLVM-COPY-NEXT: store double %mul1, double* %c, align 8
; CHECK-LLVM-COPY-NEXT: ret i32 0

; Function Attrs: mustprogress noinline norecurse nounwind optnone
define dso_local i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %pi = alloca double, align 8
  %r = alloca double, align 8
  %c = alloca double, align 8
  store i32 0, i32* %retval, align 4
  store double 3.140000e+00, double* %pi, align 8
  store double 2.000000e+00, double* %r, align 8
  %0 = load double, double* %pi, align 8
  %1 = load double, double* %r, align 8
  %mul = fmul double %0, %1
  %2 = load double, double* %r, align 8
  %mul1 = fmul double %mul, %2
  store double %mul1, double* %c, align 8
  ret i32 0
}

attributes #0 = { mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }

!llvm.module.flags = !{!0, !1}
!opencl.used.extensions = !{!2}
!opencl.used.optional.core.features = !{!3}
!opencl.compiler.options = !{!2}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{}
!3 = !{!"cl_doubles"}
!4 = !{!"Compiler"}
