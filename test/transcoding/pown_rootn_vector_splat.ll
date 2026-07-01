; Check that the translator splats a scalar integer arg to a vector for the
; pown/rootn OpenCL math builtins when the float arg is a vector, so that the
; emitted ExtInst operand matches the vector Result Type.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV

target triple = "spir-unknown-unknown"

; CHECK-SPIRV-DAG: TypeInt [[#IntTy:]] 32
; CHECK-SPIRV-DAG: TypeFloat [[#FloatTy:]] 32
; CHECK-SPIRV-DAG: TypeFloat [[#DoubleTy:]] 64
; CHECK-SPIRV-DAG: TypeVector [[#F3:]] [[#FloatTy]] 3
; CHECK-SPIRV-DAG: TypeVector [[#I3:]] [[#IntTy]] 3
; CHECK-SPIRV-DAG: TypeVector [[#D4:]] [[#DoubleTy]] 4
; CHECK-SPIRV-DAG: TypeVector [[#I4:]] [[#IntTy]] 4

; The scalar int is splatted to a vector int, then fed to the ExtInst.
; CHECK-SPIRV: VectorShuffle [[#I3]] [[#PownVec:]]
; CHECK-SPIRV-NEXT: ExtInst [[#F3]] [[#]] [[#]] pown [[#]] [[#PownVec]]

define spir_kernel void @test_pown_float(<3 x float> %x, i32 %n, ptr addrspace(1) %ret) {
entry:
  %call = call spir_func <3 x float> @_Z4pownDv3_fi(<3 x float> %x, i32 %n)
  store <3 x float> %call, ptr addrspace(1) %ret
  ret void
}

; CHECK-SPIRV: VectorShuffle [[#I4]] [[#RootnVec:]]
; CHECK-SPIRV-NEXT: ExtInst [[#D4]] [[#]] [[#]] rootn [[#]] [[#RootnVec]]

define spir_kernel void @test_rootn_double(<4 x double> %x, i32 %n, ptr addrspace(1) %ret) {
entry:
  %call = call spir_func <4 x double> @_Z5rootnDv4_di(<4 x double> %x, i32 %n)
  store <4 x double> %call, ptr addrspace(1) %ret
  ret void
}

declare spir_func <3 x float> @_Z4pownDv3_fi(<3 x float>, i32)
declare spir_func <4 x double> @_Z5rootnDv4_di(<4 x double>, i32)

!opencl.ocl.version = !{!0}
!opencl.spir.version = !{!0}
!0 = !{i32 2, i32 0}
