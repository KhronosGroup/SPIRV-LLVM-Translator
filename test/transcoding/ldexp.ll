; Check that translator does the scalar to vector conversion for ldexp math
; instructions whose second operand type is scalar
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefixes=CHECK-LLVM-CL20

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: convergent mustprogress nofree norecurse nounwind willreturn writeonly
define dso_local spir_kernel void @test_kernel(<3 x float> %x, i32 %k, <3 x float> addrspace(1)* nocapture %ret) local_unnamed_addr #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 {
entry:
  ; CHECK-SPIRV: {{.*}} ldexp
  ; CHECK-LLVM-CL20: %call = call spir_func <3 x float> @_Z5ldexpDv3_fDv3_i(
  %call = tail call spir_func <3 x float> @_Z5ldexpDv3_fi(<3 x float> %x, i32 %k) #2
  %extractVec2 = shufflevector <3 x float> %call, <3 x float> poison, <4 x i32> <i32 0, i32 1, i32 2, i32 undef>
  %storetmp3 = bitcast <3 x float> addrspace(1)* %ret to <4 x float> addrspace(1)*
  store <4 x float> %extractVec2, <4 x float> addrspace(1)* %storetmp3, align 16, !tbaa !8
  ret void
}

; Function Attrs: convergent mustprogress nofree nounwind readnone willreturn
declare spir_func <3 x float> @_Z5ldexpDv3_fi(<3 x float>, i32) local_unnamed_addr #1

attributes #0 = { convergent mustprogress nofree norecurse nounwind willreturn writeonly "frame-pointer"="none" "min-legal-vector-width"="96" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" }
attributes #1 = { convergent mustprogress nofree nounwind readnone willreturn "frame-pointer"="none" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { convergent nounwind readnone willreturn }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 14.0.0 (https://github.com/llvm/llvm-project.git 078da26b1ce3e509b9705bba95686e4ef8b8e480)"}
!3 = !{i32 0, i32 0, i32 1}
!4 = !{!"none", !"none", !"none"}
!5 = !{!"float3", !"int", !"float3*"}
!6 = !{!"float __attribute__((ext_vector_type(3)))", !"int", !"float __attribute__((ext_vector_type(3)))*"}
!7 = !{!"", !"", !""}
!8 = !{!9, !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
