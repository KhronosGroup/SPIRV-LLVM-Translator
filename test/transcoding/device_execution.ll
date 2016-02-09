; ModuleID = 'repro.cl'
;
; bash$ cat repro.cl
; void __kernel device_kernel(__global float * inout) {
;   *inout = cos(*inout);
; }
;
; void __kernel host_kernel(__global float * inout) {
;   enqueue_kernel(get_default_queue(),
;                  CLK_ENQUEUE_FLAGS_WAIT_KERNEL,
;                  ndrange_1D(1),
;                  0, NULL, NULL,
;                  ^{ device_kernel(inout); });
; }
; bash$ export PATH_TO_INCLUDE= $PATH_TO_GEN/lib/clang/3.6.1/include
; bash$ $PATH_TO_GEN/bin/clang -cc1 -x cl -cl-std=CL2.0 -triple spir64-unknonw-unknown -emit-llvm  -include opencl-20.h  repro.cl -o device_execution.ll

;; Regression test for
;; 1. enqueue_kernel built-in is mangled accordingly to SPIR2.0/C++ ABI (no substitution is done)
;; 2. the 4rth argument of enqueue_kernel is mangled as "const clk_event_t*"

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s

; CHECK-NOT: @_Z14enqueue_kernel{{.*}}{{S_|S0_|S1_}}
; CHECK:     @_Z14enqueue_kernel9ocl_queue{{22kernel_enqueue_flags_t|i}}9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvvE
declare spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvvE(%opencl.queue_t*, i32, %struct.ndrange_t* byval, i32, %opencl.clk_event_t**, %opencl.clk_event_t**, %opencl.block*) #1

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknonw-unknown"

%struct.ndrange_t = type { i32, [3 x i64], [3 x i64], [3 x i64] }
%opencl.queue_t = type opaque
%opencl.block = type opaque
%opencl.clk_event_t = type opaque

; Function Attrs: nounwind
define spir_kernel void @device_kernel(float addrspace(1)* nocapture %inout) #0 {
entry:
  %0 = load float addrspace(1)* %inout, align 4, !tbaa !11
  %call = tail call spir_func float @_Z3cosf(float %0) #2
  store float %call, float addrspace(1)* %inout, align 4, !tbaa !11
  ret void
}

declare spir_func float @_Z3cosf(float) #1

; Function Attrs: nounwind
define spir_kernel void @host_kernel(float addrspace(1)* %inout) #0 {
entry:
  %captured = alloca <{ float addrspace(1)* }>, align 8
  %agg.tmp = alloca %struct.ndrange_t, align 8
  %call = tail call spir_func %opencl.queue_t* @get_default_queue() #2
  call spir_func void @_Z10ndrange_1Dm(%struct.ndrange_t* sret %agg.tmp, i64 1) #2
  %block.captured = getelementptr inbounds <{ float addrspace(1)* }>* %captured, i64 0, i32 0
  store float addrspace(1)* %inout, float addrspace(1)** %block.captured, align 8, !tbaa !15
  %0 = bitcast <{ float addrspace(1)* }>* %captured to i8*
  %1 = call %opencl.block* @spir_block_bind(i8* bitcast (void (i8*)* @__host_kernel_block_invoke to i8*), i32 8, i32 8, i8* %0) #2
  %call1 = call spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvvE(%opencl.queue_t* %call, i32 241, %struct.ndrange_t* byval %agg.tmp, i32 0, %opencl.clk_event_t** null, %opencl.clk_event_t** null, %opencl.block* %1) #2
  ret void
}

declare spir_func %opencl.queue_t* @get_default_queue() #1

declare spir_func void @_Z10ndrange_1Dm(%struct.ndrange_t* sret, i64) #1

; Function Attrs: nounwind
define internal spir_func void @__host_kernel_block_invoke(i8* nocapture readonly %.block_descriptor) #0 {
entry:
  %block.capture.addr = bitcast i8* %.block_descriptor to float addrspace(1)**
  %0 = load float addrspace(1)** %block.capture.addr, align 8, !tbaa !15
  %1 = load float addrspace(1)* %0, align 4, !tbaa !11
  %call.i = tail call spir_func float @_Z3cosf(float %1) #2
  store float %call.i, float addrspace(1)* %0, align 4, !tbaa !11
  ret void
}

declare %opencl.block* @spir_block_bind(i8*, i32, i32, i8*)

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind }

!opencl.kernels = !{!0, !6}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!7}
!opencl.ocl.version = !{!8}
!opencl.used.extensions = !{!9}
!opencl.used.optional.core.features = !{!9}
!opencl.compiler.options = !{!9}
!llvm.ident = !{!10}

!0 = !{void (float addrspace(1)*)* @device_kernel, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 1}
!2 = !{!"kernel_arg_access_qual", !"none"}
!3 = !{!"kernel_arg_type", !"float*"}
!4 = !{!"kernel_arg_base_type", !"float*"}
!5 = !{!"kernel_arg_type_qual", !""}
!6 = !{void (float addrspace(1)*)* @host_kernel, !1, !2, !3, !4, !5}
!7 = !{i32 1, i32 2}
!8 = !{i32 2, i32 0}
!9 = !{}
!10 = !{!"clang version 3.6.1 (https://github.com/KhronosGroup/SPIR.git 49a8b4a760d227b12116a79b2f7b2e34ef2e6879) (ssh://nnopencl-git-01.inn.intel.com/home/git/repo/opencl_qa-llvm d9b98710f905089caec167209da23af2e4f72bf0)"}
!11 = !{!12, !12, i64 0}
!12 = !{!"float", !13, i64 0}
!13 = !{!"omnipotent char", !14, i64 0}
!14 = !{!"Simple C/C++ TBAA"}
!15 = !{!16, !16, i64 0}
!16 = !{!"any pointer", !13, i64 0}
