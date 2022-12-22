; RUN: llvm-as -opaque-pointers=0 %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck %s --input-file %t.txt --check-prefix CHECK-i8
; RUN: FileCheck %s --input-file %t.txt --check-prefix CHECK-i16
; RUN: FileCheck %s --input-file %t.txt --check-prefix CHECK-i32
; RUN: FileCheck %s --input-file %t.txt --check-prefix CHECK-i64
; RUN: FileCheck %s --input-file %t.txt --check-prefix CHECK-Test1
; RUN: FileCheck %s --input-file %t.txt --check-prefix CHECK-Test2
; RUN: FileCheck %s --input-file %t.txt --check-prefix CHECK-Test3
; RUN: FileCheck %s --input-file %t.txt --check-prefix CHECK-Test4
; RUN: FileCheck %s --input-file %t.txt --check-prefix CHECK-Test5
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv


target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; @Test1 and @Test2 check that lowering works for @llvm.uadd.sat.i32
; and all occurrences are replaced.

; Function Attrs: nounwind readnone
define spir_func i32 @Test1(i32 %lhs, i32 %rhs) local_unnamed_addr #0 {
entry:
  %0 = call i32 @llvm.uadd.sat.i32(i32 %lhs, i32 %rhs)
  ret i32 %0
}

; Function Attrs: nounwind readnone
define spir_func i32 @Test2(i32 %lhs, i32 %rhs) local_unnamed_addr #0 {
entry:
  %0 = call i32 @llvm.uadd.sat.i32(i32 %lhs, i32 %rhs)
  ret i32 %0
}

; @Test3, @Test4 and @Test5 check that lowering works for:
; llvm.uadd.sat.i8, llvm.uadd.sat.16 and llvm.uadd.sat.i64

; Function Attrs: nounwind readnone
define spir_func i8 @Test3(i8 %lhs, i8 %rhs) local_unnamed_addr #0 {
entry:
  %0 = call i8 @llvm.uadd.sat.i8(i8 %lhs, i8 %rhs)
  ret i8 %0
}

; Function Attrs: nounwind readnone
define spir_func i16 @Test4(i16 %lhs, i16 %rhs) local_unnamed_addr #0 {
entry:
  %0 = call i16 @llvm.uadd.sat.i16(i16 %lhs, i16 %rhs)
  ret i16 %0
}

; Function Attrs: nounwind readnone
define spir_func i64 @Test5(i64 %lhs, i64 %rhs) local_unnamed_addr #0 {
entry:
  %0 = call i64 @llvm.uadd.sat.i64(i64 %lhs, i64 %rhs)
  ret i64 %0
}

; CHECK-DAG: Name {{.*}} "llvm_uadd_sat_i16"
; CHECK-DAG: Name {{.*}} "llvm_uadd_sat_i32"
; CHECK-DAG: Name {{.*}} "llvm_uadd_sat_i64"

; CHECK-i8: Name [[name_id:[0-9]+]] "llvm_uadd_sat_i8"
; CHECK-i8-DAG: TypeInt [[type_int:[0-9]+]] 8 0
; CHECK-i8-DAG: TypeBool [[type_bool:[0-9]+]]
; CHECK-i8-DAG: Constant [[type_int]] [[constant:[0-9]+]] 255

; CHECK-i8: Function [[type_int]] [[name_id]]
; CHECK-i8: FunctionParameter [[type_int]] [[lhs:[0-9]+]]
; CHECK-i8: FunctionParameter [[type_int]] [[rhs:[0-9]+]]
; CHECK-i8: BitwiseXor [[type_int]] [[xor:[0-9]+]] [[lhs]] [[constant]]
; CHECK-i8: ULessThan [[type_bool]] [[ult_res:[0-9]+]] [[xor]] [[rhs]]
; CHECK-i8: IAdd [[type_int]] [[add_res:[0-9]+]] [[lhs]] [[rhs]]
; CHECK-i8: Select [[type_int]] [[ret:[0-9]+]] [[ult_res]] [[constant]] [[add_res]]
; CHECK-i8: ReturnValue [[ret]]

