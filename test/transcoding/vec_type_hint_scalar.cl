// RUN: %clang_cc1 -triple spir64-unknown-unknown -x cl -cl-std=CL2.0 -O0 -fdeclare-opencl-builtins -finclude-default-header -emit-llvm-bc %s -o %t.bc
// RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
// RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
// RUN: llvm-spirv %t.bc -o %t.spv
// RUN: spirv-val %t.spv
// RUN: llvm-spirv -r %t.spv -o %t.bc
// RUN: llvm-dis < %t.bc | FileCheck %s --check-prefix=CHECK-LLVM

// CHECK-LLVM-LABEL: define spir_kernel void @test_half()
// CHECK-LLVM-SAME: !vec_type_hint [[VHALF:![0-9]+]]
kernel
__attribute__((vec_type_hint(half)))
void test_half() {}

// CHECK-LLVM-LABEL: define spir_kernel void @test_float()
// CHECK-LLVM-SAME: !vec_type_hint [[VFLOAT:![0-9]+]]
kernel
__attribute__((vec_type_hint(float)))
void test_float() {}

// CHECK-LLVM-LABEL: define spir_kernel void @test_double()
// CHECK-LLVM-SAME: !vec_type_hint [[VDOUBLE:![0-9]+]]
kernel
__attribute__((vec_type_hint(double)))
void test_double() {}

// CHECK-LLVM-LABEL: define spir_kernel void @test_char()
// CHECK-LLVM-SAME: !vec_type_hint [[VCHAR:![0-9]+]]
kernel
__attribute__((vec_type_hint(char)))
void test_char() {}

// CHECK-LLVM-LABEL: define spir_kernel void @test_short()
// CHECK-LLVM-SAME: !vec_type_hint [[VSHORT:![0-9]+]]
kernel
__attribute__((vec_type_hint(short)))
void test_short() {}

// CHECK-LLVM-LABEL: define spir_kernel void @test_int()
// CHECK-LLVM-SAME: !vec_type_hint [[VINT:![0-9]+]]
kernel
__attribute__((vec_type_hint(int)))
void test_int() {}

// CHECK-LLVM-LABEL: define spir_kernel void @test_long()
// CHECK-LLVM-SAME: !vec_type_hint [[VLONG:![0-9]+]]
kernel
__attribute__((vec_type_hint(long)))
void test_long() {}

// CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_half"
// CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_float"
// CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_double"
// CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_char"
// CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_short"
// CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_int"
// CHECK-SPIRV: {{[0-9]+}} EntryPoint {{[0-9]+}} {{[0-9]+}} "test_long"
// CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 65540
// CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 65541
// CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 65542
// CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 65536
// CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 65537
// CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 65538
// CHECK-SPIRV: {{[0-9]+}} ExecutionMode {{[0-9]+}} 30 65539

// CHECK-LLVM: [[VHALF]] = !{half undef, i32 1}
// CHECK-LLVM: [[VFLOAT]] = !{float undef, i32 1}
// CHECK-LLVM: [[VDOUBLE]] = !{double undef, i32 1}
// CHECK-LLVM: [[VCHAR]] = !{i8 undef, i32 1}
// CHECK-LLVM: [[VSHORT]] = !{i16 undef, i32 1}
// CHECK-LLVM: [[VINT]] = !{i32 undef, i32 1}
// CHECK-LLVM: [[VLONG]] = !{i64 undef, i32 1}
