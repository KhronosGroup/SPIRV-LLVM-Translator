; ModuleID = '<stdin>'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s

; Check conversion of get_image_width, get_image_height, get_image_depth,
; get_image_array_size, and get_image_dim OCL built-ins.
; In general the SPRI-V reader converts OpImageQuerySize into get_image_dim
; and subsequent extract or shufflevector instructions. Unfortunately there is
; no get_image_dim for 1D images and get_image_dim cannot replace get_image_array_size

%opencl.image1d_t = type opaque
%opencl.image1d_buffer_t = type opaque
%opencl.image1d_array_t = type opaque
%opencl.image2d_t = type opaque
%opencl.image2d_depth_t = type opaque
%opencl.image2d_array_t = type opaque
%opencl.image2d_array_depth_t = type opaque
%opencl.image3d_t = type opaque

; CHECK:   call {{.*}} @_Z15get_image_width11ocl_image1d

; CHECK:   call {{.*}} @_Z15get_image_width17ocl_image1dbuffer

; CHECK:   call {{.*}} @_Z15get_image_width16ocl_image1darray
; CHECK:   insertelement <2 x i32> undef
; CHECK:   call {{.*}} i64 @_Z20get_image_array_size16ocl_image1darray
; CHECK:   trunc i64 {{.*}} to i32
; CHECK:   insertelement <2 x i32> {{.*}} 1

; CHECK:   call {{.*}} i64 @_Z20get_image_array_size16ocl_image1darray
; ATM SPIR-V writer translates get_image1d_array_t into function call

