//===- LLVMUmulWithOverflow.h - implementation of llvm.umul.with.overflow -===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2020 Intel Corporation. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal with the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimers.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimers in the documentation
// and/or other materials provided with the distribution.
// Neither the names of Intel Corporation, nor the names of its
// contributors may be used to endorse or promote products derived from this
// Software without specific prior written permission.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH
// THE SOFTWARE.
//
//===----------------------------------------------------------------------===//
//
// This file implements lowering of llvm.umul.with.overflow.* into basic LLVM
// operations.
//
//===----------------------------------------------------------------------===//

// The IR below is manually modified IR which was produced by Clang
// from the C++ code below. The modifications include:
// - adapting the return value, i.e. replacing `store` instructions for the c
//   and o arguments with `insertvalue` instructions.
// - removed unnecessary load/store instructions.
//
// #include <stdlib.h>
// #include <stdint.h>

// const unsigned short i8_unsigned_max = 0xFF; // 255;
// void llvm_umul_with_overflow_i8(uint8_t a, uint8_t b, uint8_t& c, bool& o) {
//     bool overflow = false;
//     // 32-bit integers are always supported in SPIR-V
//     uint32_t x = a * b;
//     if (x > i8_unsigned_max)
//         overflow = true;
//     c = a * b;
//     o = overflow;
// }

// const unsigned short i16_unsigned_max = 0xFFFF; // 65535;
// void llvm_umul_with_overflow_i16(uint16_t a, uint16_t b, uint16_t& c, bool&
// o) {
//     bool overflow = false;
//     // 32-bit integers are always supported in SPIR-V
//     uint32_t x = a * b;
//     if (x > i16_unsigned_max)
//         overflow = true;
//     c = a * b;
//     o = overflow;
// }

// void llvm_umul_with_overflow_i32(uint32_t a, uint32_t b, uint32_t& c, bool&
// o) {
//     bool overflow = false;
//     c = a * b;
//     if (a == 0 || b == 0)
//         overflow = false;
//     else if (a != c / b)
//         overflow = true;
//     o = overflow;
// }

// void llvm_umul_with_overflow_i64(uint64_t a, uint64_t b, uint64_t& c, bool&
// o) {
//     bool overflow = false;
//     c = a * b;
//     if (a == 0 || b == 0)
//         overflow = false;
//     else if (a != c / b)
//         overflow = true;
//     o = overflow;
// }
// Clang options: -emit-llvm -O0 -g0 -fno-discard-value-names

static const char LLVMUmulWithOverflow[]{R"(
define spir_func { i8, i1 } @llvm_umul_with_overflow_i8(i8 %a, i8 %b) {
entry:
  %overflow = alloca i1, align 1
  store i1 0, i1* %overflow, align 1
  %conv = zext i8 %a to i32
  %conv1 = zext i8 %b to i32
  %mul = mul nsw i32 %conv, %conv1
  %cmp = icmp ugt i32 %mul, 255
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  store i1 1, i1* %overflow, align 1
  br label %if.end

if.end:                                         ; preds = %if.then, %entry
  %mul1 = mul i8 %a, %b
  %load = load i1, i1* %overflow, align 1
  %agg = insertvalue {i8, i1} undef, i8 %mul1, 0
  %res = insertvalue {i8, i1} %agg, i1 %load, 1
  ret {i8, i1} %res
}

define spir_func { i16, i1 } @llvm_umul_with_overflow_i16(i16 %a, i16 %b) {
entry:
  %overflow = alloca i1, align 1
  store i1 0, i1* %overflow, align 1
  %conv = zext i16 %a to i32
  %conv1 = zext i16 %b to i32
  %mul = mul nsw i32 %conv, %conv1
  %cmp = icmp ugt i32 %mul, 65535
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  store i1 1, i1* %overflow, align 1
  br label %if.end


if.end:                                         ; preds = %if.then, %entry
  %mul1 = mul i16 %a, %b
  %load = load i1, i1* %overflow, align 1
  %agg = insertvalue {i16, i1} undef, i16 %mul1, 0
  %res = insertvalue {i16, i1} %agg, i1 %load, 1
  ret {i16, i1} %res
}

define spir_func { i32, i1 } @llvm_umul_with_overflow_i32(i32 %a, i32 %b) {
entry:
  %overflow = alloca i1, align 1
  store i1 0, i1* %overflow, align 1
  %mul = mul i32 %a, %b
  %cmp = icmp eq i32 %a, 0
  br i1 %cmp, label %if.then, label %lor.lhs.false

lor.lhs.false:                                    ; preds = %entry
  %cmp1 = icmp eq i32 %b, 0
  br i1 %cmp1, label %if.then, label %if.else

if.then:                                          ; preds = %lor.lhs.false, %entry
  store i1 0, i1* %overflow, align 1
  br label %if.end4

if.else:                                          ; preds = %lor.lhs.false
  %div = udiv i32 %mul, %b
  %cmp2 = icmp ne i32 %a, %div
  br i1 %cmp2, label %if.then3, label %if.end

if.then3:                                         ; preds = %if.else
  store i1 1, i1* %overflow, align 1
  br label %if.end

if.end:                                           ; preds = %if.then3, %if.else
  br label %if.end4

if.end4:                                          ; preds = %if.end, %if.then
  %load = load i1, i1* %overflow, align 1
  %agg = insertvalue {i32, i1} undef, i32 %mul, 0
  %res = insertvalue {i32, i1} %agg, i1 %load, 1
  ret {i32, i1} %res
}

define spir_func { i64, i1 } @llvm_umul_with_overflow_i64(i64 %a, i64 %b) {
entry:
  %overflow = alloca i1, align 1
  store i1 0, i1* %overflow, align 1
  %mul = mul i64 %a, %b
  %cmp = icmp eq i64 %a, 0
  br i1 %cmp, label %if.then, label %lor.lhs.false

lor.lhs.false:                                    ; preds = %entry
  %cmp1 = icmp eq i64 %b, 0
  br i1 %cmp1, label %if.then, label %if.else

if.then:                                          ; preds = %lor.lhs.false, %entry
  store i1 0, i1* %overflow, align 1
  br label %if.end4

if.else:                                          ; preds = %lor.lhs.false
  %div = udiv i64 %mul, %b
  %cmp2 = icmp ne i64 %a, %div
  br i1 %cmp2, label %if.then3, label %if.end

if.then3:                                         ; preds = %if.else
  store i1 1, i1* %overflow, align 1
  br label %if.end

if.end:                                           ; preds = %if.then3, %if.else
  br label %if.end4

if.end4:                                          ; preds = %if.end, %if.then
  %load = load i1, i1* %overflow, align 1
  %agg = insertvalue {i64, i1} undef, i64 %mul, 0
  %res = insertvalue {i64, i1} %agg, i1 %load, 1
  ret {i64, i1} %res
}
)"};
