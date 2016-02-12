;; bash$ cat repro.cl
;; void device_kernel(__local float* ptr0, __local float* ptr1) {
;;   *ptr0 = 0;
;;   *ptr1 = 1;
;; }
;;
;; __kernel void host_kernel(uint size) {
;;   void(^block)(__local void*, __local void*) = ^(__local void* ptr0, __local void* ptr1){
;;     device_kernel(ptr0, ptr1);
;;   };
;;
;;   uint wgSize = get_kernel_work_group_size(block);
;;   uint prefMul =  get_kernel_preferred_work_group_size_multiple(block);
;;   enqueue_kernel(get_default_queue(), CLK_ENQUEUE_FLAGS_WAIT_KERNEL, ndrange_1D(1),
;;                  0, NULL, NULL, block, size, wgSize * prefMul);
;; }
;; bash$
;; bash$ export PATH_TO_INCLUDE= $PATH_TO_GEN/lib/clang/3.6.1/include
;; bash$ $PATH_TO_GEN/bin/clang -cc1 -x cl -cl-std=CL2.0 -triple spir64-unknonw-unknown -emit-llvm  -include opencl-20.h  repro.cl -o device_execution.ll

;; 1. Check mangling of device execution built-ins for blocks with local memory arguments
;; 2. Check there is an enqueue_kernel with ellipsis

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s

; ModuleID = 'repro.cl'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknonw-unknown"

%opencl.block = type opaque
%struct.ndrange_t = type { i32, [3 x i64], [3 x i64], [3 x i64] }
%opencl.queue_t = type opaque
%opencl.clk_event_t = type opaque

; Function Attrs: nounwind
define spir_func void @device_kernel(float addrspace(3)* %ptr0, float addrspace(3)* %ptr1) #0 {
entry:
  %ptr0.addr = alloca float addrspace(3)*, align 8
  %ptr1.addr = alloca float addrspace(3)*, align 8
  store float addrspace(3)* %ptr0, float addrspace(3)** %ptr0.addr, align 8
  store float addrspace(3)* %ptr1, float addrspace(3)** %ptr1.addr, align 8
  %0 = load float addrspace(3)** %ptr0.addr, align 8
  store float 0.000000e+00, float addrspace(3)* %0, align 4
  %1 = load float addrspace(3)** %ptr1.addr, align 8
  store float 1.000000e+00, float addrspace(3)* %1, align 4
  ret void
}

; Function Attrs: nounwind
define spir_kernel void @host_kernel(i32 %size) #0 {
entry:
  %size.addr = alloca i32, align 4
  %block = alloca %opencl.block*, align 8
  %wgSize = alloca i32, align 4
  %prefMul = alloca i32, align 4
  %agg.tmp = alloca %struct.ndrange_t, align 8
  store i32 %size, i32* %size.addr, align 4
  %0 = call %opencl.block* @spir_block_bind(i8* bitcast (void (i8*, i8 addrspace(3)*, i8 addrspace(3)*)* @__host_kernel_block_invoke to i8*), i32 0, i32 0, i8* null)
  store %opencl.block* %0, %opencl.block** %block, align 8
  %1 = load %opencl.block** %block, align 8
; CHECK: call {{.*}} @_Z26get_kernel_work_group_sizeU13block_pointerFvPU3AS3vzE
  %call = call spir_func i32 @_Z26get_kernel_work_group_sizeU13block_pointerFvPU3AS3vzE(%opencl.block* %1)
  store i32 %call, i32* %wgSize, align 4
  %2 = load %opencl.block** %block, align 8
; CHECK: call {{.*}} @_Z45get_kernel_preferred_work_group_size_multipleU13block_pointerFvPU3AS3vzE
  %call1 = call spir_func i32 @_Z45get_kernel_preferred_work_group_size_multipleU13block_pointerFvPU3AS3vzE(%opencl.block* %2)
  store i32 %call1, i32* %prefMul, align 4
  %call2 = call spir_func %opencl.queue_t* @_Z17get_default_queuev()
  call spir_func void @_Z10ndrange_1Dm(%struct.ndrange_t* sret %agg.tmp, i64 1)
  %3 = load %opencl.block** %block, align 8
  %4 = load i32* %size.addr, align 4
  %5 = load i32* %wgSize, align 4
  %6 = load i32* %prefMul, align 4
  %mul = mul i32 %5, %6
