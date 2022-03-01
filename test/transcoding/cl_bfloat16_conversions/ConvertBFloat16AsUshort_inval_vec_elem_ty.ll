; RUN: llvm-as %s -o %t.bc
; RUN: not --crash llvm-spirv %t.bc -o %t.spv 2>&1 | FileCheck %s --check-prefix=CHECK-ERROR

; CHECK-ERROR: "OpConvertBFloat16NAsUShortN must be of <N x i16> and take <N x " "float>"

; ModuleID = 'kernel.cl'
source_filename = "kernel.cl"
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir"

; Function Attrs: convergent noinline norecurse nounwind optnone
define dso_local spir_kernel void @f() #0 !kernel_arg_addr_space !1 !kernel_arg_access_qual !1 !kernel_arg_type !1 !kernel_arg_base_type !1 !kernel_arg_type_qual !1 !kernel_arg_host_accessible !1 !kernel_arg_pipe_depth !1 !kernel_arg_pipe_io !1 !kernel_arg_buffer_location !1 {
entry:
  %call = call spir_func <2 x i32> @_Z34intel_convert_bfloat162_as_ushort2Dv2_f(<2 x double> zeroinitializer) #2
  ret void
}

; Function Attrs: convergent
declare spir_func <2 x i32> @_Z34intel_convert_bfloat162_as_ushort2Dv2_f(<2 x double>) #1

attributes #0 = { convergent noinline norecurse nounwind optnone "frame-pointer"="none" "min-legal-vector-width"="512" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #1 = { convergent "frame-pointer"="none" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { convergent }

!opencl.enable.FP_CONTRACT = !{}
!opencl.ocl.version = !{!0}
!opencl.spir.version = !{!0}
!opencl.used.extensions = !{!1}
!opencl.used.optional.core.features = !{!1}
!opencl.compiler.options = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 2, i32 0}
!1 = !{}
!2 = !{!"Compiler"}
