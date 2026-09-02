; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc

; On LLVM level, we'll check that the intrinsics were generated again in reverse
; translation, replacing the SPIR-V level implementations.
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM \
; RUN:   "--implicit-check-not=declare {{.*}} @spirv.llvm_umul_with_overflow_{{.*}}" \
; RUN:   "--implicit-check-not=old_llvm.umul.with.overflow.{{.*}}"
; FIXME: LLVM_SPIRV_REVERSE_FAIL for llc compilation flow

; CHECK-LLVM: %[[STRUCT8:.*]] = type { i8, i8 }
; CHECK-LLVM: %[[STRUCT32:.*]] = type { i32, i32 }
; CHECK-LLVM: %[[STRUCTV2I64:.*]] = type { <2 x i64>, <2 x i64> }

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir"

; Function Attrs: nofree nounwind writeonly
define dso_local spir_func void @_Z4foo8hhPh(i8 zeroext %a, i8 zeroext %b, ptr captures(none) %c) local_unnamed_addr #0 {
entry:
  ; CHECK-LLVM: call spir_func void @_Z20__spirv_UMulExtendedhh(ptr sret(%[[STRUCT8]]) %{{.*}}, i8 %a, i8 %b)
  ; CHECK-SPIRV: Constant [[#]] [[#ZERO8:]] 0
  ; CHECK-SPIRV: Function
  ; CHECK-SPIRV: UMulExtended [[#]] [[#MUL:]] [[#]] [[#]]
  ; CHECK-SPIRV: Store [[#PTR:]] [[#MUL]]
  ; CHECK-SPIRV: Load [[#]] [[#LOADED:]] [[#PTR]]
  ; CHECK-SPIRV: CompositeExtract [[#]] [[#HI:]] [[#LOADED]] 1
  ; CHECK-SPIRV: INotEqual [[#]] [[#]] [[#HI]] [[#ZERO8]]
  %umul = tail call { i8, i1 } @llvm.umul.with.overflow.i8(i8 %a, i8 %b)
  %cmp = extractvalue { i8, i1 } %umul, 1
  %umul.value = extractvalue { i8, i1 } %umul, 0
  %storemerge = select i1 %cmp, i8 0, i8 %umul.value
  store i8 %storemerge, ptr %c, align 1, !tbaa !2
  ; This test case verifies we don't leave any artifact calls behind (e.g. old_llvm.umul.with.overflow.i8).
  %umul2 = tail call { i8, i1 } @llvm.umul.with.overflow.i8(i8 %a, i8 %b)
  ret void
}

; Function Attrs: nofree nounwind writeonly
define dso_local spir_func void @_Z5foo32jjPj(i32 %a, i32 %b, ptr captures(none) %c) local_unnamed_addr #0 {
entry:
  ; CHECK-LLVM: call spir_func void @_Z20__spirv_UMulExtendedjj(ptr sret(%[[STRUCT32]]) %{{.*}}, i32 %b, i32 %a)
  ; CHECK-SPIRV: UMulExtended [[#]] [[#]] [[#]] [[#]]
  %umul = tail call { i32, i1 } @llvm.umul.with.overflow.i32(i32 %b, i32 %a)
  %umul.val = extractvalue { i32, i1 } %umul, 0
  %umul.ov = extractvalue { i32, i1 } %umul, 1
  %spec.select = select i1 %umul.ov, i32 0, i32 %umul.val
  store i32 %spec.select, ptr %c, align 4, !tbaa !5
  ret void
}

; Function Attrs: nofree nounwind writeonly
define dso_local spir_func void @umulo_v2i64(<2 x i64> %a, <2 x i64> %b, ptr %p) nounwind {
  ; CHECK-LLVM: call spir_func void @_Z20__spirv_UMulExtendedDv2_mS_(ptr sret(%[[STRUCTV2I64]]) %{{.*}}, <2 x i64> %a, <2 x i64> %b)
  ; CHECK-SPIRV: UMulExtended [[#]] [[#]] [[#]] [[#]]
  %umul = call {<2 x i64>, <2 x i1>} @llvm.umul.with.overflow.v2i64(<2 x i64> %a, <2 x i64> %b)
  %umul.val = extractvalue {<2 x i64>, <2 x i1>} %umul, 0
  %umul.ov = extractvalue {<2 x i64>, <2 x i1>} %umul, 1
  %zero = alloca <2 x i64>, align 16
  %spec.select = select <2 x i1> %umul.ov, <2 x i64> <i64 0, i64 0>, <2 x i64> %umul.val
  store <2 x i64> %spec.select, ptr %p
  ret void
}

; Function Attrs: nounwind readnone speculatable willreturn
declare { i8, i1 } @llvm.umul.with.overflow.i8(i8, i8) #1

; Function Attrs: nounwind readnone speculatable willreturn
declare { i32, i1 } @llvm.umul.with.overflow.i32(i32, i32) #1

; Function Attrs: nounwind readnone speculatable willreturn
declare {<2 x i64>, <2 x i1>} @llvm.umul.with.overflow.v2i64(<2 x i64>, <2 x i64>) #1

attributes #0 = { nofree nounwind writeonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 12.0.0 (https://github.com/llvm/llvm-project.git ddcc7ce59150c9ebc6b0b2d61e7ef4f2525c11f4)"}
!2 = !{!3, !3, i64 0}
!3 = !{!"omnipotent char", !4, i64 0}
!4 = !{!"Simple C++ TBAA"}
!5 = !{!6, !6, i64 0}
!6 = !{!"int", !3, i64 0}
