;; Test CL opaque types
;;
;; // cl-types.cl
;; // CL source code for generating LLVM IR.
;; // Command for compilation:
;; //  clang -cc1 -x cl -cl-std=CL2.0 -triple spir-unknonw-unknown -emit-llvm cl-types.cl
;; void kernel foo(
;;  read_only pipe int a,
;;  write_only pipe int b,
;;  read_only image1d_t c1,
;;  read_only image2d_t d1,
;;  read_only image3d_t e1,
;;  read_only image2d_array_t f1,
;;  read_only image1d_buffer_t g1,
;;  write_only image1d_t c2,
;;  read_write image2d_t d3,
;;  sampler_t s
;; ){
;; }

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spv.txt
; RUN: FileCheck < %t.spv.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: 2 Capability Sampled1D
; CHECK-SPIRV-DAG: 2 Capability SampledBuffer
; CHECK-SPIRV-DAG: 2 TypeVoid [[VOID:[0-9]+]]
; CHECK-SPIRV-DAG: 3 TypePipe [[PIPE_RD:[0-9]+]] 0
; CHECK-SPIRV-DAG: 3 TypePipe [[PIPE_WR:[0-9]+]] 1
; CHECK-SPIRV-DAG: 10 TypeImage [[IMG1D_RD:[0-9]+]] [[VOID]] 0 0 0 0 0 0 0
; CHECK-SPIRV-DAG: 10 TypeImage [[IMG2D_RD:[0-9]+]] [[VOID]] 1 0 0 0 0 0 0
; CHECK-SPIRV-DAG: 10 TypeImage [[IMG3D_RD:[0-9]+]] [[VOID]] 2 0 0 0 0 0 0
; CHECK-SPIRV-DAG: 10 TypeImage [[IMG2DA_RD:[0-9]+]] [[VOID]] 1 0 1 0 0 0 0
; CHECK-SPIRV-DAG: 10 TypeImage [[IMG1DB_RD:[0-9]+]] [[VOID]] 5 0 0 0 0 0 0
; CHECK-SPIRV-DAG: 10 TypeImage [[IMG1D_WR:[0-9]+]] [[VOID]] 0 0 0 0 0 0 1
; CHECK-SPIRV-DAG: 10 TypeImage [[IMG2D_RW:[0-9]+]] [[VOID]] 1 0 0 0 0 0 2
; CHECK-SPIRV-DAG: 2 TypeSampler [[SAMP:[0-9]+]]
; CHECK-SPIRV-DAG: 3 TypeSampledImage [[SAMPIMG:[0-9]+]] [[IMG2D_RD]]

; CHECK-SPIRV: 6 ConstantSampler [[SAMP]] [[SAMP_CONST:[0-9]+]] 0 0 1

; ModuleID = 'cl-types.cl'
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-LLVM-DAG: %opencl.pipe_t = type opaque
; CHECK-LLVM-DAG: %opencl.image3d_t = type opaque
; CHECK-LLVM-DAG: %opencl.image2d_array_t = type opaque
; CHECK-LLVM-DAG: %opencl.image1d_buffer_t = type opaque
; CHECK-LLVM-DAG: %opencl.image1d_t = type opaque
; CHECK-LLVM-DAG: %opencl.image2d_t = type opaque

%opencl.pipe_t = type opaque
%opencl.image3d_t = type opaque
%opencl.image2d_array_t = type opaque
%opencl.image1d_buffer_t = type opaque
%opencl.image1d_t = type opaque
%opencl.image2d_t = type opaque

; CHECK-SPIRV: 3 FunctionParameter [[PIPE_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[PIPE_WR]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG1D_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG2D_RD]] [[IMG_ARG:[0-9]+]]
; CHECK-SPIRV: 3 FunctionParameter [[IMG3D_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG2DA_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG1DB_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG1D_WR]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG2D_RW]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[SAMP]] [[SAMP_ARG:[0-9]+]]

; CHECK-LLVM: define spir_kernel void @foo(
; CHECK-LLVM:   %opencl.pipe_t addrspace(1)* nocapture %a,
; CHECK-LLVM:   %opencl.pipe_t addrspace(1)* nocapture %b,
; CHECK-LLVM:   %opencl.image1d_t addrspace(1)* nocapture %c1,
; CHECK-LLVM:   %opencl.image2d_t addrspace(1)* nocapture %d1,
; CHECK-LLVM:   %opencl.image3d_t addrspace(1)* nocapture %e1,
; CHECK-LLVM:   %opencl.image2d_array_t addrspace(1)* nocapture %f1,
; CHECK-LLVM:   %opencl.image1d_buffer_t addrspace(1)* nocapture %g1,
; CHECK-LLVM:   %opencl.image1d_t addrspace(1)* nocapture %c2,
; CHECK-LLVM:   %opencl.image2d_t addrspace(1)* nocapture %d3,
; CHECK-LLVM:   i32 %s)

