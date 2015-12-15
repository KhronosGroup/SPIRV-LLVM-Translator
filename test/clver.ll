; Check duplicate operands in opencl.ocl.version metadata is accepted without
; assertion.

; RUN: llvm-as < %s | llvm-spirv -spirv-text -o %t
; RUN: FileCheck < %t %s

; ModuleID = 'clver.bc'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%struct.my_struct_t = type { i8, i32 }

@var = addrspace(1) global %struct.my_struct_t { i8 97, i32 42 }, align 4

; Function Attrs: nounwind
define spir_kernel void @__OpenCL_writer_kernel(i8 zeroext %c, i32 %i) #0 {
entry:
  %c.addr = alloca i8, align 1
  %i.addr = alloca i32, align 4
  store i8 %c, i8* %c.addr, align 1, !tbaa !14
  store i32 %i, i32* %i.addr, align 4, !tbaa !17
  %0 = load i8* %c.addr, align 1, !tbaa !14
  store i8 %0, i8 addrspace(1)* getelementptr inbounds (%struct.my_struct_t addrspace(1)* @var, i32 0, i32 0), align 1, !tbaa !19
  %1 = load i32* %i.addr, align 4, !tbaa !17
  store i32 %1, i32 addrspace(1)* getelementptr inbounds (%struct.my_struct_t addrspace(1)* @var, i32 0, i32 1), align 4, !tbaa !21
  ret void
}

; Function Attrs: nounwind
define spir_kernel void @__OpenCL_reader_kernel(i8 addrspace(1)* %C, i32 addrspace(1)* %I) #0 {
entry:
  %C.addr = alloca i8 addrspace(1)*, align 8
  %I.addr = alloca i32 addrspace(1)*, align 8
  store i8 addrspace(1)* %C, i8 addrspace(1)** %C.addr, align 8, !tbaa !22
  store i32 addrspace(1)* %I, i32 addrspace(1)** %I.addr, align 8, !tbaa !22
  %0 = load i8 addrspace(1)* getelementptr inbounds (%struct.my_struct_t addrspace(1)* @var, i32 0, i32 0), align 1, !tbaa !19
  %1 = load i8 addrspace(1)** %C.addr, align 8, !tbaa !22
  store i8 %0, i8 addrspace(1)* %1, align 1, !tbaa !14
  %2 = load i32 addrspace(1)* getelementptr inbounds (%struct.my_struct_t addrspace(1)* @var, i32 0, i32 1), align 4, !tbaa !21
  %3 = load i32 addrspace(1)** %I.addr, align 8, !tbaa !22
  store i32 %2, i32 addrspace(1)* %3, align 4, !tbaa !17
  ret void
}

attributes #0 = { nounwind }

!opencl.kernels = !{!0, !7}
!opencl.enable.FP_CONTRACT = !{}
!llvm.ident = !{!12, !12}

; CHECK: 3 Source 3 200000
!opencl.ocl.version = !{!13, !13}
!opencl.spir.version = !{!13, !13}

!0 = !{void (i8, i32)* @__OpenCL_writer_kernel, !1, !2, !3, !4, !5, !6}
!1 = !{!"kernel_arg_addr_space", i32 0, i32 0}
!2 = !{!"kernel_arg_access_qual", !"none", !"none"}
!3 = !{!"kernel_arg_type", !"uchar", !"uint"}
!4 = !{!"kernel_arg_base_type", !"uchar", !"uint"}
!5 = !{!"kernel_arg_type_qual", !"", !""}
!6 = !{!"kernel_arg_name", !"c", !"i"}
!7 = !{void (i8 addrspace(1)*, i32 addrspace(1)*)* @__OpenCL_reader_kernel, !8, !2, !9, !10, !5, !11}
!8 = !{!"kernel_arg_addr_space", i32 1, i32 1}
!9 = !{!"kernel_arg_type", !"uchar*", !"uint*"}
!10 = !{!"kernel_arg_base_type", !"uchar*", !"uint*"}
!11 = !{!"kernel_arg_name", !"C", !"I"}
!12 = !{!"clang version 3.6 (tags/RELEASE_361/rc1)"}
!13 = !{i32 2, i32 0}
!14 = !{!15, !15, i64 0}
!15 = !{!"omnipotent char", !16, i64 0}
!16 = !{!"Simple C/C++ TBAA"}
!17 = !{!18, !18, i64 0}
!18 = !{!"int", !15, i64 0}
!19 = !{!20, !15, i64 0}
!20 = !{!"", !15, i64 0, !18, i64 4}
!21 = !{!20, !18, i64 4}
!22 = !{!23, !23, i64 0}
!23 = !{!"any pointer", !15, i64 0}
