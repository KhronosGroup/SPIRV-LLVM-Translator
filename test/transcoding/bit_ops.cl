// RUN: %clang_cc1 -triple spir-unknown-unknown -O1 -cl-std=CL2.0 -fdeclare-opencl-builtins -finclude-default-header -emit-llvm-bc %s -o %t.bc
// RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
// RUN: llvm-spirv %t.bc -o %t.spv
// RUN: spirv-val %t.spv
// RUN: llvm-spirv -r %t.spv -o %t.rev.bc
// RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

// Test SPIR-V backend:
// RUN: llc -O0 -mtriple=spirv64-unknown-unknown %t.bc -o %t.llc.spv -filetype=obj
// RUN: llvm-spirv -r %t.llc.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM

kernel void testBitOperations(int a, int b, int c, global int *res) {
  *res = (a & b) | (0x6F ^ c);
  *res += popcount(b);
}

// CHECK-SPIRV: BitwiseAnd
// CHECK-SPIRV: BitwiseXor
// CHECK-SPIRV: BitwiseOr
// CHECK-SPIRV: BitCount

// CHECK-LLVM-LABEL: @testBitOperations
// CHECK-LLVM: and i32
// CHECK-LLVM: xor i32
// CHECK-LLVM: or i32
// CHECK-LLVM: call spir_func i32 @_Z8popcounti(i32 %b)