; Function Attrs: nounwind readnone
define spir_kernel void @foo(
  %opencl.pipe_t addrspace(1)* nocapture %a,
  %opencl.pipe_t addrspace(1)* nocapture %b,
  %opencl.image1d_t addrspace(1)* nocapture %c1,
  %opencl.image2d_t addrspace(1)* nocapture %d1,
  %opencl.image3d_t addrspace(1)* nocapture %e1,
  %opencl.image2d_array_t addrspace(1)* nocapture %f1,
  %opencl.image1d_buffer_t addrspace(1)* nocapture %g1,
  %opencl.image1d_t addrspace(1)* nocapture %c2,
  %opencl.image2d_t addrspace(1)* nocapture %d3,
  i32 %s) #0 {
entry:
; CHECK-SPIRV: 5 SampledImage [[SAMPIMG]] [[SAMPIMG_VAR1:[0-9]+]] [[IMG_ARG]] [[SAMP_ARG]]
; CHECK-SPIRV: 7 ImageSampleExplicitLod {{[0-9]+}} {{[0-9]+}} [[SAMPIMG_VAR1]]
; CHECK-LLVM:   call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv4_if(%opencl.image2d_t addrspace(1)* %d1, i32 %s, <4 x i32> zeroinitializer, float 1.000000e+00)
  %.tmp = call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv4_if(%opencl.image2d_t addrspace(1)* %d1, i32 %s, <4 x i32> zeroinitializer, float 1.000000e+00)

; CHECK-SPIRV: 5 SampledImage [[SAMPIMG]] [[SAMPIMG_VAR2:[0-9]+]] [[IMG_ARG]] [[SAMP_CONST]]
; CHECK-SPIRV: 7 ImageSampleExplicitLod {{[0-9]+}} {{[0-9]+}} [[SAMPIMG_VAR2]]
; CHECK-LLVM:   call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv4_if(%opencl.image2d_t addrspace(1)* %d1, i32 32, <4 x i32> zeroinitializer, float 1.000000e+00)
  %.tmp2 = call spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv4_if(%opencl.image2d_t addrspace(1)* %d1, i32 32, <4 x i32> zeroinitializer, float 1.000000e+00)
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef11ocl_image2d11ocl_samplerDv4_if(%opencl.image2d_t addrspace(1)*, i32, <4 x i32>, float) #1

attributes #0 = { nounwind readnone "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!9}
!opencl.compiler.options = !{!8}
!llvm.ident = !{!10}

; CHECK-LLVM-DAG: {{![0-9]+}} = !{!"kernel_arg_addr_space", i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 0}
; CHECK-LLVM-DAG: {{![0-9]+}} = !{!"kernel_arg_access_qual", !"read_only", !"write_only", !"read_only", !"read_only", !"read_only", !"read_only", !"read_only", !"write_only", !"read_write", !"none"}
; CHECK-LLVM-DAG: {{![0-9]+}} = !{!"kernel_arg_type", !"pipe", !"pipe", !"image1d_t", !"image2d_t", !"image3d_t", !"image2d_array_t", !"image1d_buffer_t", !"image1d_t", !"image2d_t", !"sampler_t"}
; CHECK-LLVM-DAG: {{![0-9]+}} = !{!"kernel_arg_base_type", !"pipe", !"pipe", !"image1d_t", !"image2d_t", !"image3d_t", !"image2d_array_t", !"image1d_buffer_t", !"image1d_t", !"image2d_t", !"sampler_t"}
; CHECK-LLVM-DAG: {{![0-9]+}} = !{!"kernel_arg_type_qual", !"pipe", !"pipe", !"", !"", !"", !"", !"", !"", !"", !""}

!0 = !{void (%opencl.pipe_t addrspace(1)*, %opencl.pipe_t addrspace(1)*, %opencl.image1d_t addrspace(1)*, %opencl.image2d_t addrspace(1)*, %opencl.image3d_t addrspace(1)*, %opencl.image2d_array_t addrspace(1)*, %opencl.image1d_buffer_t addrspace(1)*, %opencl.image1d_t addrspace(1)*, %opencl.image2d_t addrspace(1)*, i32)* @foo, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 0}
!2 = !{!"kernel_arg_access_qual", !"read_only", !"write_only", !"read_only", !"read_only", !"read_only", !"read_only", !"read_only", !"write_only", !"read_write", !"none"}
!3 = !{!"kernel_arg_type", !"int", !"int", !"image1d_t", !"image2d_t", !"image3d_t", !"image2d_array_t", !"image1d_buffer_t", !"image1d_t", !"image2d_t", !"sampler_t"}
!4 = !{!"kernel_arg_base_type", !"int", !"int", !"image1d_t", !"image2d_t", !"image3d_t", !"image2d_array_t", !"image1d_buffer_t", !"image1d_t", !"image2d_t", !"sampler_t"}
!5 = !{!"kernel_arg_type_qual", !"pipe", !"pipe", !"", !"", !"", !"", !"", !"", !"", !""}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
!9 = !{!"cl_images"}
!10 = !{!"clang version 3.6.1 "}
