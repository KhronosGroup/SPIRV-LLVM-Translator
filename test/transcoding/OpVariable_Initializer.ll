; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-LLVM: @test_atomic_fn.L = internal addrspace(3) global [64 x i32] undef, align 4

; CHECK-SPIRV-NOT: undef
; CHECK-SPIRV-SAME: 4 Variable 5 6 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@test_atomic_fn.L = internal addrspace(3) global [64 x i32] undef, align 4

; Function Attrs: nounwind
define spir_kernel void @test_atomic_fn() #0 {
  ret void
}

attributes #0 = { nounwind }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!spirv.Source = !{!6}
!opencl.spir.version = !{!7}
!opencl.ocl.version = !{!8}
!opencl.used.extensions = !{!9}
!opencl.used.optional.core.features = !{!9}
!spirv.Generator = !{!10}

!0 = !{void ()* @test_atomic_fn, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space"}
!2 = !{!"kernel_arg_access_qual"}
!3 = !{!"kernel_arg_type"}
!4 = !{!"kernel_arg_type_qual"}
!5 = !{!"kernel_arg_base_type"}
!6 = !{i32 3, i32 100000}
!7 = !{i32 1, i32 2}
!8 = !{i32 1, i32 0}
!9 = !{}
!10 = !{i16 7, i16 0}
