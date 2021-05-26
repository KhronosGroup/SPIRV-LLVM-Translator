; It is assumed that the test will fail

; RUN: llvm-as %s -o %t.bc
; RUN: not --crash llvm-spirv %t.bc -o %t.spv 2>&1 | FileCheck %s

; CHECK: llvm.memmove of PHI instruction result not supported

; ModuleID = 'test.bc'
source_filename = "llvm-link"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown-sycldevice"

%"class.group" = type { %"class.range", %"class.range", %"class.range", %"class.range" }
%"class.range" = type { %"class.array" }
%"class.array" = type { [1 x i64] }
%"class.anon" = type { %"class.accessor" }
%"class.accessor" = type { %"class.AccessorImplDevice", %union.anon }
%"class.AccessorImplDevice" = type { %"class.range", %"class.range", %"class.range" }
%union.anon = type { i32 addrspace(1)* }
%class._ZTS5kfunc.kfunc = type <{ %"class.accessor", %"class.group", i32, [4 x i8] }>

$_ZTSZZL16test_func_objectRN2cl4sycl5queueEENKUlRNS0 = comdat any

@__spirv_BuiltInLocalInvocationIndex = external local_unnamed_addr addrspace(1) constant i64, align 8
@ArgShadow.9 = internal unnamed_addr addrspace(3) global %"class.group" undef, align 16
@ArgShadow.8 = internal unnamed_addr addrspace(3) global %"class.anon" undef, align 16
@"_ZZZZL16test_func_objectRN2cl4sycl5queueEENK3" = internal addrspace(3) global %class._ZTS5kfunc.kfunc zeroinitializer, align 8

; Function Attrs: argmemonly nofree nosync nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #1

; Function Attrs: convergent
declare dso_local void @_Z22__spirv_ControlBarrierjjj(i32, i32, i32) local_unnamed_addr #2

; Function Attrs: argmemonly nofree nosync nounwind willreturn
declare void @llvm.memcpy.p3i8.p0i8.i64(i8 addrspace(3)* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #1

; Function Attrs: argmemonly nofree nosync nounwind willreturn
declare void @llvm.memcpy.p3i8.p4i8.i64(i8 addrspace(3)* noalias nocapture writeonly, i8 addrspace(4)* noalias nocapture readonly, i64, i1 immarg) #1

; Function Attrs: convergent norecurse
define weak_odr dso_local spir_kernel void @_ZTSZZL16test_func_objectRN2cl4sycl5queueEENKUlRNS0(i32 addrspace(1)* %_arg_, %"class.range"* byval(%"class.range") align 8 %_arg_1, %"class.range"* byval(%"class.range") align 8 %_arg_2, %"class.range"* byval(%"class.range") align 8 %_arg_3) local_unnamed_addr #0 comdat !kernel_arg_buffer_location !4 {
entry:
  %0 = alloca %"class.anon", align 8
  %1 = addrspacecast %"class.anon"* %0 to %"class.anon" addrspace(4)*
  %agg.tmp6 = alloca %"class.group", align 8
  call spir_func void @"_ZZZL16test_func_objectRN2cl4sycl5queueEENK3$_1clERNS0"(%"class.anon" addrspace(4)* dereferenceable_or_null(32) %1, %"class.group"* nonnull byval(%"class.group") align 8 %agg.tmp6) #5
  ret void
}

; Function Attrs: inaccessiblememonly nofree nosync nounwind willreturn
declare void @llvm.experimental.noalias.scope.decl(metadata) #3

; Function Attrs: convergent inlinehint norecurse
define internal spir_func void @"_ZZZL16test_func_objectRN2cl4sycl5queueEENK3$_1clERNS0"(%"class.anon" addrspace(4)* dereferenceable_or_null(32) %this, %"class.group"* byval(%"class.group") align 8 %G) unnamed_addr #4 align 2 !work_group_scope !65 {
entry:
  %0 = load i64, i64 addrspace(1)* @__spirv_BuiltInLocalInvocationIndex, align 8
  tail call void @_Z22__spirv_ControlBarrierjjj(i32 2, i32 2, i32 272) #5
  %cmpz7 = icmp eq i64 %0, 0
  %1 = bitcast %"class.group"* %G to i8*
  br i1 %cmpz7, label %leader, label %entry.merge_crit_edge

entry.merge_crit_edge:                            ; preds = %entry
  %.pre53 = bitcast %"class.anon" addrspace(4)* %this to i8 addrspace(4)*
  br label %merge

leader:                                           ; preds = %entry
  call void @llvm.memcpy.p3i8.p0i8.i64(i8 addrspace(3)* align 16 dereferenceable(32) bitcast (%"class.group" addrspace(3)* @ArgShadow.9 to i8 addrspace(3)*), i8* nonnull align 8 dereferenceable(32) %1, i64 32, i1 false)
  %2 = bitcast %"class.anon" addrspace(4)* %this to i8 addrspace(4)*
  tail call void @llvm.memcpy.p3i8.p4i8.i64(i8 addrspace(3)* align 16 dereferenceable(32) bitcast (%"class.anon" addrspace(3)* @ArgShadow.8 to i8 addrspace(3)*), i8 addrspace(4)* align 8 dereferenceable(32) %2, i64 32, i1 false)
  br label %merge

merge:                                            ; preds = %entry.merge_crit_edge, %leader
  %.pre-phi54 = phi i8 addrspace(4)* [ %.pre53, %entry.merge_crit_edge ], [ %2, %leader ]
  br i1 %cmpz7, label %wg_leader, label %wg_cf

wg_leader:                                        ; preds = %merge
  call void @llvm.memmove.p4i8.p4i8.i64(i8 addrspace(4)* align 8 dereferenceable(32) addrspacecast (i8 addrspace(3)* bitcast (%class._ZTS5kfunc.kfunc addrspace(3)* @"_ZZZZL16test_func_objectRN2cl4sycl5queueEENK3" to i8 addrspace(3)*) to i8 addrspace(4)*), i8 addrspace(4)* align 8 dereferenceable(32) %.pre-phi54, i64 32, i1 false)
  br label %wg_cf

wg_cf:                                            ; preds = %merge, %wg_leader
  ret void
}

; Function Attrs: argmemonly nofree nosync nounwind willreturn
declare void @llvm.memmove.p4i8.p4i8.i64(i8 addrspace(4)* nocapture writeonly, i8 addrspace(4)* nocapture readonly, i64, i1 immarg) #1

attributes #0 = { convergent norecurse "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="kernel_types.cpp" "uniform-work-group-size"="true" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { argmemonly nofree nosync nounwind willreturn }
attributes #2 = { convergent "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { inaccessiblememonly nofree nosync nounwind willreturn }
attributes #4 = { convergent inlinehint norecurse "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { convergent }

!opencl.spir.version = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!spirv.Source = !{!1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1}
!llvm.ident = !{!2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2}
!llvm.module.flags = !{!3}

!0 = !{i32 1, i32 2}
!1 = !{i32 4, i32 100000}
!2 = !{!"clang version 13.0.0 (https://github.com/intel/llvm.git 51f22c4b69cf01465bdd7b586343f6e19e9ab045)"}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 -1, i32 -1, i32 -1, i32 -1}
!65 = !{}
