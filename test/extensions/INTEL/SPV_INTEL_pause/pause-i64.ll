; RUN: not llvm-spirv %s --spirv-ext=+SPV_INTEL_pause -o %t.spv 2>&1 | FileCheck %s

; CHECK: Clocks must be a 32-bit integer scalar

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define spir_kernel void @kernel(i64 %clocks) {
entry:
  call spir_func void @_Z18__spirv_PauseINTELm(i64 %clocks)
  ret void
}

declare spir_func void @_Z18__spirv_PauseINTELm(i64)
