; RUN: llvm-as < %s | llvm-spirv -spirv-text -o %t
; RUN: FileCheck < %t %s
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: Source 3 21
; CHECK: ExtInstImport 0 "OpenCL.std"
; CHECK: "_Z4testv"
; Function Attrs: nounwind
define spir_kernel void @_Z4testv() #0 {
; CHECK: 6 ExtInst {{[0-9]+}} {{[0-9]+}} {{[0-9]+}} sin {{[0-9]+}}
  %call = call spir_func float @_ZN2cl7__spirv3sinEf(float 1.000000e+00)
; CHECK: 6 ExtInst {{[0-9]+}} {{[0-9]+}} {{[0-9]+}} sin {{[0-9]+}}
  %call1 = call spir_func <2 x float> @_ZN2cl7__spirv3sinEDv2_f(<2 x float> <float 1.000000e+00, float 2.000000e+00>)
  ret void
}

declare spir_func float @_ZN2cl7__spirv3sinEf(float)

declare spir_func <2 x float> @_ZN2cl7__spirv3sinEDv2_f(<2 x float>)

attributes #0 = { nounwind }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}

!0 = !{void ()* @_Z4testv, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space"}
!2 = !{!"kernel_arg_access_qual"}
!3 = !{!"kernel_arg_type"}
!4 = !{!"kernel_arg_base_type"}
!5 = !{!"kernel_arg_type_qual"}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 1}
!8 = !{}
