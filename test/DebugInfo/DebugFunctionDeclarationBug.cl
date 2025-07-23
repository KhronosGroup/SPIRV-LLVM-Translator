// Test case to verify the fix for the issue where DebugFunction uses DebugInfoNone instead of DebugFunctionDeclaration
// for the Declaration operand when there's no separate function declaration.
// This test verifies that spirv-val now passes successfully after the fix.

// RUN: %clang_cc1 %s -emit-llvm-bc -triple spir -debug-info-kind=limited -O0 -o - | llvm-spirv -o %t.spv
// RUN: spirv-val %t.spv

// This test should pass spirv-val validation after the bug fix
// We can also verify that the SPIR-V contains proper DebugFunctionDeclaration
// RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV-TEXT

// CHECK-SPIRV-TEXT: DebugFunctionDeclaration
// CHECK-SPIRV-TEXT: DebugFunction

int test_function(int x) {
    return x + 1;
}

void kernel test_kernel() {
    int result = test_function(42);
} 