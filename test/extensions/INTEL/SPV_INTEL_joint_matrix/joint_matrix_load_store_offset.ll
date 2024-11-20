; This is an adapted copy of test/extensions/KHR/SPV_KHR_cooperative_matrix/cooperative_matrix.ll

; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_cooperative_matrix,+SPV_INTEL_joint_matrix -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: Capability CooperativeMatrixKHR
; CHECK-SPIRV-DAG: Capability CooperativeMatrixOffsetInstructionsINTEL
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_joint_matrix"
; CHECK-SPIRV-DAG: TypeInt [[#Int16Ty:]] 16 0
; CHECK-SPIRV-DAG: TypeInt [[#Int32Ty:]] 32 0
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const16:]] 16
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const3:]] 3
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const2:]] 2
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const0:]] 0
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const1:]] 1
; CHECK-SPIRV-DAG: TypeFloat [[#Float32Ty:]] 32
; CHECK-SPIRV-DAG: TypeJointMatrixINTEL [[#MatTy1:]] [[#Float32Ty]] [[#Const16]] [[#Const16]] [[#Const3]] [[#Const3]] [[#Const2]]
; CHECK-SPIRV-DAG: TypeJointMatrixINTEL [[#MatTy2:]] [[#Int16Ty]] [[#Const16]] [[#Const16]] [[#Const0]] [[#Const3]] [[#Const0]] [[#Const1]]
; CHECK-SPIRV-DAG: TypeJointMatrixINTEL [[#MatTy3:]] [[#Int16Ty]] [[#Const16]] [[#Const16]] [[#Const2:]] [[#Const3:]] [[#Const1:]] [[#Const1:]]
; CHECK-SPIRV: CooperativeMatrixLoadOffsetINTEL [[#MatTy1]]
; CHECK-SPIRV: CooperativeMatrixLoadOffsetINTEL [[#MatTy2]]
; CHECK-SPIRV: CooperativeMatrixLoadOffsetINTEL [[#MatTy3]]
; CHECK-SPIRV: CooperativeMatrixMulAddKHR [[#MatTy1]]
; CHECK-SPIRV: CooperativeMatrixStoreOffsetINTEL

; CHECK-LLVM: call spir_func target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) @_Z93__spirv_CooperativeMatrixLoadOffsetINTEL_RPU3AS143__spirv_JointMatrixINTEL__float_16_16_3_3_2PU3AS1fiiili(ptr addrspace(1) %add.ptr.i.i, i32 %conv.i, i32 %conv2.i, i32 0, i64 32, i32 0)
; CHECK-LLVM: call spir_func target("spirv.JointMatrixINTEL", i16, 16, 16, 0, 3, 0, 1) @"_Z95__spirv_CooperativeMatrixLoadOffsetINTEL_RPU3AS145__spirv_JointMatrixINTEL__short_16_16_0_3_0_1PU3AS138class.sycl::_V1::ext::oneapi::bfloat16iiili"(ptr addrspace(1) %add.ptr.i.i120, i32 %conv.i, i32 %22, i32 0, i64 32, i32 0)
; CHECK-LLVM: call spir_func target("spirv.JointMatrixINTEL", i16, 16, 16, 2, 3, 1, 1) @"_Z95__spirv_CooperativeMatrixLoadOffsetINTEL_RPU3AS145__spirv_JointMatrixINTEL__short_16_16_2_3_1_1PU3AS138class.sycl::_V1::ext::oneapi::bfloat16iiili"(ptr addrspace(1) %add.ptr.i.i128, i32 %23, i32 %conv2.i60, i32 2, i64 64, i32 0)
; CHECK-LLVM: call spir_func target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) @_Z27__spirv_JointMatrixMadINTELPU3AS145__spirv_JointMatrixINTEL__short_16_16_0_3_0_1PU3AS145__spirv_JointMatrixINTEL__short_16_16_2_3_1_1PU3AS143__spirv_JointMatrixINTEL__float_16_16_3_3_2i(target("spirv.JointMatrixINTEL", i16, 16, 16, 0, 3, 0, 1) %call3.i50, target("spirv.JointMatrixINTEL", i16, 16, 16, 2, 3, 1, 1) %call3.i61, target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) %sub_c.i.sroa.0.0, i32 3)
; CHECK-LLVM: call spir_func void @_Z41__spirv_CooperativeMatrixStoreOffsetINTELPU3AS1fiiPU3AS143__spirv_JointMatrixINTEL__float_16_16_3_3_2ili(ptr addrspace(1) %add.ptr.i.i, i32 %conv.i, i32 %conv2.i, target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) %sub_c.i.sroa.0.0, i32 0, i64 32, i32 0)

; ModuleID = 'joint_matrix_bfloat16.cpp'
source_filename = "joint_matrix_bfloat16.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spir64-unknown-unknown"

%"class.sycl::_V1::range" = type { %"class.sycl::_V1::detail::array" }
%"class.sycl::_V1::detail::array" = type { [2 x i64] }
%"class.sycl::_V1::id" = type { %"class.sycl::_V1::detail::array" }
%"class.sycl::_V1::ext::oneapi::bfloat16" = type { i16 }

$_ZTS7imatrixIfLm16ELm16ELm16EE = comdat any

@__spirv_BuiltInGlobalInvocationId = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32
@__spirv_BuiltInLocalInvocationId = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32

; Function Attrs: convergent mustprogress norecurse nounwind
define weak_odr dso_local spir_kernel void @_ZTS7imatrixIfLm16ELm16ELm16EE(ptr addrspace(1) noundef align 4 %_arg_accC, ptr noundef byval(%"class.sycl::_V1::range") align 8 %_arg_accC2, ptr noundef byval(%"class.sycl::_V1::id") align 8 %_arg_accC3, i64 noundef %_arg_sg_size, ptr addrspace(1) noundef align 2 %_arg_accA, ptr noundef byval(%"class.sycl::_V1::range") align 8 %_arg_accA5, ptr noundef byval(%"class.sycl::_V1::id") align 8 %_arg_accA6, ptr addrspace(1) noundef align 2 %_arg_accB, ptr noundef byval(%"class.sycl::_V1::range") align 8 %_arg_accB8, ptr noundef byval(%"class.sycl::_V1::id") align 8 %_arg_accB9) local_unnamed_addr #0 comdat {
entry:
  %agg.tmp11.sroa.0.sroa.2.0._arg_accC2.ascast.sroa_idx = getelementptr inbounds i8, ptr %_arg_accC2, i64 8
  %agg.tmp11.sroa.0.sroa.2.0.copyload = load i64, ptr %agg.tmp11.sroa.0.sroa.2.0._arg_accC2.ascast.sroa_idx, align 8
  %agg.tmp12.sroa.0.sroa.0.0.copyload = load i64, ptr %_arg_accC3, align 8
  %agg.tmp12.sroa.0.sroa.2.0._arg_accC3.ascast.sroa_idx = getelementptr inbounds i8, ptr %_arg_accC3, i64 8
  %agg.tmp12.sroa.0.sroa.2.0.copyload = load i64, ptr %agg.tmp12.sroa.0.sroa.2.0._arg_accC3.ascast.sroa_idx, align 8
  %mul.i6.i.i.i.i = mul i64 %agg.tmp12.sroa.0.sroa.0.0.copyload, %agg.tmp11.sroa.0.sroa.2.0.copyload
  %0 = getelementptr float, ptr addrspace(1) %_arg_accC, i64 %mul.i6.i.i.i.i
  %add.ptr.i = getelementptr float, ptr addrspace(1) %0, i64 %agg.tmp12.sroa.0.sroa.2.0.copyload
  %agg.tmp15.sroa.0.sroa.2.0._arg_accA5.ascast.sroa_idx = getelementptr inbounds i8, ptr %_arg_accA5, i64 8
  %agg.tmp15.sroa.0.sroa.2.0.copyload = load i64, ptr %agg.tmp15.sroa.0.sroa.2.0._arg_accA5.ascast.sroa_idx, align 8
  %agg.tmp16.sroa.0.sroa.0.0.copyload = load i64, ptr %_arg_accA6, align 8
  %agg.tmp16.sroa.0.sroa.2.0._arg_accA6.ascast.sroa_idx = getelementptr inbounds i8, ptr %_arg_accA6, i64 8
  %agg.tmp16.sroa.0.sroa.2.0.copyload = load i64, ptr %agg.tmp16.sroa.0.sroa.2.0._arg_accA6.ascast.sroa_idx, align 8
  %mul.i6.i.i.i.i91 = mul i64 %agg.tmp16.sroa.0.sroa.0.0.copyload, %agg.tmp15.sroa.0.sroa.2.0.copyload
  %1 = getelementptr %"class.sycl::_V1::ext::oneapi::bfloat16", ptr addrspace(1) %_arg_accA, i64 %mul.i6.i.i.i.i91
  %add.ptr.i92 = getelementptr %"class.sycl::_V1::ext::oneapi::bfloat16", ptr addrspace(1) %1, i64 %agg.tmp16.sroa.0.sroa.2.0.copyload
  %agg.tmp19.sroa.0.sroa.2.0._arg_accB8.ascast.sroa_idx = getelementptr inbounds i8, ptr %_arg_accB8, i64 8
  %agg.tmp19.sroa.0.sroa.2.0.copyload = load i64, ptr %agg.tmp19.sroa.0.sroa.2.0._arg_accB8.ascast.sroa_idx, align 8
  %agg.tmp20.sroa.0.sroa.0.0.copyload = load i64, ptr %_arg_accB9, align 8
  %agg.tmp20.sroa.0.sroa.2.0._arg_accB9.ascast.sroa_idx = getelementptr inbounds i8, ptr %_arg_accB9, i64 8
  %agg.tmp20.sroa.0.sroa.2.0.copyload = load i64, ptr %agg.tmp20.sroa.0.sroa.2.0._arg_accB9.ascast.sroa_idx, align 8
  %mul.i6.i.i.i.i107 = mul i64 %agg.tmp20.sroa.0.sroa.0.0.copyload, %agg.tmp19.sroa.0.sroa.2.0.copyload
  %2 = getelementptr %"class.sycl::_V1::ext::oneapi::bfloat16", ptr addrspace(1) %_arg_accB, i64 %mul.i6.i.i.i.i107
  %add.ptr.i108 = getelementptr %"class.sycl::_V1::ext::oneapi::bfloat16", ptr addrspace(1) %2, i64 %agg.tmp20.sroa.0.sroa.2.0.copyload
  %3 = load i64, ptr addrspace(1) getelementptr inbounds (i8, ptr addrspace(1) @__spirv_BuiltInGlobalInvocationId, i64 8), align 8
  %cmp.i28 = icmp ult i64 %3, 2147483648
  tail call void @llvm.assume(i1 %cmp.i28)
  %4 = load i64, ptr addrspace(1) @__spirv_BuiltInGlobalInvocationId, align 32
  %cmp.i24 = icmp ult i64 %4, 2147483648
  tail call void @llvm.assume(i1 %cmp.i24)
  %5 = load i64, ptr addrspace(1) getelementptr inbounds (i8, ptr addrspace(1) @__spirv_BuiltInLocalInvocationId, i64 8), align 8
  %cmp.i35 = icmp ult i64 %5, 2147483648
  tail call void @llvm.assume(i1 %cmp.i35)
  %sub.i = sub nsw i64 %3, %5
  %6 = load i64, ptr addrspace(1) @__spirv_BuiltInLocalInvocationId, align 32
  %cmp.i31 = icmp ult i64 %6, 2147483648
  tail call void @llvm.assume(i1 %cmp.i31)
  %sub5.i = sub nsw i64 %4, %6
  %add.i7.i.i.i.i.i = add i64 %mul.i6.i.i.i.i, %agg.tmp12.sroa.0.sroa.2.0.copyload
  %idx.neg.i.i = sub i64 0, %add.i7.i.i.i.i.i
  %add.ptr.i.i = getelementptr inbounds float, ptr addrspace(1) %add.ptr.i, i64 %idx.neg.i.i
  %div.i = udiv i64 %sub5.i, %_arg_sg_size
  %sub.i.tr = trunc i64 %sub.i to i32
  %conv.i = shl i32 %sub.i.tr, 4
  %div.i.tr = trunc i64 %div.i to i32
  %conv2.i = shl i32 %div.i.tr, 4
  %call4.i = tail call spir_func noundef target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) @_Z40__spirv_CooperativeMatrixLoadOffsetINTELIU3AS1ffLm16ELm16ELN5__spv9MatrixUseE2ELNS1_12MatrixLayoutE3ELNS1_5Scope4FlagE3EEPNS1_24__spirv_JointMatrixINTELIT0_XT1_EXT2_EXT4_EXT5_EXT3_EEEPT_iiS3_mi(ptr addrspace(1) noundef %add.ptr.i.i, i32 noundef %conv.i, i32 noundef %conv2.i, i32 noundef 0, i64 noundef 32, i32 noundef 0) #3
  %add.i7.i.i.i.i.i118 = add i64 %mul.i6.i.i.i.i91, %agg.tmp16.sroa.0.sroa.2.0.copyload
  %idx.neg.i.i119 = sub i64 0, %add.i7.i.i.i.i.i118
  %add.ptr.i.i120 = getelementptr inbounds %"class.sycl::_V1::ext::oneapi::bfloat16", ptr addrspace(1) %add.ptr.i92, i64 %idx.neg.i.i119
  %add.i7.i.i.i.i.i126 = add i64 %mul.i6.i.i.i.i107, %agg.tmp20.sroa.0.sroa.2.0.copyload
  %idx.neg.i.i127 = sub i64 0, %add.i7.i.i.i.i.i126
  %add.ptr.i.i128 = getelementptr inbounds %"class.sycl::_V1::ext::oneapi::bfloat16", ptr addrspace(1) %add.ptr.i108, i64 %idx.neg.i.i127
  %conv2.i60 = shl i32 %div.i.tr, 5
  br label %for.cond.i

for.cond.i:                                       ; preds = %for.body.i, %entry
  %sub_c.i.sroa.0.0 = phi target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) [ %call4.i, %entry ], [ %call.i63, %for.body.i ]
  %k.0.i = phi i32 [ 0, %entry ], [ %add.i, %for.body.i ]
  %cmp.i = icmp ult i32 %k.0.i, 2
  br i1 %cmp.i, label %for.body.i, label %_ZZZ15matrix_multiplyIfN4sycl3_V13ext6oneapi8bfloat16ELm32ELm32ELm32ELm16ELm16ELm16EEvR10big_matrixIT_XT1_EXT2_EERS5_IT0_XT1_EXT3_EERS5_IS9_XdvT3_Li2EEXmlT2_Li2EEEENKUlRNS1_7handlerEE_clESF_ENKUlNS1_7nd_itemILi2EEEE_clESI_.exit

for.body.i:                                       ; preds = %for.cond.i
  %7 = shl nuw nsw i32 %k.0.i, 4
  %call3.i50 = tail call spir_func noundef target("spirv.JointMatrixINTEL", i16, 16, 16, 0, 3, 0, 1) @_Z40__spirv_CooperativeMatrixLoadOffsetINTELIU3AS1N4sycl3_V13ext6oneapi8bfloat16ES4_Lm16ELm16ELN5__spv9MatrixUseE0ELNS6_12MatrixLayoutE0ELNS6_5Scope4FlagE3EEPNS6_24__spirv_JointMatrixINTELIT0_XT1_EXT2_EXT4_EXT5_EXT3_EEEPT_iiS8_mi(ptr addrspace(1) noundef %add.ptr.i.i120, i32 noundef %conv.i, i32 noundef %7, i32 noundef 0, i64 noundef 32, i32 noundef 0) #3
  %8 = shl nuw nsw i32 %k.0.i, 3
  %call3.i61 = tail call spir_func noundef target("spirv.JointMatrixINTEL", i16, 16, 16, 2, 3, 1, 1) @_Z40__spirv_CooperativeMatrixLoadOffsetINTELIU3AS1N4sycl3_V13ext6oneapi8bfloat16ES4_Lm16ELm16ELN5__spv9MatrixUseE1ELNS6_12MatrixLayoutE2ELNS6_5Scope4FlagE3EEPNS6_24__spirv_JointMatrixINTELIT0_XT1_EXT2_EXT4_EXT5_EXT3_EEEPT_iiS8_mi(ptr addrspace(1) noundef %add.ptr.i.i128, i32 noundef %8, i32 noundef %conv2.i60, i32 noundef 2, i64 noundef 64, i32 noundef 0) #3
  %call.i63 = tail call spir_func noundef target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) @_Z27__spirv_JointMatrixMadINTELIN4sycl3_V13ext6oneapi8bfloat16ES4_fLm16ELm16ELm16ELN5__spv9MatrixUseE0ELS6_1ELS6_2ELNS5_12MatrixLayoutE0ELS7_2ELS7_3ELNS5_5Scope4FlagE3EEPNS5_24__spirv_JointMatrixINTELIT1_XT2_EXT4_EXT10_EXT11_EXT7_EEEPNSA_IT_XT2_EXT3_EXT8_EXT11_EXT5_EEEPNSA_IT0_XT3_EXT4_EXT9_EXT11_EXT6_EEESD_S9_(target("spirv.JointMatrixINTEL", i16, 16, 16, 0, 3, 0, 1) noundef %call3.i50, target("spirv.JointMatrixINTEL", i16, 16, 16, 2, 3, 1, 1) noundef %call3.i61, target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) noundef %sub_c.i.sroa.0.0, i32 noundef 3) #3
  %add.i = add nuw nsw i32 %k.0.i, 1
  br label %for.cond.i

_ZZZ15matrix_multiplyIfN4sycl3_V13ext6oneapi8bfloat16ELm32ELm32ELm32ELm16ELm16ELm16EEvR10big_matrixIT_XT1_EXT2_EERS5_IT0_XT1_EXT3_EERS5_IS9_XdvT3_Li2EEXmlT2_Li2EEEENKUlRNS1_7handlerEE_clESF_ENKUlNS1_7nd_itemILi2EEEE_clESI_.exit: ; preds = %for.cond.i
  tail call spir_func void @_Z41__spirv_CooperativeMatrixStoreOffsetINTELIU3AS1ffLm16ELm16ELN5__spv9MatrixUseE2ELNS1_12MatrixLayoutE3ELNS1_5Scope4FlagE3EEvPT_iiPNS1_24__spirv_JointMatrixINTELIT0_XT1_EXT2_EXT4_EXT5_EXT3_EEES3_mi(ptr addrspace(1) noundef %add.ptr.i.i, i32 noundef %conv.i, i32 noundef %conv2.i, target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) noundef %sub_c.i.sroa.0.0, i32 noundef 0, i64 noundef 32, i32 noundef 0) #3
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #1

; Function Attrs: convergent nounwind
declare dso_local spir_func noundef target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) @_Z40__spirv_CooperativeMatrixLoadOffsetINTELIU3AS1ffLm16ELm16ELN5__spv9MatrixUseE2ELNS1_12MatrixLayoutE3ELNS1_5Scope4FlagE3EEPNS1_24__spirv_JointMatrixINTELIT0_XT1_EXT2_EXT4_EXT5_EXT3_EEEPT_iiS3_mi(ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef, i64 noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: convergent nounwind
declare dso_local spir_func noundef target("spirv.JointMatrixINTEL", i16, 16, 16, 0, 3, 0, 1) @_Z40__spirv_CooperativeMatrixLoadOffsetINTELIU3AS1N4sycl3_V13ext6oneapi8bfloat16ES4_Lm16ELm16ELN5__spv9MatrixUseE0ELNS6_12MatrixLayoutE0ELNS6_5Scope4FlagE3EEPNS6_24__spirv_JointMatrixINTELIT0_XT1_EXT2_EXT4_EXT5_EXT3_EEEPT_iiS8_mi(ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef, i64 noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: convergent nounwind
declare dso_local spir_func noundef target("spirv.JointMatrixINTEL", i16, 16, 16, 2, 3, 1, 1) @_Z40__spirv_CooperativeMatrixLoadOffsetINTELIU3AS1N4sycl3_V13ext6oneapi8bfloat16ES4_Lm16ELm16ELN5__spv9MatrixUseE1ELNS6_12MatrixLayoutE2ELNS6_5Scope4FlagE3EEPNS6_24__spirv_JointMatrixINTELIT0_XT1_EXT2_EXT4_EXT5_EXT3_EEEPT_iiS8_mi(ptr addrspace(1) noundef, i32 noundef, i32 noundef, i32 noundef, i64 noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: convergent nounwind
declare dso_local spir_func noundef target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) @_Z27__spirv_JointMatrixMadINTELIN4sycl3_V13ext6oneapi8bfloat16ES4_fLm16ELm16ELm16ELN5__spv9MatrixUseE0ELS6_1ELS6_2ELNS5_12MatrixLayoutE0ELS7_2ELS7_3ELNS5_5Scope4FlagE3EEPNS5_24__spirv_JointMatrixINTELIT1_XT2_EXT4_EXT10_EXT11_EXT7_EEEPNSA_IT_XT2_EXT3_EXT8_EXT11_EXT5_EEEPNSA_IT0_XT3_EXT4_EXT9_EXT11_EXT6_EEESD_S9_(target("spirv.JointMatrixINTEL", i16, 16, 16, 0, 3, 0, 1) noundef, target("spirv.JointMatrixINTEL", i16, 16, 16, 2, 3, 1, 1) noundef, target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: convergent nounwind
declare dso_local spir_func void @_Z41__spirv_CooperativeMatrixStoreOffsetINTELIU3AS1ffLm16ELm16ELN5__spv9MatrixUseE2ELNS1_12MatrixLayoutE3ELNS1_5Scope4FlagE3EEvPT_iiPNS1_24__spirv_JointMatrixINTELIT0_XT1_EXT2_EXT4_EXT5_EXT3_EEES3_mi(ptr addrspace(1) noundef, i32 noundef, i32 noundef, target("spirv.JointMatrixINTEL", float, 16, 16, 3, 3, 2) noundef, i32 noundef, i64 noundef, i32 noundef) local_unnamed_addr #2

attributes #0 = { convergent mustprogress norecurse nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="joint_matrix_bfloat16.cpp" "sycl-optlevel"="2" "uniform-work-group-size"="true" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #2 = { convergent nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #3 = { convergent nounwind }
