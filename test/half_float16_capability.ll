; A 16-bit float needs the Float16 capability as soon as it is used outside of
; buffer storage, i.e. in a function signature or in an instruction producing a
; 16-bit float. Clang does not emit the "cl_khr_fp16" source extension that the
; translator used to look at, so this is derived from the IR.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

; CHECK-DAG: Capability {{Float16 *$}}
; CHECK-DAG: Capability {{Float16Buffer *$}}

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %out, half %a, half %b) {
entry:
  %r = fadd half %a, %b
  store half %r, ptr addrspace(1) %out, align 2
  ret void
}
