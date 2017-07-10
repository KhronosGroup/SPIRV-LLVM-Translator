;; bash$ cat device_execution_overloading.cl
;; void device_kernel_with_local_args(__local float* ptr0, __local float* ptr1) {
;;   *ptr0 = 0;
;;   *ptr1 = 1;
;; }
;;
;; void device_kernel(__global float* ptr) {
;;   *ptr = 3;
;; }
;;
;; __kernel void host_kernel(uint size, __global float* ptr) {
;;   void(^block_with_local)(__local void*, __local void*) = ^(__local void* ptr0, __local void* ptr1){
;;     device_kernel_with_local_args(ptr0, ptr1);
;;   };
;;
;;   void(^block)(void) = ^{
;;     device_kernel(ptr);
;;   };
;;
;n;   uint wgSize = get_kernel_work_group_size(block_with_local);
;;   uint prefMul =  get_kernel_preferred_work_group_size_multiple(block_with_local);
;;   enqueue_kernel(get_default_queue(), CLK_ENQUEUE_FLAGS_WAIT_KERNEL, ndrange_1D(1),
;;                  0, NULL, NULL, block_with_local, size, wgSize * prefMul);
;;
;;   wgSize = get_kernel_work_group_size(block);
;;   prefMul =  get_kernel_preferred_work_group_size_multiple(block);
;;   enqueue_kernel(get_default_queue(), CLK_ENQUEUE_FLAGS_WAIT_KERNEL, ndrange_1D(1),
;;                  0, NULL, NULL, block);
;; }
;; bash$
;;$PATH_TO_GEN/bin/clang -cc1 -x cl -O0 -cl-std=CL2.0 -triple spir64-unknonw-unknown -include $PATH_TO_GEN/lib/clang/3.6.1/include/opencl-20.h -emit-llvm device_execution_overloading.cl -o device_execution_overloading.ll

;; Test enqueue_kernel with and wthout vaargs

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s

; CHECK: %struct.__block_descriptor = type { i64, i64 }

; CHECK: [[BLOCK:%.*]] = alloca <{ i8*, i32, i32, i8*, %struct.__block_descriptor* }>, align 8
; CHECK: [[INVOKEGEP:%.*]] = getelementptr <{ i8*, i32, i32, i8*, %struct.__block_descriptor* }>, <{ i8*, i32, i32, i8*, %struct.__block_descriptor* }>* [[BLOCK]], i32 0, i32 3
; CHECK: store i8* bitcast (void (i8*, i8 addrspace(3)*, i8 addrspace(3)*)* @__host_kernel_block_invoke to i8*), i8** [[INVOKEGEP]]
; CHECK: [[BLOCKDESCGEP:%.*]] = getelementptr <{ i8*, i32, i32, i8*, %struct.__block_descriptor* }>, <{ i8*, i32, i32, i8*, %struct.__block_descriptor* }>* [[BLOCK]], i32 0, i32 4
; CHECK: store %struct.__block_descriptor* @__block_descriptor_spirv, %struct.__block_descriptor** [[BLOCKDESCGEP]]
; CHECK: [[BLOCKBCAST:%.*]] = bitcast <{ i8*, i32, i32, i8*, %struct.__block_descriptor* }>* [[BLOCK]] to i8*
; CHECK: [[BLOCKADDRCAST:%.*]] = addrspacecast i8* [[BLOCKBCAST]] to i8 addrspace(4)*
; CHECK: call i32 @__get_kernel_work_group_size_impl(i8 addrspace(4)* [[BLOCKADDRCAST]])
; CHECK: call i32 @__get_kernel_preferred_work_group_multiple_impl(i8 addrspace(4)* [[BLOCKADDRCAST]])
; CHECK: call i32 {{.*}} @__enqueue_kernel_events_vaargs

