;; Test SPIR-V opaque types
;;
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spv.txt
; RUN: FileCheck < %t.spv.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

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
; CHECK-SPIRV-DAG: 2 TypeDeviceEvent [[DEVEVENT:[0-9]+]]
; CHECK-SPIRV-DAG: 2 TypeEvent [[EVENT:[0-9]+]]
; CHECK-SPIRV-DAG: 2 TypeQueue [[QUEUE:[0-9]+]]
; CHECK-SPIRV-DAG: 2 TypeReserveId [[RESID:[0-9]+]]

; CHECK-SPIRV: {{[0-9]+}} Function
; CHECK-SPIRV: 3 FunctionParameter [[PIPE_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[PIPE_WR]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG1D_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG2D_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG3D_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG2DA_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG1DB_RD]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG1D_WR]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[IMG2D_RW]] {{[0-9]+}}

; CHECK-SPIRV: {{[0-9]+}} Function
; CHECK-SPIRV: 3 FunctionParameter [[DEVEVENT]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[EVENT]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[QUEUE]] {{[0-9]+}}
; CHECK-SPIRV: 3 FunctionParameter [[RESID]] {{[0-9]+}}

; ModuleID = 'cl-types.cl'
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-LLVM-DAG: %opencl.pipe_t = type opaque
; CHECK-LLVM-DAG: %opencl.image3d_t = type opaque
; CHECK-LLVM-DAG: %opencl.image2d_array_t = type opaque
; CHECK-LLVM-DAG: %opencl.image1d_buffer_t = type opaque
; CHECK-LLVM-DAG: %opencl.image1d_t = type opaque
; CHECK-LLVM-DAG: %opencl.image2d_t = type opaque
; CHECK-LLVM-DAG: %opencl.clk_event_t = type opaque
; CHECK-LLVM-DAG: %opencl.event_t = type opaque
; CHECK-LLVM-DAG: %opencl.queue_t = type opaque
; CHECK-LLVM-DAG: %opencl.reserve_id_t = type opaque

%spirv.Pipe._0 = type opaque ; read_only pipe
%spirv.Pipe._1 = type opaque ; write_only pipe
%spirv.Image._0_0_0_0_0_0_0 = type opaque ; read_only image1d_t
%spirv.Image._1_0_0_0_0_0_0 = type opaque ; read_only image2d_t 
%spirv.Image._2_0_0_0_0_0_0 = type opaque ; read_only image3d_t
%spirv.Image._1_0_1_0_0_0_0 = type opaque ; read_only image2d_array_t
%spirv.Image._5_0_0_0_0_0_0 = type opaque ; read_only image1d_buffer_t
%spirv.Image._0_0_0_0_0_0_1 = type opaque ; write_only image1d_t
%spirv.Image._1_0_0_0_0_0_2 = type opaque ; read_write image2d_t
%spirv.DeviceEvent          = type opaque ; clk_event_t
%spirv.Event                = type opaque ; event_t
%spirv.Queue                = type opaque ; queue_t
%spirv.ReserveId            = type opaque ; reserve_id_t

; CHECK-LLVM: define spir_kernel void @foo(
; CHECK-LLVM:   %opencl.pipe_t addrspace(1)* nocapture %a,
; CHECK-LLVM:   %opencl.pipe_t addrspace(1)* nocapture %b,
; CHECK-LLVM:   %opencl.image1d_t addrspace(1)* nocapture %c1,
; CHECK-LLVM:   %opencl.image2d_t addrspace(1)* nocapture %d1,
; CHECK-LLVM:   %opencl.image3d_t addrspace(1)* nocapture %e1,
; CHECK-LLVM:   %opencl.image2d_array_t addrspace(1)* nocapture %f1,
; CHECK-LLVM:   %opencl.image1d_buffer_t addrspace(1)* nocapture %g1,
; CHECK-LLVM:   %opencl.image1d_t addrspace(1)* nocapture %c2,
; CHECK-LLVM:   %opencl.image2d_t addrspace(1)* nocapture %d3)
  
