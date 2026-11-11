; Check that OpTypeReserveId and OpTypePipeStorage declare their capabilities
; when they are used without any pipe instruction.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

; CHECK-DAG: Capability Pipes
; CHECK-DAG: Capability PipeStorage
; CHECK-DAG: TypeReserveId
; CHECK-DAG: TypePipeStorage

target triple = "spir64-unknown-unknown"

define spir_func void @reserve_id(target("spirv.ReserveId") %r) {
  ret void
}

define spir_func void @pipe_storage(target("spirv.PipeStorage") %p) {
  ret void
}
