; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-DAG: EntryPoint 6 [[#test_func:]] "test"
; CHECK-DAG: Decorate [[#f2_decl:]] LinkageAttributes "BuiltInGlobalOffset" Import
; CHECK-DAG: TypeInt [[#int32_ty:]] 32 0
; CHECK-DAG: TypePointer [[#i32ptr_ty:]] 5 [[#int32_ty]]
; CHECK-DAG: TypeVoid [[#void_ty:]]
; CHECK-DAG: TypeFunction [[#func_ty:]] [[#void_ty]] [[#i32ptr_ty]]
; CHECK-DAG: TypeInt [[#int64_ty:]] 64 0
; CHECK-DAG: TypeVector [[#vec_ty:]] [[#int64_ty]] 3
; CHECK-DAG: TypeFunction [[#func2_ty:]] [[#vec_ty]]
; CECK-DAG: Function [[#vec_ty]] [[#f2_decl]] 0 [[#func2_ty]]
; CHECK: FunctionEnd

define spir_kernel void @test(i32 addrspace(1)* %outOffsets) {
entry:
  %0 = call spir_func <3 x i64> @BuiltInGlobalOffset() #1
  %call = extractelement <3 x i64> %0, i32 0
  %conv = trunc i64 %call to i32

; CHECK: InBoundsPtrAccessChain [[#i32ptr_ty]] [[#i1:]] [[#outOffsets:]] 
; CHECK: Store [[#i1]] [[#]] 2 4

  %arrayidx = getelementptr inbounds i32, i32 addrspace(1)* %outOffsets, i64 0
  store i32 %conv, i32 addrspace(1)* %arrayidx, align 4
  %1 = call spir_func <3 x i64> @BuiltInGlobalOffset() #1
  %call1 = extractelement <3 x i64> %1, i32 1
  %conv2 = trunc i64 %call1 to i32

; CHECK: InBoundsPtrAccessChain [[#i32ptr_ty]] [[#i2:]] [[#outOffsets]] 
; CHECK: Store [[#i2]] [[#]] 2 4

  %arrayidx3 = getelementptr inbounds i32, i32 addrspace(1)* %outOffsets, i64 1
  store i32 %conv2, i32 addrspace(1)* %arrayidx3, align 4
  %2 = call spir_func <3 x i64> @BuiltInGlobalOffset() #1
  %call4 = extractelement <3 x i64> %2, i32 2
  %conv5 = trunc i64 %call4 to i32

; CHECK: InBoundsPtrAccessChain [[#i32ptr_ty]] [[#i3:]] [[#outOffsets]] 
; CHECK: Store [[#i3]] [[#]] 2 4

  %arrayidx6 = getelementptr inbounds i32, i32 addrspace(1)* %outOffsets, i64 2
  store i32 %conv5, i32 addrspace(1)* %arrayidx6, align 4
  ret void
}
declare spir_func <3 x i64> @BuiltInGlobalOffset() #1
attributes #1 = { nounwind readnone }
