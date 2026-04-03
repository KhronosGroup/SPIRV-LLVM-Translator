; Test --spirv-addrspace-map address space remapping on SPIR-V -> LLVM translation.

; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_variable_length_array,+SPV_INTEL_arbitrary_precision_integers,+SPV_INTEL_arbitrary_precision_fixed_point -o %t.spv
; RUN: llvm-spirv -r %t.spv --spirv-addrspace-map=0:4,1:1,2:2,3:3,4:0 \
; RUN:   -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-MAPPED
; RUN: llvm-spirv -r %t.spv \
; RUN:   -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-IDENTITY
; RUN: llvm-spirv -r %t.spv --spirv-addrspace-map=0:4 \
; RUN:   -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-PARTIAL
; RUN: not llvm-spirv -r %t.spv --spirv-addrspace-map=99:0 2>&1 \
; RUN:   | FileCheck %s --check-prefix=CHECK-ERR-IDX
; RUN: not llvm-spirv -r %t.spv --spirv-addrspace-map=bad 2>&1 \
; RUN:   | FileCheck %s --check-prefix=CHECK-ERR-FMT

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir64-unknown-unknown"

; CHECK-MAPPED: define{{.*}} @test_stable_and_generic({{.*}}ptr addrspace(1){{.*}}ptr addrspace(3){{.*}}ptr{{( addrspace\(0\))?}}
; CHECK-IDENTITY: define{{.*}} @test_stable_and_generic({{.*}}ptr addrspace(1){{.*}}ptr addrspace(3){{.*}}ptr addrspace(4)
; CHECK-PARTIAL: define{{.*}} @test_stable_and_generic({{.*}}ptr addrspace(1){{.*}}ptr addrspace(3){{.*}}ptr addrspace(4)
define spir_kernel void @test_stable_and_generic(ptr addrspace(1) %global_p,
                                                 ptr addrspace(3) %local_p,
                                                 ptr addrspace(4) %generic_p) {
  ret void
}

; CHECK-MAPPED: define{{.*}} @test_constant({{.*}}ptr addrspace(2)
; CHECK-IDENTITY: define{{.*}} @test_constant({{.*}}ptr addrspace(2)
; CHECK-PARTIAL: define{{.*}} @test_constant({{.*}}ptr addrspace(2)
define spir_kernel void @test_constant(ptr addrspace(2) %const_p) {
  ret void
}

; CHECK-MAPPED: define{{.*}} @test_private(
; CHECK-MAPPED: alloca i32,{{.*}} addrspace(4)
; CHECK-IDENTITY: define{{.*}} @test_private(
; CHECK-IDENTITY: alloca i32, align
; CHECK-PARTIAL: define{{.*}} @test_private(
; CHECK-PARTIAL: alloca i32,{{.*}} addrspace(4)
define spir_func i32 @test_private() {
  %x = alloca i32
  %v = load i32, ptr %x
  ret i32 %v
}

; CHECK-MAPPED: define{{.*}} @test_stack_save_restore(
; CHECK-MAPPED: call ptr addrspace(4) @llvm.stacksave.p4()
; CHECK-MAPPED: call void @llvm.stackrestore.p4(ptr addrspace(4)
; CHECK-IDENTITY: define{{.*}} @test_stack_save_restore(
; CHECK-IDENTITY: call ptr @llvm.stacksave.p0()
; CHECK-IDENTITY: call void @llvm.stackrestore.p0(ptr
; CHECK-PARTIAL: define{{.*}} @test_stack_save_restore(
; CHECK-PARTIAL: call ptr addrspace(4) @llvm.stacksave.p4()
; CHECK-PARTIAL: call void @llvm.stackrestore.p4(ptr addrspace(4)
define spir_func void @test_stack_save_restore(i64 %n) {
  %saved = call ptr @llvm.stacksave.p0()
  %vla = alloca i32, i64 %n, align 4
  store i32 0, ptr %vla, align 4
  call void @llvm.stackrestore.p0(ptr %saved)
  ret void
}

; CHECK-MAPPED: define{{.*}} @test_wide_fixed_point(
; CHECK-MAPPED: call void @intel_arbitrary_fixed_sincos.i66.i34(ptr{{( addrspace\(0\))?}} sret(i66)
; CHECK-IDENTITY: define{{.*}} @test_wide_fixed_point(
; CHECK-IDENTITY: call void @intel_arbitrary_fixed_sincos.i66.i34(ptr addrspace(4) sret(i66)
define spir_func void @test_wide_fixed_point() {
  %a = alloca i34, align 8
  %a.ascast = addrspacecast ptr %a to ptr addrspace(4)
  %result = alloca i66, align 8
  %result.ascast = addrspacecast ptr %result to ptr addrspace(4)
  %val = load i34, ptr addrspace(4) %a.ascast, align 8
  call spir_func void @_Z24__spirv_FixedSinCosINTELILi34ELi66EEU7_ExtIntIXmlLi2ET0_EEiU7_ExtIntIXT_EEibiiii(ptr addrspace(4) sret(i66) align 8 %result.ascast, i34 %val, i1 zeroext true, i32 3, i32 2, i32 0, i32 0)
  ret void
}

declare ptr @llvm.stacksave.p0() #0
declare void @llvm.stackrestore.p0(ptr) #0
declare spir_func void @_Z24__spirv_FixedSinCosINTELILi34ELi66EEU7_ExtIntIXmlLi2ET0_EEiU7_ExtIntIXT_EEibiiii(ptr addrspace(4) sret(i66) align 8, i34, i1 zeroext, i32, i32, i32, i32) #0

attributes #0 = { nounwind }

; CHECK-ERR-IDX: not a valid SPIRAddressSpace index
; CHECK-ERR-FMT: Invalid format for --spirv-addrspace-map
