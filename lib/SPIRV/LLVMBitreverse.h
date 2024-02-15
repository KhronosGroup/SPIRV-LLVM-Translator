//===- LLVMBitreverse.h - implementation of llvm.bitreverse -===//
//
//                     The LLVM/SPIRV Translator
//
// Copyright (c) 2024 The Khronos Group Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//===----------------------------------------------------------------------===//
//
// This file implements lowering of llvm.bitreverse.* into basic LLVM
// operations.
//
//===----------------------------------------------------------------------===//

// The IR below is slightly manually modified IR which was produced by the
// command:
//
//  clang -emit-llvm -O2 -g0 -fno-discard-value-names
//
// from the C code below with a custom clang that was modified to disable
// intrinsic generation.
//
// #include <stdlib.h>
// #include <stdint.h>
//
// #define MASK32HI 0xFFFFFFFF00000000LLU
// #define MASK32LO 0x00000000FFFFFFFFLLU
//
// #define MASK16HI 0xFFFF0000FFFF0000LLU
// #define MASK16LO 0x0000FFFF0000FFFFLLU
//
// #define  MASK8HI 0xFF00FF00FF00FF00LLU
// #define  MASK8LO 0x00FF00FF00FF00FFLLU
//
// #define  MASK4HI 0xF0F0F0F0F0F0F0F0LLU
// #define  MASK4LO 0x0F0F0F0F0F0F0F0FLLU
//
// #define  MASK2HI 0xCCCCCCCCCCCCCCCCLLU
// #define  MASK2LO 0x3333333333333333LLU
//
// #define  MASK1HI 0xAAAAAAAAAAAAAAAALLU
// #define  MASK1LO 0x5555555555555555LLU
//
// #define SWAP32(X,TYPE) ((((X)<<32)&((TYPE) MASK32HI)) | \
//                         (((X)>>32)&((TYPE) MASK32LO)))
// #define SWAP16(X,TYPE) ((((X)<<16)&((TYPE) MASK16HI)) | \
//                         (((X)>>16)&((TYPE) MASK16LO)))
// #define  SWAP8(X,TYPE) ((((X)<< 8)&((TYPE) MASK8HI )) | \
//                         (((X)>> 8)&((TYPE) MASK8LO )))
// #define  SWAP4(X,TYPE) ((((X)<< 4)&((TYPE) MASK4HI )) | \
//                         (((X)>> 4)&((TYPE) MASK4LO )))
// #define  SWAP2(X,TYPE) ((((X)<< 2)&((TYPE) MASK2HI )) | \
//                         (((X)>> 2)&((TYPE) MASK2LO )))
// #define  SWAP1(X,TYPE) ((((X)<< 1)&((TYPE) MASK1HI )) | \
//                         (((X)>> 1)&((TYPE) MASK1LO )))
//
// uint8_t llvm_bitreverse_i8(uint8_t a) {
//   a=SWAP4(a,uint8_t);
//   a=SWAP2(a,uint8_t);
//   a=SWAP1(a,uint8_t);
//   return a;
// }
//
// uint16_t llvm_bitreverse_i16(uint16_t a) {
//   a=SWAP8(a,uint16_t);
//   a=SWAP4(a,uint16_t);
//   a=SWAP2(a,uint16_t);
//   a=SWAP1(a,uint16_t);
//   return a;
// }
//
// uint32_t llvm_bitreverse_i32(uint32_t a) {
//   a=SWAP16(a,uint32_t);
//   a=SWAP8(a,uint32_t);
//   a=SWAP4(a,uint32_t);
//   a=SWAP2(a,uint32_t);
//   a=SWAP1(a,uint32_t);
//   return a;
// }
//
// uint64_t llvm_bitreverse_i64(uint64_t a) {
//   a=SWAP32(a,uint64_t);
//   a=SWAP16(a,uint64_t);
//   a=SWAP8(a,uint64_t);
//   a=SWAP4(a,uint64_t);
//   a=SWAP2(a,uint64_t);
//   a=SWAP1(a,uint64_t);
//   return a;
// }

