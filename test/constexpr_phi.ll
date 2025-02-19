; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_function_pointers -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.r.bc
; RUN: llvm-dis %t.r.bc -o %t.r.ll
; RUN: FileCheck < %t.r.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: Name [[#F:]] "_Z3runiiPi"

; 117 is OpConvertPtrToU opcode
; CHECK-SPIRV: SpecConstantOp [[#]] [[#SpecConst0:]] 117 [[#F1Ptr:]]
; CHECK-SPIRV: SpecConstantOp [[#]] [[#SpecConst1:]] 117 [[#F2Ptr:]]
; CHECK-SPIRV: ConstantComposite [[#]] [[#Compos0:]] [[#SpecConst0]] [[#SpecConst0]]
; CHECK-SPIRV: ConstantComposite [[#]] [[#Compos1:]] [[#SpecConst0]] [[#SpecConst1]]

; CHECK-SPIRV: Function [[#]] [[#F]] [[#]] [[#]]
; CHECK-SPIRV: Label [[#L1:]]
; CHECK-SPIRV: BranchConditional [[#]] [[#L2:]] [[#L3:]]
; CHECK-SPIRV: Label [[#L2]]
; CHECK-SPIRV: Branch [[#L3]]
; CHECK-SPIRV: Label [[#L3]]
; CHECK-SPIRV-NEXT: Phi [[#]] [[#]]
; CHECK-SPIRV-SAME: [[#Compos0]] [[#L2]]
; CHECK-SPIRV-SAME: [[#Compos1]] [[#L1]]

; CHECK-LLVM: br label %[[#L:]]
; CHECK-LLVM: [[#L]]:
; CHECK-LLVM-NEXT:   %[[#]] = phi <2 x i64>


target triple = "spir-unknown-unknown"

define dso_local i32 @_Z2f1i(i32 %0) {
  %2 = add nsw i32 %0, 1
  ret i32 %2
}

define dso_local i32 @_Z2f2i(i32 %0) {
  %2 = add nsw i32 %0, 2
  ret i32 %2
}

define dso_local i64 @_Z3runiiPi(i32 %0, i32 %1, ptr captures(none) %2) local_unnamed_addr {
  %4 = icmp slt i32 %0, 10
  br i1 %4, label %5, label %7

5:
  %6 = add nsw i32 %1, 2
  store i32 %6, ptr %2, align 4
  br label %7

7:
  %8 = phi <2 x i64> [ <i64 ptrtoint (ptr @_Z2f2i to i64), i64 ptrtoint (ptr @_Z2f2i to i64)>, %5 ], [ <i64 ptrtoint (ptr @_Z2f2i to i64), i64 ptrtoint (ptr @_Z2f1i to i64)>, %3 ]
  %9 = extractelement <2 x i64> %8, i64 0
  %10 = extractelement <2 x i64> %8, i64 1
  %11 = add nsw i64 %9, %10
  ret i64 %11
}