; CHECK: [[BLOCK2:%.*]] = alloca <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>, align 8
; CHECK: [[INVOKEGEP2:%.*]] = getelementptr <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>, <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>* [[BLOCK2]], i32 0, i32 3
; CHECK: store i8* bitcast (void (i8*)* @__host_kernel_block_invoke_2 to i8*), i8** [[INVOKEGEP2]]
; CHECK: [[BLOCKDESCGEP2:%.*]] = getelementptr <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>, <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>* [[BLOCK2]], i32 0, i32 4
; CHECK: store %struct.__block_descriptor* @__block_descriptor_spirv.1, %struct.__block_descriptor** [[BLOCKDESCGEP2]]
; CHECK: [[CAPTUREDGEP:%.*]] = getelementptr <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>, <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>* [[BLOCK2]], i32 0, i32 5
; CHECK: [[CAPTUREDCAST:%.*]] = bitcast [8 x i8]* [[CAPTUREDGEP]] to i8*
; CHECK: call void @llvm.memcpy.p0i8.p0i8.i32(i8* [[CAPTUREDCAST]], i8* %0, i32 8, i32 8, i1 false)
; CHECK: [[BLOCKBCAST2:%.*]] = bitcast <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>* [[BLOCK2]] to i8*
; CHECK: [[BLOCKADDRCAST2:%.*]] = addrspacecast i8* [[BLOCKBCAST2]] to i8 addrspace(4)*
; CHECK: call i32 @__get_kernel_work_group_size_impl(i8 addrspace(4)* [[BLOCKADDRCAST2]])
; CHECK: call i32 @__get_kernel_preferred_work_group_multiple_impl(i8 addrspace(4)* [[BLOCKADDRCAST2]]) #0
; CHECK: call i32 @__enqueue_kernel_basic_events

; CHECK: define internal spir_func void @__host_kernel_block_invoke(
; CHECK-NOT: bitcast i8* %.block_descriptor to <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [0 x i8] }>*

; CHECK: define internal spir_func void @__host_kernel_block_invoke_2(
; CHECK-NEXT: entry:
; CHECK-NEXT: [[INV_BLOCK:%.*]] = bitcast i8* %.block_descriptor to <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>*
; CHECK-NEXT: [[INV_CAPTUREDGEP:%.*]] = getelementptr <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>, <{ i8*, i32, i32, i8*, %struct.__block_descriptor*, [8 x i8] }>* [[INV_BLOCK]], i32 0, i32 5
; CHECK-NEXT: bitcast [8 x i8]* [[INV_CAPTUREDGEP]] to i8*
; CHECK-NEXT: br label %invoke

; ModuleID = 'device_execution_overloading.cl'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknonw-unknown"

%opencl.block = type opaque
%struct.ndrange_t = type { i32, [3 x i64], [3 x i64], [3 x i64] }
%opencl.queue_t = type opaque
%opencl.clk_event_t = type opaque

; Function Attrs: nounwind
define spir_func void @device_kernel_with_local_args(float addrspace(3)* %ptr0, float addrspace(3)* %ptr1) #0 {
entry:
  %ptr0.addr = alloca float addrspace(3)*, align 8
  %ptr1.addr = alloca float addrspace(3)*, align 8
  store float addrspace(3)* %ptr0, float addrspace(3)** %ptr0.addr, align 8
  store float addrspace(3)* %ptr1, float addrspace(3)** %ptr1.addr, align 8
  %0 = load float addrspace(3)*, float addrspace(3)** %ptr0.addr, align 8
  store float 0.000000e+00, float addrspace(3)* %0, align 4
  %1 = load float addrspace(3)*, float addrspace(3)** %ptr1.addr, align 8
  store float 1.000000e+00, float addrspace(3)* %1, align 4
  ret void
}

