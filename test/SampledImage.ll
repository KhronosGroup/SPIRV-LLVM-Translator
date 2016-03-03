; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: Capability LiteralSampler
; CHECK-SPIRV: EntryPoint 6 [[sample_kernel:[0-9]+]] "sample_kernel"

; ModuleID = '<stdin>'
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_t = type opaque

@imageSampler = constant i32 32, align 4
; CHECK-SPIRV: TypeSampler [[TypeSampler:[0-9]+]]
; CHECK-SPIRV: TypeSampledImage [[SampledImageTy:[0-9]+]]
; CHECK-SPIRV: ConstantSampler [[TypeSampler]] [[ConstSampler1:[0-9]+]] 0 0 1
; CHECK-SPIRV: ConstantSampler [[TypeSampler]] [[ConstSampler2:[0-9]+]] 3 0 0

; CHECK-LLVM: @imageSampler = constant i32 32

; Function Attrs: nounwind
define spir_kernel void @sample_kernel(%opencl.image2d_t addrspace(1)* %input, <2 x float> %coords, <4 x float> addrspace(1)* %results, i32 %argSampl) #0 {
; CHECK-SPIRV: Function {{.*}} [[sample_kernel]]
; CHECK-SPIRV: FunctionParameter {{.*}} [[InputImage:[0-9]+]]
; CHECK-SPIRV: FunctionParameter [[TypeSampler]] [[argSampl:[0-9]+]]
; CHECK-LLVM: define spir_kernel void @sample_kernel(%opencl.image2d_t addrspace(1)* %input, <2 x float> %coords, <4 x float> addrspace(1)* %results, i32 %argSampl)
entry:
  %0 = load i32* @imageSampler, align 4

  %call = call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_f(%opencl.image2d_t addrspace(1)* %input, i32 %0, <2 x float> %coords)
; CHECK-SPIRV: SampledImage [[SampledImageTy]] [[SampledImage1:[0-9]+]] [[InputImage]] [[ConstSampler1]]
; CHECK-SPIRV: ImageSampleExplicitLod {{.*}} [[SampledImage1]]
; CHECK-LLVM: call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_f(%opencl.image2d_t addrspace(1)* %input, i32 32, <2 x float> %coords)

  %arrayidx = getelementptr inbounds <4 x float> addrspace(1)* %results, i32 0
  store <4 x float> %call, <4 x float> addrspace(1)* %arrayidx, align 16

  %call1 = call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_f(%opencl.image2d_t addrspace(1)* %input, i32 %argSampl, <2 x float> %coords)
; CHECK-SPIRV: SampledImage [[SampledImageTy]] [[SampledImage2:[0-9]+]] [[InputImage]] [[argSampl]]
; CHECK-SPIRV: ImageSampleExplicitLod {{.*}} [[SampledImage2]]
; CHECK-LLVM: call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_f(%opencl.image2d_t addrspace(1)* %input, i32 %argSampl, <2 x float> %coords)

  %arrayidx2 = getelementptr inbounds <4 x float> addrspace(1)* %results, i32 0
  store <4 x float> %call1, <4 x float> addrspace(1)* %arrayidx2, align 16

  %call3 = call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_f(%opencl.image2d_t addrspace(1)* %input, i32 22, <2 x float> %coords)
; CHECK-SPIRV: SampledImage [[SampledImageTy]] [[SampledImage3:[0-9]+]] [[InputImage]] [[ConstSampler2]]
; CHECK-SPIRV: ImageSampleExplicitLod {{.*}} [[SampledImage3]]
; CHECK-LLVM: call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_f(%opencl.image2d_t addrspace(1)* %input, i32 22, <2 x float> %coords)

  %arrayidx4 = getelementptr inbounds <4 x float> addrspace(1)* %results, i32 0
  store <4 x float> %call3, <4 x float> addrspace(1)* %arrayidx4, align 16
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_f(%opencl.image2d_t addrspace(1)*, i32, <2 x float>) #1
; CHECK-LLVM: declare spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_f(%opencl.image2d_t addrspace(1)*, i32, <2 x float>)

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!9}
!opencl.compiler.options = !{!8}

!0 = !{void (%opencl.image2d_t addrspace(1)*, <2 x float>, <4 x float> addrspace(1)*, i32)* @sample_kernel, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 1, i32 0, i32 1, i32 0}
!2 = !{!"kernel_arg_access_qual", !"read_only", !"none", !"none", !"none"}
!3 = !{!"kernel_arg_type", !"image2d_t", !"float2", !"float4*", !"sampler_t"}
!4 = !{!"kernel_arg_base_type", !"image2d_t", !"float2", !"float4*", !"sampler_t"}
!5 = !{!"kernel_arg_type_qual", !"", !"", !"", !""}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
!9 = !{!"cl_images"}
