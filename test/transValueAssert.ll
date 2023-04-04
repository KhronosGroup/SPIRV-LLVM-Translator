; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -spirv-max-version=1.4 -spirv-debug-info-version=ocl-100 -spirv-allow-extra-diexpressions -spirv-allow-unknown-intrinsics=llvm.genx. -spirv-ext=-all,+SPV_EXT_shader_atomic_float_add,+SPV_EXT_shader_atomic_float_min_max,+SPV_KHR_no_integer_wrap_decoration,+SPV_KHR_float_controls,+SPV_KHR_expect_assume,+SPV_KHR_linkonce_odr,+SPV_INTEL_subgroups,+SPV_INTEL_media_block_io,+SPV_INTEL_device_side_avc_motion_estimation,+SPV_INTEL_fpga_loop_controls,+SPV_INTEL_unstructured_loop_controls,+SPV_INTEL_fpga_reg,+SPV_INTEL_blocking_pipes,+SPV_INTEL_function_pointers,+SPV_INTEL_kernel_attributes,+SPV_INTEL_io_pipes,+SPV_INTEL_inline_assembly,+SPV_INTEL_arbitrary_precision_integers,+SPV_INTEL_float_controls2,+SPV_INTEL_vector_compute,+SPV_INTEL_fast_composite,+SPV_INTEL_arbitrary_precision_fixed_point,+SPV_INTEL_arbitrary_precision_floating_point,+SPV_INTEL_variable_length_array,+SPV_INTEL_fp_fast_math_mode,+SPV_INTEL_long_constant_composite,+SPV_INTEL_arithmetic_fence,+SPV_INTEL_global_variable_decorations,+SPV_INTEL_fpga_buffer_location,+SPV_INTEL_fpga_argument_interfaces,+SPV_INTEL_fpga_invocation_pipelining_attributes,+SPV_INTEL_token_type,+SPV_INTEL_bfloat16_conversion,+SPV_INTEL_joint_matrix,+SPV_INTEL_hw_thread_queries,+SPV_KHR_uniform_group_instructions,+SPV_INTEL_masked_gather_scatter,+SPV_INTEL_tensor_float32_conversion %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
 
; ModuleID = 'transValueAssert.bc'
source_filename = "llvm-link"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%struct.getComponent = type { i8 }
%"class.sycl::_V1::vec.0" = type { <16 x i8> }

$_ZTSZZ4mainENKUlRN4sycl3_V17handlerEE_clES2_E35MIXED_VEC_CONSTRUCTOR_KERNEL_bool16 = comdat any

$_ZNK12getComponentIbLi16EEclERN4sycl3_V13vecIbLi16EEEi = comdat any

@__const._ZZZ4mainENKUlRN4sycl3_V17handlerEE_clES2_ENKUlvE_clEv.vals1 = private unnamed_addr addrspace(1) constant [16 x i8] c"\01\00\01\00\01\00\01\00\01\00\01\00\01\00\01\00", align 1
@__spirv_BuiltInWorkgroupId = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32
@__spirv_BuiltInGlobalLinearId = external dso_local local_unnamed_addr addrspace(1) constant i64, align 8
@__spirv_BuiltInWorkgroupSize = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32

; Function Attrs: norecurse
define weak_odr dso_local spir_kernel void @_ZTSZZ4mainENKUlRN4sycl3_V17handlerEE_clES2_E35MIXED_VEC_CONSTRUCTOR_KERNEL_bool16() local_unnamed_addr #0 comdat !dbg !1969 !srcloc !1975 !kernel_arg_buffer_location !156 !sycl_fixed_targets !156 !sycl_kernel_omit_args !156 {
entry:
  call void @__itt_offload_wi_start_wrapper()
  %ref.tmp.i.i.i = alloca %struct.getComponent, align 1
  %agg.tmp7.i.i = alloca %"class.sycl::_V1::vec.0", align 16
  %vals1.i = alloca [16 x i8], align 1
  call void @llvm.dbg.value(metadata ptr addrspace(4) poison, metadata !1976, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !1990
  call void @llvm.dbg.value(metadata <8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), metadata !1984, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !1990
  %0 = getelementptr inbounds [16 x i8], ptr %vals1.i, i64 0, i64 0, !dbg !1994
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %0) #8, !dbg !1994
  call void @llvm.dbg.declare(metadata ptr %vals1.i, metadata !1985, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !1995
  call void @llvm.memcpy.p0.p1.i64(ptr align 1 %0, ptr addrspace(1) align 1 @__const._ZZZ4mainENKUlRN4sycl3_V17handlerEE_clES2_ENKUlvE_clEv.vals1, i64 16, i1 false), !dbg !1995
  call void @llvm.dbg.value(metadata <16 x i8> <i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 0), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 1), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 2), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 3), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 4), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 5), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 6), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 7), i8 0) to i8), i8 1, i8 0, i8 1, i8 0, i8 1, i8 0, i8 1, i8 0>, metadata !1987, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !1990

