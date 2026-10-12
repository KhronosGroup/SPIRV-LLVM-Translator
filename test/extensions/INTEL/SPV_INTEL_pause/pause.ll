; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_pause -o %t.spv
; RUN: llvm-spirv %t.spv --to-text -o %t.spt
; RUN: FileCheck %s --check-prefix=SPV < %t.spt
; RUN: llvm-spirv %t.spv -o %t.rev.bc -r --spirv-target-env=SPV-IR
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=LLVM
; RUN: llvm-spirv %t.rev.bc --spirv-ext=+SPV_INTEL_pause -o %t.roundtrip.spv
; RUN: diff %t.spv %t.roundtrip.spv
; RUN: not llvm-spirv %t.bc --spirv-ext=-SPV_INTEL_pause -o %t.noext.spv 2>&1 | FileCheck %s --check-prefix=NOEXT
; RUN: not llvm-spirv %t.spv -r --spirv-ext=-SPV_INTEL_pause --spirv-target-env=SPV-IR -o %t.disabled.bc 2>&1 | FileCheck %s --check-prefix=DISABLED

; SPV: 2 Capability PauseINTEL
; SPV: 5 Extension "SPV_INTEL_pause"
; SPV-DAG: 4 TypeInt [[#Int32:]] 32
; SPV: 3 FunctionParameter [[#Int32]] [[#Clock:]]
; SPV: 2 PauseINTEL [[#Clock]]{{ *$}}
; LLVM: call spir_func void @_Z18__spirv_PauseINTELj(i32 %{{.*}})
; LLVM: declare spir_func void @_Z18__spirv_PauseINTELj(i32)
; NOEXT: RequiresExtension: Feature requires the following SPIR-V extension:
; NOEXT-NEXT: SPV_INTEL_pause
; DISABLED: input SPIR-V module uses extension 'SPV_INTEL_pause' which were disabled by --spirv-ext option

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define spir_kernel void @kernel(i32 %clocks) {
entry:
  call spir_func void @_Z18__spirv_PauseINTELj(i32 %clocks)
  ret void
}

declare spir_func void @_Z18__spirv_PauseINTELj(i32)
