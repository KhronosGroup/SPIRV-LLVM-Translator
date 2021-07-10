; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

; CHECK-SPIRV: 6 Select

; ModuleID = 'select_bool.cl'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64"

; Function Attrs: nofree norecurse nounwind writeonly
define dso_local spir_kernel void @test(i32 %c, <8 x i32> %op1, <8 x i32> %op2, <8 x i32> addrspace(1)* nocapture %results) local_unnamed_addr #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 {
entry:
  %tobool.not = icmp eq i32 %c, 0
  %cond = select i1 %tobool.not, <8 x i32> %op2, <8 x i32> %op1
  store <8 x i32> %cond, <8 x i32> addrspace(1)* %results, align 32, !tbaa !8
  ret void
}

attributes #0 = { nofree norecurse nounwind writeonly "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="256" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 12.0.0 (https://github.com/llvm/llvm-project 94f537c6b2bb55c8e058a9989d02ab0d68a0c61a)"}
!3 = !{i32 0, i32 0, i32 0, i32 1}
!4 = !{!"none", !"none", !"none", !"none"}
!5 = !{!"int", !"uint8", !"uint8", !"uint8*"}
!6 = !{!"int", !"uint __attribute__((ext_vector_type(8)))", !"uint __attribute__((ext_vector_type(8)))", !"uint __attribute__((ext_vector_type(8)))*"}
!7 = !{!"", !"", !"", !""}
!8 = !{!9, !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
