; RUN: llvm-as < %s | llvm-spirv -spirv-text -o %t
; RUN: FileCheck < %t %s
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: Source 3 21
; CHECK: ExtInstImport 0 "OpenCL.std.21"
; CHECK: "_Z6workerv"
; Function Attrs: nounwind
define spir_kernel void @_Z6workerv() #0 {
  %tmp = alloca i32, align 4
; CHECK: Decorate {{[0-9]+}} BuiltIn 36
; CHECK-NOT: _ZN2cl7__spirv18get_sub_group_sizeEv
  %1 = call spir_func i32 @_ZN2cl7__spirv18get_sub_group_sizeEv()
  store i32 %1, i32* %tmp, align 4
  ret void
}

declare spir_func i32 @_ZN2cl7__spirv18get_sub_group_sizeEv() #1

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
