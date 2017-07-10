; kernel
; __attribute__((vec_type_hint(float4)))
; void test_float() {}
;
; kernel
; __attribute__((vec_type_hint(double)))
; void test_double() {}
;
; kernel
; __attribute__((vec_type_hint(uint4)))
; void test_uint() {}
;
; kernel
; __attribute__((vec_type_hint(int8)))
; void test_int() {}
; bash$ clang -cc1 -triple spir64-unknown-unknown -x cl -cl-std=CL2.0 -O0 -include opencl.h -emit-llvm vec_type_hint.cl -o vec_type_hint.ll

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_float"
; CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_double"
; CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_uint"
; CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_int"
; CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 {{[0-9]+}}
; CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 {{[0-9]+}}
; CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 {{[0-9]+}}
; CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 {{[0-9]+}}

; ModuleID = 'vec_type_hint.cl'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; CHECK-LLVM: define spir_kernel void @test_float()
; CHECK-LLVM-SAME: !vec_type_hint [[VFLOAT:![0-9]+]]
; Function Attrs: nounwind
define spir_kernel void @test_float() #0 {
entry:
  ret void
}

; CHECK-LLVM: define spir_kernel void @test_double()
; CHECK-LLVM-SAME: !vec_type_hint [[VDOUBLE:![0-9]+]]
; Function Attrs: nounwind
define spir_kernel void @test_double() #0 {
entry:
  ret void
}

; CHECK-LLVM: define spir_kernel void @test_uint()
; CHECK-LLVM-SAME: !vec_type_hint [[VUINT:![0-9]+]]
; Function Attrs: nounwind
define spir_kernel void @test_uint() #0 {
entry:
  ret void
}

; CHECK-LLVM: define spir_kernel void @test_int()
; CHECK-LLVM-SAME: !vec_type_hint [[VINT:![0-9]+]]
; Function Attrs: nounwind
define spir_kernel void @test_int() #0 {
entry:
  ret void
}

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0, !7, !9, !11}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!13}
!opencl.ocl.version = !{!14}
!opencl.used.extensions = !{!15}
!opencl.used.optional.core.features = !{!15}
!opencl.compiler.options = !{!15}
!llvm.ident = !{!16}

; CHECK-LLVM: [[VFLOAT]] = !{<4 x float> undef, i32 1}
; CHECK-LLVM: [[VDOUBLE]] = !{double undef, i32 1}
; CHECK-LLVM: [[VUINT]] = !{<4 x i32> undef, i32 1}
; CHECK-LLVM: [[VINT]] = !{<8 x i32> undef, i32 1}

!0 = !{void ()* @test_float, !1, !2, !3, !4, !5, !6}
!1 = !{!"kernel_arg_addr_space"}
!2 = !{!"kernel_arg_access_qual"}
!3 = !{!"kernel_arg_type"}
!4 = !{!"kernel_arg_base_type"}
!5 = !{!"kernel_arg_type_qual"}
!6 = !{!"vec_type_hint", <4 x float> undef, i32 1}
!7 = !{void ()* @test_double, !1, !2, !3, !4, !5, !8}
!8 = !{!"vec_type_hint", double undef, i32 1}
!9 = !{void ()* @test_uint, !1, !2, !3, !4, !5, !10}
!10 = !{!"vec_type_hint", <4 x i32> undef, i32 0}
!11 = !{void ()* @test_int, !1, !2, !3, !4, !5, !12}
!12 = !{!"vec_type_hint", <8 x i32> undef, i32 1}
!13 = !{i32 1, i32 2}
!14 = !{i32 2, i32 0}
!15 = !{}
!16 = !{!"clang version 3.6.1"}
