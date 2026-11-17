; Check that bfloat16 atomic add requires SPV_KHR_bfloat16.

; RUN: not llvm-spirv %s --spirv-ext=+SPV_INTEL_16bit_atomics,+SPV_EXT_shader_atomic_float_add -o %t.nobf.spv 2>&1 | FileCheck %s --check-prefix=CHECK-NO-BF

; For now, expect that compilation will succeed without declaring any
; capabilities or extensions when the 16-bit atomics extension is not enabled.

; RUN: llvm-spirv %s --spirv-ext=+SPV_KHR_bfloat16,+SPV_EXT_shader_atomic_float_add -o %t.noatom.spv
; Note: This is not a valid SPIR-V module!
; RUN: llvm-spirv -to-text %t.noatom.spv -o %t.noatom.spt
; RUN: FileCheck < %t.noatom.spt %s --check-prefix=CHECK-NO-ATOM

; CHECK-NO-BF: RequiresExtension: Feature requires the following SPIR-V extension:
; CHECK-NO-BF-NEXT: SPV_KHR_bfloat16
; CHECK-NO-BF-NEXT: NOTE: LLVM module contains bfloat type, translation of which requires this extension

; CHECK-NO-ATOM: Capability BFloat16TypeKHR
; CHECK-NO-ATOM-NOT: Capability AtomicBFloat16AddINTEL
; CHECK-NO-ATOM-NOT: Capability Int16AtomicsINTEL
; CHECK-NO-ATOM-NOT: Extension "SPV_INTEL_16bit_atomics"

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64"

@f = common dso_local local_unnamed_addr addrspace(1) global bfloat 0.000000e+00, align 8

; Function Attrs: nounwind
define dso_local spir_func void @test_atomicrmw_fadd() local_unnamed_addr #0 {
entry:
 %0 = atomicrmw fadd ptr addrspace(1) @f, bfloat 42.000000e+00 seq_cst

  ret void
}

attributes #0 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}

!0 = !{i32 1, !"wchar_size", i32 4}