; Function Attrs: nounwind
define spir_func void @device_kernel(float addrspace(1)* %ptr) #0 {
entry:
  %ptr.addr = alloca float addrspace(1)*, align 8
  store float addrspace(1)* %ptr, float addrspace(1)** %ptr.addr, align 8
  %0 = load float addrspace(1)*, float addrspace(1)** %ptr.addr, align 8
  store float 3.000000e+00, float addrspace(1)* %0, align 4
  ret void
}
; Function Attrs: nounwind
define spir_kernel void @host_kernel(i32 %size, float addrspace(1)* %ptr) #0 {
entry:
  %size.addr = alloca i32, align 4
  %ptr.addr = alloca float addrspace(1)*, align 8
  %block_with_local = alloca %opencl.block*, align 8
  %block = alloca %opencl.block*, align 8
  %captured = alloca <{ float addrspace(1)* }>, align 8
  %wgSize = alloca i32, align 4
  %prefMul = alloca i32, align 4
  %agg.tmp = alloca %struct.ndrange_t, align 8
  %agg.tmp8 = alloca %struct.ndrange_t, align 8
  store i32 %size, i32* %size.addr, align 4
  store float addrspace(1)* %ptr, float addrspace(1)** %ptr.addr, align 8
  %0 = call %opencl.block* @spir_block_bind(i8* bitcast (void (i8*, i8 addrspace(3)*, i8 addrspace(3)*)* @__host_kernel_block_invoke to i8*), i32 0, i32 0, i8* null)
  store %opencl.block* %0, %opencl.block** %block_with_local, align 8
  %block.captured = getelementptr inbounds <{ float addrspace(1)* }>, <{ float addrspace(1)* }>* %captured, i32 0, i32 0
  %1 = load float addrspace(1)*, float addrspace(1)** %ptr.addr, align 8
  store float addrspace(1)* %1, float addrspace(1)** %block.captured, align 8
  %2 = bitcast <{ float addrspace(1)* }>* %captured to i8*
  %3 = call %opencl.block* @spir_block_bind(i8* bitcast (void (i8*)* @__host_kernel_block_invoke_2 to i8*), i32 8, i32 8, i8* %2)
  store %opencl.block* %3, %opencl.block** %block, align 8
  %4 = load %opencl.block*, %opencl.block** %block_with_local, align 8
  %call = call spir_func i32 @_Z26get_kernel_work_group_sizeU13block_pointerFvPU3AS3vzE(%opencl.block* %4)
  store i32 %call, i32* %wgSize, align 4
  %5 = load %opencl.block*, %opencl.block** %block_with_local, align 8
  %call2 = call spir_func i32 @_Z45get_kernel_preferred_work_group_size_multipleU13block_pointerFvPU3AS3vzE(%opencl.block* %5)
  store i32 %call2, i32* %prefMul, align 4
  %call3 = call spir_func %opencl.queue_t* @_Z17get_default_queuev()
  call spir_func void @_Z10ndrange_1Dm(%struct.ndrange_t* sret %agg.tmp, i64 1)
  %6 = load %opencl.block*, %opencl.block** %block_with_local, align 8
  %7 = load i32, i32* %size.addr, align 4
  %8 = load i32, i32* %wgSize, align 4
  %9 = load i32, i32* %prefMul, align 4
  %mul = mul i32 %8, %9
  %call4 = call spir_func i32 (%opencl.queue_t*, i32, %struct.ndrange_t*, i32, %opencl.clk_event_t**, %opencl.clk_event_t**, %opencl.block*, i32, ...) @_Z14enqueue_kernel9ocl_queuei9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvPU3AS3vzEjz(%opencl.queue_t* %call3, i32 241, %struct.ndrange_t* byval %agg.tmp, i32 0, %opencl.clk_event_t** null, %opencl.clk_event_t** null, %opencl.block* %6, i32 %7, i32 %mul)
  %10 = load %opencl.block*, %opencl.block** %block, align 8
  %call5 = call spir_func i32 @_Z26get_kernel_work_group_sizeU13block_pointerFvvE(%opencl.block* %10)
  store i32 %call5, i32* %wgSize, align 4
  %11 = load %opencl.block*, %opencl.block** %block, align 8
  %call6 = call spir_func i32 @_Z45get_kernel_preferred_work_group_size_multipleU13block_pointerFvvE(%opencl.block* %11)
  store i32 %call6, i32* %prefMul, align 4
  %call7 = call spir_func %opencl.queue_t* @_Z17get_default_queuev()
  call spir_func void @_Z10ndrange_1Dm(%struct.ndrange_t* sret %agg.tmp8, i64 1)
  %12 = load %opencl.block*, %opencl.block** %block, align 8
  %call9 = call spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvvE(%opencl.queue_t* %call7, i32 241, %struct.ndrange_t* byval %agg.tmp8, i32 0, %opencl.clk_event_t** null, %opencl.clk_event_t** null, %opencl.block* %12)
  ret void
}

