; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %s -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; This test checks that alloca instructions not in the entry block are hoisted
; to the entry block with appropriate lifetime intrinsics, as required by SPIR-V.
;
; Test scenarios:
; 1. Simple case: alloca in non-entry block
; 2. Multiple allocas in different non-entry blocks
; 3. Alloca with multiple return points
; 4. Alloca already in entry block (should not be modified)

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir64-unknown-unknown"

; All Name declarations appear together at the top
; CHECK-SPIRV-DAG: Name [[F:[0-9]+]] "simple_case"
; CHECK-SPIRV-DAG: Name [[CONVERSION:[0-9]+]] "conversion"
; CHECK-SPIRV-DAG: Name [[TOP:[0-9]+]] "top"
; CHECK-SPIRV-DAG: Name [[AS:[0-9]+]] "As"
; CHECK-SPIRV-DAG: Name [[MULTI:[0-9]+]] "test_multiple_allocas"
; CHECK-SPIRV-DAG: Name [[ENTRY:[0-9]+]] "entry"
; CHECK-SPIRV-DAG: Name [[BB1:[0-9]+]] "bb1"
; CHECK-SPIRV-DAG: Name [[BB2:[0-9]+]] "bb2"
; CHECK-SPIRV-DAG: Name [[EXIT:[0-9]+]] "exit"
; CHECK-SPIRV-DAG: Name [[VAR1:[0-9]+]] "var1"
; CHECK-SPIRV-DAG: Name [[VAR2:[0-9]+]] "var2"
; CHECK-SPIRV-DAG: Name [[MULTI_RET:[0-9]+]] "test_multiple_returns"
; CHECK-SPIRV-DAG: Name [[VAR:[0-9]+]] "var"
; CHECK-SPIRV-DAG: Name [[NO_MOVE:[0-9]+]] "test_entry_alloca"
; CHECK-SPIRV-DAG: Name [[VAR_ENTRY:[0-9]+]] "var_entry"

; CHECK-SPIRV: TypeInt [[I64:[0-9]+]] 64 0
; CHECK-SPIRV: Constant [[I64]] [[CONST1:[0-9]+]] 1 0
; CHECK-SPIRV: TypeArray [[ARR:[0-9]+]] [[I64]] [[CONST1]]
; CHECK-SPIRV: TypePointer [[PTR:[0-9]+]] 7 [[ARR]]

; Test 1: Simple case - alloca in non-entry block
; CHECK-SPIRV: Function {{[0-9]+}} [[F]] 0
; CHECK-SPIRV: Label [[CONVERSION]]
; Verify OpVariable is in the first block (entry block)
; CHECK-SPIRV-NEXT: Variable [[PTR]] [[AS]] 7
; CHECK-SPIRV-NEXT: Branch [[TOP]]
; CHECK-SPIRV: Label [[TOP]]
; Verify lifetime intrinsics are inserted in the original block
; CHECK-SPIRV-NEXT: LifetimeStart [[AS]] 0
; CHECK-SPIRV-NEXT: LifetimeStop [[AS]] 0
; CHECK-SPIRV-NEXT: Return

; CHECK-LLVM: define spir_kernel void @simple_case()
; CHECK-LLVM: conversion:
; Verify alloca is moved to entry block
; CHECK-LLVM-NEXT: %As = alloca [1 x i64], align 8
; CHECK-LLVM-NEXT: br label %top
; CHECK-LLVM: top:
; Verify lifetime intrinsics are in the original block
; CHECK-LLVM-NEXT: call void @llvm.lifetime.start.p0(ptr %As)
; CHECK-LLVM-NEXT: call void @llvm.lifetime.end.p0(ptr %As)
; CHECK-LLVM-NEXT: ret void

define spir_kernel void @simple_case() {
conversion:
  br label %top

top:                                              ; preds = %conversion
  %As = alloca [1 x i64], align 8
  ret void
}

; Test 2: Multiple allocas in different non-entry blocks
; CHECK-SPIRV: Function {{[0-9]+}} [[MULTI]]
; CHECK-SPIRV: Label [[ENTRY]]
; Both variables should be in entry block
; CHECK-SPIRV: Variable {{[0-9]+}} [[VAR1]] 7
; CHECK-SPIRV-NEXT: Variable {{[0-9]+}} [[VAR2]] 7

; CHECK-SPIRV: Label [[BB1]]
; Lifetime start/end for var1 wraps usage in its original block
; CHECK-SPIRV: LifetimeStart [[VAR1]]
; CHECK-SPIRV: LifetimeStop [[VAR1]]

