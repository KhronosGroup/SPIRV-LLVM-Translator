; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s --check-prefixes=COMMON,OPENCL
; RUN: spirv-val %t.spv

; RUN: llvm-spirv %t.bc --spirv-use-ocl-for-llvm-math-intrinsic=true -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s --check-prefixes=COMMON,OPENCL
; RUN: spirv-val %t.spv

; RUN: llvm-spirv %t.bc --spirv-use-ocl-for-llvm-math-intrinsic=false -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s --check-prefixes=COMMON,EMULATION
; RUN: spirv-val %t.spv

; Test checks that saturation addition and subtraction llvm intrinsics
; are translated into instruction from OpenCL Extended Instruction Set.

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; COMMON: ExtInstImport [[ext:[0-9]+]] "OpenCL.std"

; COMMON: Name [[test_uadd:[0-9]+]] "test_uadd"
; COMMON: Name [[test_usub:[0-9]+]] "test_usub"
; COMMON: Name [[test_sadd:[0-9]+]] "test_sadd"
; COMMON: Name [[test_ssub:[0-9]+]] "test_ssub"
; COMMON: Name [[test_vectors:[0-9]+]] "test_vectors"

; COMMON-DAG: TypeInt [[int:[0-9]+]] 32 0
; COMMON-DAG: TypeVoid [[void:[0-9]+]]
; COMMON-DAG: TypeVector [[vector:[0-9]+]] [[int]] 4

; EMULATION-DAG: TypeBool [[bool:[0-9]+]]
; EMULATION-DAG: TypeVector [[vector_bool:[0-9]+]] [[bool]] 4
; EMULATION-DAG: Constant [[int]] [[uint_max:[0-9]+]] 4294967295
; EMULATION-DAG: Constant [[int]] [[zero:[0-9]+]] 0
; EMULATION-DAG: Constant [[int]] [[int_max:[0-9]+]] 2147483647
; EMULATION-DAG: Constant [[int]] [[int_min:[0-9]+]] 2147483648
; EMULATION-DAG: ConstantComposite [[vector]] [[vector_uint_max:[0-9]+]] [[uint_max]] [[uint_max]] [[uint_max]] [[uint_max]]

define spir_func void @test_uadd(i32 %a, i32 %b) {
entry:
  %0 = call i32 @llvm.uadd.sat.i32(i32 %a, i32 %b)
  ret void
}

; COMMON: Function [[void]] [[test_uadd]]
; COMMON-NEXT: FunctionParameter [[int]] [[lhs:[0-9]+]]
; COMMON-NEXT: FunctionParameter [[int]] [[rhs:[0-9]+]]
; COMMON-EMPTY:
; COMMON-NEXT: Label
; OPENCL-NEXT: ExtInst [[int]] {{[0-9]+}} [[ext]] u_add_sat [[lhs]] [[rhs]]
; EMULATION-NEXT: IAdd [[int]] [[add:[0-9]+]] [[lhs]] [[rhs]]
; EMULATION-NEXT: UGreaterThanEqual [[bool]] [[greater:[0-9]+]] [[add]] [[lhs]]
; EMULATION-NEXT: Select [[int]] {{[0-9]+}} [[greater]] [[add]] [[uint_max]]
; COMMON-NEXT: Return

define spir_func void @test_usub(i32 %a, i32 %b) {
entry:
  %0 = call i32 @llvm.usub.sat.i32(i32 %a, i32 %b)
  ret void
}

; COMMON: Function [[void]] [[test_usub]]
; COMMON-NEXT: FunctionParameter [[int]] [[lhs:[0-9]+]]
; COMMON-NEXT: FunctionParameter [[int]] [[rhs:[0-9]+]]
; COMMON-EMPTY:
; COMMON-NEXT: Label
; OPENCL-NEXT: ExtInst [[int]] {{[0-9]+}} [[ext]] u_sub_sat [[lhs]] [[rhs]]
; EMULATION-NEXT: ISub [[int]] [[sub:[0-9]+]] [[lhs]] [[rhs]]
; EMULATION-NEXT: UGreaterThan [[bool]] [[greater:[0-9]+]] [[lhs]] [[rhs]]
; EMULATION-NEXT: Select [[int]] {{[0-9]+}} [[greater]] [[sub]] [[zero]]
; COMMON-NEXT: Return

define spir_func void @test_sadd(i32 %a, i32 %b) {
entry:
  %0 = call i32 @llvm.sadd.sat.i32(i32 %a, i32 %b)
  ret void
}

