; Test case for OpLoopMerge instruction placement validation.
; This test verifies that OpLoopMerge instructions are properly placed as the second-to-last
; instruction in their basic block, immediately preceding the branch instruction.

; RUN: llvm-spirv %S/loopMerge.bc -o %t.spv
; RUN: spirv-val %t.spv

; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV-TEXT
; CHECK-SPIRV-TEXT: LoopMerge
; CHECK-SPIRV-TEXT-NEXT: BranchConditional 