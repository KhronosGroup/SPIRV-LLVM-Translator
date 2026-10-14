; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %s -spirv-allow-unknown-intrinsics -spirv-text -o - \
; RUN:   | FileCheck %s --check-prefix=CHECK-SPIRV --implicit-check-not=llvm.objectsize
; RUN: spirv-val %t.spv

target triple = "spir64-unknown-unknown"

; Declared before use, so still used when SPIRVRegularizeLLVM visits it.
declare i64 @llvm.objectsize.i64.p0(ptr, i1, i1, i1)
declare i64 @llvm.objectsize.i64.p1(ptr addrspace(1), i1, i1, i1)

; CHECK-SPIRV-DAG: TypeInt [[#I64:]] 64 0
; CHECK-SPIRV-DAG: Constant [[#I64]] [[#KNOWN:]] 24 0
; CHECK-SPIRV-DAG: Constant [[#I64]] [[#MAX:]] 4294967295 4294967295
; CHECK-SPIRV-DAG: Constant [[#I64]] [[#ZERO:]] 0 0

; Known object size, then the unknown-object results for min=false and min=true.
; CHECK-SPIRV: Store [[#]] [[#KNOWN]]
; CHECK-SPIRV: Store [[#]] [[#MAX]]
; CHECK-SPIRV: Store [[#]] [[#ZERO]]

; The dynamic form of an offset into a known object is computed at run time.
; CHECK-SPIRV: ISub [[#I64]] [[#REM:]] [[#KNOWN]] [[#OFF:]]
; CHECK-SPIRV: ULessThan [[#]] [[#OOB:]] [[#KNOWN]] [[#OFF]]
; CHECK-SPIRV: Select [[#I64]] [[#SIZE:]] [[#OOB]] [[#ZERO]] [[#REM]]
; CHECK-SPIRV: Store [[#]] [[#SIZE]]

define spir_kernel void @known(ptr addrspace(1) %out) {
entry:
  %buf = alloca [24 x i8], align 1
  %size = call i64 @llvm.objectsize.i64.p0(ptr %buf, i1 false, i1 true, i1 false)
  store i64 %size, ptr addrspace(1) %out, align 8
  ret void
}

define spir_kernel void @unknown_max(ptr addrspace(1) %p, ptr addrspace(1) %out) {
entry:
  %size = call i64 @llvm.objectsize.i64.p1(ptr addrspace(1) %p, i1 false, i1 true, i1 false)
  store i64 %size, ptr addrspace(1) %out, align 8
  ret void
}

define spir_kernel void @unknown_min(ptr addrspace(1) %p, ptr addrspace(1) %out) {
entry:
  %size = call i64 @llvm.objectsize.i64.p1(ptr addrspace(1) %p, i1 true, i1 true, i1 false)
  store i64 %size, ptr addrspace(1) %out, align 8
  ret void
}

define spir_kernel void @dynamic(i64 %i, ptr addrspace(1) %out) {
entry:
  %buf = alloca [24 x i8], align 1
  %q = getelementptr i8, ptr %buf, i64 %i
  %size = call i64 @llvm.objectsize.i64.p0(ptr %q, i1 false, i1 true, i1 true)
  store i64 %size, ptr addrspace(1) %out, align 8
  ret void
}
