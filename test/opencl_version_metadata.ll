; RUN: split-file %s %t
; RUN: llvm-as %t/metadata-opencl12.ll -o %t/12.bc
; RUN: llvm-spirv %t/12.bc -o %t/12.spv
; RUN: spirv-val %t/12.spv
; RUN: llvm-spirv -to-text %t/12.spv -o - | FileCheck %t/metadata-opencl12.ll
; RUN: llvm-spirv -r %t/12.spv -o %t/12.rev.bc
; RUN: llvm-dis < %t/12.rev.bc | FileCheck %t/metadata-opencl12.ll --check-prefix=CHECK-LLVM

; RUN: llvm-as %t/metadata-opencl20.ll -o %t/20.bc
; RUN: llvm-spirv %t/20.bc -o %t/20.spv
; RUN: spirv-val %t/20.spv
; RUN: llvm-spirv -to-text %t/20.spv -o - | FileCheck %t/metadata-opencl20.ll
; RUN: llvm-spirv -r %t/20.spv -o %t/20.rev.bc
; RUN: llvm-dis < %t/20.rev.bc | FileCheck %t/metadata-opencl20.ll --check-prefix=CHECK-LLVM

; RUN: llvm-as %t/metadata-opencl22.ll -o %t/22.bc
; RUN: llvm-spirv %t/22.bc -o %t/22.spv
; RUN: spirv-val %t/22.spv
; RUN: llvm-spirv -to-text %t/22.spv -o - | FileCheck %t/metadata-opencl22.ll
; RUN: llvm-spirv -r %t/22.spv -o %t/22.rev.bc
; RUN: llvm-dis < %t/22.rev.bc | FileCheck %t/metadata-opencl22.ll --check-prefix=CHECK-LLVM

;--- metadata-opencl12.ll
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"
!opencl.ocl.version = !{!0}
!0 = !{i32 1, i32 2}
; CHECK: Source 3 102000
; CHECK-LLVM: !opencl.ocl.version = !{!2}
; CHECK-LLVM: !2 = !{i32 1, i32 2}

;--- metadata-opencl20.ll
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"
!opencl.ocl.version = !{!0}
!0 = !{i32 2, i32 0}
; CHECK: Source 3 200000
; CHECK-LLVM: !opencl.ocl.version = !{!2}
; CHECK-LLVM: !2 = !{i32 2, i32 0}

;--- metadata-opencl22.ll
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"
!opencl.ocl.version = !{!0}
!0 = !{i32 2, i32 2}
; CHECK: Source 3 202000
; CHECK-LLVM: !opencl.ocl.version = !{!0}
; CHECK-LLVM: !0 = !{i32 2, i32 2}
