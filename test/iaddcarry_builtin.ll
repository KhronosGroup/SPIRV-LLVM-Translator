; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-dis --raw-id %t.spv | FileCheck --check-prefix CHECK-SPIRV %s
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; llvm-dis %t.rev.bc -o - | FileCheck --check-prefix CHECK-LLVM %s

target triple = "spir64-unknown-unknown"

; CHECK-SPIRV:                    [[uchar:%[a-z0-9_]+]] = OpTypeInt 8
; CHECK-SPIRV:                   [[ushort:%[a-z0-9_]+]] = OpTypeInt 16
; CHECK-SPIRV:                     [[uint:%[a-z0-9_]+]] = OpTypeInt 32
; CHECK-SPIRV:                    [[ulong:%[a-z0-9_]+]] = OpTypeInt 64
; CHECK-SPIRV:                     [[void:%[a-z0-9_]+]] = OpTypeVoid
; CHECK-SPIRV:                [[_struct_9:%[a-z0-9_]+]] = OpTypeStruct [[uchar]] [[uchar]]
; CHECK-SPIRV:  [[_ptr_Function__struct_9:%[a-z0-9_]+]] = OpTypePointer Function [[_struct_9]]
; CHECK-SPIRV:               [[_struct_19:%[a-z0-9_]+]] = OpTypeStruct [[ushort]] [[ushort]]
; CHECK-SPIRV: [[_ptr_Function__struct_19:%[a-z0-9_]+]] = OpTypePointer Function [[_struct_19]]
; CHECK-SPIRV:               [[_struct_29:%[a-z0-9_]+]] = OpTypeStruct [[uint]] [[uint]]
; CHECK-SPIRV: [[_ptr_Function__struct_29:%[a-z0-9_]+]] = OpTypePointer Function [[_struct_29]]
; CHECK-SPIRV:               [[_struct_39:%[a-z0-9_]+]] = OpTypeStruct [[ulong]] [[ulong]]
; CHECK-SPIRV: [[_ptr_Function__struct_39:%[a-z0-9_]+]] = OpTypePointer Function [[_struct_39]]
; CHECK-SPIRV:                   [[v4uint:%[a-z0-9_]+]] = OpTypeVector [[uint]] 4
; CHECK-SPIRV:               [[_struct_49:%[a-z0-9_]+]] = OpTypeStruct [[v4uint]] [[v4uint]]
; CHECK-SPIRV: [[_ptr_Function__struct_49:%[a-z0-9_]+]] = OpTypePointer Function [[_struct_49]]

define spir_func void @test_builtin_iaddcarrycc(i8 %a, i8 %b) {
  entry:
  %0 = alloca {i8, i8}
  call void @_Z17__spirv_IAddCarrycc(ptr sret ({i8, i8}) %0, i8 %a, i8 %b)
  ret void
}
; CHECK-SPIRV:           [[a:%[a-z0-9_]+]] = OpFunctionParameter [[uchar]]
; CHECK-SPIRV:           [[b:%[a-z0-9_]+]] = OpFunctionParameter [[uchar]]
; CHECK-SPIRV:       [[entry:%[a-z0-9_]+]] = OpLabel
; CHECK-SPIRV:      [[var_11:%[a-z0-9_]+]] = OpVariable [[_ptr_Function__struct_9]] Function
; CHECK-SPIRV:      [[var_12:%[a-z0-9_]+]] = OpIAddCarry [[_struct_9]] [[a]] [[b]]
; CHECK-SPIRV:                               OpReturn
; CHECK-SPIRV:                               OpFunctionEnd

define spir_func void @test_builtin_iaddcarryss(i16 %a, i16 %b) {
  entry:
  %0 = alloca {i16, i16}
  call void @_Z17__spirv_IAddCarryss(ptr sret ({i16, i16}) %0, i16 %a, i16 %b)
  ret void
}
; CHECK-SPIRV:         [[a_0:%[a-z0-9_]+]] = OpFunctionParameter [[ushort]]
; CHECK-SPIRV:         [[b_0:%[a-z0-9_]+]] = OpFunctionParameter [[ushort]]
; CHECK-SPIRV:     [[entry_0:%[a-z0-9_]+]] = OpLabel
; CHECK-SPIRV:      [[var_21:%[a-z0-9_]+]] = OpVariable [[_ptr_Function__struct_19]] Function
; CHECK-SPIRV:      [[var_22:%[a-z0-9_]+]] = OpIAddCarry [[_struct_19]] [[a_0]] [[b_0]]
; CHECK-SPIRV:                               OpReturn
; CHECK-SPIRV:                               OpFunctionEnd

