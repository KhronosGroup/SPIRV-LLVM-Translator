//===- LLVMBitreverse.h - implementation of llvm.bitreverse -===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2024 Intel Corporation. All rights reserved.
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
// This file implements lowering of llvm.bitreverse.* into basic LLVM
// operations.
//
//===----------------------------------------------------------------------===//

// The IR below is slightly manually modified IR which was produced by Clang
// from the C code below. 
//
// #include <stdlib.h>
// #include <stdint.h>
// 
// uint16_t llvm_bitreverse_i16(uint16_t a) {
//   uint16_t ret=0;
//   uint32_t i;
// 
//   for (i=0; i<16; i++) {
//     ret<<=1;
//     if (a&0x1)
//       ret|=1;
//     a>>=1;
//   }
//   return ret;
// }
// 
// uint32_t llvm_bitreverse_i32(uint32_t a) {
//   uint32_t ret=0;
//   uint32_t i;
// 
//   for (i=0; i<32; i++) {
//     ret<<=1;
//     if (a&0x1)
//       ret|=1;
//     a>>=1;
//   }
//   return ret;
// }
// 
// uint64_t llvm_bitreverse_i64(uint64_t a) {
//   uint64_t ret=0;
//   uint32_t i;
// 
//   for (i=0; i<64; i++) {
//     ret<<=1;
//     if (a&0x1)
//       ret|=1;
//     a>>=1;
//   }
//   return ret;
// }
//
// Clang options: -emit-llvm -O1 -g0 -fno-discard-value-names
// -O1 is used instead of -O2 to avoid generating a call to llvm.bitreverse.i16

static const char LLVMBitreverse[]{R"(
define zeroext i16 @llvm_bitreverse_i16(i16 %a) {
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %i.013 = phi i32 [ 0, %entry ], [ %inc, %for.body ]
  %ret.012 = phi i16 [ 0, %entry ], [ %spec.select, %for.body ]
  %a.addr.011 = phi i16 [ %a, %entry ], [ %shr, %for.body ]
  %shl = shl i16 %ret.012, 1
  %0 = and i16 %a.addr.011, 1
  %spec.select = or disjoint i16 %shl, %0
  %shr = lshr i16 %a.addr.011, 1
  %inc = add nuw nsw i32 %i.013, 1
  %exitcond.not = icmp eq i32 %inc, 16
  br i1 %exitcond.not, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret i16 %spec.select
}

define i32 @llvm_bitreverse_i32(i32 %a) {
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %i.07 = phi i32 [ 0, %entry ], [ %inc, %for.body ]
  %ret.06 = phi i32 [ 0, %entry ], [ %spec.select, %for.body ]
  %a.addr.05 = phi i32 [ %a, %entry ], [ %shr, %for.body ]
  %shl = shl i32 %ret.06, 1
  %and = and i32 %a.addr.05, 1
  %spec.select = or disjoint i32 %shl, %and
  %shr = lshr i32 %a.addr.05, 1
  %inc = add nuw nsw i32 %i.07, 1
  %exitcond.not = icmp eq i32 %inc, 32
  br i1 %exitcond.not, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret i32 %spec.select
}

define i64 @llvm_bitreverse_i64(i64 %a) {
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %i.07 = phi i32 [ 0, %entry ], [ %inc, %for.body ]
  %ret.06 = phi i64 [ 0, %entry ], [ %spec.select, %for.body ]
  %a.addr.05 = phi i64 [ %a, %entry ], [ %shr, %for.body ]
  %shl = shl i64 %ret.06, 1
  %and = and i64 %a.addr.05, 1
  %spec.select = or disjoint i64 %shl, %and
  %shr = lshr i64 %a.addr.05, 1
  %inc = add nuw nsw i32 %i.07, 1
  %exitcond.not = icmp eq i32 %inc, 64
  br i1 %exitcond.not, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret i64 %spec.select
}
)"};
