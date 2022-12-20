; RUN: llvm-as -opaque-pointers=0 < %s -o %t.bc
; RUN: llvm-spirv %t.bc -opaque-pointers=0 -spirv-ext=+SPV_INTEL_joint_matrix -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv --spirv-target-env=CL2.0 -r %t.spv -o %t.rev.bc
; RUN: llvm-dis -opaque-pointers=0 %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM-CL20

; CHECK-SPIRV: Capability JointMatrixINTEL
; CHECK-SPIRV: Extension "SPV_INTEL_joint_matrix"

; CHECK-SPIRV-DAG: TypeInt [[#IntTy:]] 32 0
; CHECK-SPIRV-DAG: TypeInt [[#CharTy:]] 8 0
; CHECK-SPIRV-DAG: Constant [[#IntTy]] [[#One:]] 1
; CHECK-SPIRV-DAG: Constant [[#IntTy]] [[#ThirtyTwo:]] 32
; CHECK-SPIRV-DAG: Constant [[#IntTy]] [[#Two:]] 2
; CHECK-SPIRV-DAG: Constant [[#IntTy]] [[#Zero:]] 0
; CHECK-SPIRV-DAG: Constant [[#IntTy]] [[#Eight:]] 8
; CHECK-SPIRV-DAG: Constant [[#IntTy]] [[#Three:]] 3
; CHECK-SPIRV: TypeJointMatrixINTEL [[#ATy:]] [[#CharTy]] [[#One]] [[#ThirtyTwo]] [[#Two]] [[#Zero]]
; CHECK-SPIRV: TypeJointMatrixINTEL [[#BTy:]] [[#CharTy]] [[#Eight]] [[#ThirtyTwo]] [[#Three]] [[#Zero]]
; CHECK-SPIRV: TypeJointMatrixINTEL [[#CTy:]] [[#IntTy]] [[#One]] [[#Eight]] [[#Zero]] [[#Zero]]

; CHECK-SPIRV: JointMatrixLoadINTEL [[#ATy]] [[#A:]] [[#Aptr:]] [[#ThirtyTwo]] [[#Zero]] [[#Zero]]
; CHECK-SPIRV: JointMatrixLoadINTEL [[#BTy]] [[#B:]] [[#Bptr:]] [[#ThirtyTwo]] [[#One]] [[#Zero]]
; CHECK-SPIRV: JointMatrixLoadINTEL [[#CTy]] [[#C:]] [[#Cptr:]] [[#Eight]] [[#Zero]] [[#Zero]]
; CHECK-SPIRV: JointMatrixMadINTEL [[#CTy]] [[#DMad:]] [[#A]] [[#B]] [[#C]] [[#Zero]]
; CHECK-SPIRV: JointMatrixStoreINTEL [[#Dptr:]] [[#DMad]] [[#Eight]] [[#Zero]] [[#Zero]]

; CHECK-LLVM-CL20: %struct.ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intel
; CHECK-LLVM-CL20: %struct.ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intel
; CHECK-LLVM-CL20: %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel

; CHECK-LLVM-CL20: [[A:%.*]] = call spir_func %struct.ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intel addrspace(1)* @_Z119intel_joint_matrix_load_RPU3AS186ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intelPU3AS4ciii(i8 addrspace(4)* %arraydecay.ascast, i32 32, i32 0, i32 0)
; CHECK-LLVM-CL20: [[B:%.*]] = call spir_func %struct.ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intel addrspace(1)* @_Z119intel_joint_matrix_load_RPU3AS186ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intelPU3AS4ciii(i8 addrspace(4)* %arraydecay1.ascast, i32 32, i32 1, i32 0)
; CHECK-LLVM-CL20: [[C:%.*]] = call spir_func %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(1)* @_Z120intel_joint_matrix_load_RPU3AS187ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intelPU3AS4iiii(i32 addrspace(4)* %arraydecay3.ascast, i32 8, i32 0, i32 0)
; CHECK-LLVM-CL20: [[DMad:%.*]] = call spir_func %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(1)* @_Z22intel_joint_matrix_madPU3AS1P91opencl.Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intel_tPU3AS1P91opencl.Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intel_tPU3AS1P92opencl.Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel_ti(%struct.ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intel addrspace(1)* [[A]], %struct.ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intel addrspace(1)* [[B]], %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(1)* [[C]], i32 0)
; CHECK-LLVM-CL20: spir_func void @_Z24intel_joint_matrix_storePU3AS4iPU3AS1P92opencl.Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel_tiii(i32 addrspace(4)* %arraydecay6.ascast, %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(1)* [[DMad]], i32 8, i32 0, i32 0)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intel = type {}
%struct.ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intel = type {}
%struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel = type {}

; Function Attrs: convergent norecurse nounwind
define dso_local spir_func void @test(%struct.ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intel addrspace(4)* nocapture noundef readnone %mat1, %struct.ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intel addrspace(4)* nocapture noundef readnone %mat2, %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(4)* nocapture noundef readnone %mat3, %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(4)* nocapture noundef readnone %mat4) local_unnamed_addr #0 {
entry:
  %arrA = alloca [1 x [32 x i8]], align 1
  %arrB = alloca [8 x [32 x i8]], align 1
  %arrC = alloca [1 x [8 x i32]], align 4
  %arrD = alloca [1 x [8 x i32]], align 4
  %0 = getelementptr inbounds [1 x [32 x i8]], [1 x [32 x i8]]* %arrA, i32 0, i32 0, i32 0
  call void @llvm.lifetime.start.p0i8(i64 32, i8* nonnull %0) #4
  call void @llvm.memset.p0i8.i32(i8* noundef nonnull align 1 dereferenceable(32) %0, i8 0, i32 32, i1 false)
  %1 = getelementptr inbounds [8 x [32 x i8]], [8 x [32 x i8]]* %arrB, i32 0, i32 0, i32 0
  call void @llvm.lifetime.start.p0i8(i64 256, i8* nonnull %1) #4
  call void @llvm.memset.p0i8.i32(i8* noundef nonnull align 1 dereferenceable(256) %1, i8 0, i32 256, i1 false)
  %2 = bitcast [1 x [8 x i32]]* %arrC to i8*
  call void @llvm.lifetime.start.p0i8(i64 32, i8* nonnull %2) #4
  call void @llvm.memset.p0i8.i32(i8* noundef nonnull align 4 dereferenceable(32) %2, i8 0, i32 32, i1 false)
  %3 = bitcast [1 x [8 x i32]]* %arrD to i8*
  call void @llvm.lifetime.start.p0i8(i64 32, i8* nonnull %3) #4
  call void @llvm.memset.p0i8.i32(i8* noundef nonnull align 4 dereferenceable(32) %3, i8 0, i32 32, i1 false)
  %arraydecay.ascast = addrspacecast i8* %0 to i8 addrspace(4)*
  %call = call spir_func %struct.ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intel addrspace(4)* @_Z50intel_joint_matrix_load_sub_group_i8_packed_a_1_32PU3AS4ci19intel_matrix_layout(i8 addrspace(4)* noundef %arraydecay.ascast, i32 noundef 32, i32 noundef 0) #5
  %arraydecay1.ascast = addrspacecast i8* %1 to i8 addrspace(4)*
  %call2 = call spir_func %struct.ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intel addrspace(4)* @_Z50intel_joint_matrix_load_sub_group_i8_packed_b_8_32PU3AS4ci19intel_matrix_layout(i8 addrspace(4)* noundef %arraydecay1.ascast, i32 noundef 32, i32 noundef 1) #5
  %4 = getelementptr inbounds [1 x [8 x i32]], [1 x [8 x i32]]* %arrC, i32 0, i32 0, i32 0
  %arraydecay3.ascast = addrspacecast i32* %4 to i32 addrspace(4)*
  %call4 = call spir_func %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(4)* @_Z51intel_joint_matrix_load_sub_group_i32_row_major_1_8PU3AS4ii19intel_matrix_layout(i32 addrspace(4)* noundef %arraydecay3.ascast, i32 noundef 8, i32 noundef 0) #5
  %call5 = call spir_func %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(4)* @_Z22intel_joint_matrix_madPU3AS486ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intelPU3AS486ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intelPU3AS487ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel(%struct.ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intel addrspace(4)* noundef %call, %struct.ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intel addrspace(4)* noundef %call2, %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(4)* noundef %call4) #5
  %5 = getelementptr inbounds [1 x [8 x i32]], [1 x [8 x i32]]* %arrD, i32 0, i32 0, i32 0
  %arraydecay6.ascast = addrspacecast i32* %5 to i32 addrspace(4)*
  call spir_func void @_Z24intel_joint_matrix_storePU3AS4iPU3AS487ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_inteli19intel_matrix_layout(i32 addrspace(4)* noundef %arraydecay6.ascast, %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(4)* noundef %call5, i32 noundef 8, i32 noundef 0) #5
  call void @llvm.lifetime.end.p0i8(i64 32, i8* nonnull %3) #4
  call void @llvm.lifetime.end.p0i8(i64 32, i8* nonnull %2) #4
  call void @llvm.lifetime.end.p0i8(i64 256, i8* nonnull %1) #4
  call void @llvm.lifetime.end.p0i8(i64 32, i8* nonnull %0) #4
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0i8.i32(i8* nocapture writeonly, i8, i32, i1 immarg) #2

; Function Attrs: convergent
declare spir_func %struct.ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intel addrspace(4)* @_Z50intel_joint_matrix_load_sub_group_i8_packed_a_1_32PU3AS4ci19intel_matrix_layout(i8 addrspace(4)* noundef, i32 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: convergent
declare spir_func %struct.ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intel addrspace(4)* @_Z50intel_joint_matrix_load_sub_group_i8_packed_b_8_32PU3AS4ci19intel_matrix_layout(i8 addrspace(4)* noundef, i32 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: convergent
declare spir_func %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(4)* @_Z51intel_joint_matrix_load_sub_group_i32_row_major_1_8PU3AS4ii19intel_matrix_layout(i32 addrspace(4)* noundef, i32 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: convergent
declare spir_func %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(4)* @_Z22intel_joint_matrix_madPU3AS486ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intelPU3AS486ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intelPU3AS487ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel(%struct.ocl_Mat_matrix_i8_intel_1_32_matrix_layout_packed_a_intel_matrix_scope_sub_group_intel addrspace(4)* noundef, %struct.ocl_Mat_matrix_i8_intel_8_32_matrix_layout_packed_b_intel_matrix_scope_sub_group_intel addrspace(4)* noundef, %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(4)* noundef) local_unnamed_addr #3

; Function Attrs: convergent
declare spir_func void @_Z24intel_joint_matrix_storePU3AS4iPU3AS487ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_inteli19intel_matrix_layout(i32 addrspace(4)* noundef, %struct.ocl_Mat_matrix_i32_intel_1_8_matrix_layout_row_major_intel_matrix_scope_sub_group_intel addrspace(4)* noundef, i32 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #1

attributes #0 = { convergent norecurse nounwind "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { convergent "frame-pointer"="none" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #4 = { nounwind }
attributes #5 = { convergent nounwind }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 2, i32 0}
!2 = !{!"clang version 16.0.0 (https://github.com/llvm/llvm-project.git 1eab2d699e9581305f32473291e6afa47017d582)"}