define spir_func void @test_builtin_iaddcarryii(i32 %a, i32 %b) {
  entry:
  %0 = alloca {i32, i32}
  call void @_Z17__spirv_IAddCarryii(ptr sret ({i32, i32}) %0, i32 %a, i32 %b)
  ret void
}
; CHECK-SPIRV:         [[a_1:%[a-z0-9_]+]] = OpFunctionParameter [[uint]]
; CHECK-SPIRV:         [[b_1:%[a-z0-9_]+]] = OpFunctionParameter [[uint]]
; CHECK-SPIRV:     [[entry_1:%[a-z0-9_]+]] = OpLabel
; CHECK-SPIRV:      [[var_31:%[a-z0-9_]+]] = OpVariable [[_ptr_Function__struct_29]] Function
; CHECK-SPIRV:      [[var_32:%[a-z0-9_]+]] = OpIAddCarry [[_struct_29]] [[a_1]] [[b_1]]
; CHECK-SPIRV:                               OpReturn
; CHECK-SPIRV:                               OpFunctionEnd

define spir_func void @test_builtin_iaddcarryll(i64 %a, i64 %b) {
  entry:
  %0 = alloca {i64, i64}
  call void @_Z17__spirv_IAddCarryll(ptr sret ({i64, i64}) %0, i64 %a, i64 %b)
  ret void
}
; CHECK-SPIRV:         [[a_2:%[a-z0-9_]+]] = OpFunctionParameter [[ulong]]
; CHECK-SPIRV:         [[b_2:%[a-z0-9_]+]] = OpFunctionParameter [[ulong]]
; CHECK-SPIRV:     [[entry_2:%[a-z0-9_]+]] = OpLabel
; CHECK-SPIRV:      [[var_41:%[a-z0-9_]+]] = OpVariable [[_ptr_Function__struct_39]] Function
; CHECK-SPIRV:      [[var_42:%[a-z0-9_]+]] = OpIAddCarry [[_struct_39]] [[a_2]] [[b_2]]
; CHECK-SPIRV:                               OpReturn
; CHECK-SPIRV:                               OpFunctionEnd

define spir_func void @test_builtin_iaddcarryDv4_xS_(<4 x i32> %a, <4 x i32> %b) {
  entry:
  %0 = alloca {<4 x i32>, <4 x i32>}
  call void @_Z17__spirv_IAddCarryDv4_iS_(ptr sret ({<4 x i32>, <4 x i32>}) %0, <4 x i32> %a, <4 x i32> %b)
  ret void
}
; CHECK-SPIRV:         [[a_3:%[a-z0-9_]+]] = OpFunctionParameter [[v4uint]]
; CHECK-SPIRV:         [[b_3:%[a-z0-9_]+]] = OpFunctionParameter [[v4uint]]
; CHECK-SPIRV:     [[entry_3:%[a-z0-9_]+]] = OpLabel
; CHECK-SPIRV:      [[var_51:%[a-z0-9_]+]] = OpVariable [[_ptr_Function__struct_49]] Function
; CHECK-SPIRV:      [[var_52:%[a-z0-9_]+]] = OpIAddCarry [[_struct_49]] [[a_3]] [[b_3]]
; CHECK-SPIRV:                               OpReturn
; CHECK-SPIRV:                               OpFunctionEnd

declare void @_Z17__spirv_IAddCarrycc(ptr sret({i8, i8}), i8, i8)
declare void @_Z17__spirv_IAddCarryss(ptr sret({i16, i16}), i16, i16)
declare void @_Z17__spirv_IAddCarryii(ptr sret({i32, i32}), i32, i32)
declare void @_Z17__spirv_IAddCarryll(ptr sret({i64, i64}), i64, i64)
declare void @_Z17__spirv_IAddCarryDv4_iS_(ptr sret ({<4 x i32>, <4 x i32>}), <4 x i32>, <4 x i32>)

