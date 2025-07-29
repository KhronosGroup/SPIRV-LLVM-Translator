; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o - -spirv-text | FileCheck %s
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir-unknown-unknown"

; CHECK-DAG: TypeEvent [[#EventTy:]]
; CHECK-DAG: TypeStruct [[#StructEventTy:]] [[#EventTy]]
; CHECK-DAG: TypePointer [[#FunPtrStructEventTy:]] 7 [[#StructEventTy]]
; CHECK-DAG: TypePointer [[#GenPtrEventTy:]] 8 [[#StructEventTy]]
; CHECK-DAG: TypePointer [[#FunPtrEventTy:]] 8 [[#EventTy]]
; CHECK: Function
; CHECK: Variable [[#FunPtrStructEventTy]] [[#Var:]] 7
; CHECK-NEXT:  PtrCastToGeneric [[#GenPtrEventTy]] [[#GenEvent:]] [[#Var]]
; CHECK-NEXT:  Bitcast [[#FunPtrEventTy]] [[#FunEvent:]] [[#GenEvent]]
; CHECK-NEXT:  GroupWaitEvents [[#]] [[#]] [[#FunEvent]]

%"class.sycl::_V1::device_event" = type { target("spirv.Event") }

define weak_odr dso_local spir_kernel void @foo() {
entry:
  %var = alloca %"class.sycl::_V1::device_event"
  %eventptr = addrspacecast ptr %var to ptr addrspace(4)
  call spir_func void @_Z23__spirv_GroupWaitEventsjiP9ocl_event(i32 2, i32 1, ptr addrspace(4) %eventptr)
  ret void
}

declare dso_local spir_func void @_Z23__spirv_GroupWaitEventsjiP9ocl_event(i32, i32, ptr addrspace(4))
