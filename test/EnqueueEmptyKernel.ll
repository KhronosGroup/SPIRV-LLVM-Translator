;; This test checks that Invoke parameter of OpEnueueKernel instruction meet the
;; following specification requirements in case of enqueueing empty block:
;;"Invoke must be an OpFunction whose OpTypeFunction operand has:
;; - Result Type must be OpTypeVoid.
;; - The first parameter must have a type of OpTypePointer to an 8-bit OpTypeInt.
;; - An optional list of parameters, each of which must have a type of OpTypePointer to the Workgroup Storage Class.
;; ... "
;; __kernel void test_enqueue_empty() {
;;   enqueue_kernel(get_default_queue(),
;;                  CLK_ENQUEUE_FLAGS_WAIT_KERNEL,
;;                  ndrange_1D(1),
;;                  0, NULL, NULL,
;;                  ^(){});
; RUN: llvm-as < %s > %t.bc
; RUN: llvm-spirv %t.bc -o - -spirv-text | FileCheck %s --check-prefix=CHECK-SPIRV

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%struct.ndrange_t = type { i32, [3 x i64], [3 x i64], [3 x i64] }
%opencl.queue_t = type opaque
%opencl.block = type opaque
%opencl.clk_event_t = type opaque

; CHECK-SPIRV: TypeInt [[Int8:[0-9]+]] 8
; CHECK-SPIRV: TypeVoid [[Void:[0-9]+]]
; CHECK-SPIRV: TypePointer [[Int8Ptr:[0-9]+]] {{[0-9]+}} [[Int8]]
; CHECK-SPIRV: ConstantNull [[Int8Ptr]] [[NullInt8Ptr:[0-9]+]]

; Function Attrs: nounwind
define spir_kernel void @test_enqueue_empty() #0 {
entry:
  %agg.tmp = alloca %struct.ndrange_t, align 8
  %call = call spir_func %opencl.queue_t* @_Z17get_default_queuev()
  call spir_func void @_Z10ndrange_1Dm(%struct.ndrange_t* sret %agg.tmp, i64 1)
  %0 = call %opencl.block* @spir_block_bind(i8* bitcast (void (i8*)* @__test_enqueue_empty_block_invoke to i8*), i32 0, i32 0, i8* null)
  %call1 = call spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvvE(%opencl.queue_t* %call, i32 1, %struct.ndrange_t* byval %agg.tmp, i32 0, %opencl.clk_event_t** null, %opencl.clk_event_t** null, %opencl.block* %0)
  ret void
; CHECK-SPIRV: EnqueueKernel {{[0-9]+}} {{[0-9]+}} {{[0-9]+}} {{[0-9]+}} {{[0-9]+}} {{[0-9]+}} {{[0-9]+}} {{[0-9]+}} [[Invoke:[0-9]+]] [[NullInt8Ptr]] {{[0-9]+}} {{[0-9]+}}

}

declare spir_func i32 @_Z14enqueue_kernel9ocl_queuei9ndrange_tjPK12ocl_clkeventP12ocl_clkeventU13block_pointerFvvE(%opencl.queue_t*, i32, %struct.ndrange_t* byval, i32, %opencl.clk_event_t**, %opencl.clk_event_t**, %opencl.block*) #1

declare spir_func %opencl.queue_t* @_Z17get_default_queuev() #1

declare spir_func void @_Z10ndrange_1Dm(%struct.ndrange_t* sret, i64) #1


; CHECK-SPIRV: Function [[Void]] [[Invoke]] {{[0-9]+}} {{[0-9]+}}
; CHECK-SPIRV-NEXT: FunctionParameter [[Int8Ptr]]  {{[0-9]+}}

; Function Attrs: nounwind
define internal spir_func void @__test_enqueue_empty_block_invoke(i8* %.block_descriptor) #0 {
entry:
  %block = bitcast i8* %.block_descriptor to <{}>*
  ret void
}

declare %opencl.block* @spir_block_bind(i8*, i32, i32, i8*)

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}

!0 = !{void ()* @test_enqueue_empty, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space"}
!2 = !{!"kernel_arg_access_qual"}
!3 = !{!"kernel_arg_type"}
!4 = !{!"kernel_arg_base_type"}
!5 = !{!"kernel_arg_type_qual"}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
