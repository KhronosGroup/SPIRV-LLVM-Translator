; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_vector_compute -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefixes=OCL-IR,COMMON-IR

; RUN: llvm-spirv --spirv-target-env=SPV-IR -r %t.spv -o %t.rev.spv.bc
; RUN: llvm-dis < %t.rev.spv.bc | FileCheck %s --check-prefixes=SPV-IR,COMMON-IR

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spir64-unknown-unknown"

; SPIRV-DAG: TypeFloat [[f64:[0-9]+]] 64
; SPIRV-DAG: TypeFloat [[f32:[0-9]+]] 32
; SPIRV-DAG: ExtInst [[f64]] {{[0-9]+}} {{[0-9]+}} mad
; SPIRV-DAG: ExtInst [[f32]] {{[0-9]+}} {{[0-9]+}} mad

; Function Attrs: convergent mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite)
define dso_local spir_kernel void @testDouble(ptr addrspace(1) nocapture noundef readonly align 8 %a, ptr addrspace(1) nocapture noundef readonly align 8 %b, ptr addrspace(1) nocapture noundef align 8 %c) local_unnamed_addr #0 !kernel_arg_addr_space !2 !kernel_arg_access_qual !3 !kernel_arg_type !4 !kernel_arg_base_type !4 !kernel_arg_type_qual !5 !kernel_arg_host_accessible !6 !kernel_arg_pipe_depth !7 !kernel_arg_pipe_io !5 !kernel_arg_buffer_location !5 {
entry:
  %call = tail call spir_func i64 @_Z13get_global_idj(i32 noundef 0) #3
  %0 = shl i64 %call, 32
  %idxprom = ashr exact i64 %0, 32
  %arrayidx = getelementptr inbounds double, ptr addrspace(1) %a, i64 %idxprom
  %1 = load double, ptr addrspace(1) %arrayidx, align 8, !tbaa !8
  %vecins = insertelement <1 x double> poison, double %1, i64 0
  %arrayidx2 = getelementptr inbounds double, ptr addrspace(1) %b, i64 %idxprom
  %2 = load double, ptr addrspace(1) %arrayidx2, align 8, !tbaa !8
  %vecins3 = insertelement <1 x double> poison, double %2, i64 0
  %arrayidx5 = getelementptr inbounds double, ptr addrspace(1) %c, i64 %idxprom
  %3 = load double, ptr addrspace(1) %arrayidx5, align 8, !tbaa !8
  %vecins6 = insertelement <1 x double> poison, double %3, i64 0
