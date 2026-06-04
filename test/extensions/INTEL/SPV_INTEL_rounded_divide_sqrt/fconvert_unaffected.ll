; Guards target-sensitivity: FPRoundingMode is valid on conversion
; instructions (OpFConvert) in core SPIR-V, so even with
; SPV_INTEL_rounded_divide_sqrt enabled on the command line, an FPRoundingMode
; that lands on an OpFConvert (here from llvm.experimental.constrained.fptrunc)
; must NOT pull in the RoundedDivideSqrtINTEL capability or the extension.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_INTEL_rounded_divide_sqrt
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck %s --input-file %t.spt --check-prefix=CHECK-SPIRV

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-SPIRV-NOT: Capability RoundedDivideSqrtINTEL
; CHECK-SPIRV-NOT: Extension "SPV_INTEL_rounded_divide_sqrt"
; The conversion still carries its rounding-mode decoration (core SPIR-V).
; CHECK-SPIRV: Decorate [[#CVT:]] FPRoundingMode 1
; CHECK-SPIRV: FConvert {{[0-9]+}} [[#CVT]]

define spir_kernel void @test(double %a) {
entry:
  %r = call float @llvm.experimental.constrained.fptrunc.f32.f64(double %a, metadata !"round.towardzero", metadata !"fpexcept.strict")
  ret void
}

declare float @llvm.experimental.constrained.fptrunc.f32.f64(double, metadata, metadata)