; CHECK-i16: Name [[name_id:[0-9]+]] "llvm_uadd_sat_i16"
; CHECK-i16-DAG: TypeInt [[type_int:[0-9]+]] 16 0
; CHECK-i16-DAG: TypeBool [[type_bool:[0-9]+]]
; CHECK-i16-DAG: Constant [[type_int]] [[constant:[0-9]+]] 65535

; CHECK-i16: Function [[type_int]] [[name_id]]
; CHECK-i16: FunctionParameter [[type_int]] [[lhs:[0-9]+]]
; CHECK-i16: FunctionParameter [[type_int]] [[rhs:[0-9]+]]
; CHECK-i16: BitwiseXor [[type_int]] [[xor:[0-9]+]] [[lhs]] [[constant]]
; CHECK-i16: ULessThan [[type_bool]] [[ult_res:[0-9]+]] [[xor]] [[rhs]]
; CHECK-i16: IAdd [[type_int]] [[add_res:[0-9]+]] [[lhs]] [[rhs]]
; CHECK-i16: Select [[type_int]] [[ret:[0-9]+]] [[ult_res]] [[constant]] [[add_res]]
; CHECK-i16: ReturnValue [[ret]]

; CHECK-i32: Name [[name_id:[0-9]+]] "llvm_uadd_sat_i32"
; CHECK-i32-DAG: TypeInt [[type_int:[0-9]+]] 32 0
; CHECK-i32-DAG: TypeBool [[type_bool:[0-9]+]]
; CHECK-i32-DAG: Constant [[type_int]] [[constant:[0-9]+]] 4294967295

; CHECK-i32: Function [[type_int]] [[name_id]]
; CHECK-i32: FunctionParameter [[type_int]] [[lhs:[0-9]+]]
; CHECK-i32: FunctionParameter [[type_int]] [[rhs:[0-9]+]]
; CHECK-i32: BitwiseXor [[type_int]] [[xor:[0-9]+]] [[lhs]] [[constant]]
; CHECK-i32: ULessThan [[type_bool]] [[ult_res:[0-9]+]] [[xor]] [[rhs]]
; CHECK-i32: IAdd [[type_int]] [[add_res:[0-9]+]] [[lhs]] [[rhs]]
; CHECK-i32: Select [[type_int]] [[ret:[0-9]+]] [[ult_res]] [[constant]] [[add_res]]
; CHECK-i32: ReturnValue [[ret]]

; CHECK-i64: Name [[name_id:[0-9]+]] "llvm_uadd_sat_i64"
; CHECK-i64-DAG: TypeInt [[type_int:[0-9]+]] 64 0
; CHECK-i64-DAG: TypeBool [[type_bool:[0-9]+]]
; CHECK-i64-DAG: Constant [[type_int]] [[constant:[0-9]+]] 4294967295 4294967295

; CHECK-i64: Function [[type_int]] [[name_id]]
; CHECK-i64: FunctionParameter [[type_int]] [[lhs:[0-9]+]]
; CHECK-i64: FunctionParameter [[type_int]] [[rhs:[0-9]+]]
; CHECK-i64: BitwiseXor [[type_int]] [[xor:[0-9]+]] [[lhs]] [[constant]]
; CHECK-i64: ULessThan [[type_bool]] [[ult_res:[0-9]+]] [[xor]] [[rhs]]
; CHECK-i64: IAdd [[type_int]] [[add_res:[0-9]+]] [[lhs]] [[rhs]]
; CHECK-i64: Select [[type_int]] [[ret:[0-9]+]] [[ult_res]] [[constant]] [[add_res]]
; CHECK-i64: ReturnValue [[ret]]

; CHECK-Test1-DAG: Name [[name_id:[0-9]+]] "Test1"
; CHECK-Test1-DAG: Name [[intrinsic_replacement:[0-9]+]] "llvm_uadd_sat_i32"
; CHECK-Test1: TypeInt [[type_int:[0-9]+]] 32 0

; CHECK-Test1: Function [[type_int]] [[name_id]]
; CHECK-Test1-NEXT: FunctionParameter [[type_int]] [[lhs:[0-9]+]]
; CHECK-Test1-NEXT: FunctionParameter [[type_int]] [[rhs:[0-9]+]]
; CHECK-Test1: Label
; CHECK-Test1-NEXT: FunctionCall [[type_int]] [[ret:[0-9]+]] [[intrinsic_replacement]] [[lhs]] [[rhs]]
; CHECK-Test1-NEXT: ReturnValue [[ret]]

