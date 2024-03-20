; This is an adapted copy of test/transcoding/SPV_INTEL_joint_matrix/joint_matrix.ll

; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_cooperative_matrix,+SPV_INTEL_joint_matrix -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: Capability CooperativeMatrixKHR
; CHECK-SPIRV-DAG: Capability CooperativeMatrixCheckedInstructionsINTEL
; CHECK-SPIRV-DAG: Extension "SPV_KHR_cooperative_matrix"
; CHECK-SPIRV-DAG: TypeInt [[#Int8Ty:]] 8 0
; CHECK-SPIRV-DAG: TypeInt [[#Int32Ty:]] 32 0
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const12:]] 12
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const48:]] 48
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const0:]] 0
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const3:]] 3
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const2:]] 2
; CHECK-SPIRV-DAG: TypeCooperativeMatrixKHR [[#MatTy1:]] [[#Int8Ty]] [[#Const0]] [[#Const12]] [[#Const48]] [[#Const3]]
; CHECK-SPIRV-DAG: TypeCooperativeMatrixKHR [[#MatTy2:]] [[#Int32Ty]] [[#Const3]] [[#Const12]] [[#Const12]] [[#Const3]]
; CHECK-SPIRV-DAG: TypeCooperativeMatrixKHR [[#MatTy3:]] [[#Int8Ty]] [[#Const2]] [[#Const48]] [[#Const12]] [[#Const3]]

; CHECK-SPIRV: CooperativeMatrixLoadCheckedINTEL [[#MatTy1]] [[#Load1:]]
; TODO: Pass Matrix Type Id instead of Matrix Id to CooperativeMatrixLengthKHR.
; CHECK-SPIRV: CooperativeMatrixLengthKHR [[#Int32Ty]] [[#]] [[#Load1]]
; CHECK-SPIRV: CooperativeMatrixConstructCheckedINTEL [[#MatTy2]]
; CHECK-SPIRV: CooperativeMatrixLoadCheckedINTEL [[#MatTy3]]
; CHECK-SPIRV: CooperativeMatrixMulAddKHR [[#MatTy2]]
; CHECK-SPIRV: CooperativeMatrixStoreCheckedINTEL

; CHECK-LLVM: call spir_func %spirv.CooperativeMatrixKHR._char_0_12_48_3 addrspace(1)* @_Z95__spirv_CooperativeMatrixLoadCheckedINTEL_RPU3AS144__spirv_CooperativeMatrixKHR__char_0_12_48_3PU3AS4siiiiili(i16 addrspace(4)* %{{.*}}, i32 0, i32 0, i32 0, i32 12, i32 48, i64 %{{.*}}, i32 1)
; CHECK-LLVM: call spir_func i32 @_Z34__spirv_CooperativeMatrixLengthKHRPU3AS144__spirv_CooperativeMatrixKHR__char_0_12_48_3(%spirv.CooperativeMatrixKHR._char_0_12_48_3 addrspace(1)*
; CHECK-LLVM: call spir_func %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(1)* @_Z46__spirv_CooperativeMatrixConstructCheckedINTELiiiii(i32 4, i32 4, i32 12, i32 12, i32 %{{.*}})
; CHECK-LLVM: call spir_func %spirv.CooperativeMatrixKHR._char_2_48_12_3 addrspace(1)* @_Z95__spirv_CooperativeMatrixLoadCheckedINTEL_RPU3AS144__spirv_CooperativeMatrixKHR__char_2_48_12_3PU3AS4ciiiiil(i8 addrspace(4)* %{{.*}}, i32 0, i32 0, i32 0, i32 48, i32 12, i64 1)
; CHECK-LLVM: call spir_func %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(1)* @_Z34__spirv_CooperativeMatrixMulAddKHRPU3AS144__spirv_CooperativeMatrixKHR__char_0_12_48_3PU3AS144__spirv_CooperativeMatrixKHR__char_2_48_12_3PU3AS143__spirv_CooperativeMatrixKHR__int_3_12_12_3i(%spirv.CooperativeMatrixKHR._char_0_12_48_3 addrspace(1)* %{{.*}}, %spirv.CooperativeMatrixKHR._char_2_48_12_3 addrspace(1)* %{{.*}}, %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(1)*
; CHECK-LLVM: call spir_func void @_Z42__spirv_CooperativeMatrixStoreCheckedINTELPU3AS4siiPU3AS143__spirv_CooperativeMatrixKHR__int_3_12_12_3iiili(i16 addrspace(4)* %{{.*}}, %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(1)*
; CHECK-LLVM: call spir_func %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(1)* @_Z26__spirv_CompositeConstructi(i32 %zero)

; ModuleID = 'test-matrix-opaque.bc'
source_filename = "matrix-int8-test.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%spirv.CooperativeMatrixKHR._int_3_12_12_3 = type { [12 x [12 x i32]]* }
%spirv.CooperativeMatrixKHR._char_0_12_48_3 = type { [12 x [48 x i8]]* }
%spirv.CooperativeMatrixKHR._char_2_48_12_3 = type { [48 x [12 x i8]]* }

$_ZTSZ4mainE11matrix_test = comdat any

@__spirv_BuiltInGlobalInvocationId = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32
@__spirv_BuiltInLocalInvocationId = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32

; Function Attrs: convergent norecurse
define weak_odr dso_local spir_kernel void @_ZTSZ4mainE11matrix_test(i16 addrspace(1)* %_arg_, i64 %_arg_1, i8 addrspace(1)* %_arg_3, i8 addrspace(1)* %_arg_5, i32 noundef %_arg_6) local_unnamed_addr #0 comdat !kernel_arg_buffer_location !5 !intel_reqd_sub_group_size !6 {
entry:
  %0 = load <3 x i64>, <3 x i64> addrspace(4)* addrspacecast (<3 x i64> addrspace(1)* @__spirv_BuiltInGlobalInvocationId to <3 x i64> addrspace(4)*), align 32, !noalias !7
  %1 = extractelement <3 x i64> %0, i64 1
  %2 = extractelement <3 x i64> %0, i64 0
  %3 = load <3 x i64>, <3 x i64> addrspace(4)* addrspacecast (<3 x i64> addrspace(1)* @__spirv_BuiltInLocalInvocationId to <3 x i64> addrspace(4)*), align 32, !noalias !14
  %4 = extractelement <3 x i64> %3, i64 1
  %5 = extractelement <3 x i64> %3, i64 0
  %cmp.i.i = icmp ult i64 %1, 2147483648
  tail call void @llvm.assume(i1 %cmp.i.i)
  %cmp.i45.i = icmp ult i64 %2, 2147483648
  tail call void @llvm.assume(i1 %cmp.i45.i)
  %cmp.i43.i = icmp ult i64 %4, 2147483648
  tail call void @llvm.assume(i1 %cmp.i43.i)
  %sub.i = sub nsw i64 %1, %4
  %cmp.i41.i = icmp ult i64 %5, 2147483648
  tail call void @llvm.assume(i1 %cmp.i41.i)
  %sub5.i = sub nsw i64 %2, %5
  %mul6.i = shl nsw i64 %sub.i, 6
  %add.ptr.i51 = getelementptr inbounds i16, i16 addrspace(1)* %_arg_, i64 %mul6.i
  %add.ptr7.i52 = getelementptr inbounds i16, i16 addrspace(1)* %add.ptr.i51, i64 %sub5.i
  %add.ptr7.i = addrspacecast i16 addrspace(1)* %add.ptr7.i52 to i16 addrspace(4)*
  %call8.i = tail call spir_func %spirv.CooperativeMatrixKHR._char_0_12_48_3 addrspace(4)* @_Z41__spirv_CooperativeMatrixLoadCheckedINTEL_1(i16 addrspace(4)* %add.ptr7.i, i32 noundef 0, i32 noundef 0, i32 noundef 0, i32 noundef 12, i32 noundef 48, i64 noundef %_arg_1, i32 noundef 1) #3
  %add.ptr11.i53 = getelementptr inbounds i8, i8 addrspace(1)* %_arg_3, i64 %mul6.i
  %add.ptr16.i55 = getelementptr inbounds i8, i8 addrspace(1)* %_arg_5, i64 %sub5.i
  %len = tail call spir_func noundef i32 @_Z34__spirv_CooperativeMatrixLengthKHR(%spirv.CooperativeMatrixKHR._char_0_12_48_3 addrspace(4)* %call8.i)

  %C.0.i = call spir_func %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(4)* @_Z46__spirv_CooperativeMatrixConstructCheckedINTEL(i32 noundef 4, i32 noundef 4, i32 noundef 12, i32 noundef 12, i32 noundef %_arg_6) #1
  %add.ptr12.i54 = getelementptr inbounds i8, i8 addrspace(1)* %add.ptr11.i53, i64 0
  %add.ptr12.i = addrspacecast i8 addrspace(1)* %add.ptr12.i54 to i8 addrspace(4)*
  %call13.i = tail call spir_func %spirv.CooperativeMatrixKHR._char_2_48_12_3 addrspace(4)* @_Z41__spirv_CooperativeMatrixLoadCheckedINTEL_2(i8 addrspace(4)* %add.ptr12.i, i32 noundef 0, i32 noundef 0, i32 noundef 0, i32 noundef 48, i32 noundef 12, i64 noundef 1) #3
  %add.ptr17.i56 = getelementptr inbounds i8, i8 addrspace(1)* %add.ptr16.i55, i64 0
  %add.ptr17.i = addrspacecast i8 addrspace(1)* %add.ptr17.i56 to i8 addrspace(4)*
  %call19.i = tail call spir_func %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(4)* @_Z34__spirv_CooperativeMatrixMulAddKHR(%spirv.CooperativeMatrixKHR._char_0_12_48_3 addrspace(4)* %call8.i, %spirv.CooperativeMatrixKHR._char_2_48_12_3 addrspace(4)* %call13.i, %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(4)* %C.0.i, i32 3) #3
  tail call spir_func void @_Z42__spirv_CooperativeMatrixStoreCheckedINTEL(i16 addrspace(4)* %add.ptr7.i, i32 noundef 0, i32 noundef 0, %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(4)* %C.0.i, i32 noundef 0, i32 noundef 12, i32 noundef 12, i64 noundef %_arg_1, i32 noundef 1) #3

  %ref.tmp = alloca i32, align 4
  %ref.tmp.ascast = addrspacecast i32* %ref.tmp to i32 addrspace(4)*
  store i32 0, i32 addrspace(4)* %ref.tmp.ascast, align 4
  %zero = load i32, i32 addrspace(4)* %ref.tmp.ascast, align 8
  %C.0.i.new.load = call spir_func %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(4)* @_Z26__spirv_CompositeConstruct(i32 %zero) #1

  ret void
}

; Function Attrs: convergent
declare dso_local spir_func %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(4)* @_Z26__spirv_CompositeConstruct(i32 noundef) local_unnamed_addr #2

; Function Attrs: convergent
declare dso_local spir_func noundef %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(4)* @_Z46__spirv_CooperativeMatrixConstructCheckedINTEL(i32 noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: convergent
declare dso_local spir_func noundef i32 @_Z34__spirv_CooperativeMatrixLengthKHR(%spirv.CooperativeMatrixKHR._char_0_12_48_3 addrspace(4)* noundef)

; Function Attrs: convergent
declare dso_local spir_func noundef %spirv.CooperativeMatrixKHR._char_0_12_48_3 addrspace(4)* @_Z41__spirv_CooperativeMatrixLoadCheckedINTEL_1(i16 addrspace(4)* noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef, i64 noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: convergent
declare dso_local spir_func noundef %spirv.CooperativeMatrixKHR._char_2_48_12_3 addrspace(4)* @_Z41__spirv_CooperativeMatrixLoadCheckedINTEL_2(i8 addrspace(4)* noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef, i32 noundef, i64 noundef) local_unnamed_addr #2

; Function Attrs: convergent
declare dso_local spir_func noundef %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(4)* @_Z34__spirv_CooperativeMatrixMulAddKHR(%spirv.CooperativeMatrixKHR._char_0_12_48_3 addrspace(4)* noundef, %spirv.CooperativeMatrixKHR._char_2_48_12_3 addrspace(4)* noundef, %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(4)* noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: convergent
declare dso_local spir_func void @_Z42__spirv_CooperativeMatrixStoreCheckedINTEL(i16 addrspace(4)* noundef, i32 noundef, i32 noundef, %spirv.CooperativeMatrixKHR._int_3_12_12_3 addrspace(4)* noundef, i32 noundef, i32 noundef, i32 noundef, i64 noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: inaccessiblememonly nofree nosync nounwind willreturn
declare void @llvm.assume(i1 noundef) #2

attributes #0 = { convergent norecurse "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="./joint_matrix_test.cpp" "uniform-work-group-size"="true" }
attributes #1 = { convergent "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { inaccessiblememonly nofree nosync nounwind willreturn }
attributes #3 = { convergent }

!llvm.module.flags = !{!0, !1}
!opencl.spir.version = !{!2}
!spirv.Source = !{!3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{i32 1, i32 2}
!3 = !{i32 4, i32 100000}
!4 = !{!"clang version 13.0.0 (https://github.com/intel/llvm.git b3243d9f711a1cd80681530d6017324796668d51)"}
!5 = !{i32 -1, i32 -1, i32 -1, i32 -1}
!6 = !{i32 16}
!7 = !{!8, !10, !12}
!8 = distinct !{!8, !9, !"_ZN7__spirv29InitSizesSTGlobalInvocationIdILi2EN2cl4sycl2idILi2EEEE8initSizeEv: %agg.result"}
!9 = distinct !{!9, !"_ZN7__spirv29InitSizesSTGlobalInvocationIdILi2EN2cl4sycl2idILi2EEEE8initSizeEv"}
!10 = distinct !{!10, !11, !"_ZN7__spirvL22initGlobalInvocationIdILi2EN2cl4sycl2idILi2EEEEET0_v: %agg.result"}
!11 = distinct !{!11, !"_ZN7__spirvL22initGlobalInvocationIdILi2EN2cl4sycl2idILi2EEEEET0_v"}
!12 = distinct !{!12, !13, !"_ZN2cl4sycl6detail7Builder10getElementILi2EEEKNS0_7nd_itemIXT_EEEPS5_: %agg.result"}
!13 = distinct !{!13, !"_ZN2cl4sycl6detail7Builder10getElementILi2EEEKNS0_7nd_itemIXT_EEEPS5_"}
!14 = !{!15, !17, !12}
!15 = distinct !{!15, !16, !"_ZN7__spirv28InitSizesSTLocalInvocationIdILi2EN2cl4sycl2idILi2EEEE8initSizeEv: %agg.result"}
!16 = distinct !{!16, !"_ZN7__spirv28InitSizesSTLocalInvocationIdILi2EN2cl4sycl2idILi2EEEE8initSizeEv"}
!17 = distinct !{!17, !18, !"_ZN7__spirvL21initLocalInvocationIdILi2EN2cl4sycl2idILi2EEEEET0_v: %agg.result"}
!18 = distinct !{!18, !"_ZN7__spirvL21initLocalInvocationIdILi2EN2cl4sycl2idILi2EEEEET0_v"}
!19 = distinct !{!19, !20, !21}
!20 = !{!"llvm.loop.mustprogress"}
!21 = !{!"llvm.loop.unroll.disable"}
