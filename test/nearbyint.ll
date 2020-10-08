; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64"

; CHECK: ExtInst {{[0-9]+}} {{[0-9]+}} {{[0-9]+}} rint

; Function Attrs: noinline nounwind optnone
define weak dso_local spir_kernel void @__omp_offloading_fc09_22738a2f__Z15test_nearbyintfv_l15(float addrspace(1)* %0, i64 %1) #0 {
  %3 = alloca float, align 1                                          ; preds = %17
  %4 = load float, float* %3, align 4
  %5 = call float @llvm.nearbyint.f32(float %4)
  ret void
}

; Function Attrs: nounwind readnone speculatable willreturn
declare float @llvm.nearbyint.f32(float) #1

attributes #0 = { noinline nounwind optnone "contains-openmp-target"="true" "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "may-have-openmp-directive"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target.declare"="true" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable willreturn }


!opencl.used.extensions = !{!0, !0, !0, !0, !0, !0, !0, !0, !0}
!opencl.used.optional.core.features = !{!0, !0, !1, !0, !1, !0, !1, !0, !1}
!opencl.compiler.options = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.ident = !{!2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2}
!spirv.Source = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !4}
!llvm.module.flags = !{!5, !6}
!spirv.MemoryModel = !{!7}
!spirv.ExecutionMode = !{}

!0 = !{}
!1 = !{!"cl_doubles"}
!2 = !{!"Intel(R) oneAPI DPC++ Compiler Pro 2021.1 (2020.8.0.1004)"}
!3 = !{i32 4, i32 200000}
!4 = !{i32 3, i32 200000}
!5 = !{i32 1, !"wchar_size", i32 4}
!6 = !{i32 7, !"PIC Level", i32 2}
!7 = !{i32 2, i32 2}

