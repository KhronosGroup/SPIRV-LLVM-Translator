; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis %t.bc -o %t.ll
; RUN: FileCheck %s --input-file %t.spt -check-prefix=SPV
; RUN: FileCheck %s --input-file %t.ll  -check-prefix=LLVM

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024"
target triple = "spir64-unknown-unknown"

@s = global [16 x i32] zeroinitializer

; Function Attrs: nounwind
define spir_kernel void @f_f() {
allocas:
  %ptrArray.i = alloca <16 x i64>, align 128

; SPV-DAG: 6 SpecConstantOp 2 {{[0-9]+}} 128 {{[0-9]+}} {{[0-9]+}} 
; SPV-DAG: 6 SpecConstantOp 2 {{[0-9]+}} 130 {{[0-9]+}} {{[0-9]+}} 
; SPV-DAG: 6 SpecConstantOp 2 {{[0-9]+}} 198 {{[0-9]+}} {{[0-9]+}} 
; SPV-DAG: 6 SpecConstantOp 2 {{[0-9]+}} 197 {{[0-9]+}} {{[0-9]+}} 
; SPV-DAG: 6 SpecConstantOp 2 {{[0-9]+}} 134 {{[0-9]+}} {{[0-9]+}} 
; SPV-DAG: 6 SpecConstantOp 2 {{[0-9]+}} 132 {{[0-9]+}} {{[0-9]+}} 
; SPV-DAG: 6 SpecConstantOp 2 {{[0-9]+}} 199 {{[0-9]+}} {{[0-9]+}} 

; LLVM: store <16 x i64>
; LLVM-SAME: add
; LLVM-SAME: sub
; LLVM-SAME: xor
; LLVM-SAME: or
; LLVM-SAME: and
; LLVM-SAME: mul
; LLVM-SAME: udiv

  store <16 x i64> <i64 ptrtoint ([16 x i32]* @s to i64), i64 add (i64 ptrtoint ([16 x i32]* @s to i64), i64 4), i64 sub (i64 ptrtoint ([16 x i32]* @s to i64), i64 4), i64 xor (i64 ptrtoint ([16 x i32]* @s to i64), i64 4), i64 or (i64 ptrtoint ([16 x i32]* @s to i64), i64 4), i64 and (i64 mul (i64 udiv(i64 ptrtoint ([16 x i32]* @s to i64), i64 4), i64 4), i64 4), i64 undef, i64 undef, i64 undef, i64 undef, i64 undef, i64 undef, i64 undef, i64 undef, i64 undef, i64 undef>, <16 x i64>* %ptrArray.i, align 128
  ret void
}
