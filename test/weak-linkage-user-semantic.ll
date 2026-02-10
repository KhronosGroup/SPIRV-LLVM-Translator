; Test that LLVM linkage types not natively supported in SPIR-V are preserved
; through UserSemantic decorations when the experimental flags are enabled.

; RUN: llvm-spirv --spirv-emit-linkage-user-semantic %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv %s -o %t.noflg.spv
; RUN: llvm-spirv %t.noflg.spv -to-text -o %t.noflg.spt
; RUN: FileCheck < %t.noflg.spt %s --check-prefix=CHECK-SPIRV-NOFLG

; RUN: llvm-spirv -r --spirv-consume-linkage-user-semantic %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; RUN: llvm-spirv -r %t.spv -o %t.rev.noflg.bc
; RUN: llvm-dis %t.rev.noflg.bc -o %t.rev.noflg.ll
; RUN: FileCheck < %t.rev.noflg.ll %s --check-prefix=CHECK-LLVM-NOFLG

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG: Name [[#WeakFun:]] "weak_func"
; CHECK-SPIRV-DAG: Name [[#WeakODRFun:]] "weak_odr_func"
; CHECK-SPIRV-DAG: Name [[#LinkonceFun:]] "linkonce_func"
; CHECK-SPIRV-DAG: Name [[#WeakGV:]] "weak_gv"
; CHECK-SPIRV-DAG: Name [[#WeakODRGV:]] "weak_odr_gv"
; CHECK-SPIRV-DAG: Name [[#CommonGV:]] "common_gv"
; CHECK-SPIRV-DAG: Decorate [[#WeakFun]] UserSemantic "linkage:weak"
; CHECK-SPIRV-DAG: Decorate [[#WeakODRFun]] UserSemantic "linkage:weak_odr"
; CHECK-SPIRV-DAG: Decorate [[#LinkonceFun]] UserSemantic "linkage:linkonce"
; CHECK-SPIRV-DAG: Decorate [[#WeakGV]] UserSemantic "linkage:weak"
; CHECK-SPIRV-DAG: Decorate [[#WeakODRGV]] UserSemantic "linkage:weak_odr"
; CHECK-SPIRV-DAG: Decorate [[#CommonGV]] UserSemantic "linkage:common"

; CHECK-SPIRV-NOFLG-NOT: UserSemantic "linkage:

; CHECK-LLVM-DAG: @weak_gv = weak addrspace(1) global i32 0
; CHECK-LLVM-DAG: @weak_odr_gv = weak_odr addrspace(1) global i32 0
; CHECK-LLVM-DAG: @common_gv = common addrspace(1) global i32 0
; CHECK-LLVM-NOT: @llvm.global.annotations
; CHECK-LLVM: define weak spir_func i32 @weak_func(i32 %x)
; CHECK-LLVM: define weak_odr spir_func i32 @weak_odr_func(i32 %x)
; CHECK-LLVM: define linkonce spir_func i32 @linkonce_func(i32 %x)

; CHECK-LLVM-NOFLG-NOT: define weak
; CHECK-LLVM-NOFLG-NOT: define weak_odr
; CHECK-LLVM-NOFLG-NOT: define linkonce

@weak_gv = weak addrspace(1) global i32 0, align 4
@weak_odr_gv = weak_odr addrspace(1) global i32 0, align 4
@common_gv = common addrspace(1) global i32 0, align 4

define weak dso_local spir_func i32 @weak_func(i32 %x) {
entry:
  %val = load i32, ptr addrspace(1) @weak_gv
  ret i32 %val
}

define weak_odr dso_local spir_func i32 @weak_odr_func(i32 %x) {
entry:
  %val = load i32, ptr addrspace(1) @weak_odr_gv
  ret i32 %val
}

define linkonce dso_local spir_func i32 @linkonce_func(i32 %x) {
entry:
  %val = load i32, ptr addrspace(1) @common_gv
  ret i32 %val
}
