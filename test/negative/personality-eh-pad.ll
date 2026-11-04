; Exception handling is not supported. A personality used by a function with
; EH pads must be kept to preserve valid IR, so translation fails.

; RUN: llvm-as %s -o %t.bc
; RUN: not llvm-spirv %t.bc -o %t.spv 2>&1 | FileCheck %s

; CHECK: UnsupportedVarArgFunction

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define spir_func void @foo() personality ptr @__gxx_personality_v0 {
entry:
  invoke void @bar() to label %cont unwind label %lpad

cont:
  ret void

lpad:
  %lp = landingpad { ptr, i32 } cleanup
  resume { ptr, i32 } %lp
}

declare spir_func void @bar()
declare i32 @__gxx_personality_v0(...)
