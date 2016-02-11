; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-LLVM: call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_i

; CHECK-SPIRV-DAG: 5 SampledImage {{[0-9]+}} {{[0-9]+}} {{[0-9]+}} [[SamplerID:[0-9]+]]
; CHECK-SPIRV-DAG: 6 ConstantSampler {{[0-9]+}} [[SamplerID]] 1 0 4294967295

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_t = type opaque

; Function Attrs: nounwind
define spir_kernel void @applySelection(%opencl.image2d_t addrspace(1)* %input, %opencl.image2d_t addrspace(1)* %selection, i32 %width, i32 %height, float %bleed, %opencl.image2d_t addrspace(1)* %output) #0 {
entry:
  %call = tail call spir_func i32 @_Z13get_global_idj(i32 0) #3
  %call1 = tail call spir_func i32 @_Z13get_global_idj(i32 1) #3
  %cmp = icmp slt i32 %call1, %height
  %cmp2 = icmp slt i32 %call, %width
  %or.cond = and i1 %cmp2, %cmp
  br i1 %or.cond, label %if.end, label %return

if.end:                                           ; preds = %entry
  %vecinit = insertelement <2 x i32> undef, i32 %call, i32 0
  %vecinit3 = insertelement <2 x i32> %vecinit, i32 %call1, i32 1
  %call5 = tail call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_i(%opencl.image2d_t addrspace(1)* %selection, i32 2, <2 x i32> %vecinit3) #3
  %0 = extractelement <4 x float> %call5, i32 0
  %sub = fsub float 1.000000e+00, %bleed
  %1 = tail call float @llvm.fmuladd.f32(float %sub, float %0, float %bleed)
  %splat.splatinsert = insertelement <4 x float> undef, float %1, i32 0
  %splat.splat = shufflevector <4 x float> %splat.splatinsert, <4 x float> undef, <4 x i32> zeroinitializer
  %call6 = tail call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_i(%opencl.image2d_t addrspace(1)* %input, i32 2, <2 x i32> %vecinit3) #3
  %mul = fmul <4 x float> %call6, %splat.splat
  tail call spir_func void @_Z12write_imagef11ocl_image2dDv2_iDv4_f(%opencl.image2d_t addrspace(1)* %output, <2 x i32> %vecinit3, <4 x float> %mul) #3
  br label %return

return:                                           ; preds = %entry, %if.end
  ret void
}

declare spir_func i32 @_Z13get_global_idj(i32) #1

declare spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_i(%opencl.image2d_t addrspace(1)*, i32, <2 x i32>) #1

declare spir_func void @_Z12write_imagef11ocl_image2dDv2_iDv4_f(%opencl.image2d_t addrspace(1)*, <2 x i32>, <4 x float>) #1

; Function Attrs: nounwind readnone
declare float @llvm.fmuladd.f32(float, float, float) #2

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readnone }
attributes #3 = { nounwind }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!9}
!opencl.compiler.options = !{!8}

!0 = !{void (%opencl.image2d_t addrspace(1)*, %opencl.image2d_t addrspace(1)*, i32, i32, float, %opencl.image2d_t addrspace(1)*)* @applySelection, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 1, i32 1, i32 0, i32 0, i32 0, i32 1}
!2 = !{!"kernel_arg_access_qual", !"read_only", !"read_only", !"none", !"none", !"none", !"write_only"}
!3 = !{!"kernel_arg_type", !"image2d_t", !"image2d_t", !"int", !"int", !"float", !"image2d_t"}
!4 = !{!"kernel_arg_base_type", !"image2d_t", !"image2d_t", !"int", !"int", !"float", !"image2d_t"}
!5 = !{!"kernel_arg_type_qual", !"", !"", !"", !"", !"", !""}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
!9 = !{!"cl_images"}