; CHECK-Test2-DAG: Name [[name_id:[0-9]+]] "Test2"
; CHECK-Test2-DAG: Name [[intrinsic_replacement:[0-9]+]] "llvm_uadd_sat_i32"
; CHECK-Test2: TypeInt [[type_int:[0-9]+]] 32 0

; CHECK-Test2: Function [[type_int]] [[name_id]]
; CHECK-Test2-NEXT: FunctionParameter [[type_int]] [[lhs:[0-9]+]]
; CHECK-Test2-NEXT: FunctionParameter [[type_int]] [[rhs:[0-9]+]]
; CHECK-Test2: Label
; CHECK-Test2-NEXT: FunctionCall [[type_int]] [[ret:[0-9]+]] [[intrinsic_replacement]] [[lhs]] [[rhs]]
; CHECK-Test2-NEXT: ReturnValue [[ret]]

; CHECK-Test3-DAG: Name [[name_id:[0-9]+]] "Test3"
; CHECK-Test3-DAG: Name [[intrinsic_replacement:[0-9]+]] "llvm_uadd_sat_i8"
; CHECK-Test3: TypeInt [[type_int:[0-9]+]] 8 0

; CHECK-Test3: Function [[type_int]] [[name_id]]
; CHECK-Test3-NEXT: FunctionParameter [[type_int]] [[lhs:[0-9]+]]
; CHECK-Test3-NEXT: FunctionParameter [[type_int]] [[rhs:[0-9]+]]
; CHECK-Test3: Label
; CHECK-Test3-NEXT: FunctionCall [[type_int]] [[ret:[0-9]+]] [[intrinsic_replacement]] [[lhs]] [[rhs]]
; CHECK-Test3-NEXT: ReturnValue [[ret]]

; CHECK-Test4-DAG: Name [[name_id:[0-9]+]] "Test4"
; CHECK-Test4-DAG: Name [[intrinsic_replacement:[0-9]+]] "llvm_uadd_sat_i16"
; CHECK-Test4: TypeInt [[type_int:[0-9]+]] 16 0

; CHECK-Test4: Function [[type_int]] [[name_id]]
; CHECK-Test4-NEXT: FunctionParameter [[type_int]] [[lhs:[0-9]+]]
; CHECK-Test4-NEXT: FunctionParameter [[type_int]] [[rhs:[0-9]+]]
; CHECK-Test4: Label
; CHECK-Test4-NEXT: FunctionCall [[type_int]] [[ret:[0-9]+]] [[intrinsic_replacement]] [[lhs]] [[rhs]]
; CHECK-Test4-NEXT: ReturnValue [[ret]]

; CHECK-Test5-DAG: Name [[name_id:[0-9]+]] "Test5"
; CHECK-Test5-DAG: Name [[intrinsic_replacement:[0-9]+]] "llvm_uadd_sat_i64"
; CHECK-Test5: TypeInt [[type_int:[0-9]+]] 64 0

; CHECK-Test5: Function [[type_int]] [[name_id]]
; CHECK-Test5-NEXT: FunctionParameter [[type_int]] [[lhs:[0-9]+]]
; CHECK-Test5-NEXT: FunctionParameter [[type_int]] [[rhs:[0-9]+]]
; CHECK-Test5: Label
; CHECK-Test5-NEXT: FunctionCall [[type_int]] [[ret:[0-9]+]] [[intrinsic_replacement]] [[lhs]] [[rhs]]
; CHECK-Test5-NEXT: ReturnValue [[ret]]

; Function Attrs: nounwind readnone speculatable willreturn
declare i8 @llvm.uadd.sat.i8(i8, i8) #1

; Function Attrs: nounwind readnone speculatable willreturn
declare i16 @llvm.uadd.sat.i16(i16, i16) #1

; Function Attrs: nounwind readnone speculatable willreturn
declare i32 @llvm.uadd.sat.i32(i32, i32) #1

; Function Attrs: nounwind readnone speculatable willreturn
declare i64 @llvm.uadd.sat.i64(i64, i64) #1

attributes #0 = { nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 0}
!2 = !{i32 1, i32 2}
