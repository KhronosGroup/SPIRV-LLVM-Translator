; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -s %t.bc -o - | llvm-dis -o - | FileCheck %s \
; RUN:   --implicit-check-not="<32 x i8>"

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv64"

; The shape SROA produces for a 32-byte aggregate copied through a legal
; vector: a bitcast into an oversized vector, read back by lane and by slice.
; CHECK-LABEL: @sroa_bitcast_and_slice
; CHECK: %[[LO:.*]] = shufflevector <8 x i32> %v, <8 x i32> poison, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: %[[LOB:.*]] = bitcast <4 x i32> %[[LO]] to <16 x i8>
; CHECK: %[[HI:.*]] = shufflevector <8 x i32> %v, <8 x i32> poison, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
; CHECK: %[[HIB:.*]] = bitcast <4 x i32> %[[HI]] to <16 x i8>
; CHECK: shufflevector <16 x i8> %[[LOB]], <16 x i8> poison, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: extractelement <16 x i8> %[[LOB]], i64 4
; CHECK: extractelement <16 x i8> %[[HIB]], i64 4
define spir_kernel void @sroa_bitcast_and_slice(ptr addrspace(1) %out, <8 x i32> %v) {
  %bc = bitcast <8 x i32> %v to <32 x i8>
  %slice = shufflevector <32 x i8> %bc, <32 x i8> poison, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %lane.lo = extractelement <32 x i8> %bc, i64 4
  %lane.hi = extractelement <32 x i8> %bc, i64 20
  store <4 x i8> %slice, ptr addrspace(1) %out, align 4
  store i8 %lane.lo, ptr addrspace(1) %out, align 1
  store i8 %lane.hi, ptr addrspace(1) %out, align 1
  ret void
}

; A slice spanning both halves needs both as shuffle sources.
; CHECK-LABEL: @sroa_slice_across_halves
; CHECK: shufflevector <16 x i8> {{.*}}, <16 x i8> {{.*}}, <4 x i32> <i32 14, i32 15, i32 16, i32 17>
define spir_kernel void @sroa_slice_across_halves(ptr addrspace(1) %out, <8 x i32> %v) {
  %bc = bitcast <8 x i32> %v to <32 x i8>
  %slice = shufflevector <32 x i8> %bc, <32 x i8> poison, <4 x i32> <i32 14, i32 15, i32 16, i32 17>
  store <4 x i8> %slice, ptr addrspace(1) %out, align 4
  ret void
}

!opencl.ocl.version = !{!0}
!0 = !{i32 2, i32 0}
