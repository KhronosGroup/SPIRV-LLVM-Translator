; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t
; RUN: FileCheck < %t %s
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir"

; CHECK: Name [[#]] "var"
; CHECK: Name [[#Gvar:]] "g_var"
; CHECK: Name [[#Avar:]] "a_var"
; CHECK: Name [[#Pvar:]] "p_var"
; CHECK-DAG: TypeInt [[#CharTy:]] 8 0
; CHECK-DAG: TypeInt [[#IntTy:]] 32 0
; CHECK-DAG: TypeVector [[#V2CharTy:]] [[#CharTy]] 2
; CHECK-DAG: ConstantNull [[#V2CharTy]] [[#V2ConstNull:]]
; CHECK-DAG: Constant [[#CharTy]] [[#Const1:]] 1
; CHECK-DAG: Constant [[#IntTy]] [[#Const2:]] 2
; CHECK-DAG: TypeArray  [[#Arr2V2CharTy:]] [[#V2CharTy]] [[#Const2]]
; CHECK-DAG: TypeInt [[#LongTy:]] 64 0
; CHECK-DAG: TypePointer [[#PtrV2CharTy:]] 5 [[#V2CharTy]]
; CHECK-DAG: ConstantComposite [[#V2CharTy]] [[#V2Char1:]] [[#Const1]] [[#Const1]]
; CHECK-DAG: ConstantComposite [[#Arr2V2CharTy]] [[#Arr2V2Char:]] [[#V2Char1]] [[#V2Char1]]
; CHECK-DAG: TypePointer [[#PtrCharTy:]] 5 [[#CharTy]]
; CHECK-DAG: TypePointer [[#PtrArr2V2CharTy:]] 5 [[#Arr2V2CharTy]]
; CHECK-DAG: Constant [[#LongTy]] [[#LongZero:]] 0
; CHECK-DAG: Constant [[#LongTy]] [[#ConstLong2:]] 2
; CHECK-DAG: SpecConstantOp [[#]] [[#PvarInit:]] [[#]] 17 [[#ConstLong2]]
; CHECK-DAG: TypePointer [[#PtrPtrCharTy:]] 5 [[#PtrCharTy]]
; CHECK-DAG: Variable [[#PtrArr2V2CharTy]] [[#Avar]] 5 [[#Arr2V2Char]]
; CHECK-DAG: Variable [[#PtrPtrCharTy]] [[#Pvar]] 5 [[#PvarInit]]
; CHECK-DAG: Variable [[#PtrV2CharTy]] [[#Gvar]] 5 [[#V2Char1]]
; CHECK-DAG: Variable [[#PtrV2CharTy]] [[#]] 5 [[#V2ConstNull]]

@var = addrspace(1) global <2 x i8> zeroinitializer, align 2
@g_var = addrspace(1) global <2 x i8> <i8 1, i8 1>, align 2
@a_var = addrspace(1) global [2 x <2 x i8>] [<2 x i8> <i8 1, i8 1>, <2 x i8> <i8 1, i8 1>], align 2
@p_var = addrspace(1) global ptr addrspace(1) getelementptr (i8, ptr addrspace(1) @a_var, i64 2), align 8

define spir_func <2 x i8> @from_buf(<2 x i8> %a) #0 {
entry:
  ret <2 x i8> %a
}

define spir_func <2 x i8> @to_buf(<2 x i8> %a) #0 {
entry:
  ret <2 x i8> %a
}

define spir_kernel void @writer(ptr addrspace(1) %src, i32 %idx) #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_type_qual !8 !kernel_arg_base_type !7 !spirv.ParameterDecorations !9 {
entry:
  %arrayidx = getelementptr inbounds <2 x i8>, ptr addrspace(1) %src, i64 0
  %0 = load <2 x i8>, ptr addrspace(1) %arrayidx, align 2
  %call = call spir_func <2 x i8> @from_buf(<2 x i8> %0) #0
  store <2 x i8> %call, ptr addrspace(1) @var, align 2
  %arrayidx1 = getelementptr inbounds <2 x i8>, ptr addrspace(1) %src, i64 1
  %1 = load <2 x i8>, ptr addrspace(1) %arrayidx1, align 2
  %call2 = call spir_func <2 x i8> @from_buf(<2 x i8> %1) #0
  store <2 x i8> %call2, ptr addrspace(1) @g_var, align 2
  %arrayidx3 = getelementptr inbounds <2 x i8>, ptr addrspace(1) %src, i64 2
  %2 = load <2 x i8>, ptr addrspace(1) %arrayidx3, align 2
  %call4 = call spir_func <2 x i8> @from_buf(<2 x i8> %2) #0
  %3 = getelementptr inbounds [2 x <2 x i8>], ptr addrspace(1) @a_var, i64 0, i64 0
  store <2 x i8> %call4, ptr addrspace(1) %3, align 2
  %arrayidx5 = getelementptr inbounds <2 x i8>, ptr addrspace(1) %src, i64 3
  %4 = load <2 x i8>, ptr addrspace(1) %arrayidx5, align 2
  %call6 = call spir_func <2 x i8> @from_buf(<2 x i8> %4) #0
  %5 = getelementptr inbounds [2 x <2 x i8>], ptr addrspace(1) @a_var, i64 0, i64 1
  store <2 x i8> %call6, ptr addrspace(1) %5, align 2
  %idx.ext = zext i32 %idx to i64
  %add.ptr = getelementptr inbounds <2 x i8>, ptr addrspace(1) %3, i64 %idx.ext
  store ptr addrspace(1) %add.ptr, ptr addrspace(1) @p_var, align 8
  ret void
}

define spir_kernel void @reader(ptr addrspace(1) %dest, <2 x i8> %ptr_write_val) #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !10 !kernel_arg_type_qual !8 !kernel_arg_base_type !10 !spirv.ParameterDecorations !9 {
entry:
  %call = call spir_func <2 x i8> @from_buf(<2 x i8> %ptr_write_val) #0
  %0 = load ptr addrspace(1), ptr addrspace(1) @p_var, align 8
  store volatile <2 x i8> %call, ptr addrspace(1) %0, align 2
  %1 = load <2 x i8>, ptr addrspace(1) @var, align 2
  %call1 = call spir_func <2 x i8> @to_buf(<2 x i8> %1) #0
  %arrayidx = getelementptr inbounds <2 x i8>, ptr addrspace(1) %dest, i64 0
  store <2 x i8> %call1, ptr addrspace(1) %arrayidx, align 2
  %2 = load <2 x i8>, ptr addrspace(1) @g_var, align 2
  %call2 = call spir_func <2 x i8> @to_buf(<2 x i8> %2) #0
  %arrayidx3 = getelementptr inbounds <2 x i8>, ptr addrspace(1) %dest, i64 1
  store <2 x i8> %call2, ptr addrspace(1) %arrayidx3, align 2
  %3 = getelementptr inbounds [2 x <2 x i8>], ptr addrspace(1) @a_var, i64 0, i64 0
  %4 = load <2 x i8>, ptr addrspace(1) %3, align 2
  %call4 = call spir_func <2 x i8> @to_buf(<2 x i8> %4) #0
  %arrayidx5 = getelementptr inbounds <2 x i8>, ptr addrspace(1) %dest, i64 2
  store <2 x i8> %call4, ptr addrspace(1) %arrayidx5, align 2
  %5 = getelementptr inbounds [2 x <2 x i8>], ptr addrspace(1) @a_var, i64 0, i64 1
  %6 = load <2 x i8>, ptr addrspace(1) %5, align 2
  %call6 = call spir_func <2 x i8> @to_buf(<2 x i8> %6) #0
  %arrayidx7 = getelementptr inbounds <2 x i8>, ptr addrspace(1) %dest, i64 3
  store <2 x i8> %call6, ptr addrspace(1) %arrayidx7, align 2
  ret void
}

attributes #0 = { nounwind }

!spirv.MemoryModel = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!spirv.Source = !{!1}
!opencl.spir.version = !{!2}
!opencl.ocl.version = !{!2}
!opencl.used.extensions = !{!3}
!opencl.used.optional.core.features = !{!3}
!spirv.Generator = !{!4}

!0 = !{i32 2, i32 2}
!1 = !{i32 3, i32 200000}
!2 = !{i32 2, i32 0}
!3 = !{}
!4 = !{i16 6, i16 14}
!5 = !{i32 1, i32 0}
!6 = !{!"none", !"none"}
!7 = !{!"char2*", !"int"}
!8 = !{!"", !""}
!9 = !{!3, !3}
!10 = !{!"char2*", !"char2"}
