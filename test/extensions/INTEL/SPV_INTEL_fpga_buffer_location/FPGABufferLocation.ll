; RUN: llvm-as -opaque-pointers=0 %s -o %t.bc
; RUN: llvm-spirv %t.bc -opaque-pointers=0 --spirv-ext=+SPV_INTEL_fpga_buffer_location -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis -opaque-pointers=0 < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: llvm-spirv -spirv-text -r %t.spt -o %t.rev.bc
; RUN: llvm-dis -opaque-pointers=0 < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: 2 Capability FPGABufferLocationINTEL
; CHECK-SPIRV: 9 Extension "SPV_INTEL_fpga_buffer_location"
; CHECK-SPIRV: 3 Name [[ARGA:[0-9]+]] "a"
; CHECK-SPIRV: 3 Name [[ARGB:[0-9]+]] "b"
; CHECK-SPIRV: 3 Name [[ARGC:[0-9]+]] "c"
; CHECK-SPIRV: 3 Name [[ARGD:[0-9]+]] "d"
; CHECK-SPIRV: 3 Name [[ARGE:[0-9]+]] "e"
; CHECK-SPIRV-NOT: 4 Decorate [[ARGC]] BufferLocationINTEL -1
; CHECK-SPIRV-NOT: 4 Decorate [[ARGC]] BufferLocationINTEL -1
; CHECK-SPIRV: 4 Decorate [[ARGA]] BufferLocationINTEL 1
; CHECK-SPIRV: 4 Decorate [[ARGB]] BufferLocationINTEL 2
; CHECK-SPIRV-NOT: 4 Decorate [[ARGD]] BufferLocationINTEL -1
; CHECK-SPIRV-NOT: 4 Decorate [[ARGE]] BufferLocationINTEL 3
; CHECK-SPIRV-DAG: 4 Decorate {{[0-9]+}} BufferLocationINTEL 123456789

; CHECK-SPIRV: 5 Function
; CHECK-SPIRV: 3 FunctionParameter {{[0-9]+}} [[ARGA]]
; CHECK-SPIRV: 3 FunctionParameter {{[0-9]+}} [[ARGB]]
; CHECK-SPIRV: 3 FunctionParameter {{[0-9]+}} [[ARGC]]
; CHECK-SPIRV: 3 FunctionParameter {{[0-9]+}} [[ARGD]]
; CHECK-SPIRV: 3 FunctionParameter {{[0-9]+}} [[ARGE]]


; ModuleID = 'buffer_location.cl'
source_filename = "buffer_location.cl"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

@.str.1 = private unnamed_addr constant [9 x i8] c"main.cpp\00", section "llvm.metadata"
@.str.4 = private unnamed_addr constant [19 x i8] c"{5921:\22123456789\22}\00", section "llvm.metadata"
; CHECK-LLVM: @[[ANN_STR:[0-9]+]] = private unnamed_addr constant [33 x i8] c"{sycl-buffer-location:123456789}\00"

; Function Attrs: norecurse nounwind readnone
define spir_kernel void @test(i32 addrspace(1)* %a, float addrspace(1)* %b, i32 addrspace(1)* %c, i32 %d, i32 %e) local_unnamed_addr !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !5 !kernel_arg_buffer_location !6
; CHECK-LLVM: !kernel_arg_buffer_location ![[BUFLOC_MD:[0-9]+]]
{
entry:
  ret void
}

; test1 : direct on kernel argument
; Function Attrs: norecurse nounwind readnone
define spir_kernel void @test.1(i8 addrspace(4)* %a) #0
; CHECK-LLVM: !kernel_arg_buffer_location ![[BUFLOC_MD_TEST1:[0-9]+]]
{
entry:
  %0 = call i8 addrspace(4)* @llvm.ptr.annotation.p4i8(i8 addrspace(4)* %a, i8* getelementptr inbounds ([19 x i8], [19 x i8]* @.str.4, i32 0, i32 0), i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str.1, i32 0, i32 0), i32 7, i8* null)
  store i8 0, i8 addrspace(4)* %0, align 8
  ret void
}

%struct.MyIP = type { i32 addrspace(4)* }
$test.2 = comdat any

