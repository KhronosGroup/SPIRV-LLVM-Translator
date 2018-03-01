; This test verifies that the Vector16 capability is correctly added
; if an OpenCL kernel uses a vector of eight elements.
;
;Source:
;__kernel void test( int8 v ) {}

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o - -spirv-text | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: Capability Vector16

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir"

; Function Attrs: nounwind
define spir_kernel void @test(<8 x i32> %v) #0 {
; CHECK-LLVM: <8 x i32>
  %1 = alloca <8 x i32>, align 32
  store <8 x i32> %v, <8 x i32>* %1, align 32
  ret void
}

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!6}
!opencl.used.extensions = !{!7}
!opencl.used.optional.core.features = !{!7}
!opencl.compiler.options = !{!7}
!llvm.ident = !{!8}

!0 = !{void (<8 x i32>)* @test, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 0}
!2 = !{!"kernel_arg_access_qual", !"none"}
!3 = !{!"kernel_arg_type", !"int8"}
!4 = !{!"kernel_arg_base_type", !"int8"}
!5 = !{!"kernel_arg_type_qual", !""}
!6 = !{i32 1, i32 2}
!7 = !{}
!8 = !{!"clang version 3.6.1 (https://github.com/KhronosGroup/SPIR 2b577882b436ba3133457f27e0aa999f2ac8b11c) (https://github.com/KhronosGroup/SPIRV-LLVM.git 44ec76519179879c7900a5da4e724c751ce516a9)"}
