; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_INTEL_complex_float_mul_div
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv %t.spv -o %t.rev.bc -r
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; RUN: not llvm-spirv %t.bc 2>&1 | FileCheck %s --check-prefix=CHECK-ERROR

; CHECK-ERROR: RequiresExtension: Feature requires the following SPIR-V extension:
; CHECK-ERROR-NEXT: SPV_INTEL_complex_float_mul_div

; CHECK-SPIRV: Capability ComplexFloatMulDivINTEL
; CHECK-SPIRV: Extension "SPV_INTEL_complex_float_mul_div"
; CHECK-SPIRV: ComplexFDivINTEL [[#]] [[#]] [[#]] [[#]]
; CHECK-SPIRV: ComplexFMulINTEL [[#]] [[#]] [[#]] [[#]]

; CHECK-LLVM: call <2 x float> @llvm.experimental.complex.fdiv.v2f32(<2 x float>{{.*}}, <2 x float>{{.*}})
; CHECK-LLVM: call <2 x float> @llvm.experimental.complex.fmul.v2f32(<2 x float>{{.*}}, <2 x float>{{.*}})

; ModuleID = 'complex-operations.cpp'
source_filename = "complex-operations.cpp"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "spir-unknown-unknown"

%"struct.std::complex" = type { { float, float } }

; Function Attrs: mustprogress nofree nosync nounwind uwtable willreturn
define dso_local void @_Z19cmul_kernel_complexPSt7complexIfES1_S1_(%"struct.std::complex"* noalias nocapture readonly %a, %"struct.std::complex"* noalias nocapture readonly %b, %"struct.std::complex"* noalias nocapture writeonly %c) local_unnamed_addr #0 {
entry:
  %0 = bitcast %"struct.std::complex"* %a to <2 x float>*
  %1 = load <2 x float>, <2 x float>* %0, align 4
  %2 = bitcast %"struct.std::complex"* %b to <2 x float>*
  %3 = load <2 x float>, <2 x float>* %2, align 4, !tbaa !4
  %4 = tail call fast <2 x float> @llvm.experimental.complex.fdiv.v2f32(<2 x float> %1, <2 x float> %3)
  %ref.tmp.sroa.0.0..sroa_cast5 = bitcast %"struct.std::complex"* %c to <2 x float>*
  store <2 x float> %4, <2 x float>* %ref.tmp.sroa.0.0..sroa_cast5, align 4, !tbaa.struct !8
  %5 = tail call fast <2 x float> @llvm.experimental.complex.fmul.v2f32(<2 x float> %1, <2 x float> %3)
  store <2 x float> %5, <2 x float>* %ref.tmp.sroa.0.0..sroa_cast5, align 4, !tbaa.struct !8
  ret void
}

; Function Attrs: mustprogress nofree nosync nounwind readnone willreturn
declare <2 x float> @llvm.experimental.complex.fdiv.v2f32(<2 x float>, <2 x float>) #1

; Function Attrs: mustprogress nofree nosync nounwind readnone willreturn
declare <2 x float> @llvm.experimental.complex.fmul.v2f32(<2 x float>, <2 x float>) #1

attributes #0 = { mustprogress nofree nosync nounwind uwtable willreturn "approx-func-fp-math"="true" "denormal-fp-math"="preserve-sign,preserve-sign" "denormal-fp-math-f32"="ieee,ieee" "frame-pointer"="none" "min-legal-vector-width"="64" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" "unsafe-fp-math"="true" }
attributes #1 = { mustprogress nofree nosync nounwind readnone willreturn }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}
!nvvm.annotations = !{}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"openmp", i32 50}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{!"Complex"}
!4 = !{!5, !5, i64 0}
!5 = !{!"float", !6, i64 0}
!6 = !{!"omnipotent char", !7, i64 0}
!7 = !{!"Simple C++ TBAA"}
!8 = !{i64 0, i64 4, !5, i64 4, i64 4, !5}
