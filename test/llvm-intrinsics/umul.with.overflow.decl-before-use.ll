; Verify that leftover intrinsic declarations are removed from SPIR-V output
; when the declaration appears before the callers in the module. This ordering
; matters because the regularization pass iterates functions in module order:
; if the declaration is visited first, it still has uses and survives the
; initial unused-declaration cleanup. After the callers are processed and
; their intrinsic calls are lowered to spirv.llvm_umul_with_overflow_*,
; the original declaration becomes unused and must be cleaned up in a
; second pass. Without that cleanup, the SPIR-V file contains both the
; original declaration (as an Import) and the lowered function (as an Export),
; which causes assertion failures in SPIR-V consumers.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; Verify the lowered function is present:
; RUN: FileCheck %s --input-file=%t.spt --check-prefix=CHECK-SPIRV
; Verify no leftover original intrinsic declaration appears as an import:
; RUN: FileCheck %s --input-file=%t.spt --check-prefix=CHECK-SPIRV-NEG
; Round-trip: SPIR-V binary -> LLVM IR
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir"

; NOTE: The declare is intentionally placed BEFORE the define to exercise the
; case where the regularizer sees the declaration before lowering the callers.

; The lowered function should be in the output (Name comes before Function in SPIR-V):
; CHECK-SPIRV: Name [[NAME_UMUL_FUNC:[0-9]+]] "spirv.llvm_umul_with_overflow_i32"

; The original intrinsic declaration must NOT appear as a separate entity:
; CHECK-SPIRV-NEG-NOT: Name [[#]] "llvm.umul.with.overflow.i32"
; CHECK-SPIRV-NEG-NOT: Decorate [[#]] LinkageAttributes "llvm.umul.with.overflow.i32" Import

declare { i32, i1 } @llvm.umul.with.overflow.i32(i32, i32) #1

define dso_local spir_func void @test_umul(i32 %a, i32 %b, ptr %out) #0 {
entry:
  ; CHECK-LLVM: call { i32, i1 } @llvm.umul.with.overflow.i32
  ; CHECK-SPIRV: FunctionCall [[#]] [[#]] [[NAME_UMUL_FUNC]]
  %umul = tail call { i32, i1 } @llvm.umul.with.overflow.i32(i32 %a, i32 %b)
  %val = extractvalue { i32, i1 } %umul, 0
  %ov = extractvalue { i32, i1 } %umul, 1
  %res = select i1 %ov, i32 0, i32 %val
  store i32 %res, ptr %out, align 4
  ret void
}

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone speculatable willreturn }