; COMMON-IR-DAG: define spir_kernel void @testDouble
; COMMON-IR: [[ScalarA:%[0-9]+]] = extractelement <1 x double> %vecins, i32 0
; COMMON-IR-NEXT: [[ScalarB:%[0-9]+]] = extractelement <1 x double> %vecins3, i32 0
; COMMON-IR-NEXT: [[ScalarC:%[0-9]+]] = extractelement <1 x double> %vecins6, i32 0
; OCL-IR: [[ScalarD:%[0-9]+]] = call spir_func double @_Z3madddd(double [[ScalarA]], double [[ScalarB]], double [[ScalarC]])
; SPV-IR: [[ScalarD:%[0-9]+]] = call spir_func double @_Z15__spirv_ocl_madddd(double [[ScalarA]], double [[ScalarB]], double [[ScalarC]])
; COMMON-IR: [[VecD:%[0-9]+]] = insertelement <1 x double> undef, double [[ScalarD]], i32 0
; COMMON-IR-NEXT: %vecext = extractelement <1 x double> [[VecD]], i32 0
  %4 = tail call <1 x double> @llvm.fmuladd.v1f64(<1 x double> %vecins, <1 x double> %vecins3, <1 x double> %vecins6)
  %vecext = extractelement <1 x double> %4, i64 0
  store double %vecext, ptr addrspace(1) %arrayidx5, align 8, !tbaa !8
  ret void
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare spir_func i64 @_Z13get_global_idj(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <1 x double> @llvm.fmuladd.v1f64(<1 x double>, <1 x double>, <1 x double>) #2

; Function Attrs: convergent mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite)
define dso_local spir_kernel void @testFloat(ptr addrspace(1) nocapture noundef readonly align 4 %a, ptr addrspace(1) nocapture noundef readonly align 4 %b, ptr addrspace(1) nocapture noundef align 4 %c) local_unnamed_addr #0 !kernel_arg_addr_space !2 !kernel_arg_access_qual !3 !kernel_arg_type !12 !kernel_arg_base_type !12 !kernel_arg_type_qual !5 !kernel_arg_host_accessible !6 !kernel_arg_pipe_depth !7 !kernel_arg_pipe_io !5 !kernel_arg_buffer_location !5 {
entry:
  %call = tail call spir_func i64 @_Z13get_global_idj(i32 noundef 0) #3
  %0 = shl i64 %call, 32
  %idxprom = ashr exact i64 %0, 32
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %a, i64 %idxprom
  %1 = load float, ptr addrspace(1) %arrayidx, align 4, !tbaa !13
  %vecins = insertelement <1 x float> poison, float %1, i64 0
  %arrayidx2 = getelementptr inbounds float, ptr addrspace(1) %b, i64 %idxprom
  %2 = load float, ptr addrspace(1) %arrayidx2, align 4, !tbaa !13
  %vecins3 = insertelement <1 x float> poison, float %2, i64 0
  %arrayidx5 = getelementptr inbounds float, ptr addrspace(1) %c, i64 %idxprom
  %3 = load float, ptr addrspace(1) %arrayidx5, align 4, !tbaa !13
  %vecins6 = insertelement <1 x float> poison, float %3, i64 0
; COMMON-IR-DAG: define spir_kernel void @testFloat
; COMMON-IR: [[ScalarA:%[0-9]+]] = extractelement <1 x float> %vecins, i32 0
; COMMON-IR-NEXT: [[ScalarB:%[0-9]+]] = extractelement <1 x float> %vecins3, i32 0
; COMMON-IR-NEXT: [[ScalarC:%[0-9]+]] = extractelement <1 x float> %vecins6, i32 0
; OCL-IR: [[ScalarD:%[0-9]+]] = call spir_func float @_Z3madfff(float [[ScalarA]], float [[ScalarB]], float [[ScalarC]])
; SPV-IR: [[ScalarD:%[0-9]+]] = call spir_func float @_Z15__spirv_ocl_madfff(float [[ScalarA]], float [[ScalarB]], float [[ScalarC]])
; COMMON-IR: [[VecD:%[0-9]+]] = insertelement <1 x float> undef, float [[ScalarD]], i32 0
; COMMON-IR-NEXT: %vecext = extractelement <1 x float> [[VecD]], i32 0
  %4 = tail call <1 x float> @llvm.fmuladd.v1f32(<1 x float> %vecins, <1 x float> %vecins3, <1 x float> %vecins6)
  %vecext = extractelement <1 x float> %4, i64 0
  store float %vecext, ptr addrspace(1) %arrayidx5, align 4, !tbaa !13
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <1 x float> @llvm.fmuladd.v1f32(<1 x float>, <1 x float>, <1 x float>) #2

attributes #0 = { convergent mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" }
attributes #1 = { convergent mustprogress nofree nounwind willreturn memory(none) "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { convergent nounwind willreturn memory(none) }

!opencl.ocl.version = !{!0}
!opencl.spir.version = !{!1}

!0 = !{i32 2, i32 0}
!1 = !{i32 2, i32 0}
!2 = !{i32 1, i32 1, i32 1}
!3 = !{!"none", !"none", !"none"}
!4 = !{!"double*", !"double*", !"double*"}
!5 = !{!"", !"", !""}
!6 = !{i1 false, i1 false, i1 false}
!7 = !{i32 0, i32 0, i32 0}
!8 = !{!9, !9, i64 0}
!9 = !{!"double", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}
!12 = !{!"float*", !"float*", !"float*"}
!13 = !{!14, !14, i64 0}
!14 = !{!"float", !10, i64 0}