; COMMON: Function [[void]] [[test_sadd]]
; COMMON-NEXT: FunctionParameter [[int]] [[lhs:[0-9]+]]
; COMMON-NEXT: FunctionParameter [[int]] [[rhs:[0-9]+]]
; COMMON-EMPTY:
; COMMON-NEXT: Label
; OPENCL-NEXT: ExtInst [[int]] {{[0-9]+}} [[ext]] s_add_sat [[lhs]] [[rhs]]
; EMULATION-NEXT: SGreaterThan [[bool]] [[greater1:[0-9]+]] [[rhs]] [[zero]]
; EMULATION-NEXT: SLessThan [[bool]] [[less:[0-9]+]] [[rhs]] [[zero]]
; EMULATION-NEXT: IAdd [[int]] [[add:[0-9]+]] [[lhs]] [[rhs]]
; EMULATION-NEXT: ISub [[int]] [[sub1:[0-9]+]] [[int_max]] [[rhs]]
; EMULATION-NEXT: SGreaterThan [[bool]] [[greater2:[0-9]+]] [[lhs]] [[sub1]]
; EMULATION-NEXT: LogicalAnd [[bool]] [[and1:[0-9]+]] [[greater2]] [[greater1]]
; EMULATION-NEXT: ISub [[int]] [[sub2:[0-9]+]] [[int_min]] [[rhs]]
; EMULATION-NEXT: SGreaterThan [[bool]] [[greater3:[0-9]+]] [[sub2]] [[lhs]]
; EMULATION-NEXT: LogicalAnd [[bool]] [[and2:[0-9]+]] [[greater3]] [[less]]
; EMULATION-NEXT: Select [[int]] [[select:[0-9]+]] [[and1]] [[int_max]] [[add]]
; EMULATION-NEXT: Select [[int]] {{[0-9]+}} [[and2]] [[int_min]] [[select]]
; COMMON-NEXT: Return

define spir_func void @test_ssub(i32 %a, i32 %b) {
entry:
  %0 = call i32 @llvm.ssub.sat.i32(i32 %a, i32 %b)
  ret void
}

; COMMON: Function [[void]] [[test_ssub]]
; COMMON-NEXT: FunctionParameter [[int]] [[lhs:[0-9]+]]
; COMMON-NEXT: FunctionParameter [[int]] [[rhs:[0-9]+]]
; COMMON-EMPTY:
; COMMON-NEXT: Label
; OPENCL-NEXT: ExtInst [[int]] {{[0-9]+}} [[ext]] s_sub_sat [[lhs]] [[rhs]]
; EMULATION-NEXT: SGreaterThan [[bool]] [[greater1:[0-9]+]] [[rhs]] [[zero]]
; EMULATION-NEXT: SLessThan [[bool]] [[less:[0-9]+]] [[rhs]] [[zero]]
; EMULATION-NEXT: ISub [[int]] [[sub1:[0-9]+]] [[lhs]] [[rhs]]
; EMULATION-NEXT: IAdd [[int]] [[add1:[0-9]+]] [[int_min]] [[rhs]]
; EMULATION-NEXT: SGreaterThan [[bool]] [[greater2:[0-9]+]] [[add1]] [[lhs]]
; EMULATION-NEXT: LogicalAnd [[bool]] [[and1:[0-9]+]] [[greater2]] [[greater1]]
; EMULATION-NEXT: IAdd [[int]] [[add2:[0-9]+]] [[int_max]] [[rhs]]
; EMULATION-NEXT: SGreaterThan [[bool]] [[greater3:[0-9]+]] [[lhs]] [[add2]]
; EMULATION-NEXT: LogicalAnd [[bool]] [[and2:[0-9]+]] [[greater3]] [[less]]
; EMULATION-NEXT: Select [[int]] [[select:[0-9]+]] [[and2]] [[int_max]] [[sub1]]
; EMULATION-NEXT: Select [[int]] {{[0-9]+}} [[and1]] [[int_min]] [[select]]
; COMMON-NEXT: Return

define spir_func void @test_vectors(<4 x i32> %a, <4 x i32> %b) {
entry:
  %0 = call <4 x i32> @llvm.uadd.sat.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret void
}

; COMMON: Function [[void]] [[test_vectors]]
; COMMON-NEXT: FunctionParameter [[vector]] [[lhs:[0-9]+]]
; COMMON-NEXT: FunctionParameter [[vector]] [[rhs:[0-9]+]]
; COMMON-EMPTY:
; COMMON-NEXT: Label
; OPENCL-NEXT: ExtInst [[vector]] {{[0-9]+}} [[ext]] u_add_sat [[lhs]] [[rhs]]
; EMULATION-NEXT: IAdd [[vector]] [[add:[0-9]+]] [[lhs]] [[rhs]]
; EMULATION-NEXT: UGreaterThanEqual [[vector_bool]] [[greater:[0-9]+]] [[add]] [[lhs]]
; EMULATION-NEXT: Select [[vector]] {{[0-9]+}} [[greater]] [[add]] [[vector_uint_max]]
; COMMON-NEXT: Return

declare i32 @llvm.uadd.sat.i32(i32, i32);
declare i32 @llvm.usub.sat.i32(i32, i32);
declare i32 @llvm.sadd.sat.i32(i32, i32);
declare i32 @llvm.ssub.sat.i32(i32, i32);
declare <4 x i32> @llvm.uadd.sat.v4i32(<4 x i32>, <4 x i32>);

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 0}
!2 = !{i32 1, i32 2}
