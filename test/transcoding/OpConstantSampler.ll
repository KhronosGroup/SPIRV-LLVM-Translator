; Sources:
;
; void kernel foo(__read_only image2d_t src) {
;   sampler_t sampler1 = CLK_NORMALIZED_COORDS_TRUE |
;                        CLK_ADDRESS_REPEAT |
;                        CLK_FILTER_NEAREST;
;   sampler_t sampler2 = 0x00;
;
;   read_imagef(src, sampler1, 0, 0);
;   read_imagef(src, sampler2, 0, 0);
; }

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: ConstantSampler {{[0-9]+}} [[SamplerID0:[0-9]+]] 3 1 0
; CHECK-SPIRV: ConstantSampler {{[0-9]+}} [[SamplerID1:[0-9]+]] 0 0 0
; CHECK-SPIRV: SampledImage {{.*}} [[SamplerID0]]
; CHECK-SPIRV: SampledImage {{.*}} [[SamplerID1]]

; CHECK-LLVM: call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_f
; CHECK-LLVM: call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv2_f

target triple = "spir"

%opencl.image2d_ro_t = type opaque
%opencl.sampler_t = type opaque

; Function Attrs: noinline nounwind optnone
define spir_kernel void @foo(%opencl.image2d_ro_t addrspace(1)* %src) #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_base_type !7 !kernel_arg_type_qual !8 !kernel_arg_host_accessible !9 {
entry:
  %src.addr = alloca %opencl.image2d_ro_t addrspace(1)*, align 4
  store %opencl.image2d_ro_t addrspace(1)* %src, %opencl.image2d_ro_t addrspace(1)** %src.addr, align 4
  %sampler1 = call %opencl.sampler_t addrspace(2)* @__translate_sampler_initializer(i32 23)
  %sampler2 = call %opencl.sampler_t addrspace(2)* @__translate_sampler_initializer(i32 0)
  %0 = load %opencl.image2d_ro_t addrspace(1)*, %opencl.image2d_ro_t addrspace(1)** %src.addr, align 4
  %call = call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_ff(%opencl.image2d_ro_t addrspace(1)* %0, %opencl.sampler_t addrspace(2)* %sampler1, <2 x float> zeroinitializer, float 0.000000e+00) #2
  %1 = load %opencl.image2d_ro_t addrspace(1)*, %opencl.image2d_ro_t addrspace(1)** %src.addr, align 4
  %call1 = call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_ff(%opencl.image2d_ro_t addrspace(1)* %1, %opencl.sampler_t addrspace(2)* %sampler2, <2 x float> zeroinitializer, float 0.000000e+00) #2
  ret void
}

declare %opencl.sampler_t addrspace(2)* @__translate_sampler_initializer(i32)

; Function Attrs: nounwind readonly
declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_ff(%opencl.image2d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <2 x float>, float) #1

attributes #0 = { noinline nounwind optnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readonly }

!llvm.module.flags = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!opencl.used.extensions = !{!2}
!opencl.used.optional.core.features = !{!3}
!opencl.compiler.options = !{!2}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 2, i32 0}
!2 = !{}
!3 = !{!"cl_images"}
!4 = !{!"clang version 5.0.1 (cfe/trunk)"}
!5 = !{i32 1}
!6 = !{!"read_only"}
!7 = !{!"image2d_t"}
!8 = !{!""}
!9 = !{i1 false}
