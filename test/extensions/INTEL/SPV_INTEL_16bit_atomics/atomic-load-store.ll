; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv -to-text %t.spv -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; R/UN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_KHR_untyped_pointers
; RUN: spirv-val %t.spv
; R/UN: llvm-spirv -to-text %t.spv -o %t.spt
; R/UN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; CHECK-SPIRV-DAG: Constant [[#]] [[#CrossDeviceScope:]] 0
; CHECK-SPIRV-DAG: Constant [[#]] [[#Release:]] 4
; CHECK-SPIRV-DAG: Constant [[#]] [[#SequentiallyConsistent:]] 16
; CHECK-SPIRV-DAG: Constant [[#]] [[#Acquire:]] 2

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64"

; Function Attrs: nounwind
define dso_local spir_func void @test() {
entry:
; CHECK-SPIRV: {{(Variable|UntypedVariableKHR)}} [[#]] [[#PTR:]]
  %0 = alloca i16

; CHECK-SPIRV: AtomicStore [[#PTR]] [[#CrossDeviceScope]] {{.+}} [[#]]
  store atomic i16 0, ptr %0 monotonic, align 4
; CHECK-SPIRV: AtomicStore [[#PTR]] [[#CrossDeviceScope]] [[#Release]] [[#]]
  store atomic i16 0, ptr %0 release, align 4
; CHECK-SPIRV: AtomicStore [[#PTR]] [[#CrossDeviceScope]] [[#SequentiallyConsistent]] [[#]]
  store atomic i16 0, ptr %0 seq_cst, align 4

; CHECK-SPIRV: AtomicLoad [[#]] [[#]] [[#PTR]] [[#CrossDeviceScope]] {{.+}}
  %1 = load atomic i16, ptr %0 monotonic, align 4
; CHECK-SPIRV: AtomicLoad [[#]] [[#]] [[#PTR]] [[#CrossDeviceScope]] [[#Acquire]]
  %2 = load atomic i16, ptr %0 acquire, align 4
; CHECK-SPIRV: AtomicLoad [[#]] [[#]] [[#PTR]] [[#CrossDeviceScope]] [[#SequentiallyConsistent]]
  %3 = load atomic i16, ptr %0 seq_cst, align 4
  ret void
}
