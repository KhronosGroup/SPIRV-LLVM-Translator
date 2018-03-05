;; There are no blocks in SPIR-V. Therefore they are translated into regular
;; functions. An LLVM module which uses blocks, also contains some auxiliary
;; block-specific instructions, which are redundant in SPIR-V and should be
;; removed

;; file: block.cl
;; kernel void block_kernel(__global int* res) {
;;   typedef int (^block_t)(int);
;;   constant block_t b1 = ^(int i) { return i + 1; };
;;   *res = b1(5);
;; }
;; clang -cc1 -O0 -triple spir-unknown-unknown -cl-std=CL2.0 -x cl block.cl -emit-llvm -o - | opt -mem2reg -S > global_block.ll

; RUN: llvm-as < %s > %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir-unknown-unknown"

; CHECK-SPIRV: Name [[block_invoke:[0-9]+]] "_block_invoke"
; CHECK-SPIRV: TypeInt [[int:[0-9]+]] 32
; CHECK-SPIRV: Constant [[int]] [[five:[0-9]+]] 5
; CHECK-SPIRV: TypeFunction [[block_invoke_type:[0-9]+]] [[int]] [[int]]
;; Check that block invoke function has no block descriptor argument in SPIR-V
; CHECK-SPIRV-NOT: TypeFunction [[block_invoke_type]] [[int]] {{[0-9]+}} [[int]]

%opencl.block = type opaque

@block_kernel.b1 = internal addrspace(2) constant %opencl.block* bitcast (i32 (i8*, i32)* @_block_invoke to %opencl.block*), align 4
;; This variable is not needed in SPIRV
; CHECK-SPIRV-NOT Variable
; CHECK-LLVM-NOT: @block_kernel.b1

; Function Attrs: nounwind
define spir_kernel void @block_kernel(i32 addrspace(1)* %res) #0 {
entry:
  %0 = load %opencl.block*, %opencl.block* addrspace(2)* @block_kernel.b1, align 4
  %1 = call i8* @spir_get_block_invoke(%opencl.block* %0)
  %2 = call i8* @spir_get_block_context(%opencl.block* %0)
  %3 = bitcast i8* %1 to i32 (i8*, i32)*
  %call = call spir_func i32 %3(i8* %2, i32 5)
; CHECK-SPIRV: FunctionCall [[int]] {{[0-9]+}} [[block_invoke]] [[five]]
; CHECK-LLVM: %call = call spir_func i32 @_block_invoke(i32 5)
  store i32 %call, i32 addrspace(1)* %res, align 4
  ret void
}

; Function Attrs: nounwind
define internal spir_func i32 @_block_invoke(i8* %.block_descriptor, i32 %i) #0 {
; CHECK-SPIRV: 5 Function [[int]] [[block_invoke]] 0 [[block_invoke_type]]
; CHECK-SPIRV-NEXT: 3 FunctionParameter [[int]] {{[0-9]+}}
; CHECK-LLVM: define internal spir_func i32 @_block_invoke(i32 %i)
entry:
  %block = bitcast i8* %.block_descriptor to <{}>*
;; Instruction above is useless and should be removed.
; CHECK-SPIRV-NOT: Bitcast
; CHECK-LLVM-NOT: bitcast
  %add = add nsw i32 %i, 1
  ret i32 %add
}

declare i8* @spir_get_block_invoke(%opencl.block*)

declare i8* @spir_get_block_context(%opencl.block*)

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}

!0 = !{void (i32 addrspace(1)*)* @block_kernel, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 1}
!2 = !{!"kernel_arg_access_qual", !"none"}
!3 = !{!"kernel_arg_type", !"int*"}
!4 = !{!"kernel_arg_base_type", !"int*"}
!5 = !{!"kernel_arg_type_qual", !""}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}

