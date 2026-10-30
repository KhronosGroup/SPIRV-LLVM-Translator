; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %s -spirv-allow-unknown-intrinsics -spirv-text -o - \
; RUN:   | FileCheck %s --check-prefix=CHECK-SPIRV --implicit-check-not=llvm.ptrmask
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

target triple = "spir64-unknown-unknown"

declare ptr addrspace(1) @llvm.ptrmask.p1.i64(ptr addrspace(1), i64)

; CHECK-SPIRV-DAG: TypeInt [[#I8:]] 8 0
; CHECK-SPIRV-DAG: TypeInt [[#I64:]] 64 0
; CHECK-SPIRV-DAG: Constant [[#I64]] [[#MASK:]] 4294967280 4294967295
; CHECK-SPIRV-DAG: TypePointer [[#GLOBAL_I8:]] 5 [[#I8]]

; CHECK-SPIRV: FunctionParameter [[#GLOBAL_I8]] [[#P:]]
; CHECK-SPIRV: ConvertPtrToU [[#I64]] [[#INT:]] [[#P]]
; CHECK-SPIRV: BitwiseAnd [[#I64]] [[#AND:]] [[#INT]] [[#MASK]]
; CHECK-SPIRV: ConvertUToPtr [[#GLOBAL_I8]] [[#RES:]] [[#AND]]
; CHECK-SPIRV: Load [[#I8]] [[#]] [[#RES]]

; CHECK-LLVM: %[[#INT:]] = ptrtoint ptr addrspace(1) %p to i64
; CHECK-LLVM: %[[#AND:]] = and i64 %[[#INT]], -16
; CHECK-LLVM: %masked = inttoptr i64 %[[#AND]] to ptr addrspace(1)
; CHECK-LLVM: load i8, ptr addrspace(1) %masked

define spir_kernel void @align16(ptr addrspace(1) %p, ptr addrspace(1) %out) {
entry:
  %masked = call ptr addrspace(1) @llvm.ptrmask.p1.i64(ptr addrspace(1) %p, i64 -16)
  %val = load i8, ptr addrspace(1) %masked, align 1
  store i8 %val, ptr addrspace(1) %out, align 1
  ret void
}