static const char LLVMBitreverse[]{R"(
define zeroext i8 @llvm_bitreverse_i8(i8 %a) {
entry:
  %shl = shl i8 %a, 4
  %shr = lshr i8 %a, 4
  %or = or disjoint i8 %shl, %shr
  %shl5 = shl i8 %or, 2
  %and6 = and i8 %shl5, -52
  %shr8 = lshr i8 %or, 2
  %and9 = and i8 %shr8, 51
  %or10 = or disjoint i8 %and6, %and9
  %shl13 = shl i8 %or10, 1
  %and14 = and i8 %shl13, -86
  %shr16 = lshr i8 %or10, 1
  %and17 = and i8 %shr16, 85
  %or18 = or disjoint i8 %and14, %and17
  ret i8 %or18
}

define zeroext i16 @llvm_bitreverse_i16(i16 %a) {
entry:
  %shl = shl i16 %a, 8
  %shr = lshr i16 %a, 8
  %or = or disjoint i16 %shl, %shr
  %shl5 = shl i16 %or, 4
  %and6 = and i16 %shl5, -3856
  %shr8 = lshr i16 %or, 4
  %and9 = and i16 %shr8, 3855
  %or10 = or disjoint i16 %and6, %and9
  %shl13 = shl i16 %or10, 2
  %and14 = and i16 %shl13, -13108
  %shr16 = lshr i16 %or10, 2
  %and17 = and i16 %shr16, 13107
  %or18 = or disjoint i16 %and14, %and17
  %shl21 = shl i16 %or18, 1
  %and22 = and i16 %shl21, -21846
  %shr24 = lshr i16 %or18, 1
  %and25 = and i16 %shr24, 21845
  %or26 = or disjoint i16 %and22, %and25
  ret i16 %or26
}

define i32 @llvm_bitreverse_i32(i32 %a) {
entry:
  %shl = shl i32 %a, 16
  %shr = lshr i32 %a, 16
  %or = or disjoint i32 %shl, %shr
  %shl2 = shl i32 %or, 8
  %and3 = and i32 %shl2, -16711936
  %shr4 = lshr i32 %or, 8
  %and5 = and i32 %shr4, 16711935
  %or6 = or disjoint i32 %and3, %and5
  %shl7 = shl i32 %or6, 4
  %and8 = and i32 %shl7, -252645136
  %shr9 = lshr i32 %or6, 4
  %and10 = and i32 %shr9, 252645135
  %or11 = or disjoint i32 %and8, %and10
  %shl12 = shl i32 %or11, 2
  %and13 = and i32 %shl12, -858993460
  %shr14 = lshr i32 %or11, 2
  %and15 = and i32 %shr14, 858993459
  %or16 = or disjoint i32 %and13, %and15
  %shl17 = shl i32 %or16, 1
  %and18 = and i32 %shl17, -1431655766
  %shr19 = lshr i32 %or16, 1
  %and20 = and i32 %shr19, 1431655765
  %or21 = or disjoint i32 %and18, %and20
  ret i32 %or21
}

define i64 @llvm_bitreverse_i64(i64 %a) {
entry:
  %shl = shl i64 %a, 32
  %shr = lshr i64 %a, 32
  %or = or disjoint i64 %shl, %shr
  %shl2 = shl i64 %or, 16
  %and3 = and i64 %shl2, -281470681808896
  %shr4 = lshr i64 %or, 16
  %and5 = and i64 %shr4, 281470681808895
  %or6 = or disjoint i64 %and3, %and5
  %shl7 = shl i64 %or6, 8
  %and8 = and i64 %shl7, -71777214294589696
  %shr9 = lshr i64 %or6, 8
  %and10 = and i64 %shr9, 71777214294589695
  %or11 = or disjoint i64 %and8, %and10
  %shl12 = shl i64 %or11, 4
  %and13 = and i64 %shl12, -1085102592571150096
  %shr14 = lshr i64 %or11, 4
  %and15 = and i64 %shr14, 1085102592571150095
  %or16 = or disjoint i64 %and13, %and15
  %shl17 = shl i64 %or16, 2
  %and18 = and i64 %shl17, -3689348814741910324
  %shr19 = lshr i64 %or16, 2
  %and20 = and i64 %shr19, 3689348814741910323
  %or21 = or disjoint i64 %and18, %and20
  %shl22 = shl i64 %or21, 1
  %and23 = and i64 %shl22, -6148914691236517206
  %shr24 = lshr i64 %or21, 1
  %and25 = and i64 %shr24, 6148914691236517205
  %or26 = or disjoint i64 %and23, %and25
  ret i64 %or26
}
)"};