; Function Attrs: nounwind readnone
define spir_kernel void @foo(
  %spirv.Pipe._0 addrspace(1)* nocapture %a,
  %spirv.Pipe._1 addrspace(1)* nocapture %b,
  %spirv.Image._0_0_0_0_0_0_0 addrspace(1)* nocapture %c1,
  %spirv.Image._1_0_0_0_0_0_0 addrspace(1)* nocapture %d1,
  %spirv.Image._2_0_0_0_0_0_0 addrspace(1)* nocapture %e1,
  %spirv.Image._1_0_1_0_0_0_0 addrspace(1)* nocapture %f1,
  %spirv.Image._5_0_0_0_0_0_0 addrspace(1)* nocapture %g1,
  %spirv.Image._0_0_0_0_0_0_1 addrspace(1)* nocapture %c2,
  %spirv.Image._1_0_0_0_0_0_2 addrspace(1)* nocapture %d3) #0 {
entry:
  ret void
}

; CHECK-LLVM: define spir_func void @bar(
; CHECK-LLVM:  %opencl.clk_event_t* %a,
; CHECK-LLVM:  %opencl.event_t* %b,
; CHECK-LLVM:  %opencl.queue_t* %c,
; CHECK-LLVM:  %opencl.reserve_id_t* %d)

define spir_func void @bar(
  %spirv.DeviceEvent * %a,
  %spirv.Event * %b,
  %spirv.Queue * %c,
  %spirv.ReserveId * %d) {
  ret void
}

attributes #0 = { nounwind readnone "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!9}
!opencl.compiler.options = !{!8}
!llvm.ident = !{!10}

; CHECK-LLVM-DAG: {{![0-9]+}} = !{!"kernel_arg_addr_space", i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1}
; CHECK-LLVM-DAG: {{![0-9]+}} = !{!"kernel_arg_access_qual", !"read_only", !"write_only", !"read_only", !"read_only", !"read_only", !"read_only", !"read_only", !"write_only", !"read_write"}
; CHECK-LLVM-DAG: {{![0-9]+}} = !{!"kernel_arg_type", !"pipe", !"pipe", !"image1d_t", !"image2d_t", !"image3d_t", !"image2d_array_t", !"image1d_buffer_t", !"image1d_t", !"image2d_t"}
; CHECK-LLVM-DAG: {{![0-9]+}} = !{!"kernel_arg_base_type", !"pipe", !"pipe", !"image1d_t", !"image2d_t", !"image3d_t", !"image2d_array_t", !"image1d_buffer_t", !"image1d_t", !"image2d_t"}
; CHECK-LLVM-DAG: {{![0-9]+}} = !{!"kernel_arg_type_qual", !"pipe", !"pipe", !"", !"", !"", !"", !"", !"", !""}

!0 = !{void (%spirv.Pipe._0 addrspace(1)*, %spirv.Pipe._1 addrspace(1)*, %spirv.Image._0_0_0_0_0_0_0 addrspace(1)*, %spirv.Image._1_0_0_0_0_0_0 addrspace(1)*, %spirv.Image._2_0_0_0_0_0_0 addrspace(1)*, %spirv.Image._1_0_1_0_0_0_0 addrspace(1)*, %spirv.Image._5_0_0_0_0_0_0 addrspace(1)*, %spirv.Image._0_0_0_0_0_0_1 addrspace(1)*, %spirv.Image._1_0_0_0_0_0_2 addrspace(1)*)* @foo, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1}
!2 = !{!"kernel_arg_access_qual", !"read_only", !"write_only", !"read_only", !"read_only", !"read_only", !"read_only", !"read_only", !"write_only", !"read_write"}
!3 = !{!"kernel_arg_type", !"int", !"int", !"image1d_t", !"image2d_t", !"image3d_t", !"image2d_array_t", !"image1d_buffer_t", !"image1d_t", !"image2d_t"}
!4 = !{!"kernel_arg_base_type", !"int", !"int", !"image1d_t", !"image2d_t", !"image3d_t", !"image2d_array_t", !"image1d_buffer_t", !"image1d_t", !"image2d_t"}
!5 = !{!"kernel_arg_type_qual", !"pipe", !"pipe", !"", !"", !"", !"", !"", !"", !""}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
!9 = !{!"cl_images"}
!10 = !{!"clang version 3.6.1 "}
