; Checks that the Reader will throw error when it can't infer the pointee type of a function argument,
; in case of indirect function calls with untyped pointers (when both SPV_INTEL_function_pointers and
; SPV_KHR_untyped_pointers are enabled).

; RUN: llvm-spirv %s --spirv-ext=+SPV_INTEL_function_pointers,+SPV_KHR_untyped_pointers -o %t.spv
; RUN: not llvm-spirv -r %t.spv 2>&1 | FileCheck %s

; CHECK: Cannot infer the pointee type of an untyped pointer argument with type attribute of an indirect call

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%struct.S = type { i32 }

define spir_func void @helper(ptr %p, ptr %fp) {
entry:
  call spir_func void %fp(ptr byval(%struct.S) %p)
  ret void
}
