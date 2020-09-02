; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: FileCheck --allow-empty --input-file=%t.spv %s
; CHECK: {{$}}