; CHECK: call {{.*}} @_Z14enqueue_kernel{{.*}}U13block_pointerFvPU3AS3vzEjz({{.*}}, %opencl.block* {{.*}}, i32 {{.*}}, i32 {{.*}})
  %call3 = call spir_func i32 (%opencl.queue_t*, i32, %struct.ndrange_t*, i32, %opencl.clk_event_t**, %opencl.clk_event_t**, %opencl.block*, i32, ...)* @_Z14enqueue_kernel9ocl_queuei9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvPU3AS3vzEjz(%opencl.queue_t* %call2, i32 241, %struct.ndrange_t* byval %agg.tmp, i32 0, %opencl.clk_event_t** null, %opencl.clk_event_t** null, %opencl.block* %3, i32 %4, i32 %mul)
  ret void
}

; Function Attrs: nounwind
; CHECK-LABEL: define {{.*}} @__host_kernel_block_invoke
define internal spir_func void @__host_kernel_block_invoke(i8* %.block_descriptor, i8 addrspace(3)* %ptr0, i8 addrspace(3)* %ptr1) #0 {
entry:
  %.block_descriptor.addr = alloca i8*, align 8
  %ptr0.addr = alloca i8 addrspace(3)*, align 8
  %ptr1.addr = alloca i8 addrspace(3)*, align 8
  %block.addr = alloca <{}>*, align 8
  store i8* %.block_descriptor, i8** %.block_descriptor.addr, align 8
  %0 = load i8** %.block_descriptor.addr
  store i8 addrspace(3)* %ptr0, i8 addrspace(3)** %ptr0.addr, align 8
  store i8 addrspace(3)* %ptr1, i8 addrspace(3)** %ptr1.addr, align 8
  %block = bitcast i8* %.block_descriptor to <{}>*
  store <{}>* %block, <{}>** %block.addr, align 8
  %1 = load i8 addrspace(3)** %ptr0.addr, align 8
  %2 = bitcast i8 addrspace(3)* %1 to float addrspace(3)*
  %3 = load i8 addrspace(3)** %ptr1.addr, align 8
  %4 = bitcast i8 addrspace(3)* %3 to float addrspace(3)*
  call spir_func void @device_kernel(float addrspace(3)* %2, float addrspace(3)* %4)
  ret void
}

declare %opencl.block* @spir_block_bind(i8*, i32, i32, i8*)

declare spir_func i32 @_Z26get_kernel_work_group_sizeU13block_pointerFvPU3AS3vzE(%opencl.block*) #1

declare spir_func i32 @_Z45get_kernel_preferred_work_group_size_multipleU13block_pointerFvPU3AS3vzE(%opencl.block*) #1

; CHECK: declare {{.*}} @_Z14enqueue_kernel{{.*}}U13block_pointerFvPU3AS3vzEjz({{.*}}, %opencl.block*, i32, ...)
declare spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvPU3AS3vzEjz(%opencl.queue_t*, i32, %struct.ndrange_t* byval, i32, %opencl.clk_event_t**, %opencl.clk_event_t**, %opencl.block*, i32, ...) #1

declare spir_func %opencl.queue_t* @_Z17get_default_queuev() #1

declare spir_func void @_Z10ndrange_1Dm(%struct.ndrange_t* sret, i64) #1

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}

!0 = !{void (i32)* @host_kernel, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 0}
!2 = !{!"kernel_arg_access_qual", !"none"}
!3 = !{!"kernel_arg_type", !"uint"}
!4 = !{!"kernel_arg_base_type", !"uint"}
!5 = !{!"kernel_arg_type_qual", !""}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
