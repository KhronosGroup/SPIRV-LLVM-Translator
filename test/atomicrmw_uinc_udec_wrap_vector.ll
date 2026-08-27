; uinc_wrap/udec_wrap also accept a fixed vector of integers. Verify a vector
; operand round-trips through its own helper, like a scalar: the _p<addrspace>_
; <type> suffix spells the value type the LLVM way (<2 x i32> -> v2i32), so the
; three differing element widths resolve to distinct declarations.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM
; RUN: spirv-val %t.spv

; CHECK-SPIRV-DAG: Decorate [[UIncFnV2I32:[0-9]+]] LinkageAttributes "__translate_spirv_atomic_uinc_wrap_p1_v2i32" Import
; CHECK-SPIRV-DAG: Decorate [[UDecFnV4I16:[0-9]+]] LinkageAttributes "__translate_spirv_atomic_udec_wrap_p1_v4i16" Import
; CHECK-SPIRV-DAG: Decorate [[UIncFnV8I8:[0-9]+]] LinkageAttributes "__translate_spirv_atomic_uinc_wrap_p1_v8i8" Import

; CHECK-SPIRV-DAG: TypeInt [[Int:[0-9]+]] 32 0
; CHECK-SPIRV-DAG: TypeInt [[Short:[0-9]+]] 16 0
; CHECK-SPIRV-DAG: TypeInt [[Char:[0-9]+]] 8 0
; CHECK-SPIRV-DAG: TypeVector [[V2I32:[0-9]+]] [[Int]] 2
; CHECK-SPIRV-DAG: TypeVector [[V4I16:[0-9]+]] [[Short]] 4
; CHECK-SPIRV-DAG: TypeVector [[V8I8:[0-9]+]] [[Char]] 8
; CHECK-SPIRV-DAG: Constant [[Int]] [[Scope_CrossDevice:[0-9]+]] 0{{ *$}}
; CHECK-SPIRV-DAG: Constant [[Int]] [[MemSem_SequentiallyConsistent:[0-9]+]] 528{{ *$}}

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv64-amd-amdhsa"

@uv2i32 = common dso_local addrspace(1) global <2 x i32> zeroinitializer, align 8
@uv4i16 = common dso_local addrspace(1) global <4 x i16> zeroinitializer, align 8
@uv8i8 = common dso_local addrspace(1) global <8 x i8> zeroinitializer, align 8

; CHECK-SPIRV: FunctionCall [[V2I32]] [[#]] [[UIncFnV2I32]] [[#]] [[Scope_CrossDevice]] [[MemSem_SequentiallyConsistent]] [[#]]
; CHECK-LLVM: atomicrmw uinc_wrap ptr addrspace(1) @uv2i32, <2 x i32> splat (i32 42) seq_cst, align 8
define dso_local spir_func void @uinc_wrap_v2i32() local_unnamed_addr {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @uv2i32, <2 x i32> splat (i32 42) seq_cst
  ret void
}

; CHECK-SPIRV: FunctionCall [[V4I16]] [[#]] [[UDecFnV4I16]] [[#]] [[Scope_CrossDevice]] [[MemSem_SequentiallyConsistent]] [[#]]
; CHECK-LLVM: atomicrmw udec_wrap ptr addrspace(1) @uv4i16, <4 x i16> splat (i16 42) seq_cst, align 8
define dso_local spir_func void @udec_wrap_v4i16() local_unnamed_addr {
entry:
  %r = atomicrmw udec_wrap ptr addrspace(1) @uv4i16, <4 x i16> splat (i16 42) seq_cst
  ret void
}

; CHECK-SPIRV: FunctionCall [[V8I8]] [[#]] [[UIncFnV8I8]] [[#]] [[Scope_CrossDevice]] [[MemSem_SequentiallyConsistent]] [[#]]
; CHECK-LLVM: atomicrmw uinc_wrap ptr addrspace(1) @uv8i8, <8 x i8> splat (i8 42) seq_cst, align 8
define dso_local spir_func void @uinc_wrap_v8i8() local_unnamed_addr {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @uv8i8, <8 x i8> splat (i8 42) seq_cst
  ret void
}
