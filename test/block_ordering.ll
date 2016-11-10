; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: 2 Label [[entry:[0-9]+]]
; CHECK-SPIRV: 2 Branch [[test:[0-9]+]]
; CHECK-LLVM: entry:
; CHECK-LLVM: br label %test

; CHECK-SPIRV: 2 Label [[test]]
; CHECK-SPIRV: 4 BranchConditional {{[0-9]+}} [[if_then2:[0-9]+]] [[if_end3:[0-9]+]]
; CHECK-LLVM: test:
; CHECK-LLVM: preds = %if.end, %entry
; CHECK-LLVM: br i1 %tobool1, label %if.then2, label %if.end3

; CHECK-SPIRV: 2 Label [[if_then2]]
; CHECK-SPIRV: 2 Branch [[loop:[0-9]+]]
; CHECK-LLVM: if.then2:
; CHECK-LLVM: preds = %test
; CHECK-LLVM: br label %loop

; CHECK-SPIRV: 2 Label [[loop]]
; CHECK-SPIRV: 4 BranchConditional {{[0-9]+}} [[if_then:[0-9]+]]  [[if_end:[0-9]+]]
; CHECK-LLVM: loop:
; CHECK-LLVM: preds = %if.then2
; CHECK-LLVM: br i1 %tobool, label %if.then, label %if.end

; CHECK-SPIRV: 2 Label [[if_then]]
; CHECK-SPIRV: 2 Branch [[if_end]]
; CHECK-LLVM: if.then:
; CHECK-LLVM: preds = %loop
; CHECK-LLVM: br label %if.end

; CHECK-SPIRV: 2 Label [[if_end]]
; CHECK-SPIRV: 2 Branch [[test]]
; CHECK-LLVM: if.end:
; CHECK-LLVM: preds = %if.then, %loop
; CHECK-LLVM: br label %test

; CHECK-SPIRV: 2 Label [[if_end3]]
; CHECK-LLVM: if.end3:
; CHECK-LLVM: preds = %test

; ModuleID = 'main'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; Function Attrs: nounwind
define spir_kernel void @test_kernel(i32 addrspace(1)* %results) #0 {
entry:
  br label %test

loop:                                             ; preds = %if.then2
  %tobool = icmp ne i32 %ix.1, 0
  br i1 %tobool, label %if.then, label %if.end

if.then:                                          ; preds = %loop
  br label %if.end

if.end:                                           ; preds = %if.then, %loop
  %ix.0 = phi i32 [ 20, %if.then ], [ %ix.1, %loop ]
  br label %test

test:                                             ; preds = %if.end, %entry
  %ix.1 = phi i32 [ 10, %entry ], [ %ix.0, %if.end ]
  %tobool1 = icmp ne i32 %ix.1, 0
  br i1 %tobool1, label %if.then2, label %if.end3

if.then2:                                         ; preds = %test
  br label %loop

if.end3:                                          ; preds = %test
  ret void
}

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}
!llvm.ident = !{!9}

!0 = !{void (i32 addrspace(1)*)* @test_kernel, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 1}
!2 = !{!"kernel_arg_access_qual", !"none"}
!3 = !{!"kernel_arg_type", !"int*"}
!4 = !{!"kernel_arg_base_type", !"int*"}
!5 = !{!"kernel_arg_type_qual", !""}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
!9 = !{!"clang version 3.6.1"}