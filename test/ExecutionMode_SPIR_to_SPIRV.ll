; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; LLVM => SPIRV checks
; check for magic number followed by version 1.0
; CHECK-SPIRV: 119734787 65536

; CHECK-SPIRV-DAG: EntryPoint 6 [[WORKER:[0-9]+]] "worker"
; CHECK-SPIRV-DAG: ExecutionMode [[WORKER]] 18 128 10 1


; LLVM => SPIRV => LLVM checks
; CHECK-LLVM: define spir_kernel void @worker()
; CHECK-LLVM-SAME: !work_group_size_hint [[WG:![0-9]+]]

; CHECK-LLVM: [[WG]] = !{i32 128, i32 10, i32 1}

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir-unknown-unknown"

; Function Attrs: nounwind
define spir_kernel void @worker() #0 {
entry:
  ret void
}

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!7}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}
!llvm.ident = !{!9}

!0 = !{void ()* @worker, !1, !2, !3, !4, !5, !6}
!1 = !{!"kernel_arg_addr_space"}
!2 = !{!"kernel_arg_access_qual"}
!3 = !{!"kernel_arg_type"}
!4 = !{!"kernel_arg_base_type"}
!5 = !{!"kernel_arg_type_qual"}
!6 = !{!"work_group_size_hint", i32 128, i32 10, i32 1}
!7 = !{i32 1, i32 2}
!8 = !{}
!9 = !{!"clang version 3.6.1 "}
