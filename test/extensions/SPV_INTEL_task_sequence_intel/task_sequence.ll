; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -opaque-pointers=0 %t.bc -o %t.spt -spirv-ext=+SPV_INTEL_function_pointers,+SPV_INTEL_task_sequence --spirv-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spt -o %t.spv -to-binary
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis -opaque-pointers=0 %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: Name [[#ObjPtr:]] "sot_object.i"
; CHECK-SPIRV: Name [[#ObjId:]] "call.i.i"
; CHECK-SPIRV: Name [[#ArrayId:]] "arraydecay1.i"
; CHECK-SPIRV: Name [[#GetRetId:]] "call.i7.i"
; CHECK-SPIRV-DAG: TypeInt [[#TyInt32:]] 32 0
; CHECK-SPIRV-DAG: TypeInt [[#TyInt64:]] 64 0
; CHECK-SPIRV: Constant [[#TyInt32]] [[#ConstantId1:]] 10
; CHECK-SPIRV: Constant [[#TyInt32]] [[#ConstantId2:]] 0
; CHECK-SPIRV: Constant [[#TyInt32]] [[#ConstantId3:]] 128
; CHECK-SPIRV: TypeStruct [[#StructId:]] [[#TyInt32]] [[#TyInt64]]
; CHECK-SPIRV: TypePointer [[#TyPtr:]] 8 [[#StructId]]
; CHECK-SPIRV: ConstantFunctionPointerINTEL [[#]] [[#FPtr1:]] [[#]]
; CHECK-SPIRV: ConstantFunctionPointerINTEL [[#]] [[#FPtr2:]] [[#]]
; CHECK-SPIRV: ConstantFunctionPointerINTEL [[#]] [[#FPtr3:]] [[#]]
; CHECK-SPIRV: PtrCastToGeneric [[#TyPtr]] [[#PtrCast1:]] [[#ObjPtr]]
; CHECK-SPIRV: TaskSequenceCreateINTEL [[#TyInt32]] [[#ObjId]] [[#PtrCast1]] [[#FPtr1]] [[#ConstantId1]]
; CHECK-SPIRV: PtrCastToGeneric [[#]] [[#PtrCast2:]] [[#ArrayId]]
; CHECK-SPIRV: TaskSequenceAsyncINTEL [[#PtrCast1]] [[#FPtr2]] [[#ObjId]] [[#ConstantId2]] [[#PtrCast2]] [[#PtrCast2]] [[#ConstantId3]]
; CHECK-SPIRV: TaskSequenceGetINTEL [[#TyInt32]] [[#GetRetId]] [[#PtrCast1]] [[#FPtr3]] [[#ConstantId2]] [[#ConstantId2]]
; CHECK-SPIRV: TaskSequenceReleaseINTEL [[#PtrCast1]]

; CHECK-LLVM: %call.i.i = call spir_func i32 @_Z31__spirv_TaskSequenceCreateINTEL{{.*}}(%task_sequence addrspace(4)* %sot_object.ascast.i, i32 (i32 addrspace(4)*, i32 addrspace(4)*, i32)* @_Z8user_sotPiS_i, i32 10) #0
; CHECK-LLVM: call spir_func void @_Z30__spirv_TaskSequenceAsyncINTEL{{.*}}(%task_sequence addrspace(4)* %sot_object.ascast.i, i32 (i32 addrspace(4)*, i32 addrspace(4)*, i32)* @_Z8user_sotPiS_i, i32 %call.i.i, i32 0, i32 addrspace(4)* %arraydecay.i, i32 addrspace(4)* %arraydecay.i, i32 128)
; CHECK-LLVM: %call.i7.i = call spir_func i32 @_Z28__spirv_TaskSequenceGetINTEL{{.*}}(%task_sequence addrspace(4)* %sot_object.ascast.i, i32 (i32 addrspace(4)*, i32 addrspace(4)*, i32)* @_Z8user_sotPiS_i, i32 0, i32 0) #0
; CHECK-LLVM: call spir_func void @_Z32__spirv_TaskSequenceReleaseINTEL{{.*}}(%task_sequence addrspace(4)* %sot_object.ascast.i) #0

; ModuleID = 'task_sequence'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%"task_sequence" = type { i32, i64 }

$main = comdat any

; Function Attrs: convergent norecurse
define weak_odr dso_local spir_kernel void @main() local_unnamed_addr #0 comdat !kernel_arg_buffer_location !4 {
entry:
  %d1.i = alloca [128 x i32], align 4
  %sot_object.i = alloca %"task_sequence", align 8
  %sot_object.ascast.i = addrspacecast %"task_sequence"* %sot_object.i to %"task_sequence" addrspace(4)*
  %call.i.i = call spir_func i32 @_Z31__spirv_TaskSequenceCreateINTELIN2cl4sycl3ext5intel12experimental13task_sequenceIL_Z8user_sotPiS6_iELj10EEEiJS6_S6_iEEjPT_PFT0_DpT1_Ej(%"task_sequence" addrspace(4)* %sot_object.ascast.i, i32 (i32 addrspace(4)*, i32 addrspace(4)*, i32)* nonnull @_Z8user_sotPiS_i, i32 10) #3
  %arraydecay1.i = getelementptr inbounds [128 x i32], [128 x i32]* %d1.i, i64 0, i64 0
  %arraydecay.i = addrspacecast i32* %arraydecay1.i to i32 addrspace(4)*
  call spir_func void @_Z30__spirv_TaskSequenceAsyncINTELIN2cl4sycl3ext5intel12experimental13task_sequenceIL_Z8user_sotPiS6_iELj10EEEiJS6_S6_iEEvPT_PFT0_DpT1_EjjSC_(%"task_sequence" addrspace(4)* %sot_object.ascast.i, i32 (i32 addrspace(4)*, i32 addrspace(4)*, i32)* nonnull @_Z8user_sotPiS_i, i32 %call.i.i, i32 0, i32 addrspace(4)* %arraydecay.i, i32 addrspace(4)* %arraydecay.i, i32 128) #3
  br label %for.cond.i.i

for.cond.i.i:                                     ; preds = %for.body.i.i, %entry
  %i.0.i.i = phi i32 [ 0, %entry ], [ %inc.i8.i, %for.body.i.i ]
  %cmp.i.i = icmp ult i32 %i.0.i.i, 1
  br i1 %cmp.i.i, label %for.body.i.i, label %_ZZZ4mainENKUlRN2cl4sycl7handlerEE_clES2_ENKUlNS0_14kernel_handlerEE_clES4_.exit

for.body.i.i:                                     ; preds = %for.cond.i.i
  %call.i7.i = call spir_func i32 @_Z28__spirv_TaskSequenceGetINTELIN2cl4sycl3ext5intel12experimental13task_sequenceIL_Z8user_sotPiS6_iELj10EEEiJS6_S6_iEET0_PT_PFS8_DpT1_Ejj(%"task_sequence" addrspace(4)* %sot_object.ascast.i, i32 (i32 addrspace(4)*, i32 addrspace(4)*, i32)* nonnull @_Z8user_sotPiS_i, i32 0, i32 0) #3
  %inc.i8.i = add nuw i32 %i.0.i.i, 1
  br label %for.cond.i.i, !llvm.loop !14

_ZZZ4mainENKUlRN2cl4sycl7handlerEE_clES2_ENKUlNS0_14kernel_handlerEE_clES4_.exit: ; preds = %for.cond.i.i
  call spir_func void @_Z32__spirv_TaskSequenceReleaseINTELIN2cl4sycl3ext5intel12experimental13task_sequenceIL_Z8user_sotPiS6_iELj10EEEEvPT_(%"task_sequence" addrspace(4)* %sot_object.ascast.i) #3
  ret void
}

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z31__spirv_TaskSequenceCreateINTELIN2cl4sycl3ext5intel12experimental13task_sequenceIL_Z8user_sotPiS6_iELj10EEEiJS6_S6_iEEjPT_PFT0_DpT1_Ej(%"task_sequence" addrspace(4)*, i32 (i32 addrspace(4)*, i32 addrspace(4)*, i32)*, i32) local_unnamed_addr #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind readonly willreturn
define dso_local spir_func i32 @_Z8user_sotPiS_i(i32 addrspace(4)* nocapture readonly %data1, i32 addrspace(4)* nocapture readonly %data2, i32 %N) #2 {                            ; preds = %for.cond
  ret i32 0
}

; Function Attrs: convergent nounwind
declare dso_local spir_func void @_Z30__spirv_TaskSequenceAsyncINTELIN2cl4sycl3ext5intel12experimental13task_sequenceIL_Z8user_sotPiS6_iELj10EEEiJS6_S6_iEEvPT_PFT0_DpT1_EjjSC_(%"task_sequence" addrspace(4)*, i32 (i32 addrspace(4)*, i32 addrspace(4)*, i32)*, i32, i32, i32 addrspace(4)*, i32 addrspace(4)*, i32) local_unnamed_addr #1

; Function Attrs: convergent nounwind
declare dso_local spir_func i32 @_Z28__spirv_TaskSequenceGetINTELIN2cl4sycl3ext5intel12experimental13task_sequenceIL_Z8user_sotPiS6_iELj10EEEiJS6_S6_iEET0_PT_PFS8_DpT1_Ejj(%"task_sequence" addrspace(4)*, i32 (i32 addrspace(4)*, i32 addrspace(4)*, i32)*, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent nounwind
declare dso_local spir_func void @_Z32__spirv_TaskSequenceReleaseINTELIN2cl4sycl3ext5intel12experimental13task_sequenceIL_Z8user_sotPiS6_iELj10EEEEvPT_(%"task_sequence" addrspace(4)*) local_unnamed_addr #1

attributes #0 = { convergent norecurse "denormal-fp-math"="preserve-sign,preserve-sign" "denormal-fp-math-f32"="ieee,ieee" "frame-pointer"="all" "min-legal-vector-width"="0" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="task_sequence.cpp" "uniform-work-group-size"="true" "unsafe-fp-math"="true" }
attributes #1 = { convergent nounwind "denormal-fp-math"="preserve-sign,preserve-sign" "denormal-fp-math-f32"="ieee,ieee" "frame-pointer"="all" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind readonly willreturn "denormal-fp-math"="preserve-sign,preserve-sign" "denormal-fp-math-f32"="ieee,ieee" "frame-pointer"="all" "min-legal-vector-width"="0" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #3 = { convergent nounwind }

!llvm.module.flags = !{!0, !1}
!opencl.spir.version = !{!2}
!spirv.Source = !{!3}
!opencl.used.extensions = !{!4}
!opencl.used.optional.core.features = !{!4}
!opencl.compiler.options = !{!4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{i32 1, i32 2}
!3 = !{i32 4, i32 100000}
!4 = !{}
!5 = !{!"Compiler"}
!6 = !{i32 -1, i32 -1, i32 -1, i32 -1}
!7 = !{!8, !9, i64 0}
!8 = !{!"_ZTSN2cl4sycl3ext5intel12experimental13task_sequenceIL_Z8user_sotPiS5_iELj10EEE", !9, i64 0, !12, i64 8}
!9 = !{!"int", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C++ TBAA"}
!12 = !{!"long", !10, i64 0}
!13 = !{!8, !12, i64 8}
!14 = distinct !{!14, !15}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!9, !9, i64 0}
!17 = distinct !{!17, !15}
