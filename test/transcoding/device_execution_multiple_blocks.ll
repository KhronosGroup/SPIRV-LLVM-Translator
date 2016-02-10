;; Test what the reader correctly mangles get_kernel_work_group_size,
;; get_kernel_preferred_work_group_size_multiple, and enqueue_kernel built-ins and
;; produces spir_block_bind for the both blocks one of which is w\o captured context.
;; Notice what for the moment spir_block_bind is called as many times as how much
;; built-ins what using it. This is not against SPIR 2.0 specification so it is done this
;; way to simplify the reader implementation.
;;
;; See below how this LLVM IR has been obtained:
;; bash$
;; bash$ cat device_execution_multiple_blocks.cl
;; void block_fn(int arg, __global int* res)
;; {
;;   *res = arg;
;; }
;;
;; __global int glbRes = 0;
;; void (^kernelBlockNoCtx)(void) = ^{ block_fn(1, &glbRes); };
;;
;; kernel void enqueue_block_get_kernel_preferred_work_group_size_multiple(__global int* res)
;; {
;;
;;
;;     void (^kernelBlock)(void) = ^{ block_fn(2, res); };
;;     uint globalSize = get_kernel_work_group_size(kernelBlock);
;;     uint multiple   = get_kernel_preferred_work_group_size_multiple(kernelBlock);
;;     uint localSize  = globalSize / multiple;
;;
;;     queue_t q1 = get_default_queue();
;;     ndrange_t ndrange = ndrange_1D(localSize, globalSize);
;;     enqueue_kernel(q1, CLK_ENQUEUE_FLAGS_WAIT_KERNEL, ndrange, kernelBlock);
;;     // Enqueue kernel w\o captured context
;;     enqueue_kernel(q1, CLK_ENQUEUE_FLAGS_WAIT_KERNEL, ndrange, kernelBlockNoCtx);
;; }
;; bash$
;; bash$ export PATH_TO_GEN=path_to_spir20_generator_install_dir
;; bash$ $PATH_TO_GEN/bin/clang -cc1 -x cl -O2 -cl-std=CL2.0 -triple spir64-unknonw-unknown\
;; -emit-spirv -include $PATH_TO_GEN/lib/clang/3.6.1/include/opencl-20.h\
;; device_execution_multiple_blocks.cl -o device_execution_multiple_blocks.ll

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s

; ModuleID = 'device_execution_multiple_blocks.cl'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknonw-unknown"

%struct.ndrange_t = type { i32, [3 x i64], [3 x i64], [3 x i64] }
%opencl.block = type opaque
%opencl.queue_t = type opaque

@glbRes = addrspace(1) global i32 0, align 4

; Function Attrs: nounwind
define spir_func void @block_fn(i32 %arg, i32 addrspace(1)* nocapture %res) #0 {
entry:
  store i32 %arg, i32 addrspace(1)* %res, align 4
  ret void
}

; Function Attrs: nounwind
define internal spir_func void @kernelBlockNoCtx_block_invoke(i8* nocapture readnone %.block_descriptor) #0 {
entry:
  store i32 1, i32 addrspace(1)* @glbRes, align 4
  ret void
}

; Function Attrs: nounwind
define spir_kernel void @enqueue_block_get_kernel_preferred_work_group_size_multiple(i32 addrspace(1)* %res) #0 {
entry:
  %captured = alloca <{ i32 addrspace(1)* }>, align 8
  %ndrange = alloca %struct.ndrange_t, align 8
  %block.captured = getelementptr inbounds <{ i32 addrspace(1)* }>* %captured, i64 0, i32 0
  store i32 addrspace(1)* %res, i32 addrspace(1)** %block.captured, align 8
  %0 = bitcast <{ i32 addrspace(1)* }>* %captured to i8*
; CHECK: [[CTX:.*]] = bitcast %0* %captured to i8*
  %1 = call %opencl.block* @spir_block_bind(i8* bitcast (void (i8*)* @__enqueue_block_get_kernel_preferred_work_group_size_multiple_block_invoke to i8*), i32 8, i32 8, i8* %0) #2
; CHECK: [[BLOCK0:.*]] = call {{.*}} @spir_block_bind({{.*}}@__enqueue_block_get_kernel_preferred_work_group_size_multiple_block_invoke{{.*}}, i32 8, i32 8, i8*[[CTX]])
; CHECK: call {{.*}} @_Z26get_kernel_work_group_sizeU13block_pointerFvvE(%opencl.block*[[BLOCK0]])
  %call = call spir_func i32 @_Z26get_kernel_work_group_sizeU13block_pointerFvvE(%opencl.block* %1) #2
