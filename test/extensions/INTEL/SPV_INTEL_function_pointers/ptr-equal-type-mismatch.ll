; Check that comparing a function pointer against a differently-typed pointer
; inserts a Bitcast to unify operand types before OpPtrEqual/OpPtrNotEqual,
; as required by the SPIR-V spec.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_function_pointers -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_function_pointers -o %t.spv
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG: Name [[#ARG:]] "arg"
; CHECK-SPIRV-DAG: TypeFunction [[#FOOTY:]] [[#]] [[#]]
; CHECK-SPIRV-DAG: TypePointer [[#FUNPTRTY:]] {{[0-9]+}} [[#FOOTY]]
; CHECK-SPIRV: ConstantFunctionPointerINTEL [[#FUNPTRTY]] [[#FOOPTR:]] [[#]]

; CHECK-SPIRV: Bitcast [[#FUNPTRTY]] [[#ARGCAST:]] [[#ARG]]
; CHECK-SPIRV: PtrEqual [[#]] [[#]] [[#FOOPTR]] [[#ARGCAST]]

define spir_func i32 @foo(i32 %v) {
  ret i32 %v
}

define spir_func i1 @test(ptr %arg) {
  %val = load i32, ptr %arg
  %cmp = icmp eq ptr @foo, %arg
  ret i1 %cmp
}
