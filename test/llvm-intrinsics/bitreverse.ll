;; Check that llvm.bitreverse.* intrinsics are lowered to emulation functions

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -spirv-text %t.bc -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; SPV_KHR_bit_instructions extenstion was not enabled so BitReverse should not be generated
; CHECK-SPIRV-NOT: BitReverse

; Check for expected bitreverse lowerings

; call-sites
; CHECK-LLVM: i16 @llvm_bitreverse_i16
; CHECK-LLVM: i32 @llvm_bitreverse_i32
; CHECK-LLVM: i64 @llvm_bitreverse_i64

; definitions
; CHECK-LLVM: define spir_func {{.*}} @llvm_bitreverse_i16
; CHECK-LLVM: define spir_func {{.*}} @llvm_bitreverse_i32
; CHECK-LLVM: define spir_func {{.*}} @llvm_bitreverse_i64

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: convergent nounwind writeonly
define spir_kernel void @testBitRev(i16 %a, i32 %b, i64 %c, ptr addrspace(1) nocapture %res) local_unnamed_addr #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !5 !kernel_arg_type_qual !6 {
entry:
  %call16 = tail call i16 @llvm.bitreverse.i16(i16 %a)
  store i16 %call16, ptr addrspace(1) %res, align 2, !tbaa !7
  
  %call32 = tail call i32 @llvm.bitreverse.i32(i32 %b)
  store i32 %call32, ptr addrspace(1) %res, align 4, !tbaa !7

  %call64 = tail call i64 @llvm.bitreverse.i64(i64 %c)
  store i64 %call64, ptr addrspace(1) %res, align 8, !tbaa !7
  
  ret void
}

declare i16 @llvm.bitreverse.i16(i16)
declare i32 @llvm.bitreverse.i32(i32)
declare i64 @llvm.bitreverse.i64(i64)

attributes #0 = { convergent nounwind writeonly "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 2, i32 0}
!3 = !{i32 0, i32 0, i32 0, i32 1}
!4 = !{!"none", !"none", !"none", !"none"}
!5 = !{!"int", !"int", !"int", !"int*"}
!6 = !{!"", !"", !"", !""}
!7 = !{!8, !8, i64 0}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
