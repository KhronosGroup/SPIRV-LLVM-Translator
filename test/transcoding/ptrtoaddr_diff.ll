; Check that ptrtoaddr/sub pattern is lowered to OpPtrDiff if allowed version is
; SPIR-V 1.4.

; FIXME: add llc compilation flow when ptrtoaddr is supported in SPIR-V backend

; RUN: llvm-spirv %s -spirv-max-version=1.4 -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV-14
; RUN: llvm-spirv -spirv-max-version=1.4 %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM-14

; RUN: llvm-spirv %s -spirv-max-version=1.3 -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV-13
; RUN: llvm-spirv -spirv-max-version=1.3 %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM-13

; Check mangling
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -spirv-max-version=1.4 -s %t.bc -o %t.reg.bc
; RUN: llvm-dis %t.reg.bc -o - | FileCheck %s --check-prefix=CHECK-PASS

; CHECK-PASS: _Z15__spirv_PtrDiffPU3AS1cS0_
; CHECK-PASS-NOT: ptrtoaddr
; CHECK-PASS-NOT: ptrtoint

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test_ptrtoaddr_diff(ptr addrspace(1) %p1, ptr addrspace(1) %p2, ptr addrspace(1) %res) {
entry:
; CHECK-SPIRV-14: PtrDiff
; CHECK-SPIRV-13-NOT: PtrDiff

; CHECK-LLVM-14: %[[#Addr1:]] = ptrtoaddr ptr addrspace(1) %{{.*}} to i64
; CHECK-LLVM-14-NEXT: %[[#Addr2:]] = ptrtoaddr ptr addrspace(1) %{{.*}} to i64
; CHECK-LLVM-14-NEXT: %{{.*}} = sub i64 %[[#Addr1]], %[[#Addr2]]

; CHECK-LLVM-13: %[[#Addr1:]] = ptrtoint ptr addrspace(1) %{{.*}} to i64
; CHECK-LLVM-13-NEXT: %[[#Addr2:]] = ptrtoint ptr addrspace(1) %{{.*}} to i64
; CHECK-LLVM-13-NEXT: %{{.*}} = sub i64 %[[#Addr1]], %[[#Addr2]]
  %1 = ptrtoaddr ptr addrspace(1) %p1 to i64
  %2 = ptrtoaddr ptr addrspace(1) %p2 to i64
  %diff = sub i64 %1, %2
  store i64 %diff, ptr addrspace(1) %res, align 8
  ret void
}

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 2, i32 0}
