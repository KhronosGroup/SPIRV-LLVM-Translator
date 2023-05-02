; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t
; RUN: llvm-spirv %t.bc -spirv-text --spirv-builtin-format=function -o %t2
; RUN: llvm-spirv %t.bc -spirv-text --spirv-builtin-format=global -o %t3
; RUN: FileCheck --check-prefix=CHECK-AUTO-FORMAT< %t %s
; RUN: FileCheck --check-prefix=CHECK-FUNCTION-FORMAT< %t2 %s
; RUN: FileCheck --check-prefix=CHECK-GLOBAL-FORMAT< %t3 %s
; RUN: llvm-spirv -r %t -spirv-text --spirv-target-env=SPV-IR -o %t_rev.bc
; RUN: llvm-spirv -r %t -spirv-text -o %t_rev_ocl.bc
; Use opposite format bc for reverse translation to test conversion
; RUN: llvm-spirv -r %t3 -spirv-text --spirv-target-env=SPV-IR --spirv-builtin-format=function -o %t2_rev.bc
; RUN: llvm-spirv -r %t2 -spirv-text --spirv-target-env=SPV-IR --spirv-builtin-format=global -o %t3_rev.bc
; RUN: llvm-spirv -r %t3 -spirv-text --spirv-builtin-format=function -o %t2_rev_ocl.bc
; RUN: llvm-dis < %t_rev.bc | FileCheck --check-prefix=CHECK-AUTO-FORMAT-REV %s
; RUN: llvm-dis < %t_rev_ocl.bc | FileCheck --check-prefix=CHECK-AUTO-FORMAT-OCL-REV %s 
; RUN: llvm-dis < %t2_rev.bc | FileCheck --check-prefix=CHECK-FUNCTION-FORMAT-REV %s
; RUN: llvm-dis < %t3_rev.bc | FileCheck --check-prefix=CHECK-GLOBAL-FORMAT-REV %s
; RUN: llvm-dis < %t2_rev_ocl.bc | FileCheck --check-prefix=CHECK-FUNCTION-FORMAT-OCL-REV %s
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.bc --spirv-builtin-format=function -o %t2.spv
; RUN: spirv-val %t2.spv
; RUN: llvm-spirv %t.bc --spirv-builtin-format=global -o %t3.spv
; RUN: spirv-val %t3.spv

; CHECK-AUTO-FORMAT: Name [[#ID:]] "__spirv_BuiltInWorkgroupId"
; CHECK-AUTO-FORMAT: Variable [[#Type:]] [[#ID]]

; CHECK-AUTO-FORMAT-REV: declare spir_func i64 @_Z26__spirv_BuiltInWorkgroupIdi(i32)
; CHECK-AUTO-FORMAT-OCL-REV: declare spir_func i64 @_Z12get_group_idj(i32)

; CHECK-FUNCTION-FORMAT: Name [[#ID:]] "_Z26__spirv_BuiltInWorkgroupIdi"
; CHECK-FUNCTION-FORMAT: Function [[#Ret:]] [[#ID]]

; CHECK-FUNCTION-FORMAT-REV: declare spir_func i64 @_Z26__spirv_BuiltInWorkgroupIdi(i32)
; CHECK-FUNCTION-FORMAT-OCL-REV: declare spir_func i64 @_Z12get_group_idj(i32)

; CHECK-GLOBAL-FORMAT: Name [[#ID:]] "__spirv_BuiltInWorkgroupId"
; CHECK-GLOBAL-FORMAT: Variable [[#Type:]] [[#ID]]

; CHECK-GLOBAL-FORMAT-REV: @__spirv_BuiltInWorkgroupId = external addrspace(7) constant <3 x i64>

; ModuleID = 'test.bc'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

@__spirv_BuiltInWorkgroupId = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32

; Function Attrs: convergent norecurse nounwind
define weak_odr dso_local spir_kernel void @foo() {
entry:
  %0 = load i64, i64 addrspace(1)* getelementptr inbounds (<3 x i64>, <3 x i64> addrspace(1)* @__spirv_BuiltInWorkgroupId, i64 0, i64 0), align 32
 ret void
}