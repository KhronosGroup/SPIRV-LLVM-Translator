; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s

; CHECK-DAG: Constant {{[0-9]+}} [[CONST0:[0-9]+]] 0
; CHECK-DAG: Constant {{[0-9]+}} [[CONST1:[0-9]+]] 1
; CHECK-DAG: Constant {{[0-9]+}} [[CONST2:[0-9]+]] 2
; CHECK-DAG: Constant {{[0-9]+}} [[CONST4:[0-9]+]] 4
; CHECK-DAG: Constant {{[0-9]+}} [[CONST16:[0-9]+]] 16

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64"

; Function Attrs: nounwind
define dso_local spir_func void @test() {
entry:
; CHECK: Variable {{[0-9]+}} [[PTR:[0-9]+]]
  %0 = alloca i32

; CHECK: AtomicStore [[PTR]] [[CONST1]] [[CONST0]] [[CONST0]]
  store atomic i32 0, i32* %0 monotonic, align 4
; CHECK: AtomicStore [[PTR]] [[CONST1]] [[CONST4]] [[CONST0]]
  store atomic i32 0, i32* %0 release, align 4
; CHECK: AtomicStore [[PTR]] [[CONST1]] [[CONST16]] [[CONST0]]
  store atomic i32 0, i32* %0 seq_cst, align 4

; CHECK: AtomicLoad 6 {{[0-9]+}} [[PTR]] [[CONST1]] [[CONST0]]
  %1 = load atomic i32, i32* %0 monotonic, align 4
; CHECK: AtomicLoad 6 {{[0-9]+}} [[PTR]] [[CONST1]] [[CONST2]]
  %2 = load atomic i32, i32* %0 acquire, align 4
; CHECK: AtomicLoad 6 {{[0-9]+}} [[PTR]] [[CONST1]] [[CONST16]]
  %3 = load atomic i32, i32* %0 seq_cst, align 4
  ret void
}
