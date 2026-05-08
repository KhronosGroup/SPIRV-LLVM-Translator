; RUN: llvm-spirv %s -spirv-text --spirv-preserve-auxdata -o - | FileCheck %s --check-prefixes=CHECK-SPIRV
; RUN: llvm-spirv %s -o %t.spv --spirv-preserve-auxdata
; RUN: llvm-spirv -r --spirv-preserve-auxdata %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV-NOAUX --implicit-check-not=NonSemanticAuxData

; CHECK-SPIRV: Extension "SPV_KHR_non_semantic_info"
; CHECK-SPIRV: ExtInstImport [[#Import:]] "NonSemantic.AuxData"
; CHECK-SPIRV: Name [[#GV:]] "extern_gv"
; CHECK-SPIRV: Name [[#Fn:]] "inlinable"
; CHECK-SPIRV: TypeInt [[#I32T:]] 32 0
; CHECK-SPIRV-DAG: Constant [[#I32T]] [[#LinkageVal:]] 0
; CHECK-SPIRV: TypeVoid [[#VoidT:]]

; CHECK-SPIRV-DAG: ExtInst [[#VoidT]] [[#]] [[#Import]] NonSemanticAuxDataLinkage [[#GV]] [[#LinkageVal]] {{$}}
; CHECK-SPIRV-DAG: ExtInst [[#VoidT]] [[#]] [[#Import]] NonSemanticAuxDataLinkage [[#Fn]] [[#LinkageVal]] {{$}}

; CHECK-SPIRV-NOAUX-NOT: NonSemantic.AuxData
; CHECK-SPIRV-NOAUX-NOT: NonSemanticAuxDataLinkage

target triple = "spir64-unknown-unknown"

; CHECK-LLVM: @extern_gv = available_externally addrspace(1) global i32 42
@extern_gv = available_externally addrspace(1) global i32 42

; CHECK-LLVM: define available_externally spir_func i32 @inlinable(i32 %x)
define available_externally spir_func i32 @inlinable(i32 %x) {
  %r = add i32 %x, 1
  ret i32 %r
}
