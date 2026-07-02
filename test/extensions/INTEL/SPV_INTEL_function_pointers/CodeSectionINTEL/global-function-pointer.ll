; RUN: llvm-as < %s | llvm-spirv -spirv-ext=+SPV_INTEL_function_pointers -o %t.spv
; RUN: llvm-spirv %t.spv -spirv-ext=+SPV_INTEL_function_pointers -to-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM
; RUN: llvm-spirv -r -spirv-emit-function-ptr-addr-space %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM-ADDR-SPACE

; RUN: llvm-as < %s | llvm-spirv -spirv-ext=+SPV_INTEL_function_pointers,+SPV_KHR_untyped_pointers -o %t.spv
; RUN: llvm-spirv %t.spv -spirv-ext=+SPV_INTEL_function_pointers,+SPV_KHR_untyped_pointers -to-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV-UNTYPED
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM
; RUN: llvm-spirv -r -spirv-emit-function-ptr-addr-space %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM-UNTYPED-ADDR-SPACE

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64"


; CHECK-SPIRV: Capability FunctionPointersINTEL
; CHECK-SPIRV: Extension "SPV_INTEL_function_pointers"
; CHECK-SPIRV: TypeFunction [[#FOO_TY:]] [[#]] [[#]]
; CHECK-SPIRV: TypePointer [[#FOO_TY_PTR:]] [[#]] [[#FOO_TY]]
; CHECK-SPIRV: ConstantFunctionPointerINTEL [[#FOO_TY_PTR]] [[#FOO_PTR:]] [[#FOO:]]
; CHECK-SPIRV: Function [[#]] [[#]] [[#]] [[#FOO_TY]]

; CHECK-SPIRV-UNTYPED: Capability FunctionPointersINTEL
; CHECK-SPIRV-UNTYPED: Extension "SPV_INTEL_function_pointers"
; CHECK-SPIRV-UNTYPED: Extension "SPV_KHR_untyped_pointers"
; CHECK-SPIRV-UNTYPED: TypeUntypedPointerKHR [[#FOO_TY_PTR:]] [[#]]
; CHECK-SPIRV-UNTYPED: TypeFunction [[#FOO_TY:]] [[#]] [[#]]
; CHECK-SPIRV-UNTYPED: ConstantFunctionPointerINTEL [[#FOO_TY_PTR]] [[#FOO_PTR:]] [[#FOO:]]
; CHECK-SPIRV-UNTYPED: UntypedVariableKHR [[#]] [[#]] [[#]] [[#FOO_TY_PTR]] [[#FOO_PTR]]
; CHECK-SPIRV-UNTYPED: Function [[#]] [[#]] [[#]] [[#FOO_TY]]

; CHECK-LLVM: @two = internal addrspace(1) global ptr @_Z4barrii
; CHECK-LLVM: define spir_func i32 @_Z4barrii(i32 %[[#]], i32 %[[#]])

; CHECK-LLVM-ADDR-SPACE: @two = internal addrspace(1) global ptr addrspace(9) @_Z4barrii
; CHECK-LLVM-ADDR-SPACE: define spir_func i32 @_Z4barrii(i32 %[[#]], i32 %[[#]]) addrspace(9)

; CHECK-LLVM-UNTYPED-ADDR-SPACE: @two = internal addrspace(1) global ptr addrspacecast (ptr addrspace(9) @_Z4barrii to ptr)
; CHECK-LLVM-UNTYPED-ADDR-SPACE: define spir_func i32 @_Z4barrii(i32 %[[#]], i32 %[[#]]) addrspace(9)

@two = internal addrspace(1) global ptr @_Z4barrii, align 8

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn writeonly
define protected spir_func noundef i32 @_Z4barrii(i32 %0, i32 %1) {
entry:
  ret i32 1
}
