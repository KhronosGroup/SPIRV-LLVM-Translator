; RUN: not llvm-spirv -spirv-text -r %s 2>&1 | FileCheck %s --check-prefix=CHECK-ERROR
; CHECK-ERROR: InvalidWordCount:  WordCount exceeds remaining input stream size: expected size = 8 bytes, remaining size = 4 bytes

119734787 65536 393230 16 0
3 Capability Addresses