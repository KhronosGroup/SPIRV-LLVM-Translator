; REQUIRES: spirv-dis
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-dis --raw-id %t.spv | FileCheck --check-prefix CHECK-SPIRV %s
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r -o %t.rev.bc %t.spv
; RUN: llvm-dis -o - %t.rev.bc | FileCheck --check-prefix CHECK-LLVM %s

; llvm.ptrmask is replaced by the expansion the LLVM Language Reference gives
; for it, which keeps the result in the address space of the pointer operand
; where a ptrtoint / inttoptr round trip would not.

target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG:  [[uchar:%[a-z0-9_]+]] = OpTypeInt 8 0
; CHECK-SPIRV-DAG:  [[ulong:%[a-z0-9_]+]] = OpTypeInt 64 0
; CHECK-SPIRV-DAG:  [[mask:%[a-z0-9_]+]] = OpConstant [[ulong]] 18446744073709551600
; CHECK-SPIRV-DAG:  [[global_uchar:%[a-z0-9_]+]] = OpTypePointer CrossWorkgroup [[uchar]]

define spir_kernel void @global_align16(ptr addrspace(1) %p, ptr addrspace(1) %out) {
entry:
  %masked = call ptr addrspace(1) @llvm.ptrmask.p1.i64(ptr addrspace(1) %p, i64 -16)
  %val = load i8, ptr addrspace(1) %masked, align 1
  store i8 %val, ptr addrspace(1) %out, align 1
  ret void
}

; The address space of the pointer operand survives: the access chain and its
; result are still CrossWorkgroup.
; CHECK-SPIRV:  [[p:%[a-z0-9_]+]] = OpFunctionParameter [[global_uchar]]
; CHECK-SPIRV:  [[intptr:%[a-z0-9_]+]] = OpConvertPtrToU [[ulong]] [[p]]
; CHECK-SPIRV:  [[and:%[a-z0-9_]+]] = OpBitwiseAnd [[ulong]] [[intptr]] [[mask]]
; CHECK-SPIRV:  [[diff:%[a-z0-9_]+]] = OpISub [[ulong]] [[and]] [[intptr]]
; CHECK-SPIRV:  {{%[a-z0-9_]+}} = OpPtrAccessChain [[global_uchar]] [[p]] [[diff]]

; CHECK-LLVM-LABEL: define spir_kernel void @global_align16
; CHECK-LLVM:  [[INTPTR:%[0-9]+]] = ptrtoint ptr addrspace(1) %p to i64
; CHECK-LLVM:  [[AND:%[0-9]+]] = and i64 [[INTPTR]], -16
; CHECK-LLVM:  [[DIFF:%[0-9]+]] = sub i64 [[AND]], [[INTPTR]]
; CHECK-LLVM:  {{%[0-9]+}} = getelementptr i8, ptr addrspace(1) %p, i64 [[DIFF]]

define spir_kernel void @generic_align8(ptr addrspace(4) %p, ptr addrspace(1) %out) {
entry:
  %masked = call ptr addrspace(4) @llvm.ptrmask.p4.i64(ptr addrspace(4) %p, i64 -8)
  %val = load i8, ptr addrspace(4) %masked, align 1
  store i8 %val, ptr addrspace(1) %out, align 1
  ret void
}

; CHECK-SPIRV:  [[gp:%[a-z0-9_]+]] = OpFunctionParameter [[generic_uchar:%[a-z0-9_]+]]
; CHECK-SPIRV:  [[gintptr:%[a-z0-9_]+]] = OpConvertPtrToU [[ulong]] [[gp]]
; CHECK-SPIRV:  [[gand:%[a-z0-9_]+]] = OpBitwiseAnd [[ulong]] [[gintptr]] {{%[a-z0-9_]+}}
; CHECK-SPIRV:  [[gdiff:%[a-z0-9_]+]] = OpISub [[ulong]] [[gand]] [[gintptr]]
; CHECK-SPIRV:  {{%[a-z0-9_]+}} = OpPtrAccessChain [[generic_uchar]] [[gp]] [[gdiff]]

; CHECK-LLVM-LABEL: define spir_kernel void @generic_align8
; CHECK-LLVM:  [[GINTPTR:%[0-9]+]] = ptrtoint ptr addrspace(4) %p to i64
; CHECK-LLVM:  [[GAND:%[0-9]+]] = and i64 [[GINTPTR]], -8
; CHECK-LLVM:  [[GDIFF:%[0-9]+]] = sub i64 [[GAND]], [[GINTPTR]]
; CHECK-LLVM:  {{%[0-9]+}} = getelementptr i8, ptr addrspace(4) %p, i64 [[GDIFF]]

declare ptr addrspace(1) @llvm.ptrmask.p1.i64(ptr addrspace(1), i64)
declare ptr addrspace(4) @llvm.ptrmask.p4.i64(ptr addrspace(4), i64)
