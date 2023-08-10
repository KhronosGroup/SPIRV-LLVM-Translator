; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spv -o %t.rev.bc -r -emit-opaque-pointers --spirv-target-env=SPV-IR
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; RUN: not llvm-spirv %t.bc 2>&1 | FileCheck %s --check-prefix=CHECK-ERROR

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"


; CHECK-SPIRV: TypeInt [[#I32Ty:]] 32
; CHECK-SPIRV: TypeStruct [[#StructI32I32Ty:]] [[I32Ty]] [[I32Ty]]

; CHECK-SPIRV: FunctionParameter [[I32Ty]] [[#I32ValId:]]

; CHECK-SPIRV: OpIAddCarry [[StructI32I32Ty]] [[#]] [[I32ValId]] [[I32ValId]]

; CHECK-LLVM: call { i32, i1 } @llvm.uadd.with.overflow.i32


declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)

define { i32, i1 } @simple_fold(i32 %x) {
  %a = add nuw i32 %x, 7
  %b = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a, i32 13)
  ret { i32, i1 } %b
}

!opencl.spir.version = !{!0}
!spirv.Source = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, i32 2}
!1 = !{i32 4, i32 100000}
!2 = !{!"clang version 16.0.0"}
