; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s

; CHECK: call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 1 %0, i8* align 1 %1, i64 4, i1 false)


source_filename = "llvm-link"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-linux-sycldevice"

%"class.cl::sycl::detail::SwizzleOp.10" = type <{ %"class.cl::sycl::vec"*, %"class.cl::sycl::detail::GetOp", %"class.cl::sycl::detail::GetOp", [6 x i8] }>
%"class.cl::sycl::vec" = type { <2 x float> }
%"class.cl::sycl::detail::GetOp" = type { i8 }
%"class.cl::sycl::detail::SwizzleOp.12" = type <{ %"class.cl::sycl::vec"*, %"class.cl::sycl::detail::SwizzleOp.10", %"class.cl::sycl::detail::GetScalarOp", [4 x i8] }>
%"class.cl::sycl::detail::GetScalarOp" = type { i32 }

$_ZN2cl4sycl6detail9SwizzleOpINS0_3vecIfLi2EEENS2_IS4_NS1_5GetOpIfEES6_S5_JLi0EEEENS1_11GetScalarOpIiEESt10multipliesJLi0EEEC2EPS4_S7_S9_ = comdat any

; Function Attrs: argmemonly nounwind
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i1) #0

; Function Attrs: nounwind
declare dso_local spir_func void @_ZN2cl4sycl6detail9SwizzleOpINS0_3vecIfLi2EEENS1_5GetOpIfEES6_S5_JLi0EEEC2ERKS7_(%"class.cl::sycl::detail::SwizzleOp.10"*, %"class.cl::sycl::detail::SwizzleOp.10"* dereferenceable(16)) unnamed_addr #1 align 2

define weak_odr dso_local spir_func void @_ZN2cl4sycl6detail9SwizzleOpINS0_3vecIfLi2EEENS2_IS4_NS1_5GetOpIfEES6_S5_JLi0EEEENS1_11GetScalarOpIiEESt10multipliesJLi0EEEC2EPS4_S7_S9_(%"class.cl::sycl::detail::SwizzleOp.12"* %this, %"class.cl::sycl::vec"* %Vector, %"class.cl::sycl::detail::SwizzleOp.10"* %LeftOperation, %"class.cl::sycl::detail::GetScalarOp"* byval align 4 %RightOperation) unnamed_addr #2 comdat align 2 {
entry:
  %this.addr = alloca %"class.cl::sycl::detail::SwizzleOp.12"*, align 8
  %Vector.addr = alloca %"class.cl::sycl::vec"*, align 8
  store %"class.cl::sycl::detail::SwizzleOp.12"* %this, %"class.cl::sycl::detail::SwizzleOp.12"** %this.addr, align 8, !tbaa !4
  store %"class.cl::sycl::vec"* %Vector, %"class.cl::sycl::vec"** %Vector.addr, align 8, !tbaa !4
  %this1 = load %"class.cl::sycl::detail::SwizzleOp.12"*, %"class.cl::sycl::detail::SwizzleOp.12"** %this.addr, align 8
  %m_Vector = getelementptr inbounds %"class.cl::sycl::detail::SwizzleOp.12", %"class.cl::sycl::detail::SwizzleOp.12"* %this1, i32 0, i32 0
  %0 = load %"class.cl::sycl::vec"*, %"class.cl::sycl::vec"** %Vector.addr, align 8, !tbaa !4
  store %"class.cl::sycl::vec"* %0, %"class.cl::sycl::vec"** %m_Vector, align 8, !tbaa !8
  %m_LeftOperation = getelementptr inbounds %"class.cl::sycl::detail::SwizzleOp.12", %"class.cl::sycl::detail::SwizzleOp.12"* %this1, i32 0, i32 1
  call spir_func void @_ZN2cl4sycl6detail9SwizzleOpINS0_3vecIfLi2EEENS1_5GetOpIfEES6_S5_JLi0EEEC2ERKS7_(%"class.cl::sycl::detail::SwizzleOp.10"* %m_LeftOperation, %"class.cl::sycl::detail::SwizzleOp.10"* dereferenceable(16) %LeftOperation)
  %m_RightOperation = getelementptr inbounds %"class.cl::sycl::detail::SwizzleOp.12", %"class.cl::sycl::detail::SwizzleOp.12"* %this1, i32 0, i32 2
  %1 = bitcast %"class.cl::sycl::detail::GetScalarOp"* %m_RightOperation to i8*
  %2 = bitcast %"class.cl::sycl::detail::GetScalarOp"* %RightOperation to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 1 %1, i8* align 4 %2, i64 4, i1 false), !tbaa.struct !14
  ret void
}

attributes #0 = { argmemonly nounwind }
attributes #1 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.spir.version = !{!0}
!spirv.Source = !{!1}
!llvm.ident = !{!2}
!llvm.module.flags = !{!3}

!0 = !{i32 1, i32 2}
!1 = !{i32 4, i32 100000}
!2 = !{!"clang version 9.0.0 (ssh://git-amr-2.devtools.intel.com:29418/dpd_icl-clang b6577d6699862a24572efa214151e6e38155d592) (ssh://git-amr-2.devtools.intel.com:29418/dpd_icl-llvm 89d36028b2ee4f8ee507f5b62e3119796eaae8da)"}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{!5, !5, i64 0}
!5 = !{!"any pointer", !6, i64 0}
!6 = !{!"omnipotent char", !7, i64 0}
!7 = !{!"Simple C++ TBAA"}
!8 = !{!9, !5, i64 0}
!9 = !{!"_ZTSN2cl4sycl6detail9SwizzleOpINS0_3vecIfLi2EEENS2_IS4_NS1_5GetOpIfEES6_S5_JLi0EEEENS1_11GetScalarOpIiEESt10multipliesJLi0EEEE", !5, i64 0, !10, i64 8, !12, i64 24}
!10 = !{!"_ZTSN2cl4sycl6detail9SwizzleOpINS0_3vecIfLi2EEENS1_5GetOpIfEES6_S5_JLi0EEEE", !5, i64 0, !11, i64 8, !11, i64 9}
!11 = !{!"_ZTSN2cl4sycl6detail5GetOpIfEE"}
!12 = !{!"_ZTSN2cl4sycl6detail11GetScalarOpIiEE", !13, i64 0}
!13 = !{!"int", !6, i64 0}
!14 = !{i64 0, i64 4, !15}
!15 = !{!13, !13, i64 0}
