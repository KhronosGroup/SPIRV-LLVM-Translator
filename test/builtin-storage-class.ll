; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck --check-prefix=CHECK-SPIRV %s
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

; CHECK-SPIRV: Name [[BuiltinId:[0-9]+]] "__spirv_BuiltInWorkgroupId"
; CHECK-SPIRV-DAG: Decorate [[BuiltinId]] BuiltIn
; CHECK-SPIRV-DAG: TypePointer [[PointerTypeId:[0-9]+]] 1
; CHECK-SPIRV-DAG: Variable [[PointerTypeId]] [[BuiltinId]] 1

; ModuleID = 'test.bc'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

@__spirv_BuiltInWorkgroupId = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32

; Function Attrs: convergent norecurse nounwind
define weak_odr dso_local spir_kernel void @foo() {
entry:
  %0 = load i64, ptr addrspace(1) @__spirv_BuiltInWorkgroupId, align 32
 ret void
}
