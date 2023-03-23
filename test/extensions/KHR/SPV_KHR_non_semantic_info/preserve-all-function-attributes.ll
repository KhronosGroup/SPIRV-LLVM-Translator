; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text --spirv-preserve-all-function-attributes-and-metadata --spirv-ext=+SPV_KHR_non_semantic_info -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-preserve-all-function-attributes-and-metadata --spirv-ext=+SPV_KHR_non_semantic_info
; RUN: llvm-spirv -r -emit-opaque-pointers --spirv-preserve-all-function-attributes-and-metadata %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM
; RUN: llvm-spirv -r -emit-opaque-pointers %t.spv -o %t.rev.without.bc
; RUN: llvm-dis %t.rev.without.bc -o - | FileCheck %s --implicit-check-not="{{foo|bar|baz}}"

; CHECK-SPIRV: Extension "SPV_KHR_non_semantic_info" 
; CHECK-SPIRV: ExtInstImport [[#Import:]] "NonSemantic.AuxData"

; CHECK-SPIRV: String [[#Attr0:]] "foo"
; CHECK-SPIRV: String [[#Attr1LHS:]] "bar"
; CHECK-SPIRV: String [[#Attr1RHS:]] "baz"

; CHECK-SPIRV: Name [[#Fcn0:]] "mul_add"
; CHECK-SPIRV: Name [[#Fcn1:]] "test"

; CHECK-SPIRV: TypeVoid [[#VoidT:]]

; CHECK-SPIRV: ExtInst [[#VoidT]] [[#Attr0Inst:]] [[#Import]] NonSemanticAuxDataFunctionAttribute [[#Fcn0]] [[#Attr0]] {{$}}
; CHECK-SPIRV: ExtInst [[#VoidT]] [[#Attr1Inst:]] [[#Import]] NonSemanticAuxDataFunctionAttribute [[#Fcn1]] [[#Attr1LHS]] [[#Attr1RHS]] {{$}}

target triple = "spir64-unknown-unknown"

; CHECK-LLVM: declare spir_func void @mul_add() #[[#Fcn0IRAttr:]]
declare spir_func void @mul_add() #0

; CHECK-LLVM: define spir_func void @test() #[[#Fcn1IRAttr:]]
define spir_func void @test() #1 {
entry:
 call spir_func void @mul_add()
ret void
}

; CHECK-LLVM: attributes #[[#Fcn0IRAttr]] = { {{.*}}"foo" }
attributes #0 = { "foo" }
; CHECK-LLVM: attributes #[[#Fcn1IRAttr]] = { {{.*}}"bar"="baz" }
attributes #1 = { "bar"="baz" }
 