; CHECK: [[BLOCK1:.*]] = call {{.*}} @spir_block_bind({{.*}}@__enqueue_block_get_kernel_preferred_work_group_size_multiple_block_invoke{{.*}}, i32 8, i32 8, i8*[[CTX]])
; CHECK:  call {{.*}} @_Z45get_kernel_preferred_work_group_size_multipleU13block_pointerFvvE(%opencl.block*[[BLOCK1]])
  %call1 = call spir_func i32 @_Z45get_kernel_preferred_work_group_size_multipleU13block_pointerFvvE(%opencl.block* %1) #2
  %div = udiv i32 %call, %call1
  %call2 = call spir_func %opencl.queue_t* @get_default_queue() #2
  %conv = zext i32 %div to i64
  %conv3 = zext i32 %call to i64
  call spir_func void @_Z10ndrange_1Dmm(%struct.ndrange_t* sret %ndrange, i64 %conv, i64 %conv3) #2
; CHECK: [[BLOCK2:.*]] = call {{.*}} @spir_block_bind({{.*}}@__enqueue_block_get_kernel_preferred_work_group_size_multiple_block_invoke{{.*}}, i32 8, i32 8, i8*[[CTX]])
; CHECK:  call {{.*}} @_Z14enqueue_kernel{{.*}}, %opencl.block*[[BLOCK2]])
  %call4 = call spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tU13block_pointerFvvE(%opencl.queue_t* %call2, i32 241, %struct.ndrange_t* byval %ndrange, %opencl.block* %1) #2
; CHECK: [[BLOCK3:.*]] = call {{.*}} @spir_block_bind({{.*}}@kernelBlockNoCtx_block_invoke{{.*}}, i32 0, i32 0, i8* null)
; CHECK: call {{.*}} @_Z14enqueue_kernel{{.*}}, %opencl.block*[[BLOCK3]])
  %2 = call %opencl.block* @spir_block_bind(i8* bitcast (void (i8*)* @kernelBlockNoCtx_block_invoke to i8*), i32 0, i32 0, i8* null) #2
  %call5 = call spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tU13block_pointerFvvE(%opencl.queue_t* %call2, i32 241, %struct.ndrange_t* byval %ndrange, %opencl.block* %2) #2
  ret void
}

; Function Attrs: nounwind
define internal spir_func void @__enqueue_block_get_kernel_preferred_work_group_size_multiple_block_invoke(i8* nocapture readonly %.block_descriptor) #0 {
entry:
  %block.capture.addr = bitcast i8* %.block_descriptor to i32 addrspace(1)**
  %0 = load i32 addrspace(1)** %block.capture.addr, align 8
  store i32 2, i32 addrspace(1)* %0, align 4
  ret void
}

declare %opencl.block* @spir_block_bind(i8*, i32, i32, i8*)

declare spir_func i32 @_Z26get_kernel_work_group_sizeU13block_pointerFvvE(%opencl.block*) #1

declare spir_func i32 @_Z45get_kernel_preferred_work_group_size_multipleU13block_pointerFvvE(%opencl.block*) #1

declare spir_func %opencl.queue_t* @get_default_queue() #1

declare spir_func void @_Z10ndrange_1Dmm(%struct.ndrange_t* sret, i64, i64) #1

declare spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tU13block_pointerFvvE(%opencl.queue_t*, i32, %struct.ndrange_t* byval, %opencl.block*) #1

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}
!llvm.ident = !{!9}

!0 = !{void (i32 addrspace(1)*)* @enqueue_block_get_kernel_preferred_work_group_size_multiple, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 1}
!2 = !{!"kernel_arg_access_qual", !"none"}
!3 = !{!"kernel_arg_type", !"int*"}
!4 = !{!"kernel_arg_base_type", !"int*"}
!5 = !{!"kernel_arg_type_qual", !""}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
!9 = !{!"clang version 3.6.1 (https://github.com/KhronosGroup/SPIR.git 49a8b4a760d227b12116a79b2f7b2e34ef2e6879) (ssh://nnopencl-git-01.inn.intel.com/home/git/repo/opencl_qa-llvm d9b98710f905089caec167209da23af2e4f72bf0)"}
