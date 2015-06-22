; RUN: llvm-as < %s | llvm-spirv -spirv-text -o %t
; RUN: FileCheck < %t %s
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: Source 3 21
; CHECK: ExtInstImport 0 "OpenCL.std.21"
; CHECK: "_Z6workerv"
; Function Attrs: nounwind
define spir_kernel void @_Z6workerv() #0 {
  %i = alloca i32, align 4
  %tmp = alloca i32, align 4
  store i32 0, i32* %i, align 4
  br label %1

; <label>:1                                       ; preds = %8, %0
  %2 = load i32* %i, align 4
; CHECK-DAG: Decorate {{[0-9]+}} BuiltIn 30
; CHECK-NOT: _ZN2cl12get_work_dimEv
  %3 = call spir_func i32 @_ZN2cl12get_work_dimEv()
  %4 = icmp ult i32 %2, %3
  br i1 %4, label %5, label %11

; <label>:5                                       ; preds = %1
  %6 = load i32* %i, align 4
; CHECK-DAG: Decorate {{[0-9]+}} BuiltIn 31
; CHECK-NOT: _ZN2cl15get_global_sizeEj
  %7 = call spir_func i32 @_ZN2cl15get_global_sizeEj(i32 %6)
  store i32 %7, i32* %tmp, align 4
  br label %8

; <label>:8                                       ; preds = %5
  %9 = load i32* %i, align 4
  %10 = add i32 %9, 1
  store i32 %10, i32* %i, align 4
  br label %1

; <label>:11                                      ; preds = %1
  ret void
}

declare spir_func i32 @_ZN2cl12get_work_dimEv() #1

declare spir_func i32 @_ZN2cl15get_global_sizeEj(i32) #1

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!6}
!opencl.used.extensions = !{!7}
!opencl.used.optional.core.features = !{!7}
!opencl.compiler.options = !{!7}

!0 = !{void ()* @_Z6workerv, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space"}
!2 = !{!"kernel_arg_access_qual"}
!3 = !{!"kernel_arg_type"}
!4 = !{!"kernel_arg_type_qual"}
!5 = !{!"kernel_arg_base_type"}
!6 = !{i32 2, i32 1}
!7 = !{}
