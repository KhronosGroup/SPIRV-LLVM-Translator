; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_fpga_latency_control -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: 2 Capability FPGALatencyControlINTEL
; CHECK-SPIRV: 9 Extension "SPV_INTEL_fpga_latency_control"
; CHECK-SPIRV: 4 Decorate [[ARGA:[0-9]+]] LatencyControlLabelINTEL 0
; CHECK-SPIRV: 4 Decorate [[ARGB:[0-9]+]] LatencyControlLabelINTEL 1
; CHECK-SPIRV: 6 Decorate [[ARGB:[0-9]+]] LatencyControlConstraintINTEL 0 1 5
; CHECK-SPIRV: 4 Bitcast {{[0-9]+}} [[OUT1:[0-9]+]] [[ARGA]]
; CHECK-SPIRV-DAG: 4 Bitcast {{[0-9]+}} [[OUT2:[0-9]+]] [[OUT1]]
; CHECK-SPIRV-DAG: 6 Load {{[0-9]+}} {{[0-9]+}} [[OUT2]] {{[0-9]+}} {{[0-9]+}}
; CHECK-SPIRV: 4 Bitcast {{[0-9]+}} [[OUT3:[0-9]+]] [[ARGB]]
; CHECK-SPIRV-DAG: 4 Bitcast {{[0-9]+}} [[OUT4:[0-9]+]] [[OUT3]]
; CHECK-SPIRV-DAG: 6 Load {{[0-9]+}} {{[0-9]+}} [[OUT4]] {{[0-9]+}} {{[0-9]+}}

; ModuleID = '/iusers/asudarsa/public/llvm-2/llvm/test/SYCLLowerIR/CompileTimePropertiesPass/sycl-latency-control.ll'
source_filename = "/iusers/asudarsa/public/llvm-2/llvm/test/SYCLLowerIR/CompileTimePropertiesPass/sycl-latency-control.ll"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%struct.__spirv_Something = type { i32, i32 }

$_ZTSZ4fooEUlvE_ = comdat any

@.str = private unnamed_addr addrspace(1) constant [16 x i8] c"sycl-properties\00", section "llvm.metadata"
@.str.1 = private unnamed_addr addrspace(1) constant [19 x i8] c"inc/fpga_utils.hpp\00", section "llvm.metadata"
@.str.9 = private unnamed_addr addrspace(1) constant [11 x i8] c"{6172:\220\22}\00", section "llvm.metadata"
@.str.10 = private unnamed_addr addrspace(1) constant [25 x i8] c"{6172:\221\22}{6173:\220,1,5\22}\00", section "llvm.metadata"
; CHECK-LLVM: @[[ANN_STR1:[0-9]+]] = private unnamed_addr constant [27 x i8] c"{sycl-latency-anchor-id:0}\00"
; CHECK-LLVM: @[[ANN_STR2:[0-9]+]] = private unnamed_addr constant [58 x i8] c"{sycl-latency-anchor-id:1}{sycl-latency-constraint:0,1,5}\00"

; Function Attrs: mustprogress norecurse
define weak_odr dso_local spir_kernel void @_ZTSZ4fooEUlvE_(%struct.__spirv_Something addrspace(1)* %0) local_unnamed_addr #0 comdat !kernel_arg_buffer_location !5 !sycl_kernel_omit_args !5 {
entry:
  %1 = alloca %struct.__spirv_Something addrspace(1)*, align 8
  store %struct.__spirv_Something addrspace(1)* %0, %struct.__spirv_Something addrspace(1)** %1, align 8
  %2 = load %struct.__spirv_Something addrspace(1)*, %struct.__spirv_Something addrspace(1)** %1, align 8
  %3 = getelementptr inbounds %struct.__spirv_Something, %struct.__spirv_Something addrspace(1)* %2, i32 0, i32 0
  %4 = bitcast i32 addrspace(1)* %3 to i8 addrspace(1)*
  %5 = call i8 addrspace(1)* @llvm.ptr.annotation.p1i8.p1i8(i8 addrspace(1)* %4, i8 addrspace(1)* getelementptr inbounds ([11 x i8], [11 x i8] addrspace(1)* @.str.9, i32 0, i32 0), i8 addrspace(1)* getelementptr inbounds ([19 x i8], [19 x i8] addrspace(1)* @.str.1, i64 0, i64 0), i32 5, i8 addrspace(1)* null)
; CHECK-LLVM: call i32 addrspace(1)* @llvm.ptr.annotation.p1i32.p0i8(i32 addrspace(1)* %3, i8* getelementptr inbounds ([27 x i8], [27 x i8]* @[[ANN_STR1]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)
  %6 = bitcast i8 addrspace(1)* %5 to i32 addrspace(1)*
  %7 = load i32, i32 addrspace(1)* %6, align 8
  %8 = load %struct.__spirv_Something addrspace(1)*, %struct.__spirv_Something addrspace(1)** %1, align 8
  %9 = getelementptr inbounds %struct.__spirv_Something, %struct.__spirv_Something addrspace(1)* %8, i32 0, i32 1
  %10 = bitcast i32 addrspace(1)* %9 to i8 addrspace(1)*
  %11 = call i8 addrspace(1)* @llvm.ptr.annotation.p1i8.p1i8(i8 addrspace(1)* %10, i8 addrspace(1)* getelementptr inbounds ([25 x i8], [25 x i8] addrspace(1)* @.str.10, i32 0, i32 0), i8 addrspace(1)* getelementptr inbounds ([19 x i8], [19 x i8] addrspace(1)* @.str.1, i64 0, i64 0), i32 5, i8 addrspace(1)* null)
; CHECK-LLVM: call i32 addrspace(1)* @llvm.ptr.annotation.p1i32.p0i8(i32 addrspace(1)* %11, i8* getelementptr inbounds ([58 x i8], [58 x i8]* @[[ANN_STR2]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)
  %12 = bitcast i8 addrspace(1)* %11 to i32 addrspace(1)*
  %13 = load i32, i32 addrspace(1)* %12, align 8
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite)
declare i8 addrspace(1)* @llvm.ptr.annotation.p1i8.p1i8(i8 addrspace(1)*, i8 addrspace(1)*, i8 addrspace(1)*, i32, i8 addrspace(1)*) #1

attributes #0 = { mustprogress norecurse "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="sycl-properties-ptr-annotations.cpp" "uniform-work-group-size"="true" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }

!opencl.spir.version = !{!0, !0, !0, !0, !0, !0}
!spirv.Source = !{!1, !1, !1, !1, !1, !1}
!llvm.ident = !{!2, !2, !2, !2, !2, !2}
!llvm.module.flags = !{!3, !4}

!0 = !{i32 1, i32 2}
!1 = !{i32 4, i32 100000}
!2 = !{!"clang version 15.0.0"}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{}