; CHECK-SPIRV: ExtInst
  
  call void @llvm.dbg.value(metadata <16 x i8> <i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 0), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 1), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 2), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 3), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 4), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 5), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 6), i8 0) to i8), i8 zext (i1 icmp ne (i8 extractelement (<8 x i8> bitcast (<1 x i64> <i64 281479271743489> to <8 x i8>), i64 7), i8 0) to i8), i8 1, i8 0, i8 1, i8 0, i8 1, i8 0, i8 1, i8 0>, metadata !1996, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2007
  call void @llvm.dbg.value(metadata ptr addrspace(4) poison, metadata !2001, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2007
  call void @llvm.dbg.value(metadata i32 0, metadata !2002, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2009
  %1 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr %agg.tmp7.i.i, i64 0, i32 0, i64 0
  %agg.tmp.sroa.0.0..sroa_idx8.i.i = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr %agg.tmp7.i.i, i64 0, i32 0
  %ref.tmp.ascast.i.i.i = addrspacecast ptr %ref.tmp.i.i.i to ptr addrspace(4)
  %f.ascast.i.i.i = addrspacecast ptr %agg.tmp7.i.i to ptr addrspace(4)
  %2 = getelementptr inbounds %struct.getComponent, ptr %ref.tmp.i.i.i, i64 0, i32 0
  br label %for.cond.i.i, !dbg !2010

for.cond.i.i:                                     ; preds = %for.inc.i.i, %entry
  %i.0.i.i = phi i32 [ 0, %entry ], [ %inc.i.i, %for.inc.i.i ], !dbg !2011
  call void @llvm.dbg.value(metadata i32 %i.0.i.i, metadata !2002, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2009
  %cmp.i.i = icmp ugt i32 %i.0.i.i, 15, !dbg !2012
  br i1 %cmp.i.i, label %_ZZZ4mainENKUlRN4sycl3_V17handlerEE_clES2_ENKUlvE_clEv.exit, label %for.body.i.i, !dbg !2014

for.body.i.i:                                     ; preds = %for.cond.i.i
  %idxprom.i.i = zext i32 %i.0.i.i to i64, !dbg !2015
  %arrayidx.i16.i = getelementptr inbounds [16 x i8], ptr %vals1.i, i64 0, i64 %idxprom.i.i, !dbg !2015
  %3 = load i8, ptr %arrayidx.i16.i, align 1, !dbg !2015, !tbaa !2018, !range !2022, !noundef !156
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %1)
  store <16 x i8> <i8 1, i8 0, i8 1, i8 0, i8 1, i8 0, i8 1, i8 0, i8 1, i8 0, i8 1, i8 0, i8 1, i8 0, i8 1, i8 0>, ptr %agg.tmp.sroa.0.0..sroa_idx8.i.i, align 16, !dbg !2023
  call void @llvm.dbg.declare(metadata ptr %agg.tmp7.i.i, metadata !2028, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2033
  call void @llvm.dbg.value(metadata i32 %i.0.i.i, metadata !2029, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2023
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %2) #8, !dbg !2034
  %call.i.i.i = call spir_func noundef zeroext i1 @_ZNK12getComponentIbLi16EEclERN4sycl3_V13vecIbLi16EEEi(ptr addrspace(4) noundef align 1 dereferenceable_or_null(1) %ref.tmp.ascast.i.i.i, ptr addrspace(4) noundef align 16 dereferenceable(16) %f.ascast.i.i.i, i32 noundef %i.0.i.i), !dbg !2034
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %2) #8, !dbg !2035
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %1), !dbg !2035
  %4 = zext i1 %call.i.i.i to i8, !dbg !2036
  %cmp2.not.i.i = icmp eq i8 %3, %4, !dbg !2036
  br i1 %cmp2.not.i.i, label %for.inc.i.i, label %_ZZZ4mainENKUlRN4sycl3_V17handlerEE_clES2_ENKUlvE_clEv.exit, !dbg !2037

for.inc.i.i:                                      ; preds = %for.body.i.i
  %inc.i.i = add nuw nsw i32 %i.0.i.i, 1, !dbg !2038
  call void @llvm.dbg.value(metadata i32 %inc.i.i, metadata !2002, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2009
  br label %for.cond.i.i, !dbg !2039, !llvm.loop !2040

_ZZZ4mainENKUlRN4sycl3_V17handlerEE_clES2_ENKUlvE_clEv.exit: ; preds = %for.body.i.i, %for.cond.i.i
  call void @llvm.dbg.value(metadata i1 undef, metadata !1988, metadata !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef, DW_OP_stack_value)), !dbg !1990
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %0) #8, !dbg !2043
  call void @__itt_offload_wi_finish_wrapper(), !dbg !2044
  ret void, !dbg !2044
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: mustprogress norecurse
define linkonce_odr dso_local spir_func noundef zeroext i1 @_ZNK12getComponentIbLi16EEclERN4sycl3_V13vecIbLi16EEEi(ptr addrspace(4) noundef align 1 dereferenceable_or_null(1) %this, ptr addrspace(4) noundef align 16 dereferenceable(16) %f, i32 noundef %number) local_unnamed_addr #2 comdat align 2 !dbg !2045 !srcloc !2059 {
entry:
  call void @llvm.dbg.value(metadata ptr addrspace(4) %this, metadata !2055, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2060
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2057, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2060
  call void @llvm.dbg.value(metadata i32 %number, metadata !2058, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2060
  switch i32 %number, label %return [
    i32 0, label %sw.bb
    i32 1, label %sw.bb2
    i32 2, label %sw.bb5
    i32 3, label %sw.bb8
    i32 4, label %sw.bb11
    i32 5, label %sw.bb14
    i32 6, label %sw.bb17
    i32 7, label %sw.bb20
    i32 8, label %sw.bb23
    i32 9, label %sw.bb26
    i32 10, label %sw.bb29
    i32 11, label %sw.bb32
    i32 12, label %sw.bb35
    i32 13, label %sw.bb38
    i32 14, label %sw.bb41
    i32 15, label %sw.bb44
  ], !dbg !2061

sw.bb:                                            ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2062, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2077
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2084
  call void @llvm.dbg.value(metadata i32 0, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2084
  %arrayidx.i.i = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 0, !dbg !2086
  %0 = load i8, ptr addrspace(4) %arrayidx.i.i, align 16, !dbg !2087, !tbaa !2018, !range !2022, !noundef !156
  %tobool = icmp ne i8 %0, 0, !dbg !2087
  br label %return, !dbg !2088

sw.bb2:                                           ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2089, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2093
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2095
  call void @llvm.dbg.value(metadata i32 1, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2095
  %arrayidx.i.i62 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 1, !dbg !2097
  %1 = load i8, ptr addrspace(4) %arrayidx.i.i62, align 1, !dbg !2098, !tbaa !2018, !range !2022, !noundef !156
  %tobool4 = icmp ne i8 %1, 0, !dbg !2098
  br label %return, !dbg !2099

sw.bb5:                                           ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2100, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2104
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2106
  call void @llvm.dbg.value(metadata i32 2, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2106
  %arrayidx.i.i63 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 2, !dbg !2108
  %2 = load i8, ptr addrspace(4) %arrayidx.i.i63, align 2, !dbg !2109, !tbaa !2018, !range !2022, !noundef !156
  %tobool7 = icmp ne i8 %2, 0, !dbg !2109
  br label %return, !dbg !2110

sw.bb8:                                           ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2111, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2115
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2117
  call void @llvm.dbg.value(metadata i32 3, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2117
  %arrayidx.i.i64 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 3, !dbg !2119
  %3 = load i8, ptr addrspace(4) %arrayidx.i.i64, align 1, !dbg !2120, !tbaa !2018, !range !2022, !noundef !156
  %tobool10 = icmp ne i8 %3, 0, !dbg !2120
  br label %return, !dbg !2121

sw.bb11:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2122, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2126
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2128
  call void @llvm.dbg.value(metadata i32 4, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2128
  %arrayidx.i.i65 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 4, !dbg !2130
  %4 = load i8, ptr addrspace(4) %arrayidx.i.i65, align 4, !dbg !2131, !tbaa !2018, !range !2022, !noundef !156
  %tobool13 = icmp ne i8 %4, 0, !dbg !2131
  br label %return, !dbg !2132

sw.bb14:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2133, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2137
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2139
  call void @llvm.dbg.value(metadata i32 5, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2139
  %arrayidx.i.i66 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 5, !dbg !2141
  %5 = load i8, ptr addrspace(4) %arrayidx.i.i66, align 1, !dbg !2142, !tbaa !2018, !range !2022, !noundef !156
  %tobool16 = icmp ne i8 %5, 0, !dbg !2142
  br label %return, !dbg !2143

sw.bb17:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2144, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2148
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2150
  call void @llvm.dbg.value(metadata i32 6, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2150
  %arrayidx.i.i67 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 6, !dbg !2152
  %6 = load i8, ptr addrspace(4) %arrayidx.i.i67, align 2, !dbg !2153, !tbaa !2018, !range !2022, !noundef !156
  %tobool19 = icmp ne i8 %6, 0, !dbg !2153
  br label %return, !dbg !2154

sw.bb20:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2155, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2159
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2161
  call void @llvm.dbg.value(metadata i32 7, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2161
  %arrayidx.i.i68 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 7, !dbg !2163
  %7 = load i8, ptr addrspace(4) %arrayidx.i.i68, align 1, !dbg !2164, !tbaa !2018, !range !2022, !noundef !156
  %tobool22 = icmp ne i8 %7, 0, !dbg !2164
  br label %return, !dbg !2165

sw.bb23:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2166, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2170
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2172
  call void @llvm.dbg.value(metadata i32 8, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2172
  %arrayidx.i.i69 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 8, !dbg !2174
  %8 = load i8, ptr addrspace(4) %arrayidx.i.i69, align 8, !dbg !2175, !tbaa !2018, !range !2022, !noundef !156
  %tobool25 = icmp ne i8 %8, 0, !dbg !2175
  br label %return, !dbg !2176

sw.bb26:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2177, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2181
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2183
  call void @llvm.dbg.value(metadata i32 9, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2183
  %arrayidx.i.i70 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 9, !dbg !2185
  %9 = load i8, ptr addrspace(4) %arrayidx.i.i70, align 1, !dbg !2186, !tbaa !2018, !range !2022, !noundef !156
  %tobool28 = icmp ne i8 %9, 0, !dbg !2186
  br label %return, !dbg !2187

sw.bb29:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2188, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2192
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2194
  call void @llvm.dbg.value(metadata i32 10, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2194
  %arrayidx.i.i71 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 10, !dbg !2196
  %10 = load i8, ptr addrspace(4) %arrayidx.i.i71, align 2, !dbg !2197, !tbaa !2018, !range !2022, !noundef !156
  %tobool31 = icmp ne i8 %10, 0, !dbg !2197
  br label %return, !dbg !2198

sw.bb32:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2199, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2203
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2205
  call void @llvm.dbg.value(metadata i32 11, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2205
  %arrayidx.i.i72 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 11, !dbg !2207
  %11 = load i8, ptr addrspace(4) %arrayidx.i.i72, align 1, !dbg !2208, !tbaa !2018, !range !2022, !noundef !156
  %tobool34 = icmp ne i8 %11, 0, !dbg !2208
  br label %return, !dbg !2209

sw.bb35:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2210, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2214
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2216
  call void @llvm.dbg.value(metadata i32 12, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2216
  %arrayidx.i.i73 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 12, !dbg !2218
  %12 = load i8, ptr addrspace(4) %arrayidx.i.i73, align 4, !dbg !2219, !tbaa !2018, !range !2022, !noundef !156
  %tobool37 = icmp ne i8 %12, 0, !dbg !2219
  br label %return, !dbg !2220

sw.bb38:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2221, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2225
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2227
  call void @llvm.dbg.value(metadata i32 13, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2227
  %arrayidx.i.i74 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 13, !dbg !2229
  %13 = load i8, ptr addrspace(4) %arrayidx.i.i74, align 1, !dbg !2230, !tbaa !2018, !range !2022, !noundef !156
  %tobool40 = icmp ne i8 %13, 0, !dbg !2230
  br label %return, !dbg !2231

sw.bb41:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2232, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2236
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2238
  call void @llvm.dbg.value(metadata i32 14, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2238
  %arrayidx.i.i75 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 14, !dbg !2240
  %14 = load i8, ptr addrspace(4) %arrayidx.i.i75, align 2, !dbg !2241, !tbaa !2018, !range !2022, !noundef !156
  %tobool43 = icmp ne i8 %14, 0, !dbg !2241
  br label %return, !dbg !2242

sw.bb44:                                          ; preds = %entry
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2243, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2247
  call void @llvm.dbg.value(metadata ptr addrspace(4) %f, metadata !2080, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2249
  call void @llvm.dbg.value(metadata i32 15, metadata !2083, metadata !DIExpression(DW_OP_constu, 4, DW_OP_swap, DW_OP_xderef)), !dbg !2249
  %arrayidx.i.i76 = getelementptr inbounds %"class.sycl::_V1::vec.0", ptr addrspace(4) %f, i64 0, i32 0, i64 15, !dbg !2251
  %15 = load i8, ptr addrspace(4) %arrayidx.i.i76, align 1, !dbg !2252, !tbaa !2018, !range !2022, !noundef !156
  %tobool46 = icmp ne i8 %15, 0, !dbg !2252
  br label %return, !dbg !2253

return:                                           ; preds = %sw.bb44, %sw.bb41, %sw.bb38, %sw.bb35, %sw.bb32, %sw.bb29, %sw.bb26, %sw.bb23, %sw.bb20, %sw.bb17, %sw.bb14, %sw.bb11, %sw.bb8, %sw.bb5, %sw.bb2, %sw.bb, %entry
  %retval.0 = phi i1 [ %tobool46, %sw.bb44 ], [ %tobool43, %sw.bb41 ], [ %tobool40, %sw.bb38 ], [ %tobool37, %sw.bb35 ], [ %tobool34, %sw.bb32 ], [ %tobool31, %sw.bb29 ], [ %tobool28, %sw.bb26 ], [ %tobool25, %sw.bb23 ], [ %tobool22, %sw.bb20 ], [ %tobool19, %sw.bb17 ], [ %tobool16, %sw.bb14 ], [ %tobool13, %sw.bb11 ], [ %tobool10, %sw.bb8 ], [ %tobool7, %sw.bb5 ], [ %tobool4, %sw.bb2 ], [ %tobool, %sw.bb ], [ false, %entry ], !dbg !2254
  ret i1 %retval.0, !dbg !2255
}

; Function Attrs: alwaysinline convergent mustprogress norecurse
define weak dso_local spir_func void @__itt_offload_wi_start_wrapper() #3 !srcloc !2256 {
entry:
  %GroupID = alloca [3 x i64], align 8
  %call.i = tail call spir_func signext i8 @__spirv_SpecConstant(i32 noundef -9145239, i8 noundef signext 0) #9
  %cmp.i.not = icmp eq i8 %call.i, 0
  br i1 %cmp.i.not, label %return, label %if.end

if.end:                                           ; preds = %entry
  %0 = bitcast ptr %GroupID to ptr
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %0) #8
  %arrayinit.begin5 = getelementptr inbounds [3 x i64], ptr %GroupID, i64 0, i64 0
  %arrayinit.begin = addrspacecast ptr %arrayinit.begin5 to ptr addrspace(4)
  %1 = load <3 x i64>, ptr addrspace(1) @__spirv_BuiltInWorkgroupId, align 32
  %2 = extractelement <3 x i64> %1, i64 0
  store i64 %2, ptr %arrayinit.begin5, align 8, !tbaa !2257
  %arrayinit.element6 = getelementptr inbounds [3 x i64], ptr %GroupID, i64 0, i64 1
  %3 = extractelement <3 x i64> %1, i64 1
  store i64 %3, ptr %arrayinit.element6, align 8, !tbaa !2257
  %arrayinit.element17 = getelementptr inbounds [3 x i64], ptr %GroupID, i64 0, i64 2
  %4 = extractelement <3 x i64> %1, i64 2
  store i64 %4, ptr %arrayinit.element17, align 8, !tbaa !2257
  %5 = load i64, ptr addrspace(1) @__spirv_BuiltInGlobalLinearId, align 8, !tbaa !2257
  %6 = load i64, ptr addrspace(1) @__spirv_BuiltInWorkgroupSize, align 32
  %7 = load i64, ptr addrspace(1) getelementptr inbounds (<3 x i64>, ptr addrspace(1) @__spirv_BuiltInWorkgroupSize, i64 0, i64 1), align 8
  %mul = mul i64 %6, %7
  %8 = load i64, ptr addrspace(1) getelementptr inbounds (<3 x i64>, ptr addrspace(1) @__spirv_BuiltInWorkgroupSize, i64 0, i64 2), align 16
  %mul2 = mul i64 %mul, %8
  %conv = trunc i64 %mul2 to i32
  call spir_func void @__itt_offload_wi_start_stub(ptr addrspace(4) noundef %arrayinit.begin, i64 noundef %5, i32 noundef %conv) #9
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %0) #8
  br label %return

return:                                           ; preds = %if.end, %entry
  ret void
}

; Function Attrs: convergent
declare extern_weak dso_local spir_func signext i8 @__spirv_SpecConstant(i32 noundef, i8 noundef signext) local_unnamed_addr #4

; Function Attrs: alwaysinline convergent mustprogress norecurse
define weak dso_local spir_func void @__itt_offload_wi_finish_wrapper() #3 !srcloc !2259 {
entry:
  %GroupID = alloca [3 x i64], align 8
  %call.i = tail call spir_func signext i8 @__spirv_SpecConstant(i32 noundef -9145239, i8 noundef signext 0) #9
  %cmp.i.not = icmp eq i8 %call.i, 0
  br i1 %cmp.i.not, label %return, label %if.end

if.end:                                           ; preds = %entry
  %0 = bitcast ptr %GroupID to ptr
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %0) #8
  %arrayinit.begin3 = getelementptr inbounds [3 x i64], ptr %GroupID, i64 0, i64 0
  %arrayinit.begin = addrspacecast ptr %arrayinit.begin3 to ptr addrspace(4)
  %1 = load <3 x i64>, ptr addrspace(1) @__spirv_BuiltInWorkgroupId, align 32
  %2 = extractelement <3 x i64> %1, i64 0
  store i64 %2, ptr %arrayinit.begin3, align 8, !tbaa !2257
  %arrayinit.element4 = getelementptr inbounds [3 x i64], ptr %GroupID, i64 0, i64 1
  %3 = extractelement <3 x i64> %1, i64 1
  store i64 %3, ptr %arrayinit.element4, align 8, !tbaa !2257
  %arrayinit.element15 = getelementptr inbounds [3 x i64], ptr %GroupID, i64 0, i64 2
  %4 = extractelement <3 x i64> %1, i64 2
  store i64 %4, ptr %arrayinit.element15, align 8, !tbaa !2257
  %5 = load i64, ptr addrspace(1) @__spirv_BuiltInGlobalLinearId, align 8, !tbaa !2257
  call spir_func void @__itt_offload_wi_finish_stub(ptr addrspace(4) noundef %arrayinit.begin, i64 noundef %5) #9
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %0) #8
  br label %return

return:                                           ; preds = %if.end, %entry
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse optnone
define weak dso_local spir_func void @__itt_offload_wi_start_stub(ptr addrspace(4) noundef %group_id, i64 noundef %wi_id, i32 noundef %wg_size) local_unnamed_addr #5 !srcloc !2260 {
entry:
  %group_id.addr = alloca ptr addrspace(4), align 8
  %wi_id.addr = alloca i64, align 8
  %wg_size.addr = alloca i32, align 4
  %group_id.addr.ascast = addrspacecast ptr %group_id.addr to ptr addrspace(4)
  %wi_id.addr.ascast = addrspacecast ptr %wi_id.addr to ptr addrspace(4)
  %wg_size.addr.ascast = addrspacecast ptr %wg_size.addr to ptr addrspace(4)
  store ptr addrspace(4) %group_id, ptr addrspace(4) %group_id.addr.ascast, align 8, !tbaa !2261
  store i64 %wi_id, ptr addrspace(4) %wi_id.addr.ascast, align 8, !tbaa !2257
  store i32 %wg_size, ptr addrspace(4) %wg_size.addr.ascast, align 4, !tbaa !2263
  ret void
}

; Function Attrs: convergent mustprogress noinline norecurse optnone
define weak dso_local spir_func void @__itt_offload_wi_finish_stub(ptr addrspace(4) noundef %group_id, i64 noundef %wi_id) local_unnamed_addr #5 !srcloc !2265 {
entry:
  %group_id.addr = alloca ptr addrspace(4), align 8
  %wi_id.addr = alloca i64, align 8
  %group_id.addr.ascast = addrspacecast ptr %group_id.addr to ptr addrspace(4)
  %wi_id.addr.ascast = addrspacecast ptr %wi_id.addr to ptr addrspace(4)
  store ptr addrspace(4) %group_id, ptr addrspace(4) %group_id.addr.ascast, align 8, !tbaa !2261
  store i64 %wi_id, ptr addrspace(4) %wi_id.addr.ascast, align 8, !tbaa !2257
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #6

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p1.i64(ptr noalias nocapture writeonly, ptr addrspace(1) noalias nocapture readonly, i64, i1 immarg) #7

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #6

attributes #0 = { norecurse "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="sample_vec_cnstr.cpp" "sycl-single-task" "uniform-work-group-size"="true" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { mustprogress norecurse "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #3 = { alwaysinline convergent mustprogress norecurse "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="itt_compiler_wrappers.cpp" }
attributes #4 = { convergent "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #5 = { convergent mustprogress noinline norecurse optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="itt_stubs.cpp" }
attributes #6 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #7 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #8 = { nounwind }
attributes #9 = { convergent }

!llvm.dbg.cu = !{!0}
!opencl.spir.version = !{!1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920, !1920}
!spirv.Source = !{!1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921, !1921}
!sycl_aspects = !{!1922, !1923, !1924, !1925, !1926, !1927, !1928, !1929, !1930, !1931, !1932, !1933, !1934, !1935, !1936, !1937, !1938, !1939, !1940, !1941, !1942, !1943, !1944, !1945, !1946, !1947, !1948, !1949, !1950, !1951, !1952, !1953, !1954, !1955, !1956, !1957, !1958, !1959, !1960, !1961, !1962, !1963}
!llvm.ident = !{!1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964, !1964}
!llvm.module.flags = !{!1965, !1966, !1967, !1968}
!sycl.specialization-constants = !{}
!sycl.specialization-constants-default-values = !{}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !1, producer: "clang version 17.0.0 (https://github.com/intel/llvm 98b7de88a7d9e99e55ef7e2bd2486fe0028cfaae)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, retainedTypes: !40, imports: !480, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "sample_vec_cnstr.cpp", directory: "/test", checksumkind: CSK_MD5, checksum: "2c0519524e487cf2ec6dff8e31290593")
!2 = !{!3, !11, !27, !35}
!3 = distinct !DICompositeType(tag: DW_TAG_enumeration_type, name: "_Lock_policy", scope: !5, file: !4, line: 49, baseType: !6, size: 32, elements: !7, identifier: "_ZTSN9__gnu_cxx12_Lock_policyE")
!4 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/ext/concurrence.h", directory: "", checksumkind: CSK_MD5, checksum: "cbe76592eff84658a3ed1950a8a55fd4")
!5 = !DINamespace(name: "__gnu_cxx", scope: null)
!6 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!7 = !{!8, !9, !10}
!8 = !DIEnumerator(name: "_S_single", value: 0, isUnsigned: true)
!9 = !DIEnumerator(name: "_S_mutex", value: 1, isUnsigned: true)
!10 = !DIEnumerator(name: "_S_atomic", value: 2, isUnsigned: true)
!11 = distinct !DICompositeType(tag: DW_TAG_enumeration_type, name: "target", scope: !13, file: !12, line: 18, baseType: !16, size: 32, flags: DIFlagEnumClass, elements: !17, identifier: "_ZTSN4sycl3_V16access6targetE")
!12 = !DIFile(filename: "/build/bin/../include/sycl/access/access.hpp", directory: "", checksumkind: CSK_MD5, checksum: "232470709c2d79b4b28ee32f4277f4d0")
!13 = !DINamespace(name: "access", scope: !14)
!14 = !DINamespace(name: "_V1", scope: !15, exportSymbols: true)
!15 = !DINamespace(name: "sycl", scope: null)
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !22, !23, !24, !25, !26}
!18 = !DIEnumerator(name: "global_buffer", value: 2014)
!19 = !DIEnumerator(name: "constant_buffer", value: 2015)
!20 = !DIEnumerator(name: "local", value: 2016)
!21 = !DIEnumerator(name: "image", value: 2017)
!22 = !DIEnumerator(name: "host_buffer", value: 2018)
!23 = !DIEnumerator(name: "host_image", value: 2019)
!24 = !DIEnumerator(name: "image_array", value: 2020)
!25 = !DIEnumerator(name: "host_task", value: 2021)
!26 = !DIEnumerator(name: "device", value: 2014)
!27 = distinct !DICompositeType(tag: DW_TAG_enumeration_type, name: "memory_scope", scope: !14, file: !28, line: 26, baseType: !16, size: 32, flags: DIFlagEnumClass, elements: !29, identifier: "_ZTSN4sycl3_V112memory_scopeE")
!28 = !DIFile(filename: "/build/bin/../include/sycl/memory_enums.hpp", directory: "", checksumkind: CSK_MD5, checksum: "71d20fc2230fe7e796fb35648260b119")
!29 = !{!30, !31, !32, !33, !34}
!30 = !DIEnumerator(name: "work_item", value: 0)
!31 = !DIEnumerator(name: "sub_group", value: 1)
!32 = !DIEnumerator(name: "work_group", value: 2)
!33 = !DIEnumerator(name: "device", value: 3)
!34 = !DIEnumerator(name: "system", value: 4)
!35 = distinct !DICompositeType(tag: DW_TAG_enumeration_type, name: "fence_space", scope: !13, file: !12, line: 39, baseType: !16, size: 32, flags: DIFlagEnumClass, elements: !36, identifier: "_ZTSN4sycl3_V16access11fence_spaceE")
!36 = !{!37, !38, !39}
!37 = !DIEnumerator(name: "local_space", value: 0)
!38 = !DIEnumerator(name: "global_space", value: 1)
!39 = !DIEnumerator(name: "global_and_local", value: 2)
!40 = !{!41, !42, !146, !258, !273, !338, !384, !149}
!41 = !DIBasicType(name: "bool", size: 8, encoding: DW_ATE_boolean)
!42 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "array<bool, 1UL>", scope: !44, file: !43, line: 94, size: 8, flags: DIFlagTypePassByValue, elements: !45, templateParams: !63, identifier: "_ZTSSt5arrayIbLm1EE")
!43 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/array", directory: "", checksumkind: CSK_MD5, checksum: "9c95de8ed8f9fb8b520d4b044cc8cc95")
!44 = !DINamespace(name: "std", scope: null)
!45 = !{!46, !69, !76, !80, !85, !92, !93, !94, !100, !105, !106, !107, !108, !109, !110, !111, !115, !116, !119, !124, !128, !129, !130, !133, !136, !137, !138, !142}
!46 = !DIDerivedType(tag: DW_TAG_member, name: "_M_elems", scope: !42, file: !43, line: 110, baseType: !47, size: 8)
!47 = !DIDerivedType(tag: DW_TAG_typedef, name: "_Type", scope: !48, file: !43, line: 50, baseType: !66)
!48 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__array_traits<bool, 1UL>", scope: !44, file: !43, line: 48, size: 8, flags: DIFlagTypePassByValue, elements: !49, templateParams: !63, identifier: "_ZTSSt14__array_traitsIbLm1EE")
!49 = !{!50, !59}
!50 = !DISubprogram(name: "_S_ref", linkageName: "_ZNSt14__array_traitsIbLm1EE6_S_refERA1_Kbm", scope: !48, file: !43, line: 55, type: !51, scopeLine: 55, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !52)
!52 = !{!53, !54, !56}
!53 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !41, size: 64, dwarfAddressSpace: 4)
!54 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !55, size: 64, dwarfAddressSpace: 4)
!55 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !47)
!56 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", scope: !44, file: !57, line: 258, baseType: !58)
!57 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/x86_64-linux-gnu/c++/9/bits/c++config.h", directory: "", checksumkind: CSK_MD5, checksum: "f271377c6e7185560bbbc0bac2bc77fa")
!58 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!59 = !DISubprogram(name: "_S_ptr", linkageName: "_ZNSt14__array_traitsIbLm1EE6_S_ptrERA1_Kb", scope: !48, file: !43, line: 59, type: !60, scopeLine: 59, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!60 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !61)
!61 = !{!62, !54}
!62 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !41, size: 64, dwarfAddressSpace: 4)
!63 = !{!64, !65}
!64 = !DITemplateTypeParameter(name: "_Tp", type: !41)
!65 = !DITemplateValueParameter(name: "_Nm", type: !58, value: i64 1)
!66 = !DICompositeType(tag: DW_TAG_array_type, baseType: !41, size: 8, elements: !67)
!67 = !{!68}
!68 = !DISubrange(count: 1)
!69 = !DISubprogram(name: "fill", linkageName: "_ZNSt5arrayIbLm1EE4fillERKb", scope: !42, file: !43, line: 116, type: !70, scopeLine: 116, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!70 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !71)
!71 = !{null, !72, !73}
!72 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !42, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!73 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !74, size: 64, dwarfAddressSpace: 4)
!74 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !75)
!75 = !DIDerivedType(tag: DW_TAG_typedef, name: "value_type", scope: !42, file: !43, line: 96, baseType: !41)
!76 = !DISubprogram(name: "swap", linkageName: "_ZNSt5arrayIbLm1EE4swapERS0_", scope: !42, file: !43, line: 120, type: !77, scopeLine: 120, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!77 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !78)
!78 = !{null, !72, !79}
!79 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !42, size: 64, dwarfAddressSpace: 4)
!80 = !DISubprogram(name: "begin", linkageName: "_ZNSt5arrayIbLm1EE5beginEv", scope: !42, file: !43, line: 126, type: !81, scopeLine: 126, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!81 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !82)
!82 = !{!83, !72}
!83 = !DIDerivedType(tag: DW_TAG_typedef, name: "iterator", scope: !42, file: !43, line: 101, baseType: !84)
!84 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !75, size: 64, dwarfAddressSpace: 4)
!85 = !DISubprogram(name: "begin", linkageName: "_ZNKSt5arrayIbLm1EE5beginEv", scope: !42, file: !43, line: 130, type: !86, scopeLine: 130, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!86 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !87)
!87 = !{!88, !90}
!88 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_iterator", scope: !42, file: !43, line: 102, baseType: !89)
!89 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !74, size: 64, dwarfAddressSpace: 4)
!90 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !91, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!91 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !42)
!92 = !DISubprogram(name: "end", linkageName: "_ZNSt5arrayIbLm1EE3endEv", scope: !42, file: !43, line: 134, type: !81, scopeLine: 134, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!93 = !DISubprogram(name: "end", linkageName: "_ZNKSt5arrayIbLm1EE3endEv", scope: !42, file: !43, line: 138, type: !86, scopeLine: 138, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!94 = !DISubprogram(name: "rbegin", linkageName: "_ZNSt5arrayIbLm1EE6rbeginEv", scope: !42, file: !43, line: 142, type: !95, scopeLine: 142, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!95 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !96)
!96 = !{!97, !72}
!97 = !DIDerivedType(tag: DW_TAG_typedef, name: "reverse_iterator", scope: !42, file: !43, line: 105, baseType: !98)
!98 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "reverse_iterator<bool *>", scope: !44, file: !99, line: 105, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTSSt16reverse_iteratorIPbE")
!99 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/stl_iterator.h", directory: "", checksumkind: CSK_MD5, checksum: "96320c39582905b0a2fa52e95bb15efe")
!100 = !DISubprogram(name: "rbegin", linkageName: "_ZNKSt5arrayIbLm1EE6rbeginEv", scope: !42, file: !43, line: 146, type: !101, scopeLine: 146, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!101 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !102)
!102 = !{!103, !90}
!103 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_reverse_iterator", scope: !42, file: !43, line: 106, baseType: !104)
!104 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "reverse_iterator<const bool *>", scope: !44, file: !99, line: 105, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTSSt16reverse_iteratorIPKbE")
!105 = !DISubprogram(name: "rend", linkageName: "_ZNSt5arrayIbLm1EE4rendEv", scope: !42, file: !43, line: 150, type: !95, scopeLine: 150, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!106 = !DISubprogram(name: "rend", linkageName: "_ZNKSt5arrayIbLm1EE4rendEv", scope: !42, file: !43, line: 154, type: !101, scopeLine: 154, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!107 = !DISubprogram(name: "cbegin", linkageName: "_ZNKSt5arrayIbLm1EE6cbeginEv", scope: !42, file: !43, line: 158, type: !86, scopeLine: 158, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!108 = !DISubprogram(name: "cend", linkageName: "_ZNKSt5arrayIbLm1EE4cendEv", scope: !42, file: !43, line: 162, type: !86, scopeLine: 162, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!109 = !DISubprogram(name: "crbegin", linkageName: "_ZNKSt5arrayIbLm1EE7crbeginEv", scope: !42, file: !43, line: 166, type: !101, scopeLine: 166, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!110 = !DISubprogram(name: "crend", linkageName: "_ZNKSt5arrayIbLm1EE5crendEv", scope: !42, file: !43, line: 170, type: !101, scopeLine: 170, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!111 = !DISubprogram(name: "size", linkageName: "_ZNKSt5arrayIbLm1EE4sizeEv", scope: !42, file: !43, line: 175, type: !112, scopeLine: 175, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!112 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !113)
!113 = !{!114, !90}
!114 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_type", file: !43, line: 103, baseType: !56)
!115 = !DISubprogram(name: "max_size", linkageName: "_ZNKSt5arrayIbLm1EE8max_sizeEv", scope: !42, file: !43, line: 178, type: !112, scopeLine: 178, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!116 = !DISubprogram(name: "empty", linkageName: "_ZNKSt5arrayIbLm1EE5emptyEv", scope: !42, file: !43, line: 181, type: !117, scopeLine: 181, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!117 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !118)
!118 = !{!41, !90}
!119 = !DISubprogram(name: "operator[]", linkageName: "_ZNSt5arrayIbLm1EEixEm", scope: !42, file: !43, line: 185, type: !120, scopeLine: 185, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!120 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !121)
!121 = !{!122, !72, !114}
!122 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !42, file: !43, line: 99, baseType: !123)
!123 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !75, size: 64, dwarfAddressSpace: 4)
!124 = !DISubprogram(name: "operator[]", linkageName: "_ZNKSt5arrayIbLm1EEixEm", scope: !42, file: !43, line: 189, type: !125, scopeLine: 189, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!125 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !126)
!126 = !{!127, !90, !114}
!127 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_reference", scope: !42, file: !43, line: 100, baseType: !73)
!128 = !DISubprogram(name: "at", linkageName: "_ZNSt5arrayIbLm1EE2atEm", scope: !42, file: !43, line: 193, type: !120, scopeLine: 193, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!129 = !DISubprogram(name: "at", linkageName: "_ZNKSt5arrayIbLm1EE2atEm", scope: !42, file: !43, line: 203, type: !125, scopeLine: 203, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!130 = !DISubprogram(name: "front", linkageName: "_ZNSt5arrayIbLm1EE5frontEv", scope: !42, file: !43, line: 215, type: !131, scopeLine: 215, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!131 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !132)
!132 = !{!122, !72}
!133 = !DISubprogram(name: "front", linkageName: "_ZNKSt5arrayIbLm1EE5frontEv", scope: !42, file: !43, line: 219, type: !134, scopeLine: 219, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!134 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !135)
!135 = !{!127, !90}
!136 = !DISubprogram(name: "back", linkageName: "_ZNSt5arrayIbLm1EE4backEv", scope: !42, file: !43, line: 223, type: !131, scopeLine: 223, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!137 = !DISubprogram(name: "back", linkageName: "_ZNKSt5arrayIbLm1EE4backEv", scope: !42, file: !43, line: 227, type: !134, scopeLine: 227, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!138 = !DISubprogram(name: "data", linkageName: "_ZNSt5arrayIbLm1EE4dataEv", scope: !42, file: !43, line: 234, type: !139, scopeLine: 234, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!139 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !140)
!140 = !{!141, !72}
!141 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !42, file: !43, line: 97, baseType: !84)
!142 = !DISubprogram(name: "data", linkageName: "_ZNKSt5arrayIbLm1EE4dataEv", scope: !42, file: !43, line: 238, type: !143, scopeLine: 238, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!143 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !144)
!144 = !{!145, !90}
!145 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_pointer", scope: !42, file: !43, line: 98, baseType: !89)
!146 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !147, size: 64, dwarfAddressSpace: 4)
!147 = !DIDerivedType(tag: DW_TAG_typedef, name: "DataT", scope: !149, file: !148, line: 568, baseType: !41)
!148 = !DIFile(filename: "/build/bin/../include/sycl/types.hpp", directory: "", checksumkind: CSK_MD5, checksum: "d5d6e03c1067adc7f880ec5ceb56e311")
!149 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "vec<bool, 16>", scope: !14, file: !148, line: 567, size: 128, flags: DIFlagTypePassByValue, elements: !150, templateParams: !255, identifier: "_ZTSN4sycl3_V13vecIbLi16EEE")
!150 = !{!151, !169, !172, !176, !181, !185, !189, !190, !195, !200, !201, !202, !203, !208, !212, !213, !214, !215, !216, !217, !218, !219, !220, !221, !222, !227, !228, !229, !230, !231, !232, !233, !234, !237, !240, !241, !242, !245, !248, !249, !252}
!151 = !DIDerivedType(tag: DW_TAG_member, name: "m_Data", scope: !149, file: !148, line: 1384, baseType: !152, size: 128, align: 128)
!152 = !DIDerivedType(tag: DW_TAG_typedef, name: "DataType", scope: !149, file: !148, line: 572, baseType: !153)
!153 = !DIDerivedType(tag: DW_TAG_typedef, name: "DataType", scope: !154, file: !148, line: 2160, baseType: !161)
!154 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "VecStorage<bool, 16, void>", scope: !155, file: !148, line: 2159, size: 8, flags: DIFlagTypePassByValue, elements: !156, templateParams: !157, identifier: "_ZTSN4sycl3_V16detail10VecStorageIbLi16EvEE")
!155 = !DINamespace(name: "detail", scope: !14)
!156 = !{}
!157 = !{!158, !159, !160}
!158 = !DITemplateTypeParameter(name: "T", type: !41)
!159 = !DITemplateValueParameter(name: "N", type: !16, value: i32 16)
!160 = !DITemplateTypeParameter(name: "V", type: null, defaulted: true)
!161 = !DIDerivedType(tag: DW_TAG_typedef, name: "DataType", scope: !162, file: !148, line: 2116, baseType: !166)
!162 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "VecStorageImpl<signed char, 16>", scope: !155, file: !148, line: 2115, size: 8, flags: DIFlagTypePassByValue, elements: !156, templateParams: !163, identifier: "_ZTSN4sycl3_V16detail14VecStorageImplIaLi16EEE")
!163 = !{!164, !159}
!164 = !DITemplateTypeParameter(name: "T", type: !165)
!165 = !DIBasicType(name: "signed char", size: 8, encoding: DW_ATE_signed_char)
!166 = !DICompositeType(tag: DW_TAG_array_type, baseType: !165, size: 128, flags: DIFlagVector, elements: !167)
!167 = !{!168}
!168 = !DISubrange(count: 16)
!169 = !DISubprogram(name: "getNumElements", linkageName: "_ZN4sycl3_V13vecIbLi16EE14getNumElementsEv", scope: !149, file: !148, line: 574, type: !170, scopeLine: 574, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!170 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !171)
!171 = !{!16}
!172 = !DISubprogram(name: "vec", scope: !149, file: !148, line: 740, type: !173, scopeLine: 740, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!173 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !174)
!174 = !{null, !175}
!175 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !149, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!176 = !DISubprogram(name: "vec", scope: !149, file: !148, line: 745, type: !177, scopeLine: 745, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!177 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !178)
!178 = !{null, !175, !179}
!179 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !180, size: 64, dwarfAddressSpace: 4)
!180 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !149)
!181 = !DISubprogram(name: "vec", scope: !149, file: !148, line: 750, type: !182, scopeLine: 750, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!182 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !183)
!183 = !{null, !175, !184}
!184 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !149, size: 64, dwarfAddressSpace: 4)
!185 = !DISubprogram(name: "operator=", linkageName: "_ZN4sycl3_V13vecIbLi16EEaSERKS2_", scope: !149, file: !148, line: 752, type: !186, scopeLine: 752, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!186 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !187)
!187 = !{!188, !175, !179}
!188 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !149, size: 64, dwarfAddressSpace: 4)
!189 = !DISubprogram(name: "dump", linkageName: "_ZN4sycl3_V13vecIbLi16EE4dumpEv", scope: !149, file: !148, line: 889, type: !173, scopeLine: 889, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!190 = !DISubprogram(name: "operator signed char __attribute__((ext_vector_type(16)))", linkageName: "_ZNK4sycl3_V13vecIbLi16EEcvDv16_aEv", scope: !149, file: !148, line: 904, type: !191, scopeLine: 904, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!191 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !192)
!192 = !{!193, !194}
!193 = !DIDerivedType(tag: DW_TAG_typedef, name: "vector_t", scope: !149, file: !148, line: 737, baseType: !152, flags: DIFlagPublic)
!194 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !180, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!195 = !DISubprogram(name: "get_count", linkageName: "_ZN4sycl3_V13vecIbLi16EE9get_countEv", scope: !149, file: !148, line: 914, type: !196, scopeLine: 914, flags: DIFlagPublic | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!196 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !197)
!197 = !{!198}
!198 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !199, line: 46, baseType: !58)
!199 = !DIFile(filename: "/build/lib/clang/17/include/stddef.h", directory: "", checksumkind: CSK_MD5, checksum: "d1776268f398bd1ca997c840ad581432")
!200 = !DISubprogram(name: "size", linkageName: "_ZN4sycl3_V13vecIbLi16EE4sizeEv", scope: !149, file: !148, line: 915, type: !196, scopeLine: 915, flags: DIFlagPublic | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!201 = !DISubprogram(name: "get_size", linkageName: "_ZN4sycl3_V13vecIbLi16EE8get_sizeEv", scope: !149, file: !148, line: 918, type: !196, scopeLine: 918, flags: DIFlagPublic | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!202 = !DISubprogram(name: "byte_size", linkageName: "_ZN4sycl3_V13vecIbLi16EE9byte_sizeEv", scope: !149, file: !148, line: 919, type: !196, scopeLine: 919, flags: DIFlagPublic | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!203 = !DISubprogram(name: "operator[]", linkageName: "_ZNK4sycl3_V13vecIbLi16EEixEi", scope: !149, file: !148, line: 974, type: !204, scopeLine: 974, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!204 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !205)
!205 = !{!206, !194, !16}
!206 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !207, size: 64, dwarfAddressSpace: 4)
!207 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !147)
!208 = !DISubprogram(name: "operator[]", linkageName: "_ZN4sycl3_V13vecIbLi16EEixEi", scope: !149, file: !148, line: 978, type: !209, scopeLine: 978, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!209 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !210)
!210 = !{!211, !175, !16}
!211 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !147, size: 64, dwarfAddressSpace: 4)
!212 = !DISubprogram(name: "operator+=", linkageName: "_ZN4sycl3_V13vecIbLi16EEpLERKS2_", scope: !149, file: !148, line: 1113, type: !186, scopeLine: 1113, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!213 = !DISubprogram(name: "operator-=", linkageName: "_ZN4sycl3_V13vecIbLi16EEmIERKS2_", scope: !149, file: !148, line: 1114, type: !186, scopeLine: 1114, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!214 = !DISubprogram(name: "operator*=", linkageName: "_ZN4sycl3_V13vecIbLi16EEmLERKS2_", scope: !149, file: !148, line: 1115, type: !186, scopeLine: 1115, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!215 = !DISubprogram(name: "operator/=", linkageName: "_ZN4sycl3_V13vecIbLi16EEdVERKS2_", scope: !149, file: !148, line: 1116, type: !186, scopeLine: 1116, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!216 = !DISubprogram(name: "operator%=", linkageName: "_ZN4sycl3_V13vecIbLi16EErMERKS2_", scope: !149, file: !148, line: 1120, type: !186, scopeLine: 1120, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!217 = !DISubprogram(name: "operator|=", linkageName: "_ZN4sycl3_V13vecIbLi16EEoRERKS2_", scope: !149, file: !148, line: 1121, type: !186, scopeLine: 1121, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!218 = !DISubprogram(name: "operator&=", linkageName: "_ZN4sycl3_V13vecIbLi16EEaNERKS2_", scope: !149, file: !148, line: 1122, type: !186, scopeLine: 1122, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!219 = !DISubprogram(name: "operator^=", linkageName: "_ZN4sycl3_V13vecIbLi16EEeOERKS2_", scope: !149, file: !148, line: 1123, type: !186, scopeLine: 1123, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!220 = !DISubprogram(name: "operator>>=", linkageName: "_ZN4sycl3_V13vecIbLi16EErSERKS2_", scope: !149, file: !148, line: 1124, type: !186, scopeLine: 1124, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!221 = !DISubprogram(name: "operator<<=", linkageName: "_ZN4sycl3_V13vecIbLi16EElSERKS2_", scope: !149, file: !148, line: 1125, type: !186, scopeLine: 1125, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!222 = !DISubprogram(name: "operator==", linkageName: "_ZNK4sycl3_V13vecIbLi16EEeqERKS2_", scope: !149, file: !148, line: 1181, type: !223, scopeLine: 1181, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!223 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !224)
!224 = !{!225, !194, !179}
!225 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "vec<signed char, 16>", scope: !14, file: !226, line: 24, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTSN4sycl3_V13vecIaLi16EEE")
!226 = !DIFile(filename: "/build/bin/../include/sycl/detail/generic_type_lists.hpp", directory: "", checksumkind: CSK_MD5, checksum: "493ae2f63f437d01be430b7ddaea9aa3")
!227 = !DISubprogram(name: "operator!=", linkageName: "_ZNK4sycl3_V13vecIbLi16EEneERKS2_", scope: !149, file: !148, line: 1182, type: !223, scopeLine: 1182, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!228 = !DISubprogram(name: "operator>", linkageName: "_ZNK4sycl3_V13vecIbLi16EEgtERKS2_", scope: !149, file: !148, line: 1183, type: !223, scopeLine: 1183, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!229 = !DISubprogram(name: "operator<", linkageName: "_ZNK4sycl3_V13vecIbLi16EEltERKS2_", scope: !149, file: !148, line: 1184, type: !223, scopeLine: 1184, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!230 = !DISubprogram(name: "operator>=", linkageName: "_ZNK4sycl3_V13vecIbLi16EEgeERKS2_", scope: !149, file: !148, line: 1185, type: !223, scopeLine: 1185, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!231 = !DISubprogram(name: "operator<=", linkageName: "_ZNK4sycl3_V13vecIbLi16EEleERKS2_", scope: !149, file: !148, line: 1186, type: !223, scopeLine: 1186, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!232 = !DISubprogram(name: "operator&&", linkageName: "_ZNK4sycl3_V13vecIbLi16EEaaERKS2_", scope: !149, file: !148, line: 1188, type: !223, scopeLine: 1188, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!233 = !DISubprogram(name: "operator||", linkageName: "_ZNK4sycl3_V13vecIbLi16EEooERKS2_", scope: !149, file: !148, line: 1189, type: !223, scopeLine: 1189, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!234 = !DISubprogram(name: "operator++", linkageName: "_ZN4sycl3_V13vecIbLi16EEppEv", scope: !149, file: !148, line: 1206, type: !235, scopeLine: 1206, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!235 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !236)
!236 = !{!188, !175}
!237 = !DISubprogram(name: "operator++", linkageName: "_ZN4sycl3_V13vecIbLi16EEppEi", scope: !149, file: !148, line: 1206, type: !238, scopeLine: 1206, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!238 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !239)
!239 = !{!149, !175, !16}
!240 = !DISubprogram(name: "operator--", linkageName: "_ZN4sycl3_V13vecIbLi16EEmmEv", scope: !149, file: !148, line: 1207, type: !235, scopeLine: 1207, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!241 = !DISubprogram(name: "operator--", linkageName: "_ZN4sycl3_V13vecIbLi16EEmmEi", scope: !149, file: !148, line: 1207, type: !238, scopeLine: 1207, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!242 = !DISubprogram(name: "operator!", linkageName: "_ZNK4sycl3_V13vecIbLi16EEntEv", scope: !149, file: !148, line: 1228, type: !243, scopeLine: 1228, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!243 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !244)
!244 = !{!225, !194}
!245 = !DISubprogram(name: "operator+", linkageName: "_ZNK4sycl3_V13vecIbLi16EEpsEv", scope: !149, file: !148, line: 1243, type: !246, scopeLine: 1243, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!246 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !247)
!247 = !{!149, !194}
!248 = !DISubprogram(name: "operator-", linkageName: "_ZNK4sycl3_V13vecIbLi16EEngEv", scope: !149, file: !148, line: 1256, type: !246, scopeLine: 1256, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!249 = !DISubprogram(name: "setValue", linkageName: "_ZN4sycl3_V13vecIbLi16EE8setValueEiRKb", scope: !149, file: !148, line: 1367, type: !250, scopeLine: 1367, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!250 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !251)
!251 = !{null, !175, !16, !206}
!252 = !DISubprogram(name: "getValue", linkageName: "_ZNK4sycl3_V13vecIbLi16EE8getValueEi", scope: !149, file: !148, line: 1374, type: !253, scopeLine: 1374, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!253 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !254)
!254 = !{!147, !194, !16}
!255 = !{!256, !257}
!256 = !DITemplateTypeParameter(name: "Type", type: !41)
!257 = !DITemplateValueParameter(name: "NumElements", type: !16, value: i32 16)
!258 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "array<1>", scope: !155, file: !259, line: 21, size: 64, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !260, templateParams: !305, identifier: "_ZTSN4sycl3_V16detail5arrayILi1EEE")
!259 = !DIFile(filename: "/build/bin/../include/sycl/detail/array.hpp", directory: "", checksumkind: CSK_MD5, checksum: "5cebbd2b958640a39f7236457e80aecd")
!260 = !{!261, !263, !270, !307, !310, !315, !316, !320, !324, !328, !331, !334, !335}
!261 = !DIDerivedType(tag: DW_TAG_member, name: "common_array", scope: !258, file: !259, line: 110, baseType: !262, size: 64, flags: DIFlagProtected)
!262 = !DICompositeType(tag: DW_TAG_array_type, baseType: !198, size: 64, elements: !67)
!263 = !DISubprogram(name: "operator id", linkageName: "_ZNK4sycl3_V16detail5arrayILi1EEcvNS0_2idILi1EEEEv", scope: !258, file: !259, line: 51, type: !264, scopeLine: 51, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!264 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !265)
!265 = !{!266, !268}
!266 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "id<1>", scope: !14, file: !267, line: 32, size: 64, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTSN4sycl3_V12idILi1EEE")
!267 = !DIFile(filename: "/build/bin/../include/sycl/id.hpp", directory: "", checksumkind: CSK_MD5, checksum: "1fb331c194dc4e9aa4e4d10808ad28a9")
!268 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !269, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!269 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !258)
!270 = !DISubprogram(name: "operator range", linkageName: "_ZNK4sycl3_V16detail5arrayILi1EEcvNS0_5rangeILi1EEEEv", scope: !258, file: !259, line: 59, type: !271, scopeLine: 59, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!271 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !272)
!272 = !{!273, !268}
!273 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "range<1>", scope: !14, file: !274, line: 24, size: 64, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !275, templateParams: !305, identifier: "_ZTSN4sycl3_V15rangeILi1EEE")
!274 = !DIFile(filename: "/build/bin/../include/sycl/range.hpp", directory: "", checksumkind: CSK_MD5, checksum: "95399af99e1dc39425f279d826201ade")
!275 = !{!276, !277, !282, !287, !291, !295, !298, !301}
!276 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !273, baseType: !258, flags: DIFlagPublic, extraData: i32 0)
!277 = !DISubprogram(name: "size", linkageName: "_ZNK4sycl3_V15rangeILi1EE4sizeEv", scope: !273, file: !274, line: 50, type: !278, scopeLine: 50, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!278 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !279)
!279 = !{!198, !280}
!280 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !281, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!281 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !273)
!282 = !DISubprogram(name: "range", scope: !273, file: !274, line: 58, type: !283, scopeLine: 58, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!283 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !284)
!284 = !{null, !285, !286}
!285 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !273, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!286 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !281, size: 64, dwarfAddressSpace: 4)
!287 = !DISubprogram(name: "range", scope: !273, file: !274, line: 59, type: !288, scopeLine: 59, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!288 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !289)
!289 = !{null, !285, !290}
!290 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !273, size: 64, dwarfAddressSpace: 4)
!291 = !DISubprogram(name: "operator=", linkageName: "_ZN4sycl3_V15rangeILi1EEaSERKS2_", scope: !273, file: !274, line: 60, type: !292, scopeLine: 60, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!292 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !293)
!293 = !{!294, !285, !286}
!294 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !273, size: 64, dwarfAddressSpace: 4)
!295 = !DISubprogram(name: "operator=", linkageName: "_ZN4sycl3_V15rangeILi1EEaSEOS2_", scope: !273, file: !274, line: 61, type: !296, scopeLine: 61, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!296 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !297)
!297 = !{!294, !285, !290}
!298 = !DISubprogram(name: "range", scope: !273, file: !274, line: 62, type: !299, scopeLine: 62, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized | DISPFlagDeleted)
!299 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !300)
!300 = !{null, !285}
!301 = !DISubprogram(name: "set_range_dim0", linkageName: "_ZN4sycl3_V15rangeILi1EE14set_range_dim0Em", scope: !273, file: !274, line: 217, type: !302, scopeLine: 217, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!302 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !303)
!303 = !{null, !285, !304}
!304 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !198)
!305 = !{!306}
!306 = !DITemplateValueParameter(name: "dimensions", type: !16, defaulted: true, value: i32 1)
!307 = !DISubprogram(name: "get", linkageName: "_ZNK4sycl3_V16detail5arrayILi1EE3getEi", scope: !258, file: !259, line: 67, type: !308, scopeLine: 67, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!308 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !309)
!309 = !{!198, !268, !16}
!310 = !DISubprogram(name: "operator[]", linkageName: "_ZN4sycl3_V16detail5arrayILi1EEixEi", scope: !258, file: !259, line: 72, type: !311, scopeLine: 72, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!311 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !312)
!312 = !{!313, !314, !16}
!313 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !198, size: 64, dwarfAddressSpace: 4)
!314 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !258, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!315 = !DISubprogram(name: "operator[]", linkageName: "_ZNK4sycl3_V16detail5arrayILi1EEixEi", scope: !258, file: !259, line: 77, type: !308, scopeLine: 77, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!316 = !DISubprogram(name: "array", scope: !258, file: !259, line: 82, type: !317, scopeLine: 82, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!317 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !318)
!318 = !{null, !314, !319}
!319 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !269, size: 64, dwarfAddressSpace: 4)
!320 = !DISubprogram(name: "array", scope: !258, file: !259, line: 83, type: !321, scopeLine: 83, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!321 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !322)
!322 = !{null, !314, !323}
!323 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !258, size: 64, dwarfAddressSpace: 4)
!324 = !DISubprogram(name: "operator=", linkageName: "_ZN4sycl3_V16detail5arrayILi1EEaSERKS3_", scope: !258, file: !259, line: 84, type: !325, scopeLine: 84, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!325 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !326)
!326 = !{!327, !314, !319}
!327 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !258, size: 64, dwarfAddressSpace: 4)
!328 = !DISubprogram(name: "operator=", linkageName: "_ZN4sycl3_V16detail5arrayILi1EEaSEOS3_", scope: !258, file: !259, line: 85, type: !329, scopeLine: 85, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!329 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !330)
!330 = !{!327, !314, !323}
!331 = !DISubprogram(name: "operator==", linkageName: "_ZNK4sycl3_V16detail5arrayILi1EEeqERKS3_", scope: !258, file: !259, line: 89, type: !332, scopeLine: 89, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!332 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !333)
!333 = !{!41, !268, !319}
!334 = !DISubprogram(name: "operator!=", linkageName: "_ZNK4sycl3_V16detail5arrayILi1EEneERKS3_", scope: !258, file: !259, line: 100, type: !332, scopeLine: 100, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!335 = !DISubprogram(name: "check_dimension", linkageName: "_ZNK4sycl3_V16detail5arrayILi1EE15check_dimensionEi", scope: !258, file: !259, line: 111, type: !336, scopeLine: 111, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!336 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !337)
!337 = !{null, !268, !16}
!338 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "sub_group", scope: !340, file: !339, line: 131, size: 8, flags: DIFlagTypePassByValue, elements: !342, identifier: "_ZTSN4sycl3_V13ext6oneapi9sub_groupE")
!339 = !DIFile(filename: "/build/bin/../include/sycl/ext/oneapi/sub_group.hpp", directory: "", checksumkind: CSK_MD5, checksum: "88b9345be782c4a03fe6de74bb7c8cb3")
!340 = !DINamespace(name: "oneapi", scope: !341)
!341 = !DINamespace(name: "ext", scope: !14)
!342 = !{!343, !345, !347, !353, !361, !365, !366, !367, !368, !369, !372, !375, !376, !377, !380}
!343 = !DIDerivedType(tag: DW_TAG_member, name: "dimensions", scope: !338, file: !339, line: 136, baseType: !344, flags: DIFlagStaticMember, extraData: i32 1)
!344 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !16)
!345 = !DIDerivedType(tag: DW_TAG_member, name: "fence_scope", scope: !338, file: !339, line: 137, baseType: !346, flags: DIFlagStaticMember, extraData: i32 1)
!346 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !27)
!347 = !DISubprogram(name: "get_local_id", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group12get_local_idEv", scope: !338, file: !339, line: 142, type: !348, scopeLine: 142, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!348 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !349)
!349 = !{!350, !351}
!350 = !DIDerivedType(tag: DW_TAG_typedef, name: "id_type", scope: !338, file: !339, line: 133, baseType: !266)
!351 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !352, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer, dwarfAddressSpace: 4)
!352 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !338)
!353 = !DISubprogram(name: "get_local_linear_id", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group19get_local_linear_idEv", scope: !338, file: !339, line: 151, type: !354, scopeLine: 151, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!354 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !355)
!355 = !{!356, !351}
!356 = !DIDerivedType(tag: DW_TAG_typedef, name: "linear_id_type", scope: !338, file: !339, line: 135, baseType: !357)
!357 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint32_t", file: !358, line: 26, baseType: !359)
!358 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdint-uintn.h", directory: "", checksumkind: CSK_MD5, checksum: "d3ea318a915682aaf6645ec16ac9f991")
!359 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint32_t", file: !360, line: 42, baseType: !6)
!360 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types.h", directory: "", checksumkind: CSK_MD5, checksum: "f6304b1a6dcfc6bee76e9a51043b5090")
!361 = !DISubprogram(name: "get_local_range", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group15get_local_rangeEv", scope: !338, file: !339, line: 160, type: !362, scopeLine: 160, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!362 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !363)
!363 = !{!364, !351}
!364 = !DIDerivedType(tag: DW_TAG_typedef, name: "range_type", scope: !338, file: !339, line: 134, baseType: !273)
!365 = !DISubprogram(name: "get_max_local_range", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group19get_max_local_rangeEv", scope: !338, file: !339, line: 169, type: !362, scopeLine: 169, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!366 = !DISubprogram(name: "get_group_id", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group12get_group_idEv", scope: !338, file: !339, line: 178, type: !348, scopeLine: 178, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!367 = !DISubprogram(name: "get_group_linear_id", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group19get_group_linear_idEv", scope: !338, file: !339, line: 187, type: !354, scopeLine: 187, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!368 = !DISubprogram(name: "get_group_range", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group15get_group_rangeEv", scope: !338, file: !339, line: 196, type: !362, scopeLine: 196, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!369 = !DISubprogram(name: "barrier", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group7barrierEv", scope: !338, file: !339, line: 600, type: !370, scopeLine: 600, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!370 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !371)
!371 = !{null, !351}
!372 = !DISubprogram(name: "barrier", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group7barrierENS0_6access11fence_spaceE", scope: !338, file: !339, line: 616, type: !373, scopeLine: 616, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!373 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !374)
!374 = !{null, !351, !35}
!375 = !DISubprogram(name: "get_group_linear_range", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group22get_group_linear_rangeEv", scope: !338, file: !339, line: 748, type: !354, scopeLine: 748, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!376 = !DISubprogram(name: "get_local_linear_range", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group22get_local_linear_rangeEv", scope: !338, file: !339, line: 757, type: !354, scopeLine: 757, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!377 = !DISubprogram(name: "leader", linkageName: "_ZNK4sycl3_V13ext6oneapi9sub_group6leaderEv", scope: !338, file: !339, line: 766, type: !378, scopeLine: 766, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!378 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !379)
!379 = !{!41, !351}
!380 = !DISubprogram(name: "sub_group", scope: !338, file: !339, line: 779, type: !381, scopeLine: 779, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!381 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !382)
!382 = !{null, !383}
!383 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !338, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer, dwarfAddressSpace: 4)
!384 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "vec<bool, 8>", scope: !14, file: !148, line: 567, size: 64, flags: DIFlagTypePassByValue, elements: !385, templateParams: !478, identifier: "_ZTSN4sycl3_V13vecIbLi8EEE")
!385 = !{!386, !398, !399, !403, !408, !412, !416, !417, !422, !423, !424, !425, !426, !432, !436, !437, !438, !439, !440, !441, !442, !443, !444, !445, !446, !450, !451, !452, !453, !454, !455, !456, !457, !460, !463, !464, !465, !468, !471, !472, !475}
!386 = !DIDerivedType(tag: DW_TAG_member, name: "m_Data", scope: !384, file: !148, line: 1384, baseType: !387, size: 64, align: 64)
!387 = !DIDerivedType(tag: DW_TAG_typedef, name: "DataType", scope: !384, file: !148, line: 572, baseType: !388)
!388 = !DIDerivedType(tag: DW_TAG_typedef, name: "DataType", scope: !389, file: !148, line: 2160, baseType: !392)
!389 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "VecStorage<bool, 8, void>", scope: !155, file: !148, line: 2159, size: 8, flags: DIFlagTypePassByValue, elements: !156, templateParams: !390, identifier: "_ZTSN4sycl3_V16detail10VecStorageIbLi8EvEE")
!390 = !{!158, !391, !160}
!391 = !DITemplateValueParameter(name: "N", type: !16, value: i32 8)
!392 = !DIDerivedType(tag: DW_TAG_typedef, name: "DataType", scope: !393, file: !148, line: 2116, baseType: !395)
!393 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "VecStorageImpl<signed char, 8>", scope: !155, file: !148, line: 2115, size: 8, flags: DIFlagTypePassByValue, elements: !156, templateParams: !394, identifier: "_ZTSN4sycl3_V16detail14VecStorageImplIaLi8EEE")
!394 = !{!164, !391}
!395 = !DICompositeType(tag: DW_TAG_array_type, baseType: !165, size: 64, flags: DIFlagVector, elements: !396)
!396 = !{!397}
!397 = !DISubrange(count: 8)
!398 = !DISubprogram(name: "getNumElements", linkageName: "_ZN4sycl3_V13vecIbLi8EE14getNumElementsEv", scope: !384, file: !148, line: 574, type: !170, scopeLine: 574, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!399 = !DISubprogram(name: "vec", scope: !384, file: !148, line: 740, type: !400, scopeLine: 740, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!400 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !401)
!401 = !{null, !402}
!402 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !384, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!403 = !DISubprogram(name: "vec", scope: !384, file: !148, line: 745, type: !404, scopeLine: 745, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!404 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !405)
!405 = !{null, !402, !406}
!406 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !407, size: 64, dwarfAddressSpace: 4)
!407 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !384)
!408 = !DISubprogram(name: "vec", scope: !384, file: !148, line: 750, type: !409, scopeLine: 750, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!409 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !410)
!410 = !{null, !402, !411}
!411 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !384, size: 64, dwarfAddressSpace: 4)
!412 = !DISubprogram(name: "operator=", linkageName: "_ZN4sycl3_V13vecIbLi8EEaSERKS2_", scope: !384, file: !148, line: 752, type: !413, scopeLine: 752, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!413 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !414)
!414 = !{!415, !402, !406}
!415 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !384, size: 64, dwarfAddressSpace: 4)
!416 = !DISubprogram(name: "dump", linkageName: "_ZN4sycl3_V13vecIbLi8EE4dumpEv", scope: !384, file: !148, line: 889, type: !400, scopeLine: 889, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!417 = !DISubprogram(name: "operator signed char __attribute__((ext_vector_type(8)))", linkageName: "_ZNK4sycl3_V13vecIbLi8EEcvDv8_aEv", scope: !384, file: !148, line: 904, type: !418, scopeLine: 904, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!418 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !419)
!419 = !{!420, !421}
!420 = !DIDerivedType(tag: DW_TAG_typedef, name: "vector_t", scope: !384, file: !148, line: 737, baseType: !387, flags: DIFlagPublic)
!421 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !407, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!422 = !DISubprogram(name: "get_count", linkageName: "_ZN4sycl3_V13vecIbLi8EE9get_countEv", scope: !384, file: !148, line: 914, type: !196, scopeLine: 914, flags: DIFlagPublic | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!423 = !DISubprogram(name: "size", linkageName: "_ZN4sycl3_V13vecIbLi8EE4sizeEv", scope: !384, file: !148, line: 915, type: !196, scopeLine: 915, flags: DIFlagPublic | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!424 = !DISubprogram(name: "get_size", linkageName: "_ZN4sycl3_V13vecIbLi8EE8get_sizeEv", scope: !384, file: !148, line: 918, type: !196, scopeLine: 918, flags: DIFlagPublic | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!425 = !DISubprogram(name: "byte_size", linkageName: "_ZN4sycl3_V13vecIbLi8EE9byte_sizeEv", scope: !384, file: !148, line: 919, type: !196, scopeLine: 919, flags: DIFlagPublic | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!426 = !DISubprogram(name: "operator[]", linkageName: "_ZNK4sycl3_V13vecIbLi8EEixEi", scope: !384, file: !148, line: 974, type: !427, scopeLine: 974, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!427 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !428)
!428 = !{!429, !421, !16}
!429 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !430, size: 64, dwarfAddressSpace: 4)
!430 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !431)
!431 = !DIDerivedType(tag: DW_TAG_typedef, name: "DataT", scope: !384, file: !148, line: 568, baseType: !41)
!432 = !DISubprogram(name: "operator[]", linkageName: "_ZN4sycl3_V13vecIbLi8EEixEi", scope: !384, file: !148, line: 978, type: !433, scopeLine: 978, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!433 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !434)
!434 = !{!435, !402, !16}
!435 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !431, size: 64, dwarfAddressSpace: 4)
!436 = !DISubprogram(name: "operator+=", linkageName: "_ZN4sycl3_V13vecIbLi8EEpLERKS2_", scope: !384, file: !148, line: 1113, type: !413, scopeLine: 1113, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!437 = !DISubprogram(name: "operator-=", linkageName: "_ZN4sycl3_V13vecIbLi8EEmIERKS2_", scope: !384, file: !148, line: 1114, type: !413, scopeLine: 1114, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!438 = !DISubprogram(name: "operator*=", linkageName: "_ZN4sycl3_V13vecIbLi8EEmLERKS2_", scope: !384, file: !148, line: 1115, type: !413, scopeLine: 1115, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!439 = !DISubprogram(name: "operator/=", linkageName: "_ZN4sycl3_V13vecIbLi8EEdVERKS2_", scope: !384, file: !148, line: 1116, type: !413, scopeLine: 1116, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!440 = !DISubprogram(name: "operator%=", linkageName: "_ZN4sycl3_V13vecIbLi8EErMERKS2_", scope: !384, file: !148, line: 1120, type: !413, scopeLine: 1120, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!441 = !DISubprogram(name: "operator|=", linkageName: "_ZN4sycl3_V13vecIbLi8EEoRERKS2_", scope: !384, file: !148, line: 1121, type: !413, scopeLine: 1121, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!442 = !DISubprogram(name: "operator&=", linkageName: "_ZN4sycl3_V13vecIbLi8EEaNERKS2_", scope: !384, file: !148, line: 1122, type: !413, scopeLine: 1122, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!443 = !DISubprogram(name: "operator^=", linkageName: "_ZN4sycl3_V13vecIbLi8EEeOERKS2_", scope: !384, file: !148, line: 1123, type: !413, scopeLine: 1123, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!444 = !DISubprogram(name: "operator>>=", linkageName: "_ZN4sycl3_V13vecIbLi8EErSERKS2_", scope: !384, file: !148, line: 1124, type: !413, scopeLine: 1124, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!445 = !DISubprogram(name: "operator<<=", linkageName: "_ZN4sycl3_V13vecIbLi8EElSERKS2_", scope: !384, file: !148, line: 1125, type: !413, scopeLine: 1125, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!446 = !DISubprogram(name: "operator==", linkageName: "_ZNK4sycl3_V13vecIbLi8EEeqERKS2_", scope: !384, file: !148, line: 1181, type: !447, scopeLine: 1181, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!447 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !448)
!448 = !{!449, !421, !406}
!449 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "vec<signed char, 8>", scope: !14, file: !226, line: 24, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTSN4sycl3_V13vecIaLi8EEE")
!450 = !DISubprogram(name: "operator!=", linkageName: "_ZNK4sycl3_V13vecIbLi8EEneERKS2_", scope: !384, file: !148, line: 1182, type: !447, scopeLine: 1182, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!451 = !DISubprogram(name: "operator>", linkageName: "_ZNK4sycl3_V13vecIbLi8EEgtERKS2_", scope: !384, file: !148, line: 1183, type: !447, scopeLine: 1183, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!452 = !DISubprogram(name: "operator<", linkageName: "_ZNK4sycl3_V13vecIbLi8EEltERKS2_", scope: !384, file: !148, line: 1184, type: !447, scopeLine: 1184, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!453 = !DISubprogram(name: "operator>=", linkageName: "_ZNK4sycl3_V13vecIbLi8EEgeERKS2_", scope: !384, file: !148, line: 1185, type: !447, scopeLine: 1185, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!454 = !DISubprogram(name: "operator<=", linkageName: "_ZNK4sycl3_V13vecIbLi8EEleERKS2_", scope: !384, file: !148, line: 1186, type: !447, scopeLine: 1186, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!455 = !DISubprogram(name: "operator&&", linkageName: "_ZNK4sycl3_V13vecIbLi8EEaaERKS2_", scope: !384, file: !148, line: 1188, type: !447, scopeLine: 1188, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!456 = !DISubprogram(name: "operator||", linkageName: "_ZNK4sycl3_V13vecIbLi8EEooERKS2_", scope: !384, file: !148, line: 1189, type: !447, scopeLine: 1189, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!457 = !DISubprogram(name: "operator++", linkageName: "_ZN4sycl3_V13vecIbLi8EEppEv", scope: !384, file: !148, line: 1206, type: !458, scopeLine: 1206, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!458 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !459)
!459 = !{!415, !402}
!460 = !DISubprogram(name: "operator++", linkageName: "_ZN4sycl3_V13vecIbLi8EEppEi", scope: !384, file: !148, line: 1206, type: !461, scopeLine: 1206, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!461 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !462)
!462 = !{!384, !402, !16}
!463 = !DISubprogram(name: "operator--", linkageName: "_ZN4sycl3_V13vecIbLi8EEmmEv", scope: !384, file: !148, line: 1207, type: !458, scopeLine: 1207, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!464 = !DISubprogram(name: "operator--", linkageName: "_ZN4sycl3_V13vecIbLi8EEmmEi", scope: !384, file: !148, line: 1207, type: !461, scopeLine: 1207, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!465 = !DISubprogram(name: "operator!", linkageName: "_ZNK4sycl3_V13vecIbLi8EEntEv", scope: !384, file: !148, line: 1228, type: !466, scopeLine: 1228, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!466 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !467)
!467 = !{!449, !421}
!468 = !DISubprogram(name: "operator+", linkageName: "_ZNK4sycl3_V13vecIbLi8EEpsEv", scope: !384, file: !148, line: 1243, type: !469, scopeLine: 1243, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!469 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !470)
!470 = !{!384, !421}
!471 = !DISubprogram(name: "operator-", linkageName: "_ZNK4sycl3_V13vecIbLi8EEngEv", scope: !384, file: !148, line: 1256, type: !469, scopeLine: 1256, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!472 = !DISubprogram(name: "setValue", linkageName: "_ZN4sycl3_V13vecIbLi8EE8setValueEiRKb", scope: !384, file: !148, line: 1367, type: !473, scopeLine: 1367, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!473 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !474)
!474 = !{null, !402, !16, !429}
!475 = !DISubprogram(name: "getValue", linkageName: "_ZNK4sycl3_V13vecIbLi8EE8getValueEi", scope: !384, file: !148, line: 1374, type: !476, scopeLine: 1374, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!476 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !477)
!477 = !{!431, !421, !16}
!478 = !{!256, !479}
!479 = !DITemplateValueParameter(name: "NumElements", type: !16, value: i32 8)
!480 = !{!481, !486, !504, !507, !512, !570, !578, !582, !589, !593, !597, !599, !601, !605, !614, !618, !624, !630, !632, !636, !640, !644, !648, !655, !657, !661, !665, !669, !671, !676, !680, !684, !686, !688, !692, !700, !704, !708, !712, !714, !720, !722, !729, !734, !738, !742, !746, !750, !754, !756, !758, !762, !766, !770, !772, !776, !780, !782, !784, !788, !793, !798, !803, !804, !805, !806, !807, !808, !809, !810, !811, !812, !813, !817, !821, !825, !830, !834, !837, !840, !843, !845, !847, !849, !852, !855, !858, !861, !864, !866, !870, !873, !874, !877, !879, !881, !883, !885, !888, !891, !894, !897, !900, !902, !906, !910, !915, !921, !923, !925, !927, !929, !931, !933, !935, !937, !939, !941, !943, !945, !947, !949, !951, !955, !959, !965, !969, !973, !978, !980, !985, !989, !993, !1004, !1006, !1010, !1014, !1018, !1022, !1026, !1030, !1034, !1038, !1042, !1046, !1050, !1052, !1054, !1058, !1062, !1068, !1072, !1076, !1078, !1082, !1086, !1092, !1094, !1098, !1102, !1106, !1110, !1114, !1118, !1122, !1123, !1124, !1125, !1127, !1128, !1129, !1130, !1131, !1132, !1133, !1137, !1143, !1148, !1152, !1154, !1156, !1158, !1160, !1167, !1171, !1175, !1179, !1183, !1187, !1192, !1196, !1198, !1202, !1208, !1212, !1217, !1219, !1222, !1226, !1230, !1232, !1234, !1236, !1238, !1242, !1244, !1246, !1250, !1254, !1258, !1262, !1266, !1270, !1272, !1276, !1280, !1284, !1288, !1290, !1292, !1296, !1300, !1301, !1302, !1303, !1304, !1305, !1311, !1314, !1315, !1317, !1319, !1321, !1323, !1327, !1329, !1331, !1333, !1335, !1337, !1339, !1341, !1343, !1347, !1351, !1353, !1357, !1361, !1363, !1366, !1372, !1374, !1376, !1380, !1382, !1384, !1386, !1388, !1390, !1392, !1394, !1399, !1403, !1405, !1407, !1412, !1414, !1416, !1418, !1420, !1422, !1424, !1427, !1429, !1431, !1435, !1439, !1441, !1443, !1445, !1447, !1449, !1451, !1453, !1455, !1457, !1459, !1463, !1467, !1469, !1471, !1473, !1475, !1477, !1479, !1481, !1483, !1485, !1487, !1489, !1491, !1493, !1495, !1497, !1501, !1505, !1509, !1511, !1513, !1515, !1517, !1519, !1521, !1523, !1525, !1527, !1531, !1535, !1539, !1541, !1543, !1545, !1549, !1553, !1557, !1559, !1561, !1563, !1565, !1567, !1569, !1571, !1573, !1575, !1577, !1579, !1581, !1585, !1589, !1593, !1595, !1597, !1599, !1601, !1605, !1609, !1611, !1613, !1615, !1617, !1619, !1621, !1625, !1629, !1631, !1633, !1635, !1637, !1641, !1645, !1649, !1651, !1653, !1655, !1657, !1659, !1661, !1665, !1669, !1673, !1675, !1679, !1683, !1685, !1687, !1689, !1691, !1693, !1695, !1698, !1699, !1701, !1702, !1703, !1704, !1705, !1706, !1707, !1708, !1709, !1710, !1711, !1712, !1713, !1714, !1715, !1716, !1717, !1718, !1719, !1720, !1721, !1722, !1723, !1724, !1725, !1726, !1727, !1728, !1729, !1730, !1731, !1736, !1740, !1741, !1746, !1750, !1755, !1760, !1764, !1770, !1774, !1776, !1780, !1787, !1792, !1797, !1798, !1804, !1808, !1812, !1816, !1820, !1824, !1826, !1828, !1830, !1834, !1838, !1842, !1846, !1850, !1852, !1854, !1856, !1860, !1864, !1868, !1870, !1872, !1874, !1878, !1883, !1887, !1891, !1895, !1899, !1903, !1907, !1911, !1914, !1916}
!481 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !482, file: !485, line: 58)
!482 = !DIDerivedType(tag: DW_TAG_typedef, name: "max_align_t", file: !483, line: 24, baseType: !484)
!483 = !DIFile(filename: "/build/lib/clang/17/include/__stddef_max_align_t.h", directory: "", checksumkind: CSK_MD5, checksum: "48e8e2456f77e6cda35d245130fa7259")
!484 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !483, line: 19, size: 256, flags: DIFlagFwdDecl, identifier: "_ZTS11max_align_t")
!485 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cstddef", directory: "", checksumkind: CSK_MD5, checksum: "8cea214acdaec7b6625d7b72cd33080b")
!486 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !487, file: !503, line: 64)
!487 = !DIDerivedType(tag: DW_TAG_typedef, name: "mbstate_t", file: !488, line: 6, baseType: !489)
!488 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/mbstate_t.h", directory: "", checksumkind: CSK_MD5, checksum: "ba8742313715e20e434cf6ccb2db98e3")
!489 = !DIDerivedType(tag: DW_TAG_typedef, name: "__mbstate_t", file: !490, line: 21, baseType: !491)
!490 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/__mbstate_t.h", directory: "", checksumkind: CSK_MD5, checksum: "82911a3e689448e3691ded3e0b471a55")
!491 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !490, line: 13, size: 64, flags: DIFlagTypePassByValue, elements: !492, identifier: "_ZTS11__mbstate_t")
!492 = !{!493, !494}
!493 = !DIDerivedType(tag: DW_TAG_member, name: "__count", scope: !491, file: !490, line: 15, baseType: !16, size: 32)
!494 = !DIDerivedType(tag: DW_TAG_member, name: "__value", scope: !491, file: !490, line: 20, baseType: !495, size: 32, offset: 32)
!495 = distinct !DICompositeType(tag: DW_TAG_union_type, scope: !491, file: !490, line: 16, size: 32, flags: DIFlagTypePassByValue, elements: !496, identifier: "_ZTSN11__mbstate_tUt_E")
!496 = !{!497, !498}
!497 = !DIDerivedType(tag: DW_TAG_member, name: "__wch", scope: !495, file: !490, line: 18, baseType: !6, size: 32)
!498 = !DIDerivedType(tag: DW_TAG_member, name: "__wchb", scope: !495, file: !490, line: 19, baseType: !499, size: 32)
!499 = !DICompositeType(tag: DW_TAG_array_type, baseType: !500, size: 32, elements: !501)
!500 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!501 = !{!502}
!502 = !DISubrange(count: 4)
!503 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cwchar", directory: "", checksumkind: CSK_MD5, checksum: "c2987a89688a9d9306c7e32167fff7d1")
!504 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !505, file: !503, line: 141)
!505 = !DIDerivedType(tag: DW_TAG_typedef, name: "wint_t", file: !506, line: 20, baseType: !6)
!506 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/wint_t.h", directory: "", checksumkind: CSK_MD5, checksum: "aa31b53ef28dc23152ceb41e2763ded3")
!507 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !508, file: !503, line: 143)
!508 = !DISubprogram(name: "btowc", scope: !509, file: !509, line: 318, type: !510, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!509 = !DIFile(filename: "/usr/include/wchar.h", directory: "", checksumkind: CSK_MD5, checksum: "8900d9ecbbe40d052c41becfbc5b5531")
!510 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !511)
!511 = !{!505, !16}
!512 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !513, file: !503, line: 144)
!513 = !DISubprogram(name: "fgetwc", scope: !509, file: !509, line: 726, type: !514, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!514 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !515)
!515 = !{!505, !516}
!516 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !517, size: 64, dwarfAddressSpace: 4)
!517 = !DIDerivedType(tag: DW_TAG_typedef, name: "__FILE", file: !518, line: 5, baseType: !519)
!518 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/__FILE.h", directory: "", checksumkind: CSK_MD5, checksum: "72a8fe90981f484acae7c6f3dfc5c2b7")
!519 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_FILE", file: !520, line: 49, size: 1728, flags: DIFlagTypePassByValue, elements: !521, identifier: "_ZTS8_IO_FILE")
!520 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/struct_FILE.h", directory: "", checksumkind: CSK_MD5, checksum: "f3c970561f3408448ce03a9676ead8f4")
!521 = !{!522, !523, !525, !526, !527, !528, !529, !530, !531, !532, !533, !534, !535, !538, !540, !541, !542, !545, !547, !548, !550, !553, !555, !558, !561, !562, !564, !565, !566}
!522 = !DIDerivedType(tag: DW_TAG_member, name: "_flags", scope: !519, file: !520, line: 51, baseType: !16, size: 32)
!523 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_ptr", scope: !519, file: !520, line: 54, baseType: !524, size: 64, offset: 64)
!524 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !500, size: 64, dwarfAddressSpace: 4)
!525 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_end", scope: !519, file: !520, line: 55, baseType: !524, size: 64, offset: 128)
!526 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_base", scope: !519, file: !520, line: 56, baseType: !524, size: 64, offset: 192)
!527 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_base", scope: !519, file: !520, line: 57, baseType: !524, size: 64, offset: 256)
!528 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_ptr", scope: !519, file: !520, line: 58, baseType: !524, size: 64, offset: 320)
!529 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_end", scope: !519, file: !520, line: 59, baseType: !524, size: 64, offset: 384)
!530 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_buf_base", scope: !519, file: !520, line: 60, baseType: !524, size: 64, offset: 448)
!531 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_buf_end", scope: !519, file: !520, line: 61, baseType: !524, size: 64, offset: 512)
!532 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_save_base", scope: !519, file: !520, line: 64, baseType: !524, size: 64, offset: 576)
!533 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_backup_base", scope: !519, file: !520, line: 65, baseType: !524, size: 64, offset: 640)
!534 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_save_end", scope: !519, file: !520, line: 66, baseType: !524, size: 64, offset: 704)
!535 = !DIDerivedType(tag: DW_TAG_member, name: "_markers", scope: !519, file: !520, line: 68, baseType: !536, size: 64, offset: 768)
!536 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !537, size: 64, dwarfAddressSpace: 4)
!537 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_marker", file: !520, line: 36, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTS10_IO_marker")
!538 = !DIDerivedType(tag: DW_TAG_member, name: "_chain", scope: !519, file: !520, line: 70, baseType: !539, size: 64, offset: 832)
!539 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !519, size: 64, dwarfAddressSpace: 4)
!540 = !DIDerivedType(tag: DW_TAG_member, name: "_fileno", scope: !519, file: !520, line: 72, baseType: !16, size: 32, offset: 896)
!541 = !DIDerivedType(tag: DW_TAG_member, name: "_flags2", scope: !519, file: !520, line: 73, baseType: !16, size: 32, offset: 928)
!542 = !DIDerivedType(tag: DW_TAG_member, name: "_old_offset", scope: !519, file: !520, line: 74, baseType: !543, size: 64, offset: 960)
!543 = !DIDerivedType(tag: DW_TAG_typedef, name: "__off_t", file: !360, line: 152, baseType: !544)
!544 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!545 = !DIDerivedType(tag: DW_TAG_member, name: "_cur_column", scope: !519, file: !520, line: 77, baseType: !546, size: 16, offset: 1024)
!546 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!547 = !DIDerivedType(tag: DW_TAG_member, name: "_vtable_offset", scope: !519, file: !520, line: 78, baseType: !165, size: 8, offset: 1040)
!548 = !DIDerivedType(tag: DW_TAG_member, name: "_shortbuf", scope: !519, file: !520, line: 79, baseType: !549, size: 8, offset: 1048)
!549 = !DICompositeType(tag: DW_TAG_array_type, baseType: !500, size: 8, elements: !67)
!550 = !DIDerivedType(tag: DW_TAG_member, name: "_lock", scope: !519, file: !520, line: 81, baseType: !551, size: 64, offset: 1088)
!551 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !552, size: 64, dwarfAddressSpace: 4)
!552 = !DIDerivedType(tag: DW_TAG_typedef, name: "_IO_lock_t", file: !520, line: 43, baseType: null)
!553 = !DIDerivedType(tag: DW_TAG_member, name: "_offset", scope: !519, file: !520, line: 89, baseType: !554, size: 64, offset: 1152)
!554 = !DIDerivedType(tag: DW_TAG_typedef, name: "__off64_t", file: !360, line: 153, baseType: !544)
!555 = !DIDerivedType(tag: DW_TAG_member, name: "_codecvt", scope: !519, file: !520, line: 91, baseType: !556, size: 64, offset: 1216)
!556 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !557, size: 64, dwarfAddressSpace: 4)
!557 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_codecvt", file: !520, line: 37, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTS11_IO_codecvt")
!558 = !DIDerivedType(tag: DW_TAG_member, name: "_wide_data", scope: !519, file: !520, line: 92, baseType: !559, size: 64, offset: 1280)
!559 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !560, size: 64, dwarfAddressSpace: 4)
!560 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_wide_data", file: !520, line: 38, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTS13_IO_wide_data")
!561 = !DIDerivedType(tag: DW_TAG_member, name: "_freeres_list", scope: !519, file: !520, line: 93, baseType: !539, size: 64, offset: 1344)
!562 = !DIDerivedType(tag: DW_TAG_member, name: "_freeres_buf", scope: !519, file: !520, line: 94, baseType: !563, size: 64, offset: 1408)
!563 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64, dwarfAddressSpace: 4)
!564 = !DIDerivedType(tag: DW_TAG_member, name: "__pad5", scope: !519, file: !520, line: 95, baseType: !198, size: 64, offset: 1472)
!565 = !DIDerivedType(tag: DW_TAG_member, name: "_mode", scope: !519, file: !520, line: 96, baseType: !16, size: 32, offset: 1536)
!566 = !DIDerivedType(tag: DW_TAG_member, name: "_unused2", scope: !519, file: !520, line: 98, baseType: !567, size: 160, offset: 1568)
!567 = !DICompositeType(tag: DW_TAG_array_type, baseType: !500, size: 160, elements: !568)
!568 = !{!569}
!569 = !DISubrange(count: 20)
!570 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !571, file: !503, line: 145)
!571 = !DISubprogram(name: "fgetws", scope: !509, file: !509, line: 755, type: !572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!572 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !573)
!573 = !{!574, !576, !16, !577}
!574 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !575, size: 64, dwarfAddressSpace: 4)
!575 = !DIBasicType(name: "wchar_t", size: 32, encoding: DW_ATE_signed)
!576 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !574)
!577 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !516)
!578 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !579, file: !503, line: 146)
!579 = !DISubprogram(name: "fputwc", scope: !509, file: !509, line: 740, type: !580, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!580 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !581)
!581 = !{!505, !575, !516}
!582 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !583, file: !503, line: 147)
!583 = !DISubprogram(name: "fputws", scope: !509, file: !509, line: 762, type: !584, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!584 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !585)
!585 = !{!16, !586, !577}
!586 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !587)
!587 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !588, size: 64, dwarfAddressSpace: 4)
!588 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !575)
!589 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !590, file: !503, line: 148)
!590 = !DISubprogram(name: "fwide", scope: !509, file: !509, line: 573, type: !591, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!591 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !592)
!592 = !{!16, !516, !16}
!593 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !594, file: !503, line: 149)
!594 = !DISubprogram(name: "fwprintf", scope: !509, file: !509, line: 580, type: !595, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!595 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !596)
!596 = !{!16, !577, !586, null}
!597 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !598, file: !503, line: 150)
!598 = !DISubprogram(name: "fwscanf", linkageName: "__isoc99_fwscanf", scope: !509, file: !509, line: 640, type: !595, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!599 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !600, file: !503, line: 151)
!600 = !DISubprogram(name: "getwc", scope: !509, file: !509, line: 727, type: !514, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!601 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !602, file: !503, line: 152)
!602 = !DISubprogram(name: "getwchar", scope: !509, file: !509, line: 733, type: !603, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!603 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !604)
!604 = !{!505}
!605 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !606, file: !503, line: 153)
!606 = !DISubprogram(name: "mbrlen", scope: !509, file: !509, line: 329, type: !607, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!607 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !608)
!608 = !{!198, !609, !198, !612}
!609 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !610)
!610 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !611, size: 64, dwarfAddressSpace: 4)
!611 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !500)
!612 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !613)
!613 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !487, size: 64, dwarfAddressSpace: 4)
!614 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !615, file: !503, line: 154)
!615 = !DISubprogram(name: "mbrtowc", scope: !509, file: !509, line: 296, type: !616, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!616 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !617)
!617 = !{!198, !576, !609, !198, !612}
!618 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !619, file: !503, line: 155)
!619 = !DISubprogram(name: "mbsinit", scope: !509, file: !509, line: 292, type: !620, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!620 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !621)
!621 = !{!16, !622}
!622 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !623, size: 64, dwarfAddressSpace: 4)
!623 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !487)
!624 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !625, file: !503, line: 156)
!625 = !DISubprogram(name: "mbsrtowcs", scope: !509, file: !509, line: 337, type: !626, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!626 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !627)
!627 = !{!198, !576, !628, !198, !612}
!628 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !629)
!629 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !610, size: 64, dwarfAddressSpace: 4)
!630 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !631, file: !503, line: 157)
!631 = !DISubprogram(name: "putwc", scope: !509, file: !509, line: 741, type: !580, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!632 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !633, file: !503, line: 158)
!633 = !DISubprogram(name: "putwchar", scope: !509, file: !509, line: 747, type: !634, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!634 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !635)
!635 = !{!505, !575}
!636 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !637, file: !503, line: 160)
!637 = !DISubprogram(name: "swprintf", scope: !509, file: !509, line: 590, type: !638, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!638 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !639)
!639 = !{!16, !576, !198, !586, null}
!640 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !641, file: !503, line: 162)
!641 = !DISubprogram(name: "swscanf", linkageName: "__isoc99_swscanf", scope: !509, file: !509, line: 647, type: !642, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!642 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !643)
!643 = !{!16, !586, !586, null}
!644 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !645, file: !503, line: 163)
!645 = !DISubprogram(name: "ungetwc", scope: !509, file: !509, line: 770, type: !646, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!646 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !647)
!647 = !{!505, !505, !516}
!648 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !649, file: !503, line: 164)
!649 = !DISubprogram(name: "vfwprintf", scope: !509, file: !509, line: 598, type: !650, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!650 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !651)
!651 = !{!16, !577, !586, !652}
!652 = !DIDerivedType(tag: DW_TAG_typedef, name: "__gnuc_va_list", file: !653, line: 14, baseType: !654)
!653 = !DIFile(filename: "/build/lib/clang/17/include/stdarg.h", directory: "", checksumkind: CSK_MD5, checksum: "4c819f80dd915987182e9ab226e27a5a")
!654 = !DIDerivedType(tag: DW_TAG_typedef, name: "__builtin_va_list", file: !1, baseType: !563)
!655 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !656, file: !503, line: 166)
!656 = !DISubprogram(name: "vfwscanf", linkageName: "__isoc99_vfwscanf", scope: !509, file: !509, line: 693, type: !650, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!657 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !658, file: !503, line: 169)
!658 = !DISubprogram(name: "vswprintf", scope: !509, file: !509, line: 611, type: !659, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!659 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !660)
!660 = !{!16, !576, !198, !586, !652}
!661 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !662, file: !503, line: 172)
!662 = !DISubprogram(name: "vswscanf", linkageName: "__isoc99_vswscanf", scope: !509, file: !509, line: 700, type: !663, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!663 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !664)
!664 = !{!16, !586, !586, !652}
!665 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !666, file: !503, line: 174)
!666 = !DISubprogram(name: "vwprintf", scope: !509, file: !509, line: 606, type: !667, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!667 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !668)
!668 = !{!16, !586, !652}
!669 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !670, file: !503, line: 176)
!670 = !DISubprogram(name: "vwscanf", linkageName: "__isoc99_vwscanf", scope: !509, file: !509, line: 697, type: !667, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!671 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !672, file: !503, line: 178)
!672 = !DISubprogram(name: "wcrtomb", scope: !509, file: !509, line: 301, type: !673, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!673 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !674)
!674 = !{!198, !675, !575, !612}
!675 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !524)
!676 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !677, file: !503, line: 179)
!677 = !DISubprogram(name: "wcscat", scope: !509, file: !509, line: 97, type: !678, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!678 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !679)
!679 = !{!574, !576, !586}
!680 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !681, file: !503, line: 180)
!681 = !DISubprogram(name: "wcscmp", scope: !509, file: !509, line: 106, type: !682, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!682 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !683)
!683 = !{!16, !587, !587}
!684 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !685, file: !503, line: 181)
!685 = !DISubprogram(name: "wcscoll", scope: !509, file: !509, line: 131, type: !682, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!686 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !687, file: !503, line: 182)
!687 = !DISubprogram(name: "wcscpy", scope: !509, file: !509, line: 87, type: !678, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!688 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !689, file: !503, line: 183)
!689 = !DISubprogram(name: "wcscspn", scope: !509, file: !509, line: 187, type: !690, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!690 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !691)
!691 = !{!198, !587, !587}
!692 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !693, file: !503, line: 184)
!693 = !DISubprogram(name: "wcsftime", scope: !509, file: !509, line: 834, type: !694, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!694 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !695)
!695 = !{!198, !576, !198, !586, !696}
!696 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !697)
!697 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !698, size: 64, dwarfAddressSpace: 4)
!698 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !699)
!699 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "tm", file: !509, line: 83, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTS2tm")
!700 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !701, file: !503, line: 185)
!701 = !DISubprogram(name: "wcslen", scope: !509, file: !509, line: 222, type: !702, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!702 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !703)
!703 = !{!198, !587}
!704 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !705, file: !503, line: 186)
!705 = !DISubprogram(name: "wcsncat", scope: !509, file: !509, line: 101, type: !706, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!706 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !707)
!707 = !{!574, !576, !586, !198}
!708 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !709, file: !503, line: 187)
!709 = !DISubprogram(name: "wcsncmp", scope: !509, file: !509, line: 109, type: !710, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!710 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !711)
!711 = !{!16, !587, !587, !198}
!712 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !713, file: !503, line: 188)
!713 = !DISubprogram(name: "wcsncpy", scope: !509, file: !509, line: 92, type: !706, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!714 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !715, file: !503, line: 189)
!715 = !DISubprogram(name: "wcsrtombs", scope: !509, file: !509, line: 343, type: !716, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!716 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !717)
!717 = !{!198, !675, !718, !198, !612}
!718 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !719)
!719 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !587, size: 64, dwarfAddressSpace: 4)
!720 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !721, file: !503, line: 190)
!721 = !DISubprogram(name: "wcsspn", scope: !509, file: !509, line: 191, type: !690, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!722 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !723, file: !503, line: 191)
!723 = !DISubprogram(name: "wcstod", scope: !509, file: !509, line: 377, type: !724, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!724 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !725)
!725 = !{!726, !586, !727}
!726 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!727 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !728)
!728 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !574, size: 64, dwarfAddressSpace: 4)
!729 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !730, file: !503, line: 193)
!730 = !DISubprogram(name: "wcstof", scope: !509, file: !509, line: 382, type: !731, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!731 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !732)
!732 = !{!733, !586, !727}
!733 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!734 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !735, file: !503, line: 195)
!735 = !DISubprogram(name: "wcstok", scope: !509, file: !509, line: 217, type: !736, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!736 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !737)
!737 = !{!574, !576, !586, !727}
!738 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !739, file: !503, line: 196)
!739 = !DISubprogram(name: "wcstol", scope: !509, file: !509, line: 428, type: !740, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!740 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !741)
!741 = !{!544, !586, !727, !16}
!742 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !743, file: !503, line: 197)
!743 = !DISubprogram(name: "wcstoul", scope: !509, file: !509, line: 433, type: !744, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!744 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !745)
!745 = !{!58, !586, !727, !16}
!746 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !747, file: !503, line: 198)
!747 = !DISubprogram(name: "wcsxfrm", scope: !509, file: !509, line: 135, type: !748, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!748 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !749)
!749 = !{!198, !576, !586, !198}
!750 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !751, file: !503, line: 199)
!751 = !DISubprogram(name: "wctob", scope: !509, file: !509, line: 324, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!752 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !753)
!753 = !{!16, !505}
!754 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !755, file: !503, line: 200)
!755 = !DISubprogram(name: "wmemcmp", scope: !509, file: !509, line: 258, type: !710, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!756 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !757, file: !503, line: 201)
!757 = !DISubprogram(name: "wmemcpy", scope: !509, file: !509, line: 262, type: !706, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!758 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !759, file: !503, line: 202)
!759 = !DISubprogram(name: "wmemmove", scope: !509, file: !509, line: 267, type: !760, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!760 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !761)
!761 = !{!574, !574, !587, !198}
!762 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !763, file: !503, line: 203)
!763 = !DISubprogram(name: "wmemset", scope: !509, file: !509, line: 271, type: !764, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!764 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !765)
!765 = !{!574, !574, !575, !198}
!766 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !767, file: !503, line: 204)
!767 = !DISubprogram(name: "wprintf", scope: !509, file: !509, line: 587, type: !768, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!768 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !769)
!769 = !{!16, !586, null}
!770 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !771, file: !503, line: 205)
!771 = !DISubprogram(name: "wscanf", linkageName: "__isoc99_wscanf", scope: !509, file: !509, line: 644, type: !768, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!772 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !773, file: !503, line: 206)
!773 = !DISubprogram(name: "wcschr", scope: !509, file: !509, line: 164, type: !774, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!774 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !775)
!775 = !{!574, !587, !575}
!776 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !777, file: !503, line: 207)
!777 = !DISubprogram(name: "wcspbrk", scope: !509, file: !509, line: 201, type: !778, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!778 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !779)
!779 = !{!574, !587, !587}
!780 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !781, file: !503, line: 208)
!781 = !DISubprogram(name: "wcsrchr", scope: !509, file: !509, line: 174, type: !774, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!782 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !783, file: !503, line: 209)
!783 = !DISubprogram(name: "wcsstr", scope: !509, file: !509, line: 212, type: !778, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!784 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !785, file: !503, line: 210)
!785 = !DISubprogram(name: "wmemchr", scope: !509, file: !509, line: 253, type: !786, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!786 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !787)
!787 = !{!574, !587, !575, !198}
!788 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !789, file: !503, line: 251)
!789 = !DISubprogram(name: "wcstold", scope: !509, file: !509, line: 384, type: !790, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!790 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !791)
!791 = !{!792, !586, !727}
!792 = !DIBasicType(name: "long double", size: 128, encoding: DW_ATE_float)
!793 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !794, file: !503, line: 260)
!794 = !DISubprogram(name: "wcstoll", scope: !509, file: !509, line: 441, type: !795, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!795 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !796)
!796 = !{!797, !586, !727, !16}
!797 = !DIBasicType(name: "long long", size: 64, encoding: DW_ATE_signed)
!798 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !799, file: !503, line: 261)
!799 = !DISubprogram(name: "wcstoull", scope: !509, file: !509, line: 448, type: !800, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!800 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !801)
!801 = !{!802, !586, !727, !16}
!802 = !DIBasicType(name: "unsigned long long", size: 64, encoding: DW_ATE_unsigned)
!803 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !789, file: !503, line: 267)
!804 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !794, file: !503, line: 268)
!805 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !799, file: !503, line: 269)
!806 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !730, file: !503, line: 283)
!807 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !656, file: !503, line: 286)
!808 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !662, file: !503, line: 289)
!809 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !670, file: !503, line: 292)
!810 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !789, file: !503, line: 296)
!811 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !794, file: !503, line: 297)
!812 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !799, file: !503, line: 298)
!813 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !814, file: !815, line: 57)
!814 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "exception_ptr", scope: !816, file: !815, line: 79, size: 64, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTSNSt15__exception_ptr13exception_ptrE")
!815 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/exception_ptr.h", directory: "", checksumkind: CSK_MD5, checksum: "ad32556413cf4ca6a852273de62d0a18")
!816 = !DINamespace(name: "__exception_ptr", scope: !44)
!817 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !816, entity: !818, file: !815, line: 73)
!818 = !DISubprogram(name: "rethrow_exception", linkageName: "_ZSt17rethrow_exceptionNSt15__exception_ptr13exception_ptrE", scope: !44, file: !815, line: 69, type: !819, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: DISPFlagOptimized)
!819 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !820)
!820 = !{null, !814}
!821 = !DIImportedEntity(tag: DW_TAG_imported_module, scope: !822, entity: !823, file: !824, line: 58)
!822 = !DINamespace(name: "__gnu_debug", scope: null)
!823 = !DINamespace(name: "__debug", scope: !44)
!824 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/debug/debug.h", directory: "", checksumkind: CSK_MD5, checksum: "1e1a444391d862db9c9b259fde858dd4")
!825 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !826, file: !829, line: 47)
!826 = !DIDerivedType(tag: DW_TAG_typedef, name: "int8_t", file: !827, line: 24, baseType: !828)
!827 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdint-intn.h", directory: "", checksumkind: CSK_MD5, checksum: "081edea97425b3437dded4a7fe223193")
!828 = !DIDerivedType(tag: DW_TAG_typedef, name: "__int8_t", file: !360, line: 37, baseType: !165)
!829 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cstdint", directory: "", checksumkind: CSK_MD5, checksum: "9be24234e1d5d938d21f3b0d80b1e35b")
!830 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !831, file: !829, line: 48)
!831 = !DIDerivedType(tag: DW_TAG_typedef, name: "int16_t", file: !827, line: 25, baseType: !832)
!832 = !DIDerivedType(tag: DW_TAG_typedef, name: "__int16_t", file: !360, line: 39, baseType: !833)
!833 = !DIBasicType(name: "short", size: 16, encoding: DW_ATE_signed)
!834 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !835, file: !829, line: 49)
!835 = !DIDerivedType(tag: DW_TAG_typedef, name: "int32_t", file: !827, line: 26, baseType: !836)
!836 = !DIDerivedType(tag: DW_TAG_typedef, name: "__int32_t", file: !360, line: 41, baseType: !16)
!837 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !838, file: !829, line: 50)
!838 = !DIDerivedType(tag: DW_TAG_typedef, name: "int64_t", file: !827, line: 27, baseType: !839)
!839 = !DIDerivedType(tag: DW_TAG_typedef, name: "__int64_t", file: !360, line: 44, baseType: !544)
!840 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !841, file: !829, line: 52)
!841 = !DIDerivedType(tag: DW_TAG_typedef, name: "int_fast8_t", file: !842, line: 58, baseType: !165)
!842 = !DIFile(filename: "/usr/include/stdint.h", directory: "", checksumkind: CSK_MD5, checksum: "24103e292ae21916e87130b926c8d2f8")
!843 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !844, file: !829, line: 53)
!844 = !DIDerivedType(tag: DW_TAG_typedef, name: "int_fast16_t", file: !842, line: 60, baseType: !544)
!845 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !846, file: !829, line: 54)
!846 = !DIDerivedType(tag: DW_TAG_typedef, name: "int_fast32_t", file: !842, line: 61, baseType: !544)
!847 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !848, file: !829, line: 55)
!848 = !DIDerivedType(tag: DW_TAG_typedef, name: "int_fast64_t", file: !842, line: 62, baseType: !544)
!849 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !850, file: !829, line: 57)
!850 = !DIDerivedType(tag: DW_TAG_typedef, name: "int_least8_t", file: !842, line: 43, baseType: !851)
!851 = !DIDerivedType(tag: DW_TAG_typedef, name: "__int_least8_t", file: !360, line: 52, baseType: !828)
!852 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !853, file: !829, line: 58)
!853 = !DIDerivedType(tag: DW_TAG_typedef, name: "int_least16_t", file: !842, line: 44, baseType: !854)
!854 = !DIDerivedType(tag: DW_TAG_typedef, name: "__int_least16_t", file: !360, line: 54, baseType: !832)
!855 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !856, file: !829, line: 59)
!856 = !DIDerivedType(tag: DW_TAG_typedef, name: "int_least32_t", file: !842, line: 45, baseType: !857)
!857 = !DIDerivedType(tag: DW_TAG_typedef, name: "__int_least32_t", file: !360, line: 56, baseType: !836)
!858 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !859, file: !829, line: 60)
!859 = !DIDerivedType(tag: DW_TAG_typedef, name: "int_least64_t", file: !842, line: 46, baseType: !860)
!860 = !DIDerivedType(tag: DW_TAG_typedef, name: "__int_least64_t", file: !360, line: 58, baseType: !839)
!861 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !862, file: !829, line: 62)
!862 = !DIDerivedType(tag: DW_TAG_typedef, name: "intmax_t", file: !842, line: 101, baseType: !863)
!863 = !DIDerivedType(tag: DW_TAG_typedef, name: "__intmax_t", file: !360, line: 72, baseType: !544)
!864 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !865, file: !829, line: 63)
!865 = !DIDerivedType(tag: DW_TAG_typedef, name: "intptr_t", file: !842, line: 87, baseType: !544)
!866 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !867, file: !829, line: 65)
!867 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint8_t", file: !358, line: 24, baseType: !868)
!868 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint8_t", file: !360, line: 38, baseType: !869)
!869 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!870 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !871, file: !829, line: 66)
!871 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint16_t", file: !358, line: 25, baseType: !872)
!872 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint16_t", file: !360, line: 40, baseType: !546)
!873 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !357, file: !829, line: 67)
!874 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !875, file: !829, line: 68)
!875 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint64_t", file: !358, line: 27, baseType: !876)
!876 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint64_t", file: !360, line: 45, baseType: !58)
!877 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !878, file: !829, line: 70)
!878 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint_fast8_t", file: !842, line: 71, baseType: !869)
!879 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !880, file: !829, line: 71)
!880 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint_fast16_t", file: !842, line: 73, baseType: !58)
!881 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !882, file: !829, line: 72)
!882 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint_fast32_t", file: !842, line: 74, baseType: !58)
!883 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !884, file: !829, line: 73)
!884 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint_fast64_t", file: !842, line: 75, baseType: !58)
!885 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !886, file: !829, line: 75)
!886 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint_least8_t", file: !842, line: 49, baseType: !887)
!887 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint_least8_t", file: !360, line: 53, baseType: !868)
!888 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !889, file: !829, line: 76)
!889 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint_least16_t", file: !842, line: 50, baseType: !890)
!890 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint_least16_t", file: !360, line: 55, baseType: !872)
!891 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !892, file: !829, line: 77)
!892 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint_least32_t", file: !842, line: 51, baseType: !893)
!893 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint_least32_t", file: !360, line: 57, baseType: !359)
!894 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !895, file: !829, line: 78)
!895 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint_least64_t", file: !842, line: 52, baseType: !896)
!896 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uint_least64_t", file: !360, line: 59, baseType: !876)
!897 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !898, file: !829, line: 80)
!898 = !DIDerivedType(tag: DW_TAG_typedef, name: "uintmax_t", file: !842, line: 102, baseType: !899)
!899 = !DIDerivedType(tag: DW_TAG_typedef, name: "__uintmax_t", file: !360, line: 73, baseType: !58)
!900 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !901, file: !829, line: 81)
!901 = !DIDerivedType(tag: DW_TAG_typedef, name: "uintptr_t", file: !842, line: 90, baseType: !58)
!902 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !903, file: !905, line: 53)
!903 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "lconv", file: !904, line: 51, size: 768, flags: DIFlagFwdDecl, identifier: "_ZTS5lconv")
!904 = !DIFile(filename: "/usr/include/locale.h", directory: "", checksumkind: CSK_MD5, checksum: "0cf373fc44eed8073800bdb9da87b72f")
!905 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/clocale", directory: "", checksumkind: CSK_MD5, checksum: "4d99161546323135c4843b1179538c41")
!906 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !907, file: !905, line: 54)
!907 = !DISubprogram(name: "setlocale", scope: !904, file: !904, line: 122, type: !908, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!908 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !909)
!909 = !{!524, !16, !610}
!910 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !911, file: !905, line: 55)
!911 = !DISubprogram(name: "localeconv", scope: !904, file: !904, line: 125, type: !912, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!912 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !913)
!913 = !{!914}
!914 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !903, size: 64, dwarfAddressSpace: 4)
!915 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !916, file: !920, line: 64)
!916 = !DISubprogram(name: "isalnum", scope: !917, file: !917, line: 108, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!917 = !DIFile(filename: "/usr/include/ctype.h", directory: "", checksumkind: CSK_MD5, checksum: "36575f934ef4fe7e9d50a3cb17bd5c66")
!918 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !919)
!919 = !{!16, !16}
!920 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cctype", directory: "", checksumkind: CSK_MD5, checksum: "3d42b6e657fb76d5753f5358a42840e9")
!921 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !922, file: !920, line: 65)
!922 = !DISubprogram(name: "isalpha", scope: !917, file: !917, line: 109, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!923 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !924, file: !920, line: 66)
!924 = !DISubprogram(name: "iscntrl", scope: !917, file: !917, line: 110, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!925 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !926, file: !920, line: 67)
!926 = !DISubprogram(name: "isdigit", scope: !917, file: !917, line: 111, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!927 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !928, file: !920, line: 68)
!928 = !DISubprogram(name: "isgraph", scope: !917, file: !917, line: 113, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!929 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !930, file: !920, line: 69)
!930 = !DISubprogram(name: "islower", scope: !917, file: !917, line: 112, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!931 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !932, file: !920, line: 70)
!932 = !DISubprogram(name: "isprint", scope: !917, file: !917, line: 114, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!933 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !934, file: !920, line: 71)
!934 = !DISubprogram(name: "ispunct", scope: !917, file: !917, line: 115, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!935 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !936, file: !920, line: 72)
!936 = !DISubprogram(name: "isspace", scope: !917, file: !917, line: 116, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!937 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !938, file: !920, line: 73)
!938 = !DISubprogram(name: "isupper", scope: !917, file: !917, line: 117, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!939 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !940, file: !920, line: 74)
!940 = !DISubprogram(name: "isxdigit", scope: !917, file: !917, line: 118, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!941 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !942, file: !920, line: 75)
!942 = !DISubprogram(name: "tolower", scope: !917, file: !917, line: 122, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!943 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !944, file: !920, line: 76)
!944 = !DISubprogram(name: "toupper", scope: !917, file: !917, line: 125, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!945 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !946, file: !920, line: 87)
!946 = !DISubprogram(name: "isblank", scope: !917, file: !917, line: 130, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!947 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !56, file: !948, line: 44)
!948 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/ext/new_allocator.h", directory: "", checksumkind: CSK_MD5, checksum: "d815d3ddb625b8849e2bd401d0f6b354")
!949 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !950, file: !948, line: 45)
!950 = !DIDerivedType(tag: DW_TAG_typedef, name: "ptrdiff_t", scope: !44, file: !57, line: 259, baseType: !544)
!951 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !952, file: !954, line: 52)
!952 = !DISubprogram(name: "abs", scope: !953, file: !953, line: 840, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!953 = !DIFile(filename: "/usr/include/stdlib.h", directory: "", checksumkind: CSK_MD5, checksum: "f0db66726d35051e5af2525f5b33bd81")
!954 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/std_abs.h", directory: "", checksumkind: CSK_MD5, checksum: "81c618b4325d99b15983fb3797c33ac4")
!955 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !956, file: !958, line: 127)
!956 = !DIDerivedType(tag: DW_TAG_typedef, name: "div_t", file: !953, line: 62, baseType: !957)
!957 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !953, line: 58, size: 64, flags: DIFlagFwdDecl, identifier: "_ZTS5div_t")
!958 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cstdlib", directory: "", checksumkind: CSK_MD5, checksum: "9235e08d3442e2e443657e5bde65ba3c")
!959 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !960, file: !958, line: 128)
!960 = !DIDerivedType(tag: DW_TAG_typedef, name: "ldiv_t", file: !953, line: 70, baseType: !961)
!961 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !953, line: 66, size: 128, flags: DIFlagTypePassByValue, elements: !962, identifier: "_ZTS6ldiv_t")
!962 = !{!963, !964}
!963 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !961, file: !953, line: 68, baseType: !544, size: 64)
!964 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !961, file: !953, line: 69, baseType: !544, size: 64, offset: 64)
!965 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !966, file: !958, line: 130)
!966 = !DISubprogram(name: "abort", scope: !953, file: !953, line: 591, type: !967, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: DISPFlagOptimized)
!967 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !968)
!968 = !{null}
!969 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !970, file: !958, line: 132)
!970 = !DISubprogram(name: "aligned_alloc", scope: !953, file: !953, line: 586, type: !971, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!971 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !972)
!972 = !{!563, !198, !198}
!973 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !974, file: !958, line: 134)
!974 = !DISubprogram(name: "atexit", scope: !953, file: !953, line: 595, type: !975, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!975 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !976)
!976 = !{!16, !977}
!977 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !967, size: 64, dwarfAddressSpace: 0)
!978 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !979, file: !958, line: 137)
!979 = !DISubprogram(name: "at_quick_exit", scope: !953, file: !953, line: 600, type: !975, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!980 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !981, file: !958, line: 140)
!981 = !DISubprogram(name: "atof", scope: !982, file: !982, line: 25, type: !983, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!982 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdlib-float.h", directory: "", checksumkind: CSK_MD5, checksum: "48f612e342a3b16120b9f0760cf29677")
!983 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !984)
!984 = !{!726, !610}
!985 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !986, file: !958, line: 141)
!986 = !DISubprogram(name: "atoi", scope: !953, file: !953, line: 361, type: !987, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!987 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !988)
!988 = !{!16, !610}
!989 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !990, file: !958, line: 142)
!990 = !DISubprogram(name: "atol", scope: !953, file: !953, line: 366, type: !991, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!991 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !992)
!992 = !{!544, !610}
!993 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !994, file: !958, line: 143)
!994 = !DISubprogram(name: "bsearch", scope: !995, file: !995, line: 20, type: !996, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!995 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdlib-bsearch.h", directory: "", checksumkind: CSK_MD5, checksum: "ef5679a99236861b72c28d9a752239e4")
!996 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !997)
!997 = !{!563, !998, !998, !198, !198, !1000}
!998 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !999, size: 64, dwarfAddressSpace: 4)
!999 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!1000 = !DIDerivedType(tag: DW_TAG_typedef, name: "__compar_fn_t", file: !953, line: 808, baseType: !1001)
!1001 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1002, size: 64, dwarfAddressSpace: 0)
!1002 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1003)
!1003 = !{!16, !998, !998}
!1004 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1005, file: !958, line: 144)
!1005 = !DISubprogram(name: "calloc", scope: !953, file: !953, line: 542, type: !971, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1006 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1007, file: !958, line: 145)
!1007 = !DISubprogram(name: "div", scope: !953, file: !953, line: 852, type: !1008, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1008 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1009)
!1009 = !{!956, !16, !16}
!1010 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1011, file: !958, line: 146)
!1011 = !DISubprogram(name: "exit", scope: !953, file: !953, line: 617, type: !1012, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: DISPFlagOptimized)
!1012 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1013)
!1013 = !{null, !16}
!1014 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1015, file: !958, line: 147)
!1015 = !DISubprogram(name: "free", scope: !953, file: !953, line: 565, type: !1016, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1016 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1017)
!1017 = !{null, !563}
!1018 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1019, file: !958, line: 148)
!1019 = !DISubprogram(name: "getenv", scope: !953, file: !953, line: 634, type: !1020, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1020 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1021)
!1021 = !{!524, !610}
!1022 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1023, file: !958, line: 149)
!1023 = !DISubprogram(name: "labs", scope: !953, file: !953, line: 841, type: !1024, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1024 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1025)
!1025 = !{!544, !544}
!1026 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1027, file: !958, line: 150)
!1027 = !DISubprogram(name: "ldiv", scope: !953, file: !953, line: 854, type: !1028, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1028 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1029)
!1029 = !{!960, !544, !544}
!1030 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1031, file: !958, line: 151)
!1031 = !DISubprogram(name: "malloc", scope: !953, file: !953, line: 539, type: !1032, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1032 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1033)
!1033 = !{!563, !198}
!1034 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1035, file: !958, line: 153)
!1035 = !DISubprogram(name: "mblen", scope: !953, file: !953, line: 922, type: !1036, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1036 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1037)
!1037 = !{!16, !610, !198}
!1038 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1039, file: !958, line: 154)
!1039 = !DISubprogram(name: "mbstowcs", scope: !953, file: !953, line: 933, type: !1040, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1040 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1041)
!1041 = !{!198, !576, !609, !198}
!1042 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1043, file: !958, line: 155)
!1043 = !DISubprogram(name: "mbtowc", scope: !953, file: !953, line: 925, type: !1044, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1044 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1045)
!1045 = !{!16, !576, !609, !198}
!1046 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1047, file: !958, line: 157)
!1047 = !DISubprogram(name: "qsort", scope: !953, file: !953, line: 830, type: !1048, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1048 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1049)
!1049 = !{null, !563, !198, !198, !1000}
!1050 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1051, file: !958, line: 160)
!1051 = !DISubprogram(name: "quick_exit", scope: !953, file: !953, line: 623, type: !1012, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: DISPFlagOptimized)
!1052 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1053, file: !958, line: 163)
!1053 = !DISubprogram(name: "rand", scope: !953, file: !953, line: 453, type: !170, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1054 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1055, file: !958, line: 164)
!1055 = !DISubprogram(name: "realloc", scope: !953, file: !953, line: 550, type: !1056, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1056 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1057)
!1057 = !{!563, !563, !198}
!1058 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1059, file: !958, line: 165)
!1059 = !DISubprogram(name: "srand", scope: !953, file: !953, line: 455, type: !1060, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1060 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1061)
!1061 = !{null, !6}
!1062 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1063, file: !958, line: 166)
!1063 = !DISubprogram(name: "strtod", scope: !953, file: !953, line: 117, type: !1064, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1064 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1065)
!1065 = !{!726, !609, !1066}
!1066 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !1067)
!1067 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !524, size: 64, dwarfAddressSpace: 4)
!1068 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1069, file: !958, line: 167)
!1069 = !DISubprogram(name: "strtol", scope: !953, file: !953, line: 176, type: !1070, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1070 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1071)
!1071 = !{!544, !609, !1066, !16}
!1072 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1073, file: !958, line: 168)
!1073 = !DISubprogram(name: "strtoul", scope: !953, file: !953, line: 180, type: !1074, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1074 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1075)
!1075 = !{!58, !609, !1066, !16}
!1076 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1077, file: !958, line: 169)
!1077 = !DISubprogram(name: "system", scope: !953, file: !953, line: 784, type: !987, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1078 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1079, file: !958, line: 171)
!1079 = !DISubprogram(name: "wcstombs", scope: !953, file: !953, line: 936, type: !1080, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1080 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1081)
!1081 = !{!198, !675, !586, !198}
!1082 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1083, file: !958, line: 172)
!1083 = !DISubprogram(name: "wctomb", scope: !953, file: !953, line: 929, type: !1084, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1084 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1085)
!1085 = !{!16, !524, !575}
!1086 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1087, file: !958, line: 200)
!1087 = !DIDerivedType(tag: DW_TAG_typedef, name: "lldiv_t", file: !953, line: 80, baseType: !1088)
!1088 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !953, line: 76, size: 128, flags: DIFlagTypePassByValue, elements: !1089, identifier: "_ZTS7lldiv_t")
!1089 = !{!1090, !1091}
!1090 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !1088, file: !953, line: 78, baseType: !797, size: 64)
!1091 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !1088, file: !953, line: 79, baseType: !797, size: 64, offset: 64)
!1092 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1093, file: !958, line: 206)
!1093 = !DISubprogram(name: "_Exit", scope: !953, file: !953, line: 629, type: !1012, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: DISPFlagOptimized)
!1094 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1095, file: !958, line: 210)
!1095 = !DISubprogram(name: "llabs", scope: !953, file: !953, line: 844, type: !1096, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1096 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1097)
!1097 = !{!797, !797}
!1098 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1099, file: !958, line: 216)
!1099 = !DISubprogram(name: "lldiv", scope: !953, file: !953, line: 858, type: !1100, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1100 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1101)
!1101 = !{!1087, !797, !797}
!1102 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1103, file: !958, line: 227)
!1103 = !DISubprogram(name: "atoll", scope: !953, file: !953, line: 373, type: !1104, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1104 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1105)
!1105 = !{!797, !610}
!1106 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1107, file: !958, line: 228)
!1107 = !DISubprogram(name: "strtoll", scope: !953, file: !953, line: 200, type: !1108, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1108 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1109)
!1109 = !{!797, !609, !1066, !16}
!1110 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1111, file: !958, line: 229)
!1111 = !DISubprogram(name: "strtoull", scope: !953, file: !953, line: 205, type: !1112, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1112 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1113)
!1113 = !{!802, !609, !1066, !16}
!1114 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1115, file: !958, line: 231)
!1115 = !DISubprogram(name: "strtof", scope: !953, file: !953, line: 123, type: !1116, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1116 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1117)
!1117 = !{!733, !609, !1066}
!1118 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1119, file: !958, line: 232)
!1119 = !DISubprogram(name: "strtold", scope: !953, file: !953, line: 126, type: !1120, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1120 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1121)
!1121 = !{!792, !609, !1066}
!1122 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1087, file: !958, line: 240)
!1123 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1093, file: !958, line: 242)
!1124 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1095, file: !958, line: 244)
!1125 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1126, file: !958, line: 245)
!1126 = !DISubprogram(name: "div", linkageName: "_ZN9__gnu_cxx3divExx", scope: !5, file: !958, line: 213, type: !1100, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1127 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1099, file: !958, line: 246)
!1128 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1103, file: !958, line: 248)
!1129 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1115, file: !958, line: 249)
!1130 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1107, file: !958, line: 250)
!1131 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1111, file: !958, line: 251)
!1132 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1119, file: !958, line: 252)
!1133 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1134, file: !1136, line: 98)
!1134 = !DIDerivedType(tag: DW_TAG_typedef, name: "FILE", file: !1135, line: 7, baseType: !519)
!1135 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/FILE.h", directory: "", checksumkind: CSK_MD5, checksum: "571f9fb6223c42439075fdde11a0de5d")
!1136 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cstdio", directory: "", checksumkind: CSK_MD5, checksum: "392163602ee9b030d1de5fa1dffa4294")
!1137 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1138, file: !1136, line: 99)
!1138 = !DIDerivedType(tag: DW_TAG_typedef, name: "fpos_t", file: !1139, line: 84, baseType: !1140)
!1139 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "5b917eded35ce2507d1e294bf8cb74d7")
!1140 = !DIDerivedType(tag: DW_TAG_typedef, name: "__fpos_t", file: !1141, line: 14, baseType: !1142)
!1141 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/__fpos_t.h", directory: "", checksumkind: CSK_MD5, checksum: "32de8bdaf3551a6c0a9394f9af4389ce")
!1142 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_G_fpos_t", file: !1141, line: 10, size: 128, flags: DIFlagFwdDecl, identifier: "_ZTS9_G_fpos_t")
!1143 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1144, file: !1136, line: 101)
!1144 = !DISubprogram(name: "clearerr", scope: !1139, file: !1139, line: 757, type: !1145, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1145 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1146)
!1146 = !{null, !1147}
!1147 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1134, size: 64, dwarfAddressSpace: 4)
!1148 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1149, file: !1136, line: 102)
!1149 = !DISubprogram(name: "fclose", scope: !1139, file: !1139, line: 213, type: !1150, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1150 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1151)
!1151 = !{!16, !1147}
!1152 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1153, file: !1136, line: 103)
!1153 = !DISubprogram(name: "feof", scope: !1139, file: !1139, line: 759, type: !1150, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1154 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1155, file: !1136, line: 104)
!1155 = !DISubprogram(name: "ferror", scope: !1139, file: !1139, line: 761, type: !1150, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1156 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1157, file: !1136, line: 105)
!1157 = !DISubprogram(name: "fflush", scope: !1139, file: !1139, line: 218, type: !1150, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1158 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1159, file: !1136, line: 106)
!1159 = !DISubprogram(name: "fgetc", scope: !1139, file: !1139, line: 485, type: !1150, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1160 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1161, file: !1136, line: 107)
!1161 = !DISubprogram(name: "fgetpos", scope: !1139, file: !1139, line: 731, type: !1162, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1162 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1163)
!1163 = !{!16, !1164, !1165}
!1164 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !1147)
!1165 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !1166)
!1166 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1138, size: 64, dwarfAddressSpace: 4)
!1167 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1168, file: !1136, line: 108)
!1168 = !DISubprogram(name: "fgets", scope: !1139, file: !1139, line: 564, type: !1169, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1169 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1170)
!1170 = !{!524, !675, !16, !1164}
!1171 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1172, file: !1136, line: 109)
!1172 = !DISubprogram(name: "fopen", scope: !1139, file: !1139, line: 246, type: !1173, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1173 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1174)
!1174 = !{!1147, !609, !609}
!1175 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1176, file: !1136, line: 110)
!1176 = !DISubprogram(name: "fprintf", scope: !1139, file: !1139, line: 326, type: !1177, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1177 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1178)
!1178 = !{!16, !1164, !609, null}
!1179 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1180, file: !1136, line: 111)
!1180 = !DISubprogram(name: "fputc", scope: !1139, file: !1139, line: 521, type: !1181, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1181 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1182)
!1182 = !{!16, !16, !1147}
!1183 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1184, file: !1136, line: 112)
!1184 = !DISubprogram(name: "fputs", scope: !1139, file: !1139, line: 626, type: !1185, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1185 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1186)
!1186 = !{!16, !609, !1164}
!1187 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1188, file: !1136, line: 113)
!1188 = !DISubprogram(name: "fread", scope: !1139, file: !1139, line: 646, type: !1189, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1189 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1190)
!1190 = !{!198, !1191, !198, !198, !1164}
!1191 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !563)
!1192 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1193, file: !1136, line: 114)
!1193 = !DISubprogram(name: "freopen", scope: !1139, file: !1139, line: 252, type: !1194, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1194 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1195)
!1195 = !{!1147, !609, !609, !1164}
!1196 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1197, file: !1136, line: 115)
!1197 = !DISubprogram(name: "fscanf", linkageName: "__isoc99_fscanf", scope: !1139, file: !1139, line: 407, type: !1177, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1198 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1199, file: !1136, line: 116)
!1199 = !DISubprogram(name: "fseek", scope: !1139, file: !1139, line: 684, type: !1200, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1200 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1201)
!1201 = !{!16, !1147, !544, !16}
!1202 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1203, file: !1136, line: 117)
!1203 = !DISubprogram(name: "fsetpos", scope: !1139, file: !1139, line: 736, type: !1204, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1204 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1205)
!1205 = !{!16, !1147, !1206}
!1206 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1207, size: 64, dwarfAddressSpace: 4)
!1207 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !1138)
!1208 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1209, file: !1136, line: 118)
!1209 = !DISubprogram(name: "ftell", scope: !1139, file: !1139, line: 689, type: !1210, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1210 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1211)
!1211 = !{!544, !1147}
!1212 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1213, file: !1136, line: 119)
!1213 = !DISubprogram(name: "fwrite", scope: !1139, file: !1139, line: 652, type: !1214, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1214 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1215)
!1215 = !{!198, !1216, !198, !198, !1164}
!1216 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !998)
!1217 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1218, file: !1136, line: 120)
!1218 = !DISubprogram(name: "getc", scope: !1139, file: !1139, line: 486, type: !1150, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1219 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1220, file: !1136, line: 121)
!1220 = !DISubprogram(name: "getchar", scope: !1221, file: !1221, line: 47, type: !170, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1221 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "fe48be26b3c1dd399597f5e6205450c5")
!1222 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1223, file: !1136, line: 126)
!1223 = !DISubprogram(name: "perror", scope: !1139, file: !1139, line: 775, type: !1224, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1224 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1225)
!1225 = !{null, !610}
!1226 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1227, file: !1136, line: 127)
!1227 = !DISubprogram(name: "printf", scope: !1139, file: !1139, line: 332, type: !1228, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1228 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1229)
!1229 = !{!16, !609, null}
!1230 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1231, file: !1136, line: 128)
!1231 = !DISubprogram(name: "putc", scope: !1139, file: !1139, line: 522, type: !1181, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1232 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1233, file: !1136, line: 129)
!1233 = !DISubprogram(name: "putchar", scope: !1221, file: !1221, line: 82, type: !918, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1234 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1235, file: !1136, line: 130)
!1235 = !DISubprogram(name: "puts", scope: !1139, file: !1139, line: 632, type: !987, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1236 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1237, file: !1136, line: 131)
!1237 = !DISubprogram(name: "remove", scope: !1139, file: !1139, line: 146, type: !987, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1238 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1239, file: !1136, line: 132)
!1239 = !DISubprogram(name: "rename", scope: !1139, file: !1139, line: 148, type: !1240, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1240 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1241)
!1241 = !{!16, !610, !610}
!1242 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1243, file: !1136, line: 133)
!1243 = !DISubprogram(name: "rewind", scope: !1139, file: !1139, line: 694, type: !1145, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1244 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1245, file: !1136, line: 134)
!1245 = !DISubprogram(name: "scanf", linkageName: "__isoc99_scanf", scope: !1139, file: !1139, line: 410, type: !1228, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1246 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1247, file: !1136, line: 135)
!1247 = !DISubprogram(name: "setbuf", scope: !1139, file: !1139, line: 304, type: !1248, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1248 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1249)
!1249 = !{null, !1164, !675}
!1250 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1251, file: !1136, line: 136)
!1251 = !DISubprogram(name: "setvbuf", scope: !1139, file: !1139, line: 308, type: !1252, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1252 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1253)
!1253 = !{!16, !1164, !675, !16, !198}
!1254 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1255, file: !1136, line: 137)
!1255 = !DISubprogram(name: "sprintf", scope: !1139, file: !1139, line: 334, type: !1256, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1256 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1257)
!1257 = !{!16, !675, !609, null}
!1258 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1259, file: !1136, line: 138)
!1259 = !DISubprogram(name: "sscanf", linkageName: "__isoc99_sscanf", scope: !1139, file: !1139, line: 412, type: !1260, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1260 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1261)
!1261 = !{!16, !609, !609, null}
!1262 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1263, file: !1136, line: 139)
!1263 = !DISubprogram(name: "tmpfile", scope: !1139, file: !1139, line: 173, type: !1264, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1264 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1265)
!1265 = !{!1147}
!1266 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1267, file: !1136, line: 141)
!1267 = !DISubprogram(name: "tmpnam", scope: !1139, file: !1139, line: 187, type: !1268, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1268 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1269)
!1269 = !{!524, !524}
!1270 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1271, file: !1136, line: 143)
!1271 = !DISubprogram(name: "ungetc", scope: !1139, file: !1139, line: 639, type: !1181, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1272 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1273, file: !1136, line: 144)
!1273 = !DISubprogram(name: "vfprintf", scope: !1139, file: !1139, line: 341, type: !1274, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1274 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1275)
!1275 = !{!16, !1164, !609, !652}
!1276 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1277, file: !1136, line: 145)
!1277 = !DISubprogram(name: "vprintf", scope: !1221, file: !1221, line: 39, type: !1278, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1278 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1279)
!1279 = !{!16, !609, !652}
!1280 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1281, file: !1136, line: 146)
!1281 = !DISubprogram(name: "vsprintf", scope: !1139, file: !1139, line: 349, type: !1282, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1282 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1283)
!1283 = !{!16, !675, !609, !652}
!1284 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1285, file: !1136, line: 175)
!1285 = !DISubprogram(name: "snprintf", scope: !1139, file: !1139, line: 354, type: !1286, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1286 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1287)
!1287 = !{!16, !675, !198, !609, null}
!1288 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1289, file: !1136, line: 176)
!1289 = !DISubprogram(name: "vfscanf", linkageName: "__isoc99_vfscanf", scope: !1139, file: !1139, line: 451, type: !1274, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1290 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1291, file: !1136, line: 177)
!1291 = !DISubprogram(name: "vscanf", linkageName: "__isoc99_vscanf", scope: !1139, file: !1139, line: 456, type: !1278, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1292 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1293, file: !1136, line: 178)
!1293 = !DISubprogram(name: "vsnprintf", scope: !1139, file: !1139, line: 358, type: !1294, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1294 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1295)
!1295 = !{!16, !675, !198, !609, !652}
!1296 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !5, entity: !1297, file: !1136, line: 179)
!1297 = !DISubprogram(name: "vsscanf", linkageName: "__isoc99_vsscanf", scope: !1139, file: !1139, line: 459, type: !1298, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1298 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1299)
!1299 = !{!16, !609, !609, !652}
!1300 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1285, file: !1136, line: 185)
!1301 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1289, file: !1136, line: 186)
!1302 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1291, file: !1136, line: 187)
!1303 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1293, file: !1136, line: 188)
!1304 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1297, file: !1136, line: 189)
!1305 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1306, file: !1310, line: 82)
!1306 = !DIDerivedType(tag: DW_TAG_typedef, name: "wctrans_t", file: !1307, line: 48, baseType: !1308)
!1307 = !DIFile(filename: "/usr/include/wctype.h", directory: "", checksumkind: CSK_MD5, checksum: "e83097fbf57cc71ea472db59df3ba75d")
!1308 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1309, size: 64, dwarfAddressSpace: 4)
!1309 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !836)
!1310 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cwctype", directory: "", checksumkind: CSK_MD5, checksum: "d81d92891a289d1c51555705eae7f4d6")
!1311 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1312, file: !1310, line: 83)
!1312 = !DIDerivedType(tag: DW_TAG_typedef, name: "wctype_t", file: !1313, line: 38, baseType: !58)
!1313 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/wctype-wchar.h", directory: "", checksumkind: CSK_MD5, checksum: "3598b9d23ef5d76319026b46e316b55f")
!1314 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !505, file: !1310, line: 84)
!1315 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1316, file: !1310, line: 86)
!1316 = !DISubprogram(name: "iswalnum", scope: !1313, file: !1313, line: 95, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1317 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1318, file: !1310, line: 87)
!1318 = !DISubprogram(name: "iswalpha", scope: !1313, file: !1313, line: 101, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1319 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1320, file: !1310, line: 89)
!1320 = !DISubprogram(name: "iswblank", scope: !1313, file: !1313, line: 146, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1321 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1322, file: !1310, line: 91)
!1322 = !DISubprogram(name: "iswcntrl", scope: !1313, file: !1313, line: 104, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1323 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1324, file: !1310, line: 92)
!1324 = !DISubprogram(name: "iswctype", scope: !1313, file: !1313, line: 159, type: !1325, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1325 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1326)
!1326 = !{!16, !505, !1312}
!1327 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1328, file: !1310, line: 93)
!1328 = !DISubprogram(name: "iswdigit", scope: !1313, file: !1313, line: 108, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1329 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1330, file: !1310, line: 94)
!1330 = !DISubprogram(name: "iswgraph", scope: !1313, file: !1313, line: 112, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1331 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1332, file: !1310, line: 95)
!1332 = !DISubprogram(name: "iswlower", scope: !1313, file: !1313, line: 117, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1333 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1334, file: !1310, line: 96)
!1334 = !DISubprogram(name: "iswprint", scope: !1313, file: !1313, line: 120, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1335 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1336, file: !1310, line: 97)
!1336 = !DISubprogram(name: "iswpunct", scope: !1313, file: !1313, line: 125, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1337 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1338, file: !1310, line: 98)
!1338 = !DISubprogram(name: "iswspace", scope: !1313, file: !1313, line: 130, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1339 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1340, file: !1310, line: 99)
!1340 = !DISubprogram(name: "iswupper", scope: !1313, file: !1313, line: 135, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1341 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1342, file: !1310, line: 100)
!1342 = !DISubprogram(name: "iswxdigit", scope: !1313, file: !1313, line: 140, type: !752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1343 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1344, file: !1310, line: 101)
!1344 = !DISubprogram(name: "towctrans", scope: !1307, file: !1307, line: 55, type: !1345, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1345 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1346)
!1346 = !{!505, !505, !1306}
!1347 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1348, file: !1310, line: 102)
!1348 = !DISubprogram(name: "towlower", scope: !1313, file: !1313, line: 166, type: !1349, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1349 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1350)
!1350 = !{!505, !505}
!1351 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1352, file: !1310, line: 103)
!1352 = !DISubprogram(name: "towupper", scope: !1313, file: !1313, line: 169, type: !1349, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1353 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1354, file: !1310, line: 104)
!1354 = !DISubprogram(name: "wctrans", scope: !1307, file: !1307, line: 52, type: !1355, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1355 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1356)
!1356 = !{!1306, !610}
!1357 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1358, file: !1310, line: 105)
!1358 = !DISubprogram(name: "wctype", scope: !1313, file: !1313, line: 155, type: !1359, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1359 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1360)
!1360 = !{!1312, !610}
!1361 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !3, file: !1362, line: 86)
!1362 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/shared_ptr_base.h", directory: "", checksumkind: CSK_MD5, checksum: "1733263deedfa36d980cec211a9e526a")
!1363 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1364, file: !1362, line: 87)
!1364 = !DIGlobalVariable(name: "__default_lock_policy", linkageName: "_ZN9__gnu_cxxL21__default_lock_policyE", scope: !5, file: !4, line: 53, type: !1365, isLocal: true, isDefinition: false)
!1365 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !3)
!1366 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1367, file: !1371, line: 83)
!1367 = !DISubprogram(name: "acos", scope: !1368, file: !1368, line: 53, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1368 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/mathcalls.h", directory: "", checksumkind: CSK_MD5, checksum: "833006f6c08fa0a86f73f7ac7f62dccb")
!1369 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1370)
!1370 = !{!726, !726}
!1371 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cmath", directory: "", checksumkind: CSK_MD5, checksum: "f4b7216422c35b5109134da0340565c8")
!1372 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1373, file: !1371, line: 102)
!1373 = !DISubprogram(name: "asin", scope: !1368, file: !1368, line: 55, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1374 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1375, file: !1371, line: 121)
!1375 = !DISubprogram(name: "atan", scope: !1368, file: !1368, line: 57, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1376 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1377, file: !1371, line: 140)
!1377 = !DISubprogram(name: "atan2", scope: !1368, file: !1368, line: 59, type: !1378, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1378 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1379)
!1379 = !{!726, !726, !726}
!1380 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1381, file: !1371, line: 161)
!1381 = !DISubprogram(name: "ceil", scope: !1368, file: !1368, line: 159, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1382 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1383, file: !1371, line: 180)
!1383 = !DISubprogram(name: "cos", scope: !1368, file: !1368, line: 62, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1384 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1385, file: !1371, line: 199)
!1385 = !DISubprogram(name: "cosh", scope: !1368, file: !1368, line: 71, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1386 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1387, file: !1371, line: 218)
!1387 = !DISubprogram(name: "exp", scope: !1368, file: !1368, line: 95, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1388 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1389, file: !1371, line: 237)
!1389 = !DISubprogram(name: "fabs", scope: !1368, file: !1368, line: 162, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1390 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1391, file: !1371, line: 256)
!1391 = !DISubprogram(name: "floor", scope: !1368, file: !1368, line: 165, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1392 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1393, file: !1371, line: 275)
!1393 = !DISubprogram(name: "fmod", scope: !1368, file: !1368, line: 168, type: !1378, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1394 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1395, file: !1371, line: 296)
!1395 = !DISubprogram(name: "frexp", scope: !1368, file: !1368, line: 98, type: !1396, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1396 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1397)
!1397 = !{!726, !726, !1398}
!1398 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !16, size: 64, dwarfAddressSpace: 4)
!1399 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1400, file: !1371, line: 315)
!1400 = !DISubprogram(name: "ldexp", scope: !1368, file: !1368, line: 101, type: !1401, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1401 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1402)
!1402 = !{!726, !726, !16}
!1403 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1404, file: !1371, line: 334)
!1404 = !DISubprogram(name: "log", scope: !1368, file: !1368, line: 104, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1405 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1406, file: !1371, line: 353)
!1406 = !DISubprogram(name: "log10", scope: !1368, file: !1368, line: 107, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1407 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1408, file: !1371, line: 372)
!1408 = !DISubprogram(name: "modf", scope: !1368, file: !1368, line: 110, type: !1409, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1409 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1410)
!1410 = !{!726, !726, !1411}
!1411 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !726, size: 64, dwarfAddressSpace: 4)
!1412 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1413, file: !1371, line: 384)
!1413 = !DISubprogram(name: "pow", scope: !1368, file: !1368, line: 140, type: !1378, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1414 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1415, file: !1371, line: 421)
!1415 = !DISubprogram(name: "sin", scope: !1368, file: !1368, line: 64, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1416 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1417, file: !1371, line: 440)
!1417 = !DISubprogram(name: "sinh", scope: !1368, file: !1368, line: 73, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1418 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1419, file: !1371, line: 459)
!1419 = !DISubprogram(name: "sqrt", scope: !1368, file: !1368, line: 143, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1420 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1421, file: !1371, line: 478)
!1421 = !DISubprogram(name: "tan", scope: !1368, file: !1368, line: 66, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1422 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1423, file: !1371, line: 497)
!1423 = !DISubprogram(name: "tanh", scope: !1368, file: !1368, line: 75, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1424 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1425, file: !1371, line: 1065)
!1425 = !DIDerivedType(tag: DW_TAG_typedef, name: "double_t", file: !1426, line: 150, baseType: !726)
!1426 = !DIFile(filename: "/usr/include/math.h", directory: "", checksumkind: CSK_MD5, checksum: "2fed8744bf26ef122777e2a4593ca401")
!1427 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1428, file: !1371, line: 1066)
!1428 = !DIDerivedType(tag: DW_TAG_typedef, name: "float_t", file: !1426, line: 149, baseType: !733)
!1429 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1430, file: !1371, line: 1069)
!1430 = !DISubprogram(name: "acosh", scope: !1368, file: !1368, line: 85, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1431 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1432, file: !1371, line: 1070)
!1432 = !DISubprogram(name: "acoshf", scope: !1368, file: !1368, line: 85, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1433 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1434)
!1434 = !{!733, !733}
!1435 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1436, file: !1371, line: 1071)
!1436 = !DISubprogram(name: "acoshl", scope: !1368, file: !1368, line: 85, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1437 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1438)
!1438 = !{!792, !792}
!1439 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1440, file: !1371, line: 1073)
!1440 = !DISubprogram(name: "asinh", scope: !1368, file: !1368, line: 87, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1441 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1442, file: !1371, line: 1074)
!1442 = !DISubprogram(name: "asinhf", scope: !1368, file: !1368, line: 87, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1443 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1444, file: !1371, line: 1075)
!1444 = !DISubprogram(name: "asinhl", scope: !1368, file: !1368, line: 87, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1445 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1446, file: !1371, line: 1077)
!1446 = !DISubprogram(name: "atanh", scope: !1368, file: !1368, line: 89, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1447 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1448, file: !1371, line: 1078)
!1448 = !DISubprogram(name: "atanhf", scope: !1368, file: !1368, line: 89, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1449 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1450, file: !1371, line: 1079)
!1450 = !DISubprogram(name: "atanhl", scope: !1368, file: !1368, line: 89, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1451 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1452, file: !1371, line: 1081)
!1452 = !DISubprogram(name: "cbrt", scope: !1368, file: !1368, line: 152, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1453 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1454, file: !1371, line: 1082)
!1454 = !DISubprogram(name: "cbrtf", scope: !1368, file: !1368, line: 152, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1455 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1456, file: !1371, line: 1083)
!1456 = !DISubprogram(name: "cbrtl", scope: !1368, file: !1368, line: 152, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1457 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1458, file: !1371, line: 1085)
!1458 = !DISubprogram(name: "copysign", scope: !1368, file: !1368, line: 196, type: !1378, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1459 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1460, file: !1371, line: 1086)
!1460 = !DISubprogram(name: "copysignf", scope: !1368, file: !1368, line: 196, type: !1461, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1461 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1462)
!1462 = !{!733, !733, !733}
!1463 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1464, file: !1371, line: 1087)
!1464 = !DISubprogram(name: "copysignl", scope: !1368, file: !1368, line: 196, type: !1465, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1465 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1466)
!1466 = !{!792, !792, !792}
!1467 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1468, file: !1371, line: 1089)
!1468 = !DISubprogram(name: "erf", scope: !1368, file: !1368, line: 228, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1469 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1470, file: !1371, line: 1090)
!1470 = !DISubprogram(name: "erff", scope: !1368, file: !1368, line: 228, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1471 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1472, file: !1371, line: 1091)
!1472 = !DISubprogram(name: "erfl", scope: !1368, file: !1368, line: 228, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1473 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1474, file: !1371, line: 1093)
!1474 = !DISubprogram(name: "erfc", scope: !1368, file: !1368, line: 229, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1475 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1476, file: !1371, line: 1094)
!1476 = !DISubprogram(name: "erfcf", scope: !1368, file: !1368, line: 229, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1477 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1478, file: !1371, line: 1095)
!1478 = !DISubprogram(name: "erfcl", scope: !1368, file: !1368, line: 229, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1479 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1480, file: !1371, line: 1097)
!1480 = !DISubprogram(name: "exp2", scope: !1368, file: !1368, line: 130, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1481 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1482, file: !1371, line: 1098)
!1482 = !DISubprogram(name: "exp2f", scope: !1368, file: !1368, line: 130, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1483 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1484, file: !1371, line: 1099)
!1484 = !DISubprogram(name: "exp2l", scope: !1368, file: !1368, line: 130, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1485 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1486, file: !1371, line: 1101)
!1486 = !DISubprogram(name: "expm1", scope: !1368, file: !1368, line: 119, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1487 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1488, file: !1371, line: 1102)
!1488 = !DISubprogram(name: "expm1f", scope: !1368, file: !1368, line: 119, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1489 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1490, file: !1371, line: 1103)
!1490 = !DISubprogram(name: "expm1l", scope: !1368, file: !1368, line: 119, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1491 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1492, file: !1371, line: 1105)
!1492 = !DISubprogram(name: "fdim", scope: !1368, file: !1368, line: 326, type: !1378, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1493 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1494, file: !1371, line: 1106)
!1494 = !DISubprogram(name: "fdimf", scope: !1368, file: !1368, line: 326, type: !1461, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1495 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1496, file: !1371, line: 1107)
!1496 = !DISubprogram(name: "fdiml", scope: !1368, file: !1368, line: 326, type: !1465, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1497 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1498, file: !1371, line: 1109)
!1498 = !DISubprogram(name: "fma", scope: !1368, file: !1368, line: 335, type: !1499, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1499 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1500)
!1500 = !{!726, !726, !726, !726}
!1501 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1502, file: !1371, line: 1110)
!1502 = !DISubprogram(name: "fmaf", scope: !1368, file: !1368, line: 335, type: !1503, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1503 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1504)
!1504 = !{!733, !733, !733, !733}
!1505 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1506, file: !1371, line: 1111)
!1506 = !DISubprogram(name: "fmal", scope: !1368, file: !1368, line: 335, type: !1507, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1507 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1508)
!1508 = !{!792, !792, !792, !792}
!1509 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1510, file: !1371, line: 1113)
!1510 = !DISubprogram(name: "fmax", scope: !1368, file: !1368, line: 329, type: !1378, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1511 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1512, file: !1371, line: 1114)
!1512 = !DISubprogram(name: "fmaxf", scope: !1368, file: !1368, line: 329, type: !1461, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1513 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1514, file: !1371, line: 1115)
!1514 = !DISubprogram(name: "fmaxl", scope: !1368, file: !1368, line: 329, type: !1465, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1515 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1516, file: !1371, line: 1117)
!1516 = !DISubprogram(name: "fmin", scope: !1368, file: !1368, line: 332, type: !1378, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1517 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1518, file: !1371, line: 1118)
!1518 = !DISubprogram(name: "fminf", scope: !1368, file: !1368, line: 332, type: !1461, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1519 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1520, file: !1371, line: 1119)
!1520 = !DISubprogram(name: "fminl", scope: !1368, file: !1368, line: 332, type: !1465, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1521 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1522, file: !1371, line: 1121)
!1522 = !DISubprogram(name: "hypot", scope: !1368, file: !1368, line: 147, type: !1378, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1523 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1524, file: !1371, line: 1122)
!1524 = !DISubprogram(name: "hypotf", scope: !1368, file: !1368, line: 147, type: !1461, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1525 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1526, file: !1371, line: 1123)
!1526 = !DISubprogram(name: "hypotl", scope: !1368, file: !1368, line: 147, type: !1465, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1527 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1528, file: !1371, line: 1125)
!1528 = !DISubprogram(name: "ilogb", scope: !1368, file: !1368, line: 280, type: !1529, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1529 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1530)
!1530 = !{!16, !726}
!1531 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1532, file: !1371, line: 1126)
!1532 = !DISubprogram(name: "ilogbf", scope: !1368, file: !1368, line: 280, type: !1533, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1533 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1534)
!1534 = !{!16, !733}
!1535 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1536, file: !1371, line: 1127)
!1536 = !DISubprogram(name: "ilogbl", scope: !1368, file: !1368, line: 280, type: !1537, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1537 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1538)
!1538 = !{!16, !792}
!1539 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1540, file: !1371, line: 1129)
!1540 = !DISubprogram(name: "lgamma", scope: !1368, file: !1368, line: 230, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1541 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1542, file: !1371, line: 1130)
!1542 = !DISubprogram(name: "lgammaf", scope: !1368, file: !1368, line: 230, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1543 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1544, file: !1371, line: 1131)
!1544 = !DISubprogram(name: "lgammal", scope: !1368, file: !1368, line: 230, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1545 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1546, file: !1371, line: 1134)
!1546 = !DISubprogram(name: "llrint", scope: !1368, file: !1368, line: 316, type: !1547, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1547 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1548)
!1548 = !{!797, !726}
!1549 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1550, file: !1371, line: 1135)
!1550 = !DISubprogram(name: "llrintf", scope: !1368, file: !1368, line: 316, type: !1551, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1551 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1552)
!1552 = !{!797, !733}
!1553 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1554, file: !1371, line: 1136)
!1554 = !DISubprogram(name: "llrintl", scope: !1368, file: !1368, line: 316, type: !1555, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1555 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1556)
!1556 = !{!797, !792}
!1557 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1558, file: !1371, line: 1138)
!1558 = !DISubprogram(name: "llround", scope: !1368, file: !1368, line: 322, type: !1547, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1559 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1560, file: !1371, line: 1139)
!1560 = !DISubprogram(name: "llroundf", scope: !1368, file: !1368, line: 322, type: !1551, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1561 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1562, file: !1371, line: 1140)
!1562 = !DISubprogram(name: "llroundl", scope: !1368, file: !1368, line: 322, type: !1555, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1563 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1564, file: !1371, line: 1143)
!1564 = !DISubprogram(name: "log1p", scope: !1368, file: !1368, line: 122, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1565 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1566, file: !1371, line: 1144)
!1566 = !DISubprogram(name: "log1pf", scope: !1368, file: !1368, line: 122, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1567 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1568, file: !1371, line: 1145)
!1568 = !DISubprogram(name: "log1pl", scope: !1368, file: !1368, line: 122, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1569 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1570, file: !1371, line: 1147)
!1570 = !DISubprogram(name: "log2", scope: !1368, file: !1368, line: 133, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1571 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1572, file: !1371, line: 1148)
!1572 = !DISubprogram(name: "log2f", scope: !1368, file: !1368, line: 133, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1573 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1574, file: !1371, line: 1149)
!1574 = !DISubprogram(name: "log2l", scope: !1368, file: !1368, line: 133, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1575 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1576, file: !1371, line: 1151)
!1576 = !DISubprogram(name: "logb", scope: !1368, file: !1368, line: 125, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1577 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1578, file: !1371, line: 1152)
!1578 = !DISubprogram(name: "logbf", scope: !1368, file: !1368, line: 125, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1579 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1580, file: !1371, line: 1153)
!1580 = !DISubprogram(name: "logbl", scope: !1368, file: !1368, line: 125, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1581 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1582, file: !1371, line: 1155)
!1582 = !DISubprogram(name: "lrint", scope: !1368, file: !1368, line: 314, type: !1583, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1583 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1584)
!1584 = !{!544, !726}
!1585 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1586, file: !1371, line: 1156)
!1586 = !DISubprogram(name: "lrintf", scope: !1368, file: !1368, line: 314, type: !1587, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1587 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1588)
!1588 = !{!544, !733}
!1589 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1590, file: !1371, line: 1157)
!1590 = !DISubprogram(name: "lrintl", scope: !1368, file: !1368, line: 314, type: !1591, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1591 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1592)
!1592 = !{!544, !792}
!1593 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1594, file: !1371, line: 1159)
!1594 = !DISubprogram(name: "lround", scope: !1368, file: !1368, line: 320, type: !1583, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1595 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1596, file: !1371, line: 1160)
!1596 = !DISubprogram(name: "lroundf", scope: !1368, file: !1368, line: 320, type: !1587, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1597 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1598, file: !1371, line: 1161)
!1598 = !DISubprogram(name: "lroundl", scope: !1368, file: !1368, line: 320, type: !1591, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1599 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1600, file: !1371, line: 1163)
!1600 = !DISubprogram(name: "nan", scope: !1368, file: !1368, line: 201, type: !983, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1601 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1602, file: !1371, line: 1164)
!1602 = !DISubprogram(name: "nanf", scope: !1368, file: !1368, line: 201, type: !1603, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1603 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1604)
!1604 = !{!733, !610}
!1605 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1606, file: !1371, line: 1165)
!1606 = !DISubprogram(name: "nanl", scope: !1368, file: !1368, line: 201, type: !1607, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1607 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1608)
!1608 = !{!792, !610}
!1609 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1610, file: !1371, line: 1167)
!1610 = !DISubprogram(name: "nearbyint", scope: !1368, file: !1368, line: 294, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1611 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1612, file: !1371, line: 1168)
!1612 = !DISubprogram(name: "nearbyintf", scope: !1368, file: !1368, line: 294, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1613 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1614, file: !1371, line: 1169)
!1614 = !DISubprogram(name: "nearbyintl", scope: !1368, file: !1368, line: 294, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1615 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1616, file: !1371, line: 1171)
!1616 = !DISubprogram(name: "nextafter", scope: !1368, file: !1368, line: 259, type: !1378, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1617 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1618, file: !1371, line: 1172)
!1618 = !DISubprogram(name: "nextafterf", scope: !1368, file: !1368, line: 259, type: !1461, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1619 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1620, file: !1371, line: 1173)
!1620 = !DISubprogram(name: "nextafterl", scope: !1368, file: !1368, line: 259, type: !1465, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1621 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1622, file: !1371, line: 1175)
!1622 = !DISubprogram(name: "nexttoward", scope: !1368, file: !1368, line: 261, type: !1623, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1623 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1624)
!1624 = !{!726, !726, !792}
!1625 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1626, file: !1371, line: 1176)
!1626 = !DISubprogram(name: "nexttowardf", scope: !1368, file: !1368, line: 261, type: !1627, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1627 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1628)
!1628 = !{!733, !733, !792}
!1629 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1630, file: !1371, line: 1177)
!1630 = !DISubprogram(name: "nexttowardl", scope: !1368, file: !1368, line: 261, type: !1465, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1631 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1632, file: !1371, line: 1179)
!1632 = !DISubprogram(name: "remainder", scope: !1368, file: !1368, line: 272, type: !1378, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1633 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1634, file: !1371, line: 1180)
!1634 = !DISubprogram(name: "remainderf", scope: !1368, file: !1368, line: 272, type: !1461, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1635 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1636, file: !1371, line: 1181)
!1636 = !DISubprogram(name: "remainderl", scope: !1368, file: !1368, line: 272, type: !1465, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1637 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1638, file: !1371, line: 1183)
!1638 = !DISubprogram(name: "remquo", scope: !1368, file: !1368, line: 307, type: !1639, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1639 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1640)
!1640 = !{!726, !726, !726, !1398}
!1641 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1642, file: !1371, line: 1184)
!1642 = !DISubprogram(name: "remquof", scope: !1368, file: !1368, line: 307, type: !1643, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1643 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1644)
!1644 = !{!733, !733, !733, !1398}
!1645 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1646, file: !1371, line: 1185)
!1646 = !DISubprogram(name: "remquol", scope: !1368, file: !1368, line: 307, type: !1647, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1647 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1648)
!1648 = !{!792, !792, !792, !1398}
!1649 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1650, file: !1371, line: 1187)
!1650 = !DISubprogram(name: "rint", scope: !1368, file: !1368, line: 256, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1651 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1652, file: !1371, line: 1188)
!1652 = !DISubprogram(name: "rintf", scope: !1368, file: !1368, line: 256, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1653 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1654, file: !1371, line: 1189)
!1654 = !DISubprogram(name: "rintl", scope: !1368, file: !1368, line: 256, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1655 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1656, file: !1371, line: 1191)
!1656 = !DISubprogram(name: "round", scope: !1368, file: !1368, line: 298, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1657 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1658, file: !1371, line: 1192)
!1658 = !DISubprogram(name: "roundf", scope: !1368, file: !1368, line: 298, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1659 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1660, file: !1371, line: 1193)
!1660 = !DISubprogram(name: "roundl", scope: !1368, file: !1368, line: 298, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1661 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1662, file: !1371, line: 1195)
!1662 = !DISubprogram(name: "scalbln", scope: !1368, file: !1368, line: 290, type: !1663, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1663 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1664)
!1664 = !{!726, !726, !544}
!1665 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1666, file: !1371, line: 1196)
!1666 = !DISubprogram(name: "scalblnf", scope: !1368, file: !1368, line: 290, type: !1667, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1667 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1668)
!1668 = !{!733, !733, !544}
!1669 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1670, file: !1371, line: 1197)
!1670 = !DISubprogram(name: "scalblnl", scope: !1368, file: !1368, line: 290, type: !1671, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1671 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1672)
!1672 = !{!792, !792, !544}
!1673 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1674, file: !1371, line: 1199)
!1674 = !DISubprogram(name: "scalbn", scope: !1368, file: !1368, line: 276, type: !1401, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1675 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1676, file: !1371, line: 1200)
!1676 = !DISubprogram(name: "scalbnf", scope: !1368, file: !1368, line: 276, type: !1677, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1677 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1678)
!1678 = !{!733, !733, !16}
!1679 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1680, file: !1371, line: 1201)
!1680 = !DISubprogram(name: "scalbnl", scope: !1368, file: !1368, line: 276, type: !1681, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1681 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1682)
!1682 = !{!792, !792, !16}
!1683 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1684, file: !1371, line: 1203)
!1684 = !DISubprogram(name: "tgamma", scope: !1368, file: !1368, line: 235, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1685 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1686, file: !1371, line: 1204)
!1686 = !DISubprogram(name: "tgammaf", scope: !1368, file: !1368, line: 235, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1687 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1688, file: !1371, line: 1205)
!1688 = !DISubprogram(name: "tgammal", scope: !1368, file: !1368, line: 235, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1689 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1690, file: !1371, line: 1207)
!1690 = !DISubprogram(name: "trunc", scope: !1368, file: !1368, line: 302, type: !1369, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1691 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1692, file: !1371, line: 1208)
!1692 = !DISubprogram(name: "truncf", scope: !1368, file: !1368, line: 302, type: !1433, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1693 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1694, file: !1371, line: 1209)
!1694 = !DISubprogram(name: "truncl", scope: !1368, file: !1368, line: 302, type: !1437, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1695 = !DIImportedEntity(tag: DW_TAG_imported_declaration, name: "RT", scope: !155, entity: !1696, file: !1697, line: 242)
!1696 = !DINamespace(name: "pi", scope: !155)
!1697 = !DIFile(filename: "/build/bin/../include/sycl/detail/pi.hpp", directory: "", checksumkind: CSK_MD5, checksum: "c034c18e60356cce31e4657d1e4b44d6")
!1698 = !DIImportedEntity(tag: DW_TAG_imported_declaration, name: "RT", scope: !14, entity: !1696, file: !1697, line: 277)
!1699 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !966, file: !1700, line: 38)
!1700 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/stdlib.h", directory: "", checksumkind: CSK_MD5, checksum: "4cd0241d66f1b357b386fcd60bc71b0f")
!1701 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !974, file: !1700, line: 39)
!1702 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1011, file: !1700, line: 40)
!1703 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !979, file: !1700, line: 43)
!1704 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1051, file: !1700, line: 46)
!1705 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !956, file: !1700, line: 51)
!1706 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !960, file: !1700, line: 52)
!1707 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !981, file: !1700, line: 55)
!1708 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !986, file: !1700, line: 56)
!1709 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !990, file: !1700, line: 57)
!1710 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !994, file: !1700, line: 58)
!1711 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1005, file: !1700, line: 59)
!1712 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1126, file: !1700, line: 60)
!1713 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1015, file: !1700, line: 61)
!1714 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1019, file: !1700, line: 62)
!1715 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1023, file: !1700, line: 63)
!1716 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1027, file: !1700, line: 64)
!1717 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1031, file: !1700, line: 65)
!1718 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1035, file: !1700, line: 67)
!1719 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1039, file: !1700, line: 68)
!1720 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1043, file: !1700, line: 69)
!1721 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1047, file: !1700, line: 71)
!1722 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1053, file: !1700, line: 72)
!1723 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1055, file: !1700, line: 73)
!1724 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1059, file: !1700, line: 74)
!1725 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1063, file: !1700, line: 75)
!1726 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1069, file: !1700, line: 76)
!1727 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1073, file: !1700, line: 77)
!1728 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1077, file: !1700, line: 78)
!1729 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1079, file: !1700, line: 80)
!1730 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !0, entity: !1083, file: !1700, line: 81)
!1731 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1732, file: !1735, line: 60)
!1732 = !DIDerivedType(tag: DW_TAG_typedef, name: "clock_t", file: !1733, line: 7, baseType: !1734)
!1733 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/clock_t.h", directory: "", checksumkind: CSK_MD5, checksum: "1aade99fd778d1551600c7ca1410b9f1")
!1734 = !DIDerivedType(tag: DW_TAG_typedef, name: "__clock_t", file: !360, line: 156, baseType: !544)
!1735 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/ctime", directory: "", checksumkind: CSK_MD5, checksum: "a010c62132c7dd12d48143f4244be2b8")
!1736 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1737, file: !1735, line: 61)
!1737 = !DIDerivedType(tag: DW_TAG_typedef, name: "time_t", file: !1738, line: 7, baseType: !1739)
!1738 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/time_t.h", directory: "", checksumkind: CSK_MD5, checksum: "49b4e16ef1215de5afdbb283400ab90c")
!1739 = !DIDerivedType(tag: DW_TAG_typedef, name: "__time_t", file: !360, line: 160, baseType: !544)
!1740 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !699, file: !1735, line: 62)
!1741 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1742, file: !1735, line: 64)
!1742 = !DISubprogram(name: "clock", scope: !1743, file: !1743, line: 72, type: !1744, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1743 = !DIFile(filename: "/usr/include/time.h", directory: "", checksumkind: CSK_MD5, checksum: "2dc9fb937b28c900f98919b5c35320c2")
!1744 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1745)
!1745 = !{!1732}
!1746 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1747, file: !1735, line: 65)
!1747 = !DISubprogram(name: "difftime", scope: !1743, file: !1743, line: 78, type: !1748, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1748 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1749)
!1749 = !{!726, !1737, !1737}
!1750 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1751, file: !1735, line: 66)
!1751 = !DISubprogram(name: "mktime", scope: !1743, file: !1743, line: 82, type: !1752, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1752 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1753)
!1753 = !{!1737, !1754}
!1754 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !699, size: 64, dwarfAddressSpace: 4)
!1755 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1756, file: !1735, line: 67)
!1756 = !DISubprogram(name: "time", scope: !1743, file: !1743, line: 75, type: !1757, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1757 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1758)
!1758 = !{!1737, !1759}
!1759 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1737, size: 64, dwarfAddressSpace: 4)
!1760 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1761, file: !1735, line: 68)
!1761 = !DISubprogram(name: "asctime", scope: !1743, file: !1743, line: 139, type: !1762, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1762 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1763)
!1763 = !{!524, !697}
!1764 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1765, file: !1735, line: 69)
!1765 = !DISubprogram(name: "ctime", scope: !1743, file: !1743, line: 142, type: !1766, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1766 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1767)
!1767 = !{!524, !1768}
!1768 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1769, size: 64, dwarfAddressSpace: 4)
!1769 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !1737)
!1770 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1771, file: !1735, line: 70)
!1771 = !DISubprogram(name: "gmtime", scope: !1743, file: !1743, line: 119, type: !1772, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1772 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1773)
!1773 = !{!1754, !1768}
!1774 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1775, file: !1735, line: 71)
!1775 = !DISubprogram(name: "localtime", scope: !1743, file: !1743, line: 123, type: !1772, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1776 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1777, file: !1735, line: 72)
!1777 = !DISubprogram(name: "strftime", scope: !1743, file: !1743, line: 88, type: !1778, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1778 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1779)
!1779 = !{!198, !675, !198, !609, !696}
!1780 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1781, file: !1735, line: 79)
!1781 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "timespec", file: !1782, line: 10, size: 128, flags: DIFlagTypePassByValue, elements: !1783, identifier: "_ZTS8timespec")
!1782 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/struct_timespec.h", directory: "", checksumkind: CSK_MD5, checksum: "33f28095c70788baa6982a79b13f774b")
!1783 = !{!1784, !1785}
!1784 = !DIDerivedType(tag: DW_TAG_member, name: "tv_sec", scope: !1781, file: !1782, line: 12, baseType: !1739, size: 64)
!1785 = !DIDerivedType(tag: DW_TAG_member, name: "tv_nsec", scope: !1781, file: !1782, line: 16, baseType: !1786, size: 64, offset: 64)
!1786 = !DIDerivedType(tag: DW_TAG_typedef, name: "__syscall_slong_t", file: !360, line: 196, baseType: !544)
!1787 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1788, file: !1735, line: 80)
!1788 = !DISubprogram(name: "timespec_get", scope: !1743, file: !1743, line: 257, type: !1789, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1789 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1790)
!1790 = !{!16, !1791, !16}
!1791 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1781, size: 64, dwarfAddressSpace: 4)
!1792 = !DIImportedEntity(tag: DW_TAG_imported_module, scope: !1793, entity: !1794, file: !1796, line: 973)
!1793 = !DINamespace(name: "chrono", scope: !44)
!1794 = !DINamespace(name: "chrono_literals", scope: !1795, exportSymbols: true)
!1795 = !DINamespace(name: "literals", scope: !44, exportSymbols: true)
!1796 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/chrono", directory: "", checksumkind: CSK_MD5, checksum: "4d877d308571c97c6dd4c566beabe528")
!1797 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !14, entity: !11, file: !12, line: 62)
!1798 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1799, file: !1803, line: 77)
!1799 = !DISubprogram(name: "memchr", scope: !1800, file: !1800, line: 84, type: !1801, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1800 = !DIFile(filename: "/usr/include/string.h", directory: "", checksumkind: CSK_MD5, checksum: "61f60112cf5c0a45c54ea1f595add24c")
!1801 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1802)
!1802 = !{!998, !998, !16, !198}
!1803 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cstring", directory: "", checksumkind: CSK_MD5, checksum: "987c0ccd0b58c1cdd2158b81703ef20a")
!1804 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1805, file: !1803, line: 78)
!1805 = !DISubprogram(name: "memcmp", scope: !1800, file: !1800, line: 64, type: !1806, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1806 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1807)
!1807 = !{!16, !998, !998, !198}
!1808 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1809, file: !1803, line: 79)
!1809 = !DISubprogram(name: "memcpy", scope: !1800, file: !1800, line: 43, type: !1810, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1810 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1811)
!1811 = !{!563, !1191, !1216, !198}
!1812 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1813, file: !1803, line: 80)
!1813 = !DISubprogram(name: "memmove", scope: !1800, file: !1800, line: 47, type: !1814, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1814 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1815)
!1815 = !{!563, !563, !998, !198}
!1816 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1817, file: !1803, line: 81)
!1817 = !DISubprogram(name: "memset", scope: !1800, file: !1800, line: 61, type: !1818, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1818 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1819)
!1819 = !{!563, !563, !16, !198}
!1820 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1821, file: !1803, line: 82)
!1821 = !DISubprogram(name: "strcat", scope: !1800, file: !1800, line: 130, type: !1822, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1822 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1823)
!1823 = !{!524, !675, !609}
!1824 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1825, file: !1803, line: 83)
!1825 = !DISubprogram(name: "strcmp", scope: !1800, file: !1800, line: 137, type: !1240, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1826 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1827, file: !1803, line: 84)
!1827 = !DISubprogram(name: "strcoll", scope: !1800, file: !1800, line: 144, type: !1240, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1828 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1829, file: !1803, line: 85)
!1829 = !DISubprogram(name: "strcpy", scope: !1800, file: !1800, line: 122, type: !1822, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1830 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1831, file: !1803, line: 86)
!1831 = !DISubprogram(name: "strcspn", scope: !1800, file: !1800, line: 273, type: !1832, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1832 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1833)
!1833 = !{!198, !610, !610}
!1834 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1835, file: !1803, line: 87)
!1835 = !DISubprogram(name: "strerror", scope: !1800, file: !1800, line: 397, type: !1836, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1836 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1837)
!1837 = !{!524, !16}
!1838 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1839, file: !1803, line: 88)
!1839 = !DISubprogram(name: "strlen", scope: !1800, file: !1800, line: 385, type: !1840, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1840 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1841)
!1841 = !{!198, !610}
!1842 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1843, file: !1803, line: 89)
!1843 = !DISubprogram(name: "strncat", scope: !1800, file: !1800, line: 133, type: !1844, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1844 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1845)
!1845 = !{!524, !675, !609, !198}
!1846 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1847, file: !1803, line: 90)
!1847 = !DISubprogram(name: "strncmp", scope: !1800, file: !1800, line: 140, type: !1848, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1848 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1849)
!1849 = !{!16, !610, !610, !198}
!1850 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1851, file: !1803, line: 91)
!1851 = !DISubprogram(name: "strncpy", scope: !1800, file: !1800, line: 125, type: !1844, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1852 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1853, file: !1803, line: 92)
!1853 = !DISubprogram(name: "strspn", scope: !1800, file: !1800, line: 277, type: !1832, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1854 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1855, file: !1803, line: 93)
!1855 = !DISubprogram(name: "strtok", scope: !1800, file: !1800, line: 336, type: !1822, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1856 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1857, file: !1803, line: 94)
!1857 = !DISubprogram(name: "strxfrm", scope: !1800, file: !1800, line: 147, type: !1858, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1858 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1859)
!1859 = !{!198, !675, !609, !198}
!1860 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1861, file: !1803, line: 95)
!1861 = !DISubprogram(name: "strchr", scope: !1800, file: !1800, line: 219, type: !1862, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1862 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1863)
!1863 = !{!610, !610, !16}
!1864 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1865, file: !1803, line: 96)
!1865 = !DISubprogram(name: "strpbrk", scope: !1800, file: !1800, line: 296, type: !1866, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1866 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1867)
!1867 = !{!610, !610, !610}
!1868 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1869, file: !1803, line: 97)
!1869 = !DISubprogram(name: "strrchr", scope: !1800, file: !1800, line: 246, type: !1862, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1870 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1871, file: !1803, line: 98)
!1871 = !DISubprogram(name: "strstr", scope: !1800, file: !1800, line: 323, type: !1866, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1872 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !14, entity: !338, file: !1873, line: 16)
!1873 = !DIFile(filename: "/build/bin/../include/sycl/sub_group.hpp", directory: "", checksumkind: CSK_MD5, checksum: "85a8d9c458ca7e42e41aba8186983daf")
!1874 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !1875, file: !1877, line: 285)
!1875 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "queue_impl", scope: !155, file: !1876, line: 25, flags: DIFlagFwdDecl | DIFlagNonTrivial, identifier: "_ZTSN4sycl3_V16detail10queue_implE")
!1876 = !DIFile(filename: "/build/bin/../include/sycl/exception_list.hpp", directory: "", checksumkind: CSK_MD5, checksum: "d662de53901fb27dfcff1e53b7ad0dbd")
!1877 = !DIFile(filename: "/build/bin/../include/sycl/handler.hpp", directory: "", checksumkind: CSK_MD5, checksum: "8a44c2a9025b21389a8bdb20a78333f5")
!1878 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1879, file: !1882, line: 58)
!1879 = !DIDerivedType(tag: DW_TAG_typedef, name: "imaxdiv_t", file: !1880, line: 275, baseType: !1881)
!1880 = !DIFile(filename: "/usr/include/inttypes.h", directory: "", checksumkind: CSK_MD5, checksum: "a8351e0854e4f68bd930332ed3311c02")
!1881 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !1880, line: 271, size: 128, flags: DIFlagFwdDecl, identifier: "_ZTS9imaxdiv_t")
!1882 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cinttypes", directory: "", checksumkind: CSK_MD5, checksum: "6d45471be6574aa600037bad6d05eb99")
!1883 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1884, file: !1882, line: 61)
!1884 = !DISubprogram(name: "imaxabs", scope: !1880, file: !1880, line: 290, type: !1885, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1885 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1886)
!1886 = !{!862, !862}
!1887 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1888, file: !1882, line: 62)
!1888 = !DISubprogram(name: "imaxdiv", scope: !1880, file: !1880, line: 293, type: !1889, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1889 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1890)
!1890 = !{!1879, !862, !862}
!1891 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1892, file: !1882, line: 68)
!1892 = !DISubprogram(name: "strtoimax", scope: !1880, file: !1880, line: 324, type: !1893, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1893 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1894)
!1894 = !{!862, !609, !1066, !16}
!1895 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1896, file: !1882, line: 69)
!1896 = !DISubprogram(name: "strtoumax", scope: !1880, file: !1880, line: 336, type: !1897, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1897 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1898)
!1898 = !{!898, !609, !1066, !16}
!1899 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1900, file: !1882, line: 72)
!1900 = !DISubprogram(name: "wcstoimax", scope: !1880, file: !1880, line: 348, type: !1901, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1901 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1902)
!1902 = !{!862, !586, !727, !16}
!1903 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !44, entity: !1904, file: !1882, line: 73)
!1904 = !DISubprogram(name: "wcstoumax", scope: !1880, file: !1880, line: 362, type: !1905, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1905 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1906)
!1906 = !{!898, !586, !727, !16}
!1907 = !DIImportedEntity(tag: DW_TAG_imported_module, scope: !1908, entity: !1909, file: !1910, line: 1102)
!1908 = !DINamespace(name: "intel", scope: !14)
!1909 = !DINamespace(name: "intel", scope: !341)
!1910 = !DIFile(filename: "/build/bin/../include/sycl/builtins.hpp", directory: "", checksumkind: CSK_MD5, checksum: "895f7ae6f2e421fbb0a1f871cfe69f88")
!1911 = !DIImportedEntity(tag: DW_TAG_imported_module, scope: !1912, entity: !155, file: !1913, line: 30)
!1912 = !DINamespace(name: "detail", scope: !340)
!1913 = !DIFile(filename: "/build/bin/../include/sycl/ext/oneapi/atomic_ref.hpp", directory: "", checksumkind: CSK_MD5, checksum: "5f6e90ec3f39204aed43e9e0b256765f")
!1914 = !DIImportedEntity(tag: DW_TAG_imported_module, scope: !1912, entity: !155, file: !1915, line: 23)
!1915 = !DIFile(filename: "/build/bin/../include/sycl/ext/oneapi/atomic_fence.hpp", directory: "", checksumkind: CSK_MD5, checksum: "ccd540e3f5975925b1d7d4c17f85493b")
!1916 = !DIImportedEntity(tag: DW_TAG_imported_module, scope: !1917, entity: !1918, file: !1919, line: 203)
!1917 = !DINamespace(name: "level_zero", scope: !14)
!1918 = !DINamespace(name: "level_zero", scope: !340)
!1919 = !DIFile(filename: "/build/bin/../include/sycl/ext/oneapi/backend/level_zero.hpp", directory: "", checksumkind: CSK_MD5, checksum: "246e8f4d910f77024797834bc765de1f")
!1920 = !{i32 1, i32 2}
!1921 = !{i32 4, i32 100000}
!1922 = !{!"cpu", i32 1}
!1923 = !{!"gpu", i32 2}
!1924 = !{!"accelerator", i32 3}
!1925 = !{!"custom", i32 4}
!1926 = !{!"fp16", i32 5}
!1927 = !{!"fp64", i32 6}
!1928 = !{!"image", i32 9}
!1929 = !{!"online_compiler", i32 10}
!1930 = !{!"online_linker", i32 11}
!1931 = !{!"queue_profiling", i32 12}
!1932 = !{!"usm_device_allocations", i32 13}
!1933 = !{!"usm_host_allocations", i32 14}
!1934 = !{!"usm_shared_allocations", i32 15}
!1935 = !{!"usm_system_allocations", i32 17}
!1936 = !{!"ext_intel_pci_address", i32 18}
!1937 = !{!"ext_intel_gpu_eu_count", i32 19}
!1938 = !{!"ext_intel_gpu_eu_simd_width", i32 20}
!1939 = !{!"ext_intel_gpu_slices", i32 21}
!1940 = !{!"ext_intel_gpu_subslices_per_slice", i32 22}
!1941 = !{!"ext_intel_gpu_eu_count_per_subslice", i32 23}
!1942 = !{!"ext_intel_max_mem_bandwidth", i32 24}
!1943 = !{!"ext_intel_mem_channel", i32 25}
!1944 = !{!"usm_atomic_host_allocations", i32 26}
!1945 = !{!"usm_atomic_shared_allocations", i32 27}
!1946 = !{!"atomic64", i32 28}
!1947 = !{!"ext_intel_device_info_uuid", i32 29}
!1948 = !{!"ext_oneapi_srgb", i32 30}
!1949 = !{!"ext_oneapi_native_assert", i32 31}
!1950 = !{!"host_debuggable", i32 32}
!1951 = !{!"ext_intel_gpu_hw_threads_per_eu", i32 33}
!1952 = !{!"ext_oneapi_cuda_async_barrier", i32 34}
!1953 = !{!"ext_oneapi_bfloat16_math_functions", i32 35}
!1954 = !{!"ext_intel_free_memory", i32 36}
!1955 = !{!"ext_intel_device_id", i32 37}
!1956 = !{!"ext_intel_memory_clock_rate", i32 38}
!1957 = !{!"ext_intel_memory_bus_width", i32 39}
!1958 = !{!"emulated", i32 40}
!1959 = !{!"int64_base_atomics", i32 7}
!1960 = !{!"int64_extended_atomics", i32 8}
!1961 = !{!"usm_system_allocator", i32 17}
!1962 = !{!"usm_restricted_shared_allocations", i32 16}
!1963 = !{!"host", i32 0}
!1964 = !{!"clang version 17.0.0 (https://github.com/intel/llvm 98b7de88a7d9e99e55ef7e2bd2486fe0028cfaae)"}
!1965 = !{i32 7, !"Dwarf Version", i32 5}
!1966 = !{i32 2, !"Debug Info Version", i32 3}
!1967 = !{i32 1, !"wchar_size", i32 4}
!1968 = !{i32 7, !"frame-pointer", i32 2}
!1969 = distinct !DISubprogram(name: "_ZTSZZ4mainENKUlRN4sycl3_V17handlerEE_clES2_E35MIXED_VEC_CONSTRUCTOR_KERNEL_bool16", scope: !1, file: !1, line: 169, type: !1970, flags: DIFlagArtificial | DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !1971)
!1970 = !DISubroutineType(cc: DW_CC_LLVM_OpenCLKernel, types: !968)
!1971 = !{!1972}
!1972 = !DILocalVariable(name: "__SYCLKernel", scope: !1973, file: !1, line: 169, type: !1974)
!1973 = !DILexicalBlockFile(scope: !1969, file: !1, discriminator: 0)
!1974 = distinct !DICompositeType(tag: DW_TAG_class_type, file: !1, line: 169, size: 8, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !156)
!1975 = !{i32 4589068}
!1976 = !DILocalVariable(name: "this", arg: 1, scope: !1977, type: !1989, flags: DIFlagArtificial | DIFlagObjectPointer)
!1977 = distinct !DISubprogram(name: "operator()", linkageName: "_ZZZ4mainENKUlRN4sycl3_V17handlerEE_clES2_ENKUlvE_clEv", scope: !1974, file: !1, line: 169, type: !1978, scopeLine: 169, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !0, declaration: !1982, retainedNodes: !1983)
!1978 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1979)
!1979 = !{null, !1980}
!1980 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1981, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer, dwarfAddressSpace: 4)
!1981 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !1974)
!1982 = !DISubprogram(name: "operator()", scope: !1974, file: !1, line: 169, type: !1978, scopeLine: 169, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1983 = !{!1976, !1984, !1985, !1987, !1988}
!1984 = !DILocalVariable(name: "input_vec", scope: !1977, file: !1, line: 171, type: !384)
!1985 = !DILocalVariable(name: "vals1", scope: !1977, file: !1, line: 172, type: !1986)
!1986 = !DICompositeType(tag: DW_TAG_array_type, baseType: !41, size: 128, elements: !167)
!1987 = !DILocalVariable(name: "test1", scope: !1977, file: !1, line: 173, type: !149)
!1988 = !DILocalVariable(name: "res", scope: !1977, file: !1, line: 175, type: !41)
!1989 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1981, size: 64, dwarfAddressSpace: 4)
!1990 = !DILocation(line: 0, scope: !1977, inlinedAt: !1991)
!1991 = distinct !DILocation(line: 1211, column: 5, scope: !1992)
!1992 = distinct !DILexicalBlock(scope: !1993, file: !1877, line: 1209, column: 53)
!1993 = !DILexicalBlockFile(scope: !1969, file: !1877, discriminator: 0)
!1994 = !DILocation(line: 172, column: 11, scope: !1977, inlinedAt: !1991)
!1995 = !DILocation(line: 172, column: 16, scope: !1977, inlinedAt: !1991)
!1996 = !DILocalVariable(name: "vector", arg: 1, scope: !1997, file: !1, line: 155, type: !149)
!1997 = distinct !DISubprogram(name: "check_vector_values<bool, 16>", linkageName: "_Z19check_vector_valuesIbLi16EEbN4sycl3_V13vecIT_XT0_EEEPS3_", scope: !1, file: !1, line: 155, type: !1998, scopeLine: 156, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2004, retainedNodes: !2000)
!1998 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !1999)
!1999 = !{!41, !149, !62}
!2000 = !{!1996, !2001, !2002}
!2001 = !DILocalVariable(name: "vals", arg: 2, scope: !1997, file: !1, line: 156, type: !62)
!2002 = !DILocalVariable(name: "i", scope: !2003, file: !1, line: 157, type: !16)
!2003 = distinct !DILexicalBlock(scope: !1997, file: !1, line: 157, column: 3)
!2004 = !{!2005, !2006}
!2005 = !DITemplateTypeParameter(name: "vecType", type: !41)
!2006 = !DITemplateValueParameter(name: "numOfElems", type: !16, value: i32 16)
!2007 = !DILocation(line: 0, scope: !1997, inlinedAt: !2008)
!2008 = distinct !DILocation(line: 175, column: 22, scope: !1977, inlinedAt: !1991)
!2009 = !DILocation(line: 0, scope: !2003, inlinedAt: !2008)
!2010 = !DILocation(line: 157, column: 8, scope: !2003, inlinedAt: !2008)
!2011 = !DILocation(line: 157, scope: !2003, inlinedAt: !2008)
!2012 = !DILocation(line: 157, column: 21, scope: !2013, inlinedAt: !2008)
!2013 = distinct !DILexicalBlock(scope: !2003, file: !1, line: 157, column: 3)
!2014 = !DILocation(line: 157, column: 3, scope: !2003, inlinedAt: !2008)
!2015 = !DILocation(line: 158, column: 10, scope: !2016, inlinedAt: !2008)
!2016 = distinct !DILexicalBlock(scope: !2017, file: !1, line: 158, column: 9)
!2017 = distinct !DILexicalBlock(scope: !2013, file: !1, line: 157, column: 40)
!2018 = !{!2019, !2019, i64 0}
!2019 = !{!"bool", !2020, i64 0}
!2020 = !{!"omnipotent char", !2021, i64 0}
!2021 = !{!"Simple C++ TBAA"}
!2022 = !{i8 0, i8 2}
!2023 = !DILocation(line: 0, scope: !2024, inlinedAt: !2032)
!2024 = distinct !DISubprogram(name: "getElement<bool, 16>", linkageName: "_Z10getElementIbLi16EET_N4sycl3_V13vecIS0_XT0_EEEi", scope: !1, file: !1, line: 150, type: !2025, scopeLine: 150, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2030, retainedNodes: !2027)
!2025 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !2026)
!2026 = !{!41, !149, !16}
!2027 = !{!2028, !2029}
!2028 = !DILocalVariable(name: "f", arg: 1, scope: !2024, file: !1, line: 150, type: !149)
!2029 = !DILocalVariable(name: "ix", arg: 2, scope: !2024, file: !1, line: 150, type: !16)
!2030 = !{!158, !2031}
!2031 = !DITemplateValueParameter(name: "dim", type: !16, value: i32 16)
!2032 = distinct !DILocation(line: 158, column: 21, scope: !2016, inlinedAt: !2008)
!2033 = !DILocation(line: 150, column: 32, scope: !2024, inlinedAt: !2032)
!2034 = !DILocation(line: 151, column: 10, scope: !2024, inlinedAt: !2032)
!2035 = !DILocation(line: 151, column: 3, scope: !2024, inlinedAt: !2032)
!2036 = !DILocation(line: 158, column: 18, scope: !2016, inlinedAt: !2008)
!2037 = !DILocation(line: 158, column: 9, scope: !2017, inlinedAt: !2008)
!2038 = !DILocation(line: 157, column: 36, scope: !2013, inlinedAt: !2008)
!2039 = !DILocation(line: 157, column: 3, scope: !2013, inlinedAt: !2008)
!2040 = distinct !{!2040, !2014, !2041, !2042}
!2041 = !DILocation(line: 161, column: 3, scope: !2003, inlinedAt: !2008)
!2042 = !{!"llvm.loop.mustprogress"}
!2043 = !DILocation(line: 177, column: 9, scope: !1977, inlinedAt: !1991)
!2044 = !DILocation(line: 1215, column: 3, scope: !1993)
!2045 = distinct !DISubprogram(name: "operator()", linkageName: "_ZNK12getComponentIbLi16EEclERN4sycl3_V13vecIbLi16EEEi", scope: !2046, file: !1, line: 93, type: !2050, scopeLine: 93, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, declaration: !2049, retainedNodes: !2054)
!2046 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "getComponent<bool, 16>", file: !1, line: 91, size: 8, flags: DIFlagTypePassByValue, elements: !2047, templateParams: !2030, identifier: "_ZTS12getComponentIbLi16EE")
!2047 = !{!2048, !2049}
!2048 = !DIDerivedType(tag: DW_TAG_member, name: "dim", scope: !2046, file: !1, line: 92, baseType: !344, flags: DIFlagStaticMember, extraData: i32 16)
!2049 = !DISubprogram(name: "operator()", linkageName: "_ZNK12getComponentIbLi16EEclERN4sycl3_V13vecIbLi16EEEi", scope: !2046, file: !1, line: 93, type: !2050, scopeLine: 93, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2050 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !2051)
!2051 = !{!41, !2052, !188, !16}
!2052 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2053, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!2053 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !2046)
!2054 = !{!2055, !2057, !2058}
!2055 = !DILocalVariable(name: "this", arg: 1, scope: !2045, type: !2056, flags: DIFlagArtificial | DIFlagObjectPointer)
!2056 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2053, size: 64)
!2057 = !DILocalVariable(name: "f", arg: 2, scope: !2045, file: !1, line: 93, type: !188)
!2058 = !DILocalVariable(name: "number", arg: 3, scope: !2045, file: !1, line: 93, type: !16)
!2059 = !{i32 4586945}
!2060 = !DILocation(line: 0, scope: !2045)
!2061 = !DILocation(line: 94, column: 5, scope: !2045)
!2062 = !DILocalVariable(name: "this", arg: 1, scope: !2063, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2063 = distinct !DISubprogram(name: "s0<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s0ILi16EEENSt9enable_ifIXgtT_Li0EERbE4typeEv", scope: !149, file: !2064, line: 90, type: !2065, scopeLine: 90, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2073, retainedNodes: !2075)
!2064 = !DIFile(filename: "/build/bin/../include/sycl/swizzles.def", directory: "", checksumkind: CSK_MD5, checksum: "41a62f77378d2062279430731df85a09")
!2065 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !2066)
!2066 = !{!2067, !175}
!2067 = !DIDerivedType(tag: DW_TAG_typedef, name: "type", scope: !2069, file: !2068, line: 2045, baseType: !53)
!2068 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/type_traits", directory: "", checksumkind: CSK_MD5, checksum: "c0abc0de21199c8fb5ada6dd92e00cb6")
!2069 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "enable_if<true, bool &>", scope: !44, file: !2068, line: 2044, size: 8, flags: DIFlagTypePassByValue, elements: !156, templateParams: !2070, identifier: "_ZTSSt9enable_ifILb1ERbE")
!2070 = !{!2071, !2072}
!2071 = !DITemplateValueParameter(type: !41, value: i1 true)
!2072 = !DITemplateTypeParameter(name: "_Tp", type: !53)
!2073 = !DISubprogram(name: "s0<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s0ILi16EEENSt9enable_ifIXgtT_Li0EERbE4typeEv", scope: !149, file: !2064, line: 90, type: !2065, scopeLine: 90, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2074 = !{!159}
!2075 = !{!2062}
!2076 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !149, size: 64)
!2077 = !DILocation(line: 0, scope: !2063, inlinedAt: !2078)
!2078 = distinct !DILocation(line: 95, column: 24, scope: !2079)
!2079 = distinct !DILexicalBlock(scope: !2045, file: !1, line: 94, column: 21)
!2080 = !DILocalVariable(name: "this", arg: 1, scope: !2081, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2081 = distinct !DISubprogram(name: "operator[]", linkageName: "_ZN4sycl3_V13vecIbLi16EEixEi", scope: !149, file: !148, line: 978, type: !209, scopeLine: 978, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, declaration: !208, retainedNodes: !2082)
!2082 = !{!2080, !2083}
!2083 = !DILocalVariable(name: "i", arg: 2, scope: !2081, file: !148, line: 978, type: !16)
!2084 = !DILocation(line: 0, scope: !2081, inlinedAt: !2085)
!2085 = distinct !DILocation(line: 90, column: 99, scope: !2063, inlinedAt: !2078)
!2086 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2085)
!2087 = !DILocation(line: 95, column: 24, scope: !2079)
!2088 = !DILocation(line: 95, column: 15, scope: !2079)
!2089 = !DILocalVariable(name: "this", arg: 1, scope: !2090, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2090 = distinct !DISubprogram(name: "s1<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s1ILi16EEENSt9enable_ifIXgtT_Li1EERbE4typeEv", scope: !149, file: !2064, line: 91, type: !2065, scopeLine: 91, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2091, retainedNodes: !2092)
!2091 = !DISubprogram(name: "s1<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s1ILi16EEENSt9enable_ifIXgtT_Li1EERbE4typeEv", scope: !149, file: !2064, line: 91, type: !2065, scopeLine: 91, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2092 = !{!2089}
!2093 = !DILocation(line: 0, scope: !2090, inlinedAt: !2094)
!2094 = distinct !DILocation(line: 96, column: 24, scope: !2079)
!2095 = !DILocation(line: 0, scope: !2081, inlinedAt: !2096)
!2096 = distinct !DILocation(line: 91, column: 99, scope: !2090, inlinedAt: !2094)
!2097 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2096)
!2098 = !DILocation(line: 96, column: 24, scope: !2079)
!2099 = !DILocation(line: 96, column: 15, scope: !2079)
!2100 = !DILocalVariable(name: "this", arg: 1, scope: !2101, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2101 = distinct !DISubprogram(name: "s2<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s2ILi16EEENSt9enable_ifIXgtT_Li2EERbE4typeEv", scope: !149, file: !2064, line: 92, type: !2065, scopeLine: 92, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2102, retainedNodes: !2103)
!2102 = !DISubprogram(name: "s2<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s2ILi16EEENSt9enable_ifIXgtT_Li2EERbE4typeEv", scope: !149, file: !2064, line: 92, type: !2065, scopeLine: 92, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2103 = !{!2100}
!2104 = !DILocation(line: 0, scope: !2101, inlinedAt: !2105)
!2105 = distinct !DILocation(line: 97, column: 24, scope: !2079)
!2106 = !DILocation(line: 0, scope: !2081, inlinedAt: !2107)
!2107 = distinct !DILocation(line: 92, column: 99, scope: !2101, inlinedAt: !2105)
!2108 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2107)
!2109 = !DILocation(line: 97, column: 24, scope: !2079)
!2110 = !DILocation(line: 97, column: 15, scope: !2079)
!2111 = !DILocalVariable(name: "this", arg: 1, scope: !2112, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2112 = distinct !DISubprogram(name: "s3<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s3ILi16EEENSt9enable_ifIXgtT_Li2EERbE4typeEv", scope: !149, file: !2064, line: 93, type: !2065, scopeLine: 93, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2113, retainedNodes: !2114)
!2113 = !DISubprogram(name: "s3<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s3ILi16EEENSt9enable_ifIXgtT_Li2EERbE4typeEv", scope: !149, file: !2064, line: 93, type: !2065, scopeLine: 93, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2114 = !{!2111}
!2115 = !DILocation(line: 0, scope: !2112, inlinedAt: !2116)
!2116 = distinct !DILocation(line: 98, column: 24, scope: !2079)
!2117 = !DILocation(line: 0, scope: !2081, inlinedAt: !2118)
!2118 = distinct !DILocation(line: 93, column: 99, scope: !2112, inlinedAt: !2116)
!2119 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2118)
!2120 = !DILocation(line: 98, column: 24, scope: !2079)
!2121 = !DILocation(line: 98, column: 15, scope: !2079)
!2122 = !DILocalVariable(name: "this", arg: 1, scope: !2123, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2123 = distinct !DISubprogram(name: "s4<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s4ILi16EEENSt9enable_ifIXgtT_Li4EERbE4typeEv", scope: !149, file: !2064, line: 94, type: !2065, scopeLine: 94, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2124, retainedNodes: !2125)
!2124 = !DISubprogram(name: "s4<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s4ILi16EEENSt9enable_ifIXgtT_Li4EERbE4typeEv", scope: !149, file: !2064, line: 94, type: !2065, scopeLine: 94, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2125 = !{!2122}
!2126 = !DILocation(line: 0, scope: !2123, inlinedAt: !2127)
!2127 = distinct !DILocation(line: 99, column: 24, scope: !2079)
!2128 = !DILocation(line: 0, scope: !2081, inlinedAt: !2129)
!2129 = distinct !DILocation(line: 94, column: 99, scope: !2123, inlinedAt: !2127)
!2130 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2129)
!2131 = !DILocation(line: 99, column: 24, scope: !2079)
!2132 = !DILocation(line: 99, column: 15, scope: !2079)
!2133 = !DILocalVariable(name: "this", arg: 1, scope: !2134, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2134 = distinct !DISubprogram(name: "s5<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s5ILi16EEENSt9enable_ifIXgtT_Li4EERbE4typeEv", scope: !149, file: !2064, line: 95, type: !2065, scopeLine: 95, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2135, retainedNodes: !2136)
!2135 = !DISubprogram(name: "s5<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s5ILi16EEENSt9enable_ifIXgtT_Li4EERbE4typeEv", scope: !149, file: !2064, line: 95, type: !2065, scopeLine: 95, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2136 = !{!2133}
!2137 = !DILocation(line: 0, scope: !2134, inlinedAt: !2138)
!2138 = distinct !DILocation(line: 100, column: 24, scope: !2079)
!2139 = !DILocation(line: 0, scope: !2081, inlinedAt: !2140)
!2140 = distinct !DILocation(line: 95, column: 99, scope: !2134, inlinedAt: !2138)
!2141 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2140)
!2142 = !DILocation(line: 100, column: 24, scope: !2079)
!2143 = !DILocation(line: 100, column: 15, scope: !2079)
!2144 = !DILocalVariable(name: "this", arg: 1, scope: !2145, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2145 = distinct !DISubprogram(name: "s6<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s6ILi16EEENSt9enable_ifIXgtT_Li4EERbE4typeEv", scope: !149, file: !2064, line: 96, type: !2065, scopeLine: 96, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2146, retainedNodes: !2147)
!2146 = !DISubprogram(name: "s6<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s6ILi16EEENSt9enable_ifIXgtT_Li4EERbE4typeEv", scope: !149, file: !2064, line: 96, type: !2065, scopeLine: 96, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2147 = !{!2144}
!2148 = !DILocation(line: 0, scope: !2145, inlinedAt: !2149)
!2149 = distinct !DILocation(line: 101, column: 24, scope: !2079)
!2150 = !DILocation(line: 0, scope: !2081, inlinedAt: !2151)
!2151 = distinct !DILocation(line: 96, column: 99, scope: !2145, inlinedAt: !2149)
!2152 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2151)
!2153 = !DILocation(line: 101, column: 24, scope: !2079)
!2154 = !DILocation(line: 101, column: 15, scope: !2079)
!2155 = !DILocalVariable(name: "this", arg: 1, scope: !2156, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2156 = distinct !DISubprogram(name: "s7<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s7ILi16EEENSt9enable_ifIXgtT_Li4EERbE4typeEv", scope: !149, file: !2064, line: 97, type: !2065, scopeLine: 97, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2157, retainedNodes: !2158)
!2157 = !DISubprogram(name: "s7<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s7ILi16EEENSt9enable_ifIXgtT_Li4EERbE4typeEv", scope: !149, file: !2064, line: 97, type: !2065, scopeLine: 97, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2158 = !{!2155}
!2159 = !DILocation(line: 0, scope: !2156, inlinedAt: !2160)
!2160 = distinct !DILocation(line: 102, column: 24, scope: !2079)
!2161 = !DILocation(line: 0, scope: !2081, inlinedAt: !2162)
!2162 = distinct !DILocation(line: 97, column: 99, scope: !2156, inlinedAt: !2160)
!2163 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2162)
!2164 = !DILocation(line: 102, column: 24, scope: !2079)
!2165 = !DILocation(line: 102, column: 15, scope: !2079)
!2166 = !DILocalVariable(name: "this", arg: 1, scope: !2167, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2167 = distinct !DISubprogram(name: "s8<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s8ILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 98, type: !2065, scopeLine: 98, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2168, retainedNodes: !2169)
!2168 = !DISubprogram(name: "s8<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s8ILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 98, type: !2065, scopeLine: 98, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2169 = !{!2166}
!2170 = !DILocation(line: 0, scope: !2167, inlinedAt: !2171)
!2171 = distinct !DILocation(line: 103, column: 24, scope: !2079)
!2172 = !DILocation(line: 0, scope: !2081, inlinedAt: !2173)
!2173 = distinct !DILocation(line: 98, column: 101, scope: !2167, inlinedAt: !2171)
!2174 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2173)
!2175 = !DILocation(line: 103, column: 24, scope: !2079)
!2176 = !DILocation(line: 103, column: 15, scope: !2079)
!2177 = !DILocalVariable(name: "this", arg: 1, scope: !2178, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2178 = distinct !DISubprogram(name: "s9<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s9ILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 99, type: !2065, scopeLine: 99, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2179, retainedNodes: !2180)
!2179 = !DISubprogram(name: "s9<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2s9ILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 99, type: !2065, scopeLine: 99, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2180 = !{!2177}
!2181 = !DILocation(line: 0, scope: !2178, inlinedAt: !2182)
!2182 = distinct !DILocation(line: 104, column: 24, scope: !2079)
!2183 = !DILocation(line: 0, scope: !2081, inlinedAt: !2184)
!2184 = distinct !DILocation(line: 99, column: 101, scope: !2178, inlinedAt: !2182)
!2185 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2184)
!2186 = !DILocation(line: 104, column: 24, scope: !2079)
!2187 = !DILocation(line: 104, column: 15, scope: !2079)
!2188 = !DILocalVariable(name: "this", arg: 1, scope: !2189, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2189 = distinct !DISubprogram(name: "sA<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sAILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 100, type: !2065, scopeLine: 100, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2190, retainedNodes: !2191)
!2190 = !DISubprogram(name: "sA<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sAILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 100, type: !2065, scopeLine: 100, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2191 = !{!2188}
!2192 = !DILocation(line: 0, scope: !2189, inlinedAt: !2193)
!2193 = distinct !DILocation(line: 105, column: 25, scope: !2079)
!2194 = !DILocation(line: 0, scope: !2081, inlinedAt: !2195)
!2195 = distinct !DILocation(line: 100, column: 101, scope: !2189, inlinedAt: !2193)
!2196 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2195)
!2197 = !DILocation(line: 105, column: 25, scope: !2079)
!2198 = !DILocation(line: 105, column: 16, scope: !2079)
!2199 = !DILocalVariable(name: "this", arg: 1, scope: !2200, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2200 = distinct !DISubprogram(name: "sB<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sBILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 101, type: !2065, scopeLine: 101, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2201, retainedNodes: !2202)
!2201 = !DISubprogram(name: "sB<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sBILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 101, type: !2065, scopeLine: 101, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2202 = !{!2199}
!2203 = !DILocation(line: 0, scope: !2200, inlinedAt: !2204)
!2204 = distinct !DILocation(line: 106, column: 25, scope: !2079)
!2205 = !DILocation(line: 0, scope: !2081, inlinedAt: !2206)
!2206 = distinct !DILocation(line: 101, column: 101, scope: !2200, inlinedAt: !2204)
!2207 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2206)
!2208 = !DILocation(line: 106, column: 25, scope: !2079)
!2209 = !DILocation(line: 106, column: 16, scope: !2079)
!2210 = !DILocalVariable(name: "this", arg: 1, scope: !2211, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2211 = distinct !DISubprogram(name: "sC<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sCILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 102, type: !2065, scopeLine: 102, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2212, retainedNodes: !2213)
!2212 = !DISubprogram(name: "sC<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sCILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 102, type: !2065, scopeLine: 102, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2213 = !{!2210}
!2214 = !DILocation(line: 0, scope: !2211, inlinedAt: !2215)
!2215 = distinct !DILocation(line: 107, column: 25, scope: !2079)
!2216 = !DILocation(line: 0, scope: !2081, inlinedAt: !2217)
!2217 = distinct !DILocation(line: 102, column: 101, scope: !2211, inlinedAt: !2215)
!2218 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2217)
!2219 = !DILocation(line: 107, column: 25, scope: !2079)
!2220 = !DILocation(line: 107, column: 16, scope: !2079)
!2221 = !DILocalVariable(name: "this", arg: 1, scope: !2222, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2222 = distinct !DISubprogram(name: "sD<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sDILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 103, type: !2065, scopeLine: 103, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2223, retainedNodes: !2224)
!2223 = !DISubprogram(name: "sD<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sDILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 103, type: !2065, scopeLine: 103, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2224 = !{!2221}
!2225 = !DILocation(line: 0, scope: !2222, inlinedAt: !2226)
!2226 = distinct !DILocation(line: 108, column: 25, scope: !2079)
!2227 = !DILocation(line: 0, scope: !2081, inlinedAt: !2228)
!2228 = distinct !DILocation(line: 103, column: 101, scope: !2222, inlinedAt: !2226)
!2229 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2228)
!2230 = !DILocation(line: 108, column: 25, scope: !2079)
!2231 = !DILocation(line: 108, column: 16, scope: !2079)
!2232 = !DILocalVariable(name: "this", arg: 1, scope: !2233, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2233 = distinct !DISubprogram(name: "sE<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sEILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 104, type: !2065, scopeLine: 104, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2234, retainedNodes: !2235)
!2234 = !DISubprogram(name: "sE<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sEILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 104, type: !2065, scopeLine: 104, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2235 = !{!2232}
!2236 = !DILocation(line: 0, scope: !2233, inlinedAt: !2237)
!2237 = distinct !DILocation(line: 109, column: 25, scope: !2079)
!2238 = !DILocation(line: 0, scope: !2081, inlinedAt: !2239)
!2239 = distinct !DILocation(line: 104, column: 101, scope: !2233, inlinedAt: !2237)
!2240 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2239)
!2241 = !DILocation(line: 109, column: 25, scope: !2079)
!2242 = !DILocation(line: 109, column: 16, scope: !2079)
!2243 = !DILocalVariable(name: "this", arg: 1, scope: !2244, type: !2076, flags: DIFlagArtificial | DIFlagObjectPointer)
!2244 = distinct !DISubprogram(name: "sF<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sFILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 105, type: !2065, scopeLine: 105, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, templateParams: !2074, declaration: !2245, retainedNodes: !2246)
!2245 = !DISubprogram(name: "sF<16>", linkageName: "_ZN4sycl3_V13vecIbLi16EE2sFILi16EEENSt9enable_ifIXeqT_Li16EERbE4typeEv", scope: !149, file: !2064, line: 105, type: !2065, scopeLine: 105, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !2074)
!2246 = !{!2243}
!2247 = !DILocation(line: 0, scope: !2244, inlinedAt: !2248)
!2248 = distinct !DILocation(line: 110, column: 25, scope: !2079)
!2249 = !DILocation(line: 0, scope: !2081, inlinedAt: !2250)
!2250 = distinct !DILocation(line: 105, column: 101, scope: !2244, inlinedAt: !2248)
!2251 = !DILocation(line: 978, column: 37, scope: !2081, inlinedAt: !2250)
!2252 = !DILocation(line: 110, column: 25, scope: !2079)
!2253 = !DILocation(line: 110, column: 16, scope: !2079)
!2254 = !DILocation(line: 0, scope: !2079)
!2255 = !DILocation(line: 114, column: 3, scope: !2045)
!2256 = !{i32 435}
!2257 = !{!2258, !2258, i64 0}
!2258 = !{!"long", !2020, i64 0}
!2259 = !{i32 1016}
!2260 = !{i32 455}
!2261 = !{!2262, !2262, i64 0}
!2262 = !{!"any pointer", !2020, i64 0}
!2263 = !{!2264, !2264, i64 0}
!2264 = !{!"int", !2020, i64 0}
!2265 = !{i32 578}