; test2 : general
; Function Attrs: convergent mustprogress norecurse
define weak_odr dso_local spir_kernel void @test.2(i32 addrspace(1)* noundef align 4 %arg_a) #0 comdat !kernel_arg_buffer_location !7 {
entry:
  %this.addr.i = alloca %struct.MyIP addrspace(4)*, align 8
  %arg_a.addr = alloca i32 addrspace(1)*, align 8
  %MyIP = alloca %struct.MyIP, align 8
  %arg_a.addr.ascast = addrspacecast i32 addrspace(1)** %arg_a.addr to i32 addrspace(1)* addrspace(4)*
  %MyIP.ascast = addrspacecast %struct.MyIP* %MyIP to %struct.MyIP addrspace(4)*
  store i32 addrspace(1)* %arg_a, i32 addrspace(1)* addrspace(4)* %arg_a.addr.ascast, align 8
  %0 = bitcast %struct.MyIP* %MyIP to i8*
  %a = getelementptr inbounds %struct.MyIP, %struct.MyIP addrspace(4)* %MyIP.ascast, i32 0, i32 0
  %1 = bitcast i32 addrspace(4)* addrspace(4)* %a to i8 addrspace(4)*
  %2 = call i8 addrspace(4)* @llvm.ptr.annotation.p4i8(i8 addrspace(4)* %1, i8* getelementptr inbounds ([19 x i8], [19 x i8]* @.str.4, i32 0, i32 0), i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str.1, i32 0, i32 0), i32 7, i8* null)
; CHEKC-LLVM: call i32 addrspace(4)* addrspace(4)* @llvm.ptr.annotation.p4p4i32.p0i8(i32 addrspace(4)* addrspace(4)* %a, i8* getelementptr inbounds ([33 x i8], [33 x i8]* @[[ANN_STR]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)
  %3 = bitcast i8 addrspace(4)* %2 to i32 addrspace(4)* addrspace(4)*
  %4 = load i32 addrspace(1)*, i32 addrspace(1)* addrspace(4)* %arg_a.addr.ascast, align 8
  %5 = addrspacecast i32 addrspace(1)* %4 to i32 addrspace(4)*
  store i32 addrspace(4)* %5, i32 addrspace(4)* addrspace(4)* %3, align 8
  %this.addr.ascast.i = addrspacecast %struct.MyIP addrspace(4)** %this.addr.i to %struct.MyIP addrspace(4)* addrspace(4)*
  store %struct.MyIP addrspace(4)* %MyIP.ascast, %struct.MyIP addrspace(4)* addrspace(4)* %this.addr.ascast.i, align 8
  %this1.i = load %struct.MyIP addrspace(4)*, %struct.MyIP addrspace(4)* addrspace(4)* %this.addr.ascast.i, align 8
  %a.i = getelementptr inbounds %struct.MyIP, %struct.MyIP addrspace(4)* %this1.i, i32 0, i32 0
  %6 = bitcast i32 addrspace(4)* addrspace(4)* %a.i to i8 addrspace(4)*
  %7 = call i8 addrspace(4)* @llvm.ptr.annotation.p4i8(i8 addrspace(4)* %6, i8* getelementptr inbounds ([19 x i8], [19 x i8]* @.str.4, i32 0, i32 0), i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str.1, i32 0, i32 0), i32 7, i8* null)
; CHECK-LLVM: call i32 addrspace(4)* addrspace(4)* @llvm.ptr.annotation.p4p4i32.p0i8(i32 addrspace(4)* addrspace(4)* %a.i, i8* getelementptr inbounds ([33 x i8], [33 x i8]* @[[ANN_STR]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)
  %8 = bitcast i8 addrspace(4)* %7 to i32 addrspace(4)* addrspace(4)*
  %9 = load i32 addrspace(4)*, i32 addrspace(4)* addrspace(4)* %8, align 8
  %10 = load i32, i32 addrspace(4)* %9, align 4
  %inc.i = add nsw i32 %10, 1
  store i32 %inc.i, i32 addrspace(4)* %9, align 4
  %11 = bitcast %struct.MyIP* %MyIP to i8*
  ret void
}

; Function Attrs: inaccessiblememonly nofree nosync nounwind willreturn
declare i8 addrspace(4)* @llvm.ptr.annotation.p4i8(i8 addrspace(4)*, i8*, i8*, i32, i8*) #2

!opencl.enable.FP_CONTRACT = !{}
!opencl.ocl.version = !{!0}
!opencl.spir.version = !{!0}
!opencl.used.extensions = !{!1}
!opencl.used.optional.core.features = !{!1}
!opencl.compiler.options = !{!1}
!llvm.ident = !{!2}

; CHECK-LLVM: ![[BUFLOC_MD]] = !{i32 1, i32 2, i32 -1, i32 -1, i32 -1}
; CHECK-LLVM: ![[BUFLOC_MD_TEST1]] = !{i32 123456789}
!0 = !{i32 2, i32 0}
!1 = !{}
!2 = !{!""}
!3 = !{i32 1, i32 1, i32 1}
!4 = !{!"none", !"none", !"none"}
!5 = !{!"int*", !"float*", !"int*"}
!6 = !{i32 1, i32 2, i32 -1, i32 -1, i32 3}
!7 = !{i32 -1}
