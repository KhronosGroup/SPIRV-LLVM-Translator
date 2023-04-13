; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-DAG: 4 TypeInt [[I8:[0-9]+]] 8 0
; CHECK-DAG: 4 TypeInt [[I16:[0-9]+]] 16 0
; CHECK-DAG: 4 TypeInt [[I32:[0-9]+]] 32 0
; CHECK-DAG: 4 TypePointer [[I8PTR:[0-9]+]] 5 [[I8]]
; CHECK-DAG: 4 TypePointer [[I16PTR:[0-9]+]] 5 [[I16]]
; CHECK-DAG: 4 TypePointer [[I16PTRPTR:[0-9]+]] 5 [[I16PTR]]
; CHECK-DAG: 4 TypePointer [[I32PTR:[0-9]+]] 5 [[I32]]
; CHECK-DAG: 4 TypeArray [[I8PTRx2:[0-9]+]] [[I8PTR]]
; CHECK-DAG: 4 TypePointer [[I8PTRx2PTR:[0-9]+]] 5 [[I8PTRx2]]
; CHECK: 5 Variable [[I16PTR]] [[A:[0-9]+]] 5
; CHECK: 4 Variable [[I32PTR]] [[B:[0-9]+]] 5
; CHECK: 5 Variable [[I16PTRPTR]] [[C:[0-9]+]] 5 [[A]]
; CHECK: 5 SpecConstantOp [[I8PTR]] [[AI8:[0-9]+]] 124 [[A]]
; CHECK: 5 SpecConstantOp [[I8PTR]] [[BI8:[0-9]+]] 124 [[B]]
; CHECK: 5 ConstantComposite [[I8PTRx2]] [[DINIT:[0-9]+]] [[AI8]] [[BI8]]
; CHECK: 5 Variable [[I8PTRx2PTR]] [[D:[0-9]+]] 5 [[DINIT]]

@a = addrspace(1) global i16 0
@b = external addrspace(1) global i32
@c = addrspace(1) global ptr addrspace(1) @a
@d = addrspace(1) global [2 x ptr addrspace(1)] [ptr addrspace(1) @a, ptr addrspace(1) @b]
;@e = global [1 x ptr] [ptr @foo]

; Function Attrs: nounwind
define spir_kernel void @foo() {
entry:
  ret void
}
