; uinc_wrap/udec_wrap have no SPIR-V opcode; on an AMD triple they are carried
; across as a call to an imported __translate_spirv_atomic_u{inc,dec}_wrap
; helper and restored to the original atomicrmw on reverse translation. The name
; carries a _p<addrspace>_i<width> suffix since SPIR-V resolves an import by
; linkage name alone. This is an AMD internal spirv builtin; other vendors
; report the atomicrmw as unsupported (atomicrmw_uinc_udec_wrap_non_amd.ll).

; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM
; RUN: spirv-val %t.spv

; All helpers are imported; each distinct (address space, value type) gets its
; own declaration.
; CHECK-SPIRV-DAG: Decorate [[#UIncFn:]] LinkageAttributes "__translate_spirv_atomic_uinc_wrap_p1_i32" Import
; CHECK-SPIRV-DAG: Decorate [[#UDecFn:]] LinkageAttributes "__translate_spirv_atomic_udec_wrap_p1_i32" Import
; CHECK-SPIRV-DAG: Decorate [[#UIncFnLocal:]] LinkageAttributes "__translate_spirv_atomic_uinc_wrap_p3_i32" Import
; CHECK-SPIRV-DAG: Decorate [[#UIncFn64:]] LinkageAttributes "__translate_spirv_atomic_uinc_wrap_p1_i64" Import

; CHECK-SPIRV: TypeInt [[#Int:]] 32 0
; CHECK-SPIRV-DAG: TypeInt [[#Long:]] 64 0
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#Scope_CrossDevice:]] 0{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#Scope_Device:]] 1{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#Scope_Workgroup:]] 2{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#Scope_Subgroup:]] 3{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#Scope_Invocation:]] 4{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#MemSem_Relaxed:]] 512{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#MemSem_Acquire:]] 514{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#MemSem_Release:]] 516{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#MemSem_AcquireRelease:]] 520{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#MemSem_SequentiallyConsistent:]] 528{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#Value:]] 42{{ *$}}
; The storage class contributes to the memory semantics: a Workgroup pointer
; carries WorkgroupMemory (256), a CrossWorkgroup one CrossWorkgroupMemory (512).
; CHECK-SPIRV-DAG: Constant [[#Int]] [[#MemSem_Relaxed_Local:]] 256{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Long]] [[#Value64:]] 42 0{{ *$}}

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv64-amd-amdhsa"

@ui = common dso_local addrspace(1) global i32 0, align 4
@lui = common dso_local addrspace(3) global i32 0, align 4
@ul = common dso_local addrspace(1) global i64 0, align 8

; Memory orderings, on the default (system) sync scope.

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UIncFn]] [[#]] [[#Scope_CrossDevice]] [[#MemSem_Relaxed]] [[#Value]]
; CHECK-LLVM: atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 monotonic
define spir_func void @test_uinc_wrap_monotonic() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 monotonic
  ret void
}

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UIncFn]] [[#]] [[#Scope_CrossDevice]] [[#MemSem_Acquire]] [[#Value]]
; CHECK-LLVM: atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 acquire
define spir_func void @test_uinc_wrap_acquire() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 acquire
  ret void
}

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UIncFn]] [[#]] [[#Scope_CrossDevice]] [[#MemSem_Release]] [[#Value]]
; CHECK-LLVM: atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 release
define spir_func void @test_uinc_wrap_release() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 release
  ret void
}

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UIncFn]] [[#]] [[#Scope_CrossDevice]] [[#MemSem_AcquireRelease]] [[#Value]]
; CHECK-LLVM: atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 acq_rel
define spir_func void @test_uinc_wrap_acq_rel() {
entry:
  %r = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 acq_rel
  ret void
}

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UDecFn]] [[#]] [[#Scope_CrossDevice]] [[#MemSem_SequentiallyConsistent]] [[#Value]]
; CHECK-LLVM: atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 seq_cst
define spir_func void @test_udec_wrap_seq_cst() {
entry:
  %r = atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 seq_cst
  ret void
}

; Sync scopes. The reverse translation picks the generic LLVM scope names for a
; non-AMDGCN target triple.

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UDecFn]] [[#]] [[#Scope_Device]] [[#MemSem_SequentiallyConsistent]] [[#Value]]
; CHECK-LLVM: atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("device") seq_cst
define spir_func void @test_udec_wrap_device_scope() {
entry:
  %r = atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("device") seq_cst
  ret void
}

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UDecFn]] [[#]] [[#Scope_Workgroup]] [[#MemSem_SequentiallyConsistent]] [[#Value]]
; CHECK-LLVM: atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("workgroup") seq_cst
define spir_func void @test_udec_wrap_workgroup_scope() {
entry:
  %r = atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("workgroup") seq_cst
  ret void
}

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UDecFn]] [[#]] [[#Scope_Subgroup]] [[#MemSem_SequentiallyConsistent]] [[#Value]]
; CHECK-LLVM: atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("subgroup") seq_cst
define spir_func void @test_udec_wrap_subgroup_scope() {
entry:
  %r = atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("subgroup") seq_cst
  ret void
}

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UDecFn]] [[#]] [[#Scope_Invocation]] [[#MemSem_SequentiallyConsistent]] [[#Value]]
; CHECK-LLVM: atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("singlethread") seq_cst
define spir_func void @test_udec_wrap_singlethread_scope() {
entry:
  %r = atomicrmw udec_wrap ptr addrspace(1) @ui, i32 42 syncscope("singlethread") seq_cst
  ret void
}

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UIncFn]] [[#]] [[#Scope_CrossDevice]] [[#MemSem_Relaxed]] [[#Value]]
; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UIncFnLocal]] [[#]] [[#Scope_CrossDevice]] [[#MemSem_Relaxed_Local]] [[#Value]]
; CHECK-LLVM: atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 monotonic
; CHECK-LLVM: atomicrmw uinc_wrap ptr addrspace(3) @lui, i32 42 monotonic
define spir_func void @test_uinc_wrap_mixed_addrspace() {
entry:
  %g = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 monotonic
  %l = atomicrmw uinc_wrap ptr addrspace(3) @lui, i32 42 monotonic
  ret void
}

; CHECK-SPIRV: FunctionCall [[#Int]] [[#]] [[#UIncFn]] [[#]] [[#Scope_CrossDevice]] [[#MemSem_Relaxed]] [[#Value]]
; CHECK-SPIRV: FunctionCall [[#Long]] [[#]] [[#UIncFn64]] [[#]] [[#Scope_CrossDevice]] [[#MemSem_Relaxed]] [[#Value64]]
; CHECK-LLVM: atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 monotonic
; CHECK-LLVM: atomicrmw uinc_wrap ptr addrspace(1) @ul, i64 42 monotonic
define spir_func void @test_uinc_wrap_mixed_width() {
entry:
  %a = atomicrmw uinc_wrap ptr addrspace(1) @ui, i32 42 monotonic
  %b = atomicrmw uinc_wrap ptr addrspace(1) @ul, i64 42 monotonic
  ret void
}
