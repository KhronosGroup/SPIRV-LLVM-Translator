; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_INTEL_vector_compute,+SPV_KHR_float_controls,+SPV_INTEL_float_controls2 --spirv-allow-unknown-intrinsics
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck %s --input-file %t.spt  -check-prefix=SPV

; ModuleID = 'slm.bc'
source_filename = "slm.cpp"
target datalayout = "e-p:64:64-i64:64-n8:16:32"
target triple = "spir"

; SPV-NOT: Capability Shader
; SPV: Capability VectorComputeINTEL
@in = internal global <256 x i8> undef, align 256 #0
declare <256 x i8> @llvm.genx.vload(<256 x i8>* nonnull %aaa)

; Function Attrs: noinline norecurse nounwind readnone
define dso_local dllexport spir_kernel void @k_rte(i32 %ibuf, i32 %obuf) local_unnamed_addr #1 {
entry:
  %gload53 = tail call <256 x i8> @llvm.genx.vload(<256 x i8>* nonnull @in)
  ret void
}

attributes #0 = { "VCGlobalVariable"}
attributes #1 = { noinline norecurse nounwind readnone "VCFloatControl"="0" "VCFunction" "VCSLMSize"="256" "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "oclrt"="1" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

; Note
!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 8.0.1"}
