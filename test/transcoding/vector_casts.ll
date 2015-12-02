; ModuleID = 'in.bc'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s

; OpenCL C/C++ doesn't support vector casts. Check what convert_gentypeN built-ins
; which translated into undecorated vector casts in SPIR-V are translated back
; to calls to built-ins. This test doesn't cover all possible combinations of the casts;
; there are to many of them. I hope it will be enought to catch regressions at early stage.

; CHECK:      _Z13convert_uint4Dv4_f
; CHECK-NOT:  fptoui

; Function Attrs: nounwind
define spir_kernel void @test_vector_casts(<4 x float> %in, <4 x i32> addrspace(1)* nocapture %out) #0 {
entry:
  %call = tail call spir_func <4 x i32> @_Z13convert_uint4Dv4_f(<4 x float> %in) #1
  store <4 x i32> %call, <4 x i32> addrspace(1)* %out, align 16
  ret void
}

; Function Attrs: nounwind readnone
declare spir_func <4 x i32> @_Z13convert_uint4Dv4_f(<4 x float>) #1

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!6}
!opencl.used.extensions = !{!7}
!opencl.used.optional.core.features = !{!7}
!opencl.compiler.options = !{!7}

!0 = !{void (<4 x float>, <4 x i32> addrspace(1)*)* @test_vector_casts, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 0, i32 1}
!2 = !{!"kernel_arg_access_qual", !"none", !"none"}
!3 = !{!"kernel_arg_type", !"float4", !"uint4*"}
!4 = !{!"kernel_arg_base_type", !"float4", !"uint4*"}
!5 = !{!"kernel_arg_type_qual", !"", !""}
!6 = !{i32 1, i32 2}
!7 = !{}
