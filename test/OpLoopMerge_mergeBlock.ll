; Test case for OpLoopMerge merge block assignment validation.
; This test verifies that OpLoopMerge instructions properly assign unique merge blocks
; and don't create conflicts where the same block is used as a merge block for multiple loops.

; RUN: llvm-spirv %S/mergeBlock.bc -o %t.spv
; RUN: spirv-val %t.spv

; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV-TEXT
; CHECK-SPIRV-TEXT: LoopMerge
; CHECK-SPIRV-TEXT: BranchConditional 