; CHECK-SPIRV: Label [[BB2]]
; Lifetime start/end for var2 wraps usage in its original block
; CHECK-SPIRV: LifetimeStart [[VAR2]]
; CHECK-SPIRV: LifetimeStop [[VAR2]]

; CHECK-SPIRV: Label [[EXIT]]
; No lifetime intrinsics at final return
; CHECK-SPIRV: Return

; CHECK-LLVM: define spir_kernel void @test_multiple_allocas(i32 %cond)
; CHECK-LLVM: entry:
; Both allocas moved to entry
; CHECK-LLVM: %var1 = alloca i32, align 4
; CHECK-LLVM-NEXT: %var2 = alloca i64, align 8
; CHECK-LLVM: bb1:
; Lifetime intrinsics wrap usage in original block
; CHECK-LLVM: call void @llvm.lifetime.start.p0(ptr %var1)
; CHECK-LLVM: call void @llvm.lifetime.end.p0(ptr %var1)
; CHECK-LLVM: bb2:
; CHECK-LLVM: call void @llvm.lifetime.start.p0(ptr %var2)
; CHECK-LLVM: call void @llvm.lifetime.end.p0(ptr %var2)
; CHECK-LLVM: exit:
; CHECK-LLVM: ret void

define spir_kernel void @test_multiple_allocas(i32 %cond) {
entry:
  %cmp = icmp eq i32 %cond, 0
  br i1 %cmp, label %bb1, label %bb2

bb1:
  %var1 = alloca i32, align 4
  store i32 42, ptr %var1, align 4
  br label %exit

bb2:
  %var2 = alloca i64, align 8
  store i64 123, ptr %var2, align 8
  br label %exit

exit:
  ret void
}

; Test 3: Alloca with multiple return points
; CHECK-SPIRV: Function {{[0-9]+}} [[MULTI_RET]]
; CHECK-SPIRV: Label {{[0-9]+}}
; Variable in entry block
; CHECK-SPIRV-NEXT: Variable {{[0-9]+}} [[VAR]] 7

; Lifetime intrinsics only in the block where alloca was originally used
; CHECK-SPIRV: LifetimeStart [[VAR]]
; CHECK-SPIRV: LifetimeStop [[VAR]]
; CHECK-SPIRV-NEXT: Return
; The else block has no lifetime intrinsics (alloca wasn't used there)
; CHECK-SPIRV: Return

; CHECK-LLVM: define spir_kernel void @test_multiple_returns(i32 %cond)
; CHECK-LLVM: entry:
; CHECK-LLVM: %var = alloca i32, align 4
; CHECK-LLVM: then:
; Lifetime intrinsics wrap usage in the original block
; CHECK-LLVM: call void @llvm.lifetime.start.p0(ptr %var)
; CHECK-LLVM: call void @llvm.lifetime.end.p0(ptr %var)
; CHECK-LLVM-NEXT: ret void
; CHECK-LLVM: else:
; No lifetime intrinsics in else (alloca wasn't originally here)
; CHECK-LLVM-NEXT: ret void

define spir_kernel void @test_multiple_returns(i32 %cond) {
entry:
  %cmp = icmp eq i32 %cond, 0
  br i1 %cmp, label %then, label %else

then:
  %var = alloca i32, align 4
  store i32 1, ptr %var, align 4
  ret void

else:
  ret void
}

; Test 4: Alloca already in entry block (should not be modified)
; CHECK-SPIRV: Function {{[0-9]+}} [[NO_MOVE]]
; CHECK-SPIRV: Label {{[0-9]+}}
; CHECK-SPIRV-NEXT: Variable {{[0-9]+}} [[VAR_ENTRY]] 7
; No lifetime intrinsics should be added if already in entry
; CHECK-SPIRV-NOT: LifetimeStart [[VAR_ENTRY]]

; CHECK-LLVM: define spir_kernel void @test_entry_alloca()
; CHECK-LLVM: entry:
; CHECK-LLVM-NEXT: %var_entry = alloca i32, align 4
; No lifetime intrinsics added
; CHECK-LLVM-NOT: call void @llvm.lifetime.start.p0(ptr %var_entry)

define spir_kernel void @test_entry_alloca() {
entry:
  %var_entry = alloca i32, align 4
  store i32 5, ptr %var_entry, align 4
  ret void
}