; Function Attrs: nounwind
define spir_kernel void @test_image1d(i32 addrspace(1)* nocapture %sizes, %opencl.image1d_t addrspace(1)* %img, %opencl.image1d_buffer_t addrspace(1)* %buffer, %opencl.image1d_array_t addrspace(1)* %array) #0 {
  %1 = tail call spir_func i32 @_Z15get_image_width11ocl_image1d(%opencl.image1d_t addrspace(1)* %img) #1
  %2 = tail call spir_func i32 @_Z15get_image_width17ocl_image1dbuffer(%opencl.image1d_buffer_t addrspace(1)* %buffer) #1
  %3 = tail call spir_func i32 @_Z15get_image_width16ocl_image1darray(%opencl.image1d_array_t addrspace(1)* %array) #1
  %4 = tail call spir_func i64 @_Z20get_image_array_size16ocl_image1darray(%opencl.image1d_array_t addrspace(1)* %array) #1
  %5 = trunc i64 %4 to i32
  %6 = add nsw i32 %2, %1
  %7 = add nsw i32 %6, %3
  %8 = add nsw i32 %7, %5
  store i32 %8, i32 addrspace(1)* %sizes, align 4, !tbaa !22
  ret void
}

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z15get_image_width11ocl_image1d(%opencl.image1d_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z15get_image_width17ocl_image1dbuffer(%opencl.image1d_buffer_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z15get_image_width16ocl_image1darray(%opencl.image1d_array_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func i64 @_Z20get_image_array_size16ocl_image1darray(%opencl.image1d_array_t addrspace(1)*) #1

; CHECK:   call {{.*}} @_Z13get_image_dim11ocl_image2d
; CHECK:   extractelement <2 x i32> {{.*}} 0

; CHECK:   call {{.*}} @_Z13get_image_dim11ocl_image2d
; CHECK:   extractelement <2 x i32> {{.*}} 1

; CHECK:   call {{.*}} @_Z13get_image_dim11ocl_image2d
; CHECK:   call {{.*}} @_Z13get_image_dim16ocl_image2darray
; CHECK:   shufflevector <2 x i32> {{.*}} <3 x i32>
; CHECK:   call {{.*}} i64 @_Z20get_image_array_size16ocl_image2darray
; CHECK:   trunc i64 {{.*}} to i32
; CHECK:   insertelement <3 x i32> {{.*}} i32 2
; CHECK:   extractelement <3 x i32> {{.*}} 0

; CHECK:   call {{.*}} @_Z13get_image_dim16ocl_image2darray
; CHECK:   shufflevector <2 x i32> {{.*}} <3 x i32>
; CHECK:   call {{.*}} i64 @_Z20get_image_array_size16ocl_image2darray
; CHECK:   trunc i64 {{.*}} to i32
; CHECK:   insertelement <3 x i32> {{.*}} i32 2
; CHECK:   extractelement <3 x i32> {{.*}} 1

; CHECK:   call {{.*}} @_Z20get_image_array_size16ocl_image2darray

; CHECK:   call {{.*}} @_Z13get_image_dim16ocl_image2darray
; CHECK:   shufflevector <2 x i32> {{.*}} <3 x i32>
; CHECK:   call {{.*}} i64 @_Z20get_image_array_size16ocl_image2darray
; CHECK:   trunc i64 {{.*}} to i32
; CHECK:   insertelement <3 x i32> {{.*}} i32 2
; CHECK:   shufflevector <3 x i32> {{.*}} <2 x i32>

; Function Attrs: nounwind
define spir_kernel void @test_image2d(i32 addrspace(1)* nocapture %sizes, %opencl.image2d_t addrspace(1)* %img, %opencl.image2d_depth_t addrspace(1)* nocapture %img_depth, %opencl.image2d_array_t addrspace(1)* %array, %opencl.image2d_array_depth_t addrspace(1)* nocapture %array_depth) #0 {
  %1 = tail call spir_func i32 @_Z15get_image_width11ocl_image2d(%opencl.image2d_t addrspace(1)* %img) #1
  %2 = tail call spir_func i32 @_Z16get_image_height11ocl_image2d(%opencl.image2d_t addrspace(1)* %img) #1
  %3 = tail call spir_func <2 x i32> @_Z13get_image_dim11ocl_image2d(%opencl.image2d_t addrspace(1)* %img) #1
  %4 = tail call spir_func i32 @_Z15get_image_width16ocl_image2darray(%opencl.image2d_array_t addrspace(1)* %array) #1
  %5 = tail call spir_func i32 @_Z16get_image_height16ocl_image2darray(%opencl.image2d_array_t addrspace(1)* %array) #1
  %6 = tail call spir_func i64 @_Z20get_image_array_size16ocl_image2darray(%opencl.image2d_array_t addrspace(1)* %array) #1
  %7 = trunc i64 %6 to i32
  %8 = tail call spir_func <2 x i32> @_Z13get_image_dim16ocl_image2darray(%opencl.image2d_array_t addrspace(1)* %array) #1
  %9 = add nsw i32 %2, %1
  %10 = extractelement <2 x i32> %3, i32 0
  %11 = add nsw i32 %9, %10
  %12 = extractelement <2 x i32> %3, i32 1
  %13 = add nsw i32 %11, %12
  %14 = add nsw i32 %13, %4
  %15 = add nsw i32 %14, %5
  %16 = add nsw i32 %15, %7
  %17 = extractelement <2 x i32> %8, i32 0
  %18 = add nsw i32 %16, %17
  %19 = extractelement <2 x i32> %8, i32 1
  %20 = add nsw i32 %18, %19
  store i32 %20, i32 addrspace(1)* %sizes, align 4, !tbaa !22
  ret void
}

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z15get_image_width11ocl_image2d(%opencl.image2d_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z16get_image_height11ocl_image2d(%opencl.image2d_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func <2 x i32> @_Z13get_image_dim11ocl_image2d(%opencl.image2d_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z15get_image_width16ocl_image2darray(%opencl.image2d_array_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z16get_image_height16ocl_image2darray(%opencl.image2d_array_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func i64 @_Z20get_image_array_size16ocl_image2darray(%opencl.image2d_array_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func <2 x i32> @_Z13get_image_dim16ocl_image2darray(%opencl.image2d_array_t addrspace(1)*) #1

; CHECK:   call {{.*}} @_Z13get_image_dim11ocl_image3d
; CHECK:   shufflevector <4 x i32> {{.*}} <3 x i32>
; CHECK:   extractelement <3 x i32> {{.*}} 0

; CHECK:   call {{.*}} @_Z13get_image_dim11ocl_image3d
; CHECK:   shufflevector <4 x i32> {{.*}} <3 x i32>
; CHECK:   extractelement <3 x i32> {{.*}} 1

; CHECK:   call {{.*}} @_Z13get_image_dim11ocl_image3d
; CHECK:   shufflevector <4 x i32> {{.*}} <3 x i32>
; CHECK:   extractelement <3 x i32> {{.*}} 2

; CHECK:   call {{.*}} @_Z13get_image_dim11ocl_image3d
; CHECK:   shufflevector <4 x i32> {{.*}} <3 x i32>
; CHECK:   shufflevector <3 x i32> {{.*}} <4 x i32>

; Function Attrs: nounwind
define spir_kernel void @test_image3d(i32 addrspace(1)* nocapture %sizes, %opencl.image3d_t addrspace(1)* %img) #0 {
  %1 = tail call spir_func i32 @_Z15get_image_width11ocl_image3d(%opencl.image3d_t addrspace(1)* %img) #1
  %2 = tail call spir_func i32 @_Z16get_image_height11ocl_image3d(%opencl.image3d_t addrspace(1)* %img) #1
  %3 = tail call spir_func i32 @_Z15get_image_depth11ocl_image3d(%opencl.image3d_t addrspace(1)* %img) #1
  %4 = tail call spir_func <4 x i32> @_Z13get_image_dim11ocl_image3d(%opencl.image3d_t addrspace(1)* %img) #1
  %5 = add nsw i32 %2, %1
  %6 = add nsw i32 %5, %3
  %7 = extractelement <4 x i32> %4, i32 0
  %8 = add nsw i32 %6, %7
  %9 = extractelement <4 x i32> %4, i32 1
  %10 = add nsw i32 %8, %9
  %11 = extractelement <4 x i32> %4, i32 2
  %12 = add nsw i32 %10, %11
  %13 = extractelement <4 x i32> %4, i32 3
  %14 = add nsw i32 %12, %13
  store i32 %14, i32 addrspace(1)* %sizes, align 4, !tbaa !22
  ret void
}

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z15get_image_width11ocl_image3d(%opencl.image3d_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z16get_image_height11ocl_image3d(%opencl.image3d_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z15get_image_depth11ocl_image3d(%opencl.image3d_t addrspace(1)*) #1

; Function Attrs: nounwind readnone
declare spir_func <4 x i32> @_Z13get_image_dim11ocl_image3d(%opencl.image3d_t addrspace(1)*) #1

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone }

!opencl.kernels = !{!0, !6, !12}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!18}
!opencl.ocl.version = !{!18}
!opencl.used.extensions = !{!19}
!opencl.used.optional.core.features = !{!20}
!opencl.compiler.options = !{!21}

!0 = !{void (i32 addrspace(1)*, %opencl.image1d_t addrspace(1)*, %opencl.image1d_buffer_t addrspace(1)*, %opencl.image1d_array_t addrspace(1)*)* @test_image1d, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 1, i32 1, i32 1, i32 1}
!2 = !{!"kernel_arg_access_qual", !"none", !"read_only", !"read_only", !"read_only"}
!3 = !{!"kernel_arg_type", !"int*", !"image1d_t", !"image1d_buffer_t", !"image1d_array_t"}
!4 = !{!"kernel_arg_type_qual", !"", !"", !"", !""}
!5 = !{!"kernel_arg_base_type", !"int*", !"image1d_t", !"image1d_buffer_t", !"image1d_array_t"}
!6 = !{void (i32 addrspace(1)*, %opencl.image2d_t addrspace(1)*, %opencl.image2d_depth_t addrspace(1)*, %opencl.image2d_array_t addrspace(1)*, %opencl.image2d_array_depth_t addrspace(1)*)* @test_image2d, !7, !8, !9, !10, !11}
!7 = !{!"kernel_arg_addr_space", i32 1, i32 1, i32 1, i32 1, i32 1}
!8 = !{!"kernel_arg_access_qual", !"none", !"read_only", !"read_only", !"read_only", !"read_only"}
!9 = !{!"kernel_arg_type", !"int*", !"image2d_t", !"image2d_depth_t", !"image2d_array_t", !"image2d_array_depth_t"}
!10 = !{!"kernel_arg_type_qual", !"", !"", !"", !"", !""}
!11 = !{!"kernel_arg_base_type", !"int*", !"image2d_t", !"image2d_depth_t", !"image2d_array_t", !"image2d_array_depth_t"}
!12 = !{void (i32 addrspace(1)*, %opencl.image3d_t addrspace(1)*)* @test_image3d, !13, !14, !15, !16, !17}
!13 = !{!"kernel_arg_addr_space", i32 1, i32 1}
!14 = !{!"kernel_arg_access_qual", !"none", !"read_only"}
!15 = !{!"kernel_arg_type", !"int*", !"image3d_t"}
!16 = !{!"kernel_arg_type_qual", !"", !""}
!17 = !{!"kernel_arg_base_type", !"int*", !"image3d_t"}
!18 = !{i32 1, i32 2}
!19 = !{!"cl_khr_depth_images"}
!20 = !{!"cl_images"}
!21 = !{}
!22 = !{!23, !23, i64 0}
!23 = !{!"int", !24}
!24 = !{!"omnipotent char", !25}
!25 = !{!"Simple C/C++ TBAA"}
