; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_KHR_float_controls2
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --implicit-check-not=ExecutionMode --implicit-check-not=FloatControls2 --implicit-check-not=float_controls2

; No floating-point types, so FPFastMathDefault is not set.
; CHECK: EntryPoint 6 {{[0-9]+}} "foo"

target triple = "spir64-unknown-unknown"

define spir_kernel void @foo(ptr addrspace(1) %p, i32 %a, i32 %b) {
entry:
  %mul = mul i32 %a, %b
  %add = add i32 %mul, %b
  store i32 %add, ptr addrspace(1) %p
  ret void
}
