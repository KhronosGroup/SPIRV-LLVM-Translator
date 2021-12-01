; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -spirv-text %t.bc -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -to-binary %t.spt -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: TypeInt [[#TypeInt32:]] 32 0
; CHECK-SPIRV: TypeInt [[#TypeInt16:]] 16 0
; CHECK-SPIRV: TypeInt [[#TypeInt64:]] 64 0

; CHECK-SPIRV: ShiftLeftLogical [[#TypeInt16]]
; CHECK-SPIRV: ShiftRightLogical [[#TypeInt16]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt16]]

; CHECK-SPIRV: ShiftLeftLogical [[#TypeInt32]]
; CHECK-SPIRV: ShiftLeftLogical [[#TypeInt32]]
; CHECK-SPIRV: ShiftRightLogical [[#TypeInt32]]
; CHECK-SPIRV: ShiftRightLogical [[#TypeInt32]]
; CHECK-SPIRV: BitwiseAnd [[#TypeInt32]]
; CHECK-SPIRV: BitwiseAnd [[#TypeInt32]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt32]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt32]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt32]]

; CHECK-SPIRV: ShiftLeftLogical [[#TypeInt64]]
; CHECK-SPIRV: ShiftLeftLogical [[#TypeInt64]]
; CHECK-SPIRV: ShiftLeftLogical [[#TypeInt64]]
; CHECK-SPIRV: ShiftLeftLogical [[#TypeInt64]]
; CHECK-SPIRV: ShiftRightLogical [[#TypeInt64]]
; CHECK-SPIRV: ShiftRightLogical [[#TypeInt64]]
; CHECK-SPIRV: ShiftRightLogical [[#TypeInt64]]
; CHECK-SPIRV: ShiftRightLogical [[#TypeInt64]]
; CHECK-SPIRV: BitwiseAnd [[#TypeInt64]]
; CHECK-SPIRV: BitwiseAnd [[#TypeInt64]]
; CHECK-SPIRV: BitwiseAnd [[#TypeInt64]]
; CHECK-SPIRV: BitwiseAnd [[#TypeInt64]]
; CHECK-SPIRV: BitwiseAnd [[#TypeInt64]]
; CHECK-SPIRV: BitwiseAnd [[#TypeInt64]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt64]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt64]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt64]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt64]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt64]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt64]]
; CHECK-SPIRV: BitwiseOr [[#TypeInt64]]

; CHECK-LLVM: %bswap.2 = shl i16 %0, 8
; CHECK-LLVM: %bswap.1 = lshr i16 %0, 8
; CHECK-LLVM: %bswap.i16 = or i16 %bswap.2, %bswap.1

; CHECK-LLVM: %bswap.4 = shl i32 %1, 24
; CHECK-LLVM: %bswap.3 = shl i32 %1, 8
; CHECK-LLVM: %bswap.21 = lshr i32 %1, 8
; CHECK-LLVM: %bswap.12 = lshr i32 %1, 24
; CHECK-LLVM: %bswap.and3 = and i32 %bswap.3, 16711680
; CHECK-LLVM: %bswap.and2 = and i32 %bswap.21, 65280
; CHECK-LLVM: %bswap.or1 = or i32 %bswap.4, %bswap.and3
; CHECK-LLVM: %bswap.or2 = or i32 %bswap.and2, %bswap.12
; CHECK-LLVM: %bswap.i32 = or i32 %bswap.or1, %bswap.or2

; CHECK-LLVM: %bswap.8 = shl i64 %2, 56
; CHECK-LLVM: %bswap.7 = shl i64 %2, 40
; CHECK-LLVM: %bswap.6 = shl i64 %2, 24
; CHECK-LLVM: %bswap.5 = shl i64 %2, 8
; CHECK-LLVM: %bswap.43 = lshr i64 %2, 8
; CHECK-LLVM: %bswap.34 = lshr i64 %2, 24
; CHECK-LLVM: %bswap.25 = lshr i64 %2, 40
; CHECK-LLVM: %bswap.16 = lshr i64 %2, 56
; CHECK-LLVM: %bswap.and7 = and i64 %bswap.7, 71776119061217280
; CHECK-LLVM: %bswap.and6 = and i64 %bswap.6, 280375465082880
; CHECK-LLVM: %bswap.and5 = and i64 %bswap.5, 1095216660480
; CHECK-LLVM: %bswap.and4 = and i64 %bswap.43, 4278190080
; CHECK-LLVM: %bswap.and37 = and i64 %bswap.34, 16711680
; CHECK-LLVM: %bswap.and28 = and i64 %bswap.25, 65280
; CHECK-LLVM: %bswap.or19 = or i64 %bswap.8, %bswap.and7
; CHECK-LLVM: %bswap.or210 = or i64 %bswap.and6, %bswap.and5
; CHECK-LLVM: %bswap.or3 = or i64 %bswap.and4, %bswap.and37
; CHECK-LLVM: %bswap.or4 = or i64 %bswap.and28, %bswap.16
; CHECK-LLVM: %bswap.or5 = or i64 %bswap.or19, %bswap.or210
; CHECK-LLVM: %bswap.or6 = or i64 %bswap.or3, %bswap.or4
; CHECK-LLVM: %bswap.i64 = or i64 %bswap.or5, %bswap.or6

; ModuleID = 'source.cpp'
source_filename = "source.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64"

; Function Attrs: mustprogress noinline norecurse nounwind optnone
define dso_local i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %a = alloca i16, align 2
  %b = alloca i16, align 2
  %c = alloca i32, align 4
  %d = alloca i32, align 4
  %e = alloca i64, align 8
  %f = alloca i64, align 8
  store i32 0, i32* %retval, align 4
  store i16 258, i16* %a, align 2
  %0 = load i16, i16* %a, align 2
  %1 = call i16 @llvm.bswap.i16(i16 %0)
  store i16 %1, i16* %b, align 2
  store i32 566, i32* %c, align 4
  %2 = load i32, i32* %c, align 4
  %3 = call i32 @llvm.bswap.i32(i32 %2)
  store i32 %3, i32* %d, align 4
  store i64 12587, i64* %e, align 8
  %4 = load i64, i64* %e, align 8
  %5 = call i64 @llvm.bswap.i64(i64 %4)
  store i64 %5, i64* %f, align 8
  ret i32 0
}

; Function Attrs: nofree nosync nounwind readnone speculatable willreturn
declare i16 @llvm.bswap.i16(i16) #1

; Function Attrs: nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.bswap.i32(i32) #1

; Function Attrs: nofree nosync nounwind readnone speculatable willreturn
declare i64 @llvm.bswap.i64(i64) #1

attributes #0 = { mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #1 = { nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1}
!opencl.used.extensions = !{!2}
!opencl.used.optional.core.features = !{!2}
!opencl.compiler.options = !{!2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{}
!3 = !{!"Compiler"}
