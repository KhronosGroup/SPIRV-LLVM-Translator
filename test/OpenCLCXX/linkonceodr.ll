; RUN: llvm-as < %s | llvm-spirv -spirv-text -o %t
; RUN: FileCheck < %t %s
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: nounwind
define spir_kernel void @_Z10testKernelv() #0 {
entry:
  %var = alloca i32, align 4
  %call = call spir_func i32 @_Z4FuncIiET_S0_(i32 10)
  store i32 %call, i32* %var, align 4
  ret void
}

; CHECK: Source 3 21
; CHECK: EntryPoint 6 3
; CHECK: ExtInstImport 0 "OpenCL.std"
; CHECK: _Z4FuncIiET_S0_
; Function Attrs: nounwind
define linkonce_odr spir_func i32 @_Z4FuncIiET_S0_(i32 %var) #0 {
entry:
  %var.addr = alloca i32, align 4
  store i32 %var, i32* %var.addr, align 4
  %0 = load i32* %var.addr, align 4
  %add = add nsw i32 %0, 5
  ret i32 %add
}

attributes #0 = { nounwind }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!6}
!opencl.used.extensions = !{!7}
!opencl.used.optional.core.features = !{!7}
!opencl.compiler.options = !{!7}

!0 = !{void ()* @_Z10testKernelv, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space"}
!2 = !{!"kernel_arg_access_qual"}
!3 = !{!"kernel_arg_type"}
!4 = !{!"kernel_arg_type_qual"}
!5 = !{!"kernel_arg_base_type"}
!6 = !{i32 2, i32 1}
!7 = !{}
