; RUN: llvm-as %S/empty.ll -o %t1.bc
; RUN: llvm-as %S/empty.ll -o %t2.bc

; ir - > -spirv-text + Filecheck
; RUN: llvm-spirv %t1.bc %t2.bc -spirv-text
; RUN: FileCheck %S/empty.ll < %t1.spt
; RUN: FileCheck %S/empty.ll < %t2.spt

; ir -> SPV + validator
; RUN: llvm-spirv %t1.bc %t2.bc
; RUN: spirv-val %t1.spv
; RUN: spirv-val %t2.spv

; SPV -> ir + filecheck
; RUN: llvm-spirv -r %t1.spv %t2.spv
; RUN: llvm-dis < %t1.bc | FileCheck %s
; RUN: llvm-dis < %t2.bc | FileCheck %s
; CHECK: define spir_kernel void @foo

; SPV -> to-text + filecheck
; RUN: llvm-spirv -to-text %t1.spv %t2.spv
; RUN: FileCheck %S/empty.ll < %t1.spt
; RUN: FileCheck %S/empty.ll < %t2.spt

; SPT -> to-binary + validator
; RUN: llvm-spirv -to-binary %t1.spt %t2.spt
; RUN: spirv-val %t1.spv
; RUN: spirv-val %t2.spv

; Check file list
; llvm-spirv %t1.bc %t2.bc -o %t.list
; FileCheck < %t.list %s --check-prefix=CHECK-LIST
; CHECK-LIST: t1.spv
; CHECK-LIST: t2.spv
