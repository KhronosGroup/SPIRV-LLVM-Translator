; REQUIRES: spirv-dis
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-dis --raw-id %t.spv | FileCheck --check-prefix CHECK-SPIRV %s
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r -o %t.rev.bc %t.spv
; RUN: llvm-dis -o - %t.rev.bc | FileCheck --check-prefix CHECK-LLVM %s

; llvm.objectsize reads no memory and always folds to a constant. Clang emits
; it for _FORTIFY_SOURCE and it survives to the back end at -O0.

target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG:  [[ulong:%[a-z0-9_]+]] = OpTypeInt 64 0
; CHECK-SPIRV-DAG:  [[known:%[a-z0-9_]+]] = OpConstant [[ulong]] 24
; CHECK-SPIRV-DAG:  [[unknown_max:%[a-z0-9_]+]] = OpConstant [[ulong]] 18446744073709551615
; CHECK-SPIRV-DAG:  [[unknown_min:%[a-z0-9_]+]] = OpConstant [[ulong]] 0

; The size of an object the module can see is folded to that size.
define spir_kernel void @known(ptr addrspace(1) %out) {
entry:
  %buf = alloca [24 x i8], align 1
  %size = call i64 @llvm.objectsize.i64.p0(ptr %buf, i1 false, i1 true, i1 false)
  store i64 %size, ptr addrspace(1) %out, align 8
  ret void
}

; CHECK-SPIRV:  [[out:%[a-z0-9_]+]] = OpFunctionParameter {{%[a-z0-9_]+}}
; CHECK-SPIRV:  OpStore [[out]] [[known]] Aligned 8

; CHECK-LLVM-LABEL: define spir_kernel void @known
; CHECK-LLVM:  store i64 24, ptr addrspace(1) %out

; An unknown object with min set to false folds to -1 ...
define spir_kernel void @unknown_max(ptr addrspace(1) %p, ptr addrspace(1) %out) {
entry:
  %size = call i64 @llvm.objectsize.i64.p1(ptr addrspace(1) %p, i1 false, i1 true, i1 false)
  store i64 %size, ptr addrspace(1) %out, align 8
  ret void
}

; CHECK-SPIRV:  OpFunctionParameter
; CHECK-SPIRV:  [[out1:%[a-z0-9_]+]] = OpFunctionParameter {{%[a-z0-9_]+}}
; CHECK-SPIRV:  OpStore [[out1]] [[unknown_max]] Aligned 8

; CHECK-LLVM-LABEL: define spir_kernel void @unknown_max
; CHECK-LLVM:  store i64 -1, ptr addrspace(1) %out

; ... and with min set to true it folds to 0.
define spir_kernel void @unknown_min(ptr addrspace(1) %p, ptr addrspace(1) %out) {
entry:
  %size = call i64 @llvm.objectsize.i64.p1(ptr addrspace(1) %p, i1 true, i1 true, i1 false)
  store i64 %size, ptr addrspace(1) %out, align 8
  ret void
}

; CHECK-SPIRV:  OpFunctionParameter
; CHECK-SPIRV:  [[out2:%[a-z0-9_]+]] = OpFunctionParameter {{%[a-z0-9_]+}}
; CHECK-SPIRV:  OpStore [[out2]] [[unknown_min]] Aligned 8

; CHECK-LLVM-LABEL: define spir_kernel void @unknown_min
; CHECK-LLVM:  store i64 0, ptr addrspace(1) %out

; The dynamic form is folded conservatively rather than expanded into an
; instruction sequence.
define spir_kernel void @dynamic(ptr addrspace(1) %p, ptr addrspace(1) %out) {
entry:
  %size = call i64 @llvm.objectsize.i64.p1(ptr addrspace(1) %p, i1 false, i1 true, i1 true)
  store i64 %size, ptr addrspace(1) %out, align 8
  ret void
}

; CHECK-SPIRV:  OpFunctionParameter
; CHECK-SPIRV:  [[out3:%[a-z0-9_]+]] = OpFunctionParameter {{%[a-z0-9_]+}}
; CHECK-SPIRV:  OpStore [[out3]] [[unknown_max]] Aligned 8

; CHECK-LLVM-LABEL: define spir_kernel void @dynamic
; CHECK-LLVM:  store i64 -1, ptr addrspace(1) %out

declare i64 @llvm.objectsize.i64.p0(ptr, i1 immarg, i1 immarg, i1 immarg)
declare i64 @llvm.objectsize.i64.p1(ptr addrspace(1), i1 immarg, i1 immarg, i1 immarg)
