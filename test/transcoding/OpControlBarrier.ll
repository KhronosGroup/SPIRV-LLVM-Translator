; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-LLVM: call spir_func void @_Z18work_group_barrierj(i32 2)
; CHECK-LLVM: call spir_func void @_Z18work_group_barrierj(i32 1)
; CHECK-LLVM: call spir_func void @_Z18work_group_barrierj(i32 4)

; CHECK-SPIRV-DAG: 4 ControlBarrier [[Scope1:[0-9]+]] [[Scope2:[0-9]+]] [[MemSema1:[0-9]+]]
; CHECK-SPIRV-DAG: 4 Constant {{[0-9]+}} [[Scope1]] {{[0-9]+}} 
; CHECK-SPIRV-DAG: 4 Constant {{[0-9]+}} [[Scope2]] {{[0-9]+}} 
; CHECK-SPIRV-DAG: 4 Constant {{[0-9]+}} [[MemSema1]] {{[0-9]+}} 

; CHECK-SPIRV-DAG: 4 ControlBarrier [[Scope1]] [[Scope2]] [[MemSema2:[0-9]+]]
; CHECK-SPIRV-DAG: 4 Constant {{[0-9]+}} [[MemSema2]] {{[0-9]+}} 

; CHECK-SPIRV-DAG: 4 ControlBarrier [[Scope1]] [[Scope2]] [[MemSema3:[0-9]+]]
; CHECK-SPIRV-DAG: 4 Constant {{[0-9]+}} [[MemSema3]] {{[0-9]+}} 

; ModuleID = 'P:\work_group_barrier.cl'
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: nounwind
define spir_kernel void @test() #0 {
entry:
  tail call spir_func void @_Z18work_group_barrierj(i32 2) #2
  tail call spir_func void @_Z18work_group_barrierj(i32 1) #2
  tail call spir_func void @_Z18work_group_barrierj(i32 4) #2
  ret void
}

declare spir_func void @_Z18work_group_barrierj(i32) #1

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

!0 = !{void ()* @test, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space"}
!2 = !{!"kernel_arg_access_qual"}
!3 = !{!"kernel_arg_type"}
!4 = !{!"kernel_arg_base_type"}
!5 = !{!"kernel_arg_type_qual"}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
