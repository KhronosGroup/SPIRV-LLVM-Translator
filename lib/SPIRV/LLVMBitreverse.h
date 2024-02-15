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
//  clang -emit-llvm -O2 -g0 -fno-discard-value-names -c
//
// from the C code below with a custom clang that was modified to disable
// intrinsic generation.
//
// #include <stdlib.h>
// #include <stdint.h>
//
// #define MASK32LO 0x00000000FFFFFFFFLLU
// #define MASK16LO 0x0000FFFF0000FFFFLLU
// #define  MASK8LO 0x00FF00FF00FF00FFLLU
// #define  MASK4LO 0x0F0F0F0F0F0F0F0FLLU
// #define  MASK2LO 0x3333333333333333LLU
// #define  MASK1LO 0x5555555555555555LLU
//
// #define SWAP32(X,TYPE) (((X&MASK32LO)<<32) | (((X)>>32)&((TYPE) MASK32LO)))
// #define SWAP16(X,TYPE) (((X&MASK16LO)<<16) | (((X)>>16)&((TYPE) MASK16LO)))
// #define  SWAP8(X,TYPE) (((X&MASK8LO )<< 8) | (((X)>> 8)&((TYPE) MASK8LO)))
// #define  SWAP4(X,TYPE) (((X&MASK4LO )<< 4) | (((X)>> 4)&((TYPE) MASK4LO)))
// #define  SWAP2(X,TYPE) (((X&MASK2LO )<< 2) | (((X)>> 2)&((TYPE) MASK2LO)))
// #define  SWAP1(X,TYPE) (((X&MASK1LO )<< 1) | (((X)>> 1)&((TYPE) MASK1LO)))
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
  %0 = shl i8 %a, 4
  %1 = lshr i8 %a, 4
  %or29 = or disjoint i8 %0, %1
  %2 = shl i8 %or29, 2
  %3 = and i8 %2, -52
  %4 = lshr i8 %or29, 2
  %5 = and i8 %4, 51
  %or1230 = or disjoint i8 %3, %5
  %6 = shl i8 %or1230, 1
  %7 = and i8 %6, -86
  %8 = lshr i8 %or1230, 1
  %9 = and i8 %8, 85
  %or2131 = or disjoint i8 %7, %9
  ret i8 %or2131
}

define zeroext i16 @llvm_bitreverse_i16(i16 %a) {
entry:
  %0 = shl i16 %a, 8
  %1 = lshr i16 %a, 8
  %or40 = or disjoint i16 %0, %1
  %2 = shl i16 %or40, 4
  %3 = and i16 %2, -3856
  %4 = lshr i16 %or40, 4
  %5 = and i16 %4, 3855
  %or1241 = or disjoint i16 %3, %5
  %6 = shl i16 %or1241, 2
  %7 = and i16 %6, -13108
  %8 = lshr i16 %or1241, 2
  %9 = and i16 %8, 13107
  %or2142 = or disjoint i16 %7, %9
  %10 = shl i16 %or2142, 1
  %11 = and i16 %10, -21846
  %12 = lshr i16 %or2142, 1
  %13 = and i16 %12, 21845
  %or3043 = or disjoint i16 %11, %13
  ret i16 %or3043
}

define i32 @llvm_bitreverse_i32(i32 %a) {
entry:
  %0 = shl i32 %a, 16
  %shr = lshr i32 %a, 16
  %or46 = or disjoint i32 %0, %shr
  %1 = shl i32 %or46, 8
  %2 = and i32 %1, -16711936
  %shr7 = lshr i32 %or46, 8
  %and8 = and i32 %shr7, 16711935
  %or1047 = or disjoint i32 %2, %and8
  %3 = shl i32 %or1047, 4
  %4 = and i32 %3, -252645136
  %shr15 = lshr i32 %or1047, 4
  %and16 = and i32 %shr15, 252645135
  %or1848 = or disjoint i32 %4, %and16
  %5 = shl i32 %or1848, 2
  %6 = and i32 %5, -858993460
  %shr23 = lshr i32 %or1848, 2
  %and24 = and i32 %shr23, 858993459
  %or2649 = or disjoint i32 %6, %and24
  %7 = shl i32 %or2649, 1
  %8 = and i32 %7, -1431655766
  %shr31 = lshr i32 %or2649, 1
  %and32 = and i32 %shr31, 1431655765
  %or3450 = or disjoint i32 %8, %and32
  ret i32 %or3450
}

define i64 @llvm_bitreverse_i64(i64 %a) {
entry:
  %and = shl i64 %a, 32
  %shr = lshr i64 %a, 32
  %or = or disjoint i64 %and, %shr
  %and2 = shl i64 %or, 16
  %shl3 = and i64 %and2, -281470681808896
  %shr4 = lshr i64 %or, 16
  %and5 = and i64 %shr4, 281470681808895
  %or6 = or disjoint i64 %shl3, %and5
  %and7 = shl i64 %or6, 8
  %shl8 = and i64 %and7, -71777214294589696
  %shr9 = lshr i64 %or6, 8
  %and10 = and i64 %shr9, 71777214294589695
  %or11 = or disjoint i64 %shl8, %and10
  %and12 = shl i64 %or11, 4
  %shl13 = and i64 %and12, -1085102592571150096
  %shr14 = lshr i64 %or11, 4
  %and15 = and i64 %shr14, 1085102592571150095
  %or16 = or disjoint i64 %shl13, %and15
  %and17 = shl i64 %or16, 2
  %shl18 = and i64 %and17, -3689348814741910324
  %shr19 = lshr i64 %or16, 2
  %and20 = and i64 %shr19, 3689348814741910323
  %or21 = or disjoint i64 %shl18, %and20
  %and22 = shl i64 %or21, 1
  %shl23 = and i64 %and22, -6148914691236517206
  %shr24 = lshr i64 %or21, 1
  %and25 = and i64 %shr24, 6148914691236517205
  %or26 = or disjoint i64 %shl23, %and25
  ret i64 %or26
}
)"};
