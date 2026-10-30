; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG: Name [[#SADD:]] "sadd_v4i32"
; CHECK-SPIRV-DAG: Name [[#SSUB:]] "ssub_i32"
; CHECK-SPIRV-DAG: Name [[#SMUL:]] "smul_i32"
; CHECK-SPIRV-DAG: Name [[#VSMUL:]] "smul_v4i32"
; CHECK-SPIRV-DAG: TypeInt [[#I32:]] 32 0
; CHECK-SPIRV-DAG: TypeBool [[#BOOL:]]
; CHECK-SPIRV-DAG: Constant [[#I32]] [[#ZERO:]] 0
; CHECK-SPIRV-DAG: Constant [[#I32]] [[#C31:]] 31
; CHECK-SPIRV-DAG: TypeVector [[#V4I32:]] [[#I32]] 4
; CHECK-SPIRV-DAG: TypeVector [[#V4BOOL:]] [[#BOOL]] 4
; CHECK-SPIRV-DAG: TypeStruct [[#STRUCT:]] [[#I32]] [[#BOOL]]
; CHECK-SPIRV-DAG: TypeStruct [[#VSTRUCT:]] [[#V4I32]] [[#V4BOOL]]
; CHECK-SPIRV-DAG: TypeStruct [[#EXT:]] [[#I32]] [[#I32]]
; CHECK-SPIRV-DAG: TypeStruct [[#VEXT:]] [[#V4I32]] [[#V4I32]]
; CHECK-SPIRV-DAG: ConstantNull [[#V4I32]] [[#VZERO:]]
; CHECK-SPIRV-DAG: ConstantComposite [[#V4I32]] [[#VC31:]] [[#C31]] [[#C31]] [[#C31]] [[#C31]]

; CHECK-SPIRV: Function [[#]] [[#SADD]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#V4I32]] [[#A:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#V4I32]] [[#B:]]
; CHECK-SPIRV-EMPTY:
; CHECK-SPIRV-NEXT: Label
; CHECK-SPIRV-NEXT: IAdd [[#V4I32]] [[#R:]] [[#A]] [[#B]]
; CHECK-SPIRV-NEXT: BitwiseXor [[#V4I32]] [[#X1:]] [[#A]] [[#R]]
; CHECK-SPIRV-NEXT: BitwiseXor [[#V4I32]] [[#X2:]] [[#B]] [[#R]]
; CHECK-SPIRV-NEXT: BitwiseAnd [[#V4I32]] [[#AND:]] [[#X1]] [[#X2]]
; CHECK-SPIRV-NEXT: SLessThan [[#V4BOOL]] [[#O:]] [[#AND]] [[#VZERO]]
; CHECK-SPIRV-NEXT: CompositeInsert [[#VSTRUCT]] [[#S:]] [[#R]] [[#]] 0
; CHECK-SPIRV-NEXT: CompositeInsert [[#VSTRUCT]] [[#]] [[#O]] [[#S]] 1

; CHECK-SPIRV: Function [[#]] [[#SSUB]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#I32]] [[#A:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#I32]] [[#B:]]
; CHECK-SPIRV-EMPTY:
; CHECK-SPIRV-NEXT: Label
; CHECK-SPIRV-NEXT: ISub [[#I32]] [[#R:]] [[#A]] [[#B]]
; CHECK-SPIRV-NEXT: BitwiseXor [[#I32]] [[#X1:]] [[#A]] [[#B]]
; CHECK-SPIRV-NEXT: BitwiseXor [[#I32]] [[#X2:]] [[#A]] [[#R]]
; CHECK-SPIRV-NEXT: BitwiseAnd [[#I32]] [[#AND:]] [[#X1]] [[#X2]]
; CHECK-SPIRV-NEXT: SLessThan [[#BOOL]] [[#O:]] [[#AND]] [[#ZERO]]
; CHECK-SPIRV-NEXT: CompositeInsert [[#STRUCT]] [[#S:]] [[#R]] [[#]] 0
; CHECK-SPIRV-NEXT: CompositeInsert [[#STRUCT]] [[#]] [[#O]] [[#S]] 1

; CHECK-SPIRV: Function [[#]] [[#SMUL]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#I32]] [[#A:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#I32]] [[#B:]]
; CHECK-SPIRV-EMPTY:
; CHECK-SPIRV-NEXT: Label
; CHECK-SPIRV-NEXT: SMulExtended [[#EXT]] [[#M:]] [[#A]] [[#B]]
; CHECK-SPIRV-NEXT: CompositeExtract [[#I32]] [[#LO:]] [[#M]] 0
; CHECK-SPIRV-NEXT: CompositeExtract [[#I32]] [[#HI:]] [[#M]] 1
; CHECK-SPIRV-NEXT: ShiftRightArithmetic [[#I32]] [[#SIGN:]] [[#LO]] [[#C31]]
; CHECK-SPIRV-NEXT: INotEqual [[#BOOL]] [[#O:]] [[#HI]] [[#SIGN]]
; CHECK-SPIRV-NEXT: CompositeInsert [[#STRUCT]] [[#S:]] [[#LO]] [[#]] 0
; CHECK-SPIRV-NEXT: CompositeInsert [[#STRUCT]] [[#]] [[#O]] [[#S]] 1

; CHECK-SPIRV: Function [[#]] [[#VSMUL]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#V4I32]] [[#A:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#V4I32]] [[#B:]]
; CHECK-SPIRV-EMPTY:
; CHECK-SPIRV-NEXT: Label
; CHECK-SPIRV-NEXT: SMulExtended [[#VEXT]] [[#M:]] [[#A]] [[#B]]
; CHECK-SPIRV-NEXT: CompositeExtract [[#V4I32]] [[#LO:]] [[#M]] 0
; CHECK-SPIRV-NEXT: CompositeExtract [[#V4I32]] [[#HI:]] [[#M]] 1
; CHECK-SPIRV-NEXT: ShiftRightArithmetic [[#V4I32]] [[#SIGN:]] [[#LO]] [[#VC31]]
; CHECK-SPIRV-NEXT: INotEqual [[#V4BOOL]] [[#O:]] [[#HI]] [[#SIGN]]
; CHECK-SPIRV-NEXT: CompositeInsert [[#VSTRUCT]] [[#S:]] [[#LO]] [[#]] 0
; CHECK-SPIRV-NEXT: CompositeInsert [[#VSTRUCT]] [[#]] [[#O]] [[#S]] 1

; CHECK-LLVM-LABEL: define spir_func {{.*}} @sadd_v4i32(
; CHECK-LLVM: %[[#R:]] = add <4 x i32> %a, %b
; CHECK-LLVM: %[[#X1:]] = xor <4 x i32> %a, %[[#R]]
; CHECK-LLVM: %[[#X2:]] = xor <4 x i32> %b, %[[#R]]
; CHECK-LLVM: %[[#AND:]] = and <4 x i32> %[[#X1]], %[[#X2]]
; CHECK-LLVM: icmp slt <4 x i32> %[[#AND]], zeroinitializer

; CHECK-LLVM-LABEL: define spir_func {{.*}} @ssub_i32(
; CHECK-LLVM: %[[#R:]] = sub i32 %a, %b
; CHECK-LLVM: %[[#X1:]] = xor i32 %a, %b
; CHECK-LLVM: %[[#X2:]] = xor i32 %a, %[[#R]]
; CHECK-LLVM: %[[#AND:]] = and i32 %[[#X1]], %[[#X2]]
; CHECK-LLVM: icmp slt i32 %[[#AND]], 0

; CHECK-LLVM-LABEL: define spir_func {{.*}} @smul_i32(
; CHECK-LLVM: call spir_func void @_Z20__spirv_SMulExtendedii(
; CHECK-LLVM: ashr i32 %{{.*}}, 31
; CHECK-LLVM: icmp ne i32

define spir_func { <4 x i32>, <4 x i1> } @sadd_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call { <4 x i32>, <4 x i1> } @llvm.sadd.with.overflow.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret { <4 x i32>, <4 x i1> } %r
}

define spir_func { i32, i1 } @ssub_i32(i32 %a, i32 %b) {
entry:
  %r = call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 %a, i32 %b)
  ret { i32, i1 } %r
}

define spir_func { i32, i1 } @smul_i32(i32 %a, i32 %b) {
entry:
  %r = call { i32, i1 } @llvm.smul.with.overflow.i32(i32 %a, i32 %b)
  ret { i32, i1 } %r
}

define spir_func { <4 x i32>, <4 x i1> } @smul_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call { <4 x i32>, <4 x i1> } @llvm.smul.with.overflow.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret { <4 x i32>, <4 x i1> } %r
}
