; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s

target datalayout = "e-p:64:64"
target triple = "spir64-unknown-unknown"

; CHECK:     EntryPoint 6 [[#]] "global_check" [[#var0:]] [[#var1:]] [[#var2:]] [[#var3:]]
; CHECK:     EntryPoint 6 [[#]] "writer" [[#var0]] [[#var1]] [[#var2]] [[#var3]]
; CHECK:     EntryPoint 6 [[#]] "reader" [[#var0]] [[#var1]] [[#var2]] [[#var3]]
; CHECK-DAG: Name [[#var0]] "var"
; CHECK-DAG: Name [[#var1]] "g_var"
; CHECK-DAG: Name [[#var2]] "a_var"
; CHECK-DAG: Name [[#var3]] "p_var"

@var = addrspace(1) global <2 x i8> zeroinitializer, align 2
@g_var = addrspace(1) global <2 x i8> zeroinitializer, align 2
@a_var = addrspace(1) global [2 x <2 x i8>] zeroinitializer, align 2
@p_var = addrspace(1) global <2 x i8> addrspace(1)* null, align 8

define spir_kernel void @global_check() {
entry:
  %v = load <2 x i8>, <2 x i8> addrspace(1)* @var
  %g = load <2 x i8>, <2 x i8> addrspace(1)* @g_var
  %a_ptr = getelementptr inbounds [2 x <2 x i8>], [2 x <2 x i8>] addrspace(1)* @a_var, i64 0, i64 0
  %a = load <2 x i8>, <2 x i8> addrspace(1)* %a_ptr
  %p = load <2 x i8> addrspace(1)*, <2 x i8> addrspace(1)* addrspace(1)* @p_var
  ret void
}

define spir_kernel void @writer() {
entry:
  store <2 x i8> zeroinitializer, <2 x i8> addrspace(1)* @var
  store <2 x i8> zeroinitializer, <2 x i8> addrspace(1)* @g_var
  %a_ptr = getelementptr inbounds [2 x <2 x i8>], [2 x <2 x i8>] addrspace(1)* @a_var, i64 0, i64 1
  store <2 x i8> zeroinitializer, <2 x i8> addrspace(1)* %a_ptr
  %p_target = inttoptr i64 0 to <2 x i8> addrspace(1)*
  store <2 x i8> addrspace(1)* %p_target, <2 x i8> addrspace(1)* addrspace(1)* @p_var
  ret void
}

define spir_kernel void @reader() {
entry:
  %v = load <2 x i8>, <2 x i8> addrspace(1)* @var
  %g = load <2 x i8>, <2 x i8> addrspace(1)* @g_var
  %a_ptr = getelementptr inbounds [2 x <2 x i8>], [2 x <2 x i8>] addrspace(1)* @a_var, i64 0, i64 1
  %a = load <2 x i8>, <2 x i8> addrspace(1)* %a_ptr
  %p = load <2 x i8> addrspace(1)*, <2 x i8> addrspace(1)* addrspace(1)* @p_var
  ret void
}