; Function Attrs: nounwind
define internal spir_func void @__host_kernel_block_invoke(i8* %.block_descriptor, i8 addrspace(3)* %ptr0, i8 addrspace(3)* %ptr1) #0 {
entry:
  %.block_descriptor.addr = alloca i8*, align 8
  %ptr0.addr = alloca i8 addrspace(3)*, align 8
  %ptr1.addr = alloca i8 addrspace(3)*, align 8
  %block.addr = alloca <{}>*, align 8
  store i8* %.block_descriptor, i8** %.block_descriptor.addr, align 8
  %0 = load i8*, i8** %.block_descriptor.addr
  store i8 addrspace(3)* %ptr0, i8 addrspace(3)** %ptr0.addr, align 8
  store i8 addrspace(3)* %ptr1, i8 addrspace(3)** %ptr1.addr, align 8
  %block = bitcast i8* %.block_descriptor to <{}>*
  store <{}>* %block, <{}>** %block.addr, align 8
  %1 = load i8 addrspace(3)*, i8 addrspace(3)** %ptr0.addr, align 8
  %2 = bitcast i8 addrspace(3)* %1 to float addrspace(3)*
  %3 = load i8 addrspace(3)*, i8 addrspace(3)** %ptr1.addr, align 8
  %4 = bitcast i8 addrspace(3)* %3 to float addrspace(3)*
  call spir_func void @device_kernel_with_local_args(float addrspace(3)* %2, float addrspace(3)* %4)
  ret void
}

declare %opencl.block* @spir_block_bind(i8*, i32, i32, i8*)

; Function Attrs: nounwind
define internal spir_func void @__host_kernel_block_invoke_2(i8* %.block_descriptor) #0 {
entry:
  %.block_descriptor.addr = alloca i8*, align 8
  %block.addr = alloca <{ float addrspace(1)* }>*, align 8
  store i8* %.block_descriptor, i8** %.block_descriptor.addr, align 8
  %0 = load i8*, i8** %.block_descriptor.addr
  %block = bitcast i8* %.block_descriptor to <{ float addrspace(1)* }>*
  store <{ float addrspace(1)* }>* %block, <{ float addrspace(1)* }>** %block.addr, align 8
  %block.capture.addr = getelementptr inbounds <{ float addrspace(1)* }>, <{ float addrspace(1)* }>* %block, i32 0, i32 0
  %1 = load float addrspace(1)*, float addrspace(1)** %block.capture.addr, align 8
  call spir_func void @device_kernel(float addrspace(1)* %1)
  ret void
}

declare spir_func i32 @_Z26get_kernel_work_group_sizeU13block_pointerFvPU3AS3vzE(%opencl.block*) #1

declare spir_func i32 @_Z45get_kernel_preferred_work_group_size_multipleU13block_pointerFvPU3AS3vzE(%opencl.block*) #1

declare spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvPU3AS3vzEjz(%opencl.queue_t*, i32, %struct.ndrange_t* byval, i32, %opencl.clk_event_t**, %opencl.clk_event_t**, %opencl.block*, i32, ...) #1

declare spir_func %opencl.queue_t* @_Z17get_default_queuev() #1

declare spir_func void @_Z10ndrange_1Dm(%struct.ndrange_t* sret, i64) #1

declare spir_func i32 @_Z26get_kernel_work_group_sizeU13block_pointerFvvE(%opencl.block*) #1

declare spir_func i32 @_Z45get_kernel_preferred_work_group_size_multipleU13block_pointerFvvE(%opencl.block*) #1

declare spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvvE(%opencl.queue_t*, i32, %struct.ndrange_t* byval, i32, %opencl.clk_event_t**, %opencl.clk_event_t**, %opencl.block*) #1

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}

!0 = !{void (i32, float addrspace(1)*)* @host_kernel, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 0, i32 1}
!2 = !{!"kernel_arg_access_qual", !"none", !"none"}
!3 = !{!"kernel_arg_type", !"uint", !"float*"}
!4 = !{!"kernel_arg_base_type", !"uint", !"float*"}
!5 = !{!"kernel_arg_type_qual", !"", !""}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
