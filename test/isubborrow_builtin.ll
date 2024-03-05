; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-dis --raw-id %t.spv | FileCheck --check-prefix CHECK-SPIRV %s
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck --check-prefix CHECK-LLVM %s

target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG:                    [[uchar:%[a-z0-9_]+]] = OpTypeInt 8
; CHECK-SPIRV-DAG:                   [[ushort:%[a-z0-9_]+]] = OpTypeInt 16
; CHECK-SPIRV-DAG:                     [[uint:%[a-z0-9_]+]] = OpTypeInt 32
; CHECK-SPIRV-DAG:                    [[ulong:%[a-z0-9_]+]] = OpTypeInt 64
; CHECK-SPIRV-DAG:                     [[void:%[a-z0-9_]+]] = OpTypeVoid
; CHECK-SPIRV-DAG:                [[_struct_9:%[a-z0-9_]+]] = OpTypeStruct [[uchar]] [[uchar]]
; CHECK-SPIRV-DAG:  [[_ptr_Function__struct_9:%[a-z0-9_]+]] = OpTypePointer Function [[_struct_9]]
; CHECK-SPIRV-DAG:               [[_struct_19:%[a-z0-9_]+]] = OpTypeStruct [[ushort]] [[ushort]]
; CHECK-SPIRV-DAG: [[_ptr_Function__struct_19:%[a-z0-9_]+]] = OpTypePointer Function [[_struct_19]]
; CHECK-SPIRV-DAG:               [[_struct_29:%[a-z0-9_]+]] = OpTypeStruct [[uint]] [[uint]]
; CHECK-SPIRV-DAG: [[_ptr_Function__struct_29:%[a-z0-9_]+]] = OpTypePointer Function [[_struct_29]]
; CHECK-SPIRV-DAG:               [[_struct_39:%[a-z0-9_]+]] = OpTypeStruct [[ulong]] [[ulong]]
; CHECK-SPIRV-DAG: [[_ptr_Function__struct_39:%[a-z0-9_]+]] = OpTypePointer Function [[_struct_39]]
; CHECK-SPIRV-DAG:                   [[v4uint:%[a-z0-9_]+]] = OpTypeVector [[uint]] 4
; CHECK-SPIRV-DAG:               [[_struct_49:%[a-z0-9_]+]] = OpTypeStruct [[v4uint]] [[v4uint]]
; CHECK-SPIRV-DAG: [[_ptr_Function__struct_49:%[a-z0-9_]+]] = OpTypePointer Function [[_struct_49]]

; CHECK-LLVM-DAG: [[structtype:%[a-z0-9_.]+]] = type { i8, i8 }
; CHECK-LLVM-DAG: [[structtype_0:%[a-z0-9_.]+]] = type { i16, i16 }
; CHECK-LLVM-DAG: [[structtype_1:%[a-z0-9_.]+]] = type { i32, i32 }
; CHECK-LLVM-DAG: [[structtype_2:%[a-z0-9_.]+]] = type { i64, i64 }
; CHECK-LLVM-DAG: [[structtype_3:%[a-z0-9_.]+]] = type { <4 x i32>, <4 x i32> }

define spir_func void @test_builtin_isubborrowcc(i8 %a, i8 %b) {
  entry:
  %0 = alloca {i8, i8}
  call void @_Z18__spirv_ISubBorrowcc(ptr sret ({i8, i8}) %0, i8 %a, i8 %b)
  ret void
}
; CHECK-SPIRV:           [[a:%[a-z0-9_]+]] = OpFunctionParameter [[uchar]]
; CHECK-SPIRV:           [[b:%[a-z0-9_]+]] = OpFunctionParameter [[uchar]]
; CHECK-SPIRV:       [[entry:%[a-z0-9_]+]] = OpLabel
; CHECK-SPIRV:      [[var_11:%[a-z0-9_]+]] = OpVariable [[_ptr_Function__struct_9]] Function
; CHECK-SPIRV:      [[var_12:%[a-z0-9_]+]] = OpISubBorrow [[_struct_9]] [[a]] [[b]]
; CHECK-SPIRV:                               OpStore [[var_11]] [[var_12]]
; CHECK-SPIRV:                               OpReturn
; CHECK-SPIRV:                               OpFunctionEnd

; CHECK-LLVM:   %0 = alloca [[structtype]], align 8
; CHECK-LLVM:   call spir_func void @_Z18__spirv_ISubBorrowcc(ptr sret([[structtype]]) %0, i8 %a, i8 %b)
; CHECK-LLVM:   ret void

define spir_func void @test_builtin_isubborrowss(i16 %a, i16 %b) {
  entry:
  %0 = alloca {i16, i16}
  call void @_Z18__spirv_ISubBorrowss(ptr sret ({i16, i16}) %0, i16 %a, i16 %b)
  ret void
}
; CHECK-SPIRV:         [[a_0:%[a-z0-9_]+]] = OpFunctionParameter [[ushort]]
; CHECK-SPIRV:         [[b_0:%[a-z0-9_]+]] = OpFunctionParameter [[ushort]]
; CHECK-SPIRV:     [[entry_0:%[a-z0-9_]+]] = OpLabel
; CHECK-SPIRV:      [[var_21:%[a-z0-9_]+]] = OpVariable [[_ptr_Function__struct_19]] Function
; CHECK-SPIRV:      [[var_22:%[a-z0-9_]+]] = OpISubBorrow [[_struct_19]] [[a_0]] [[b_0]]
; CHECK-SPIRV:                               OpStore [[var_21]] [[var_22]]
; CHECK-SPIRV:                               OpReturn
; CHECK-SPIRV:                               OpFunctionEnd

; CHECK-LLVM:   %0 = alloca [[structtype_0]], align 8
; CHECK-LLVM:   call spir_func void @_Z18__spirv_ISubBorrowss(ptr sret([[structtype_0]]) %0, i16 %a, i16 %b)
; CHECK-LLVM:   ret void
define spir_func void @test_builtin_isubborrowii(i32 %a, i32 %b) {
  entry:
  %0 = alloca {i32, i32}
  call void @_Z18__spirv_ISubBorrowii(ptr sret ({i32, i32}) %0, i32 %a, i32 %b)
  ret void
}
; CHECK-SPIRV:         [[a_1:%[a-z0-9_]+]] = OpFunctionParameter [[uint]]
; CHECK-SPIRV:         [[b_1:%[a-z0-9_]+]] = OpFunctionParameter [[uint]]
; CHECK-SPIRV:     [[entry_1:%[a-z0-9_]+]] = OpLabel
; CHECK-SPIRV:      [[var_31:%[a-z0-9_]+]] = OpVariable [[_ptr_Function__struct_29]] Function
; CHECK-SPIRV:      [[var_32:%[a-z0-9_]+]] = OpISubBorrow [[_struct_29]] [[a_1]] [[b_1]]
; CHECK-SPIRV:                               OpStore [[var_31]] [[var_32]]
; CHECK-SPIRV:                               OpReturn
; CHECK-SPIRV:                               OpFunctionEnd

; CHECK-LLVM:   %0 = alloca [[structtype_1]], align 8
; CHECK-LLVM:   call spir_func void @_Z18__spirv_ISubBorrowii(ptr sret([[structtype_1]]) %0, i32 %a, i32 %b)
; CHECK-LLVM:   ret void
define spir_func void @test_builtin_isubborrowll(i64 %a, i64 %b) {
  entry:
  %0 = alloca {i64, i64}
  call void @_Z18__spirv_ISubBorrowll(ptr sret ({i64, i64}) %0, i64 %a, i64 %b)
  ret void
}
; CHECK-SPIRV:         [[a_2:%[a-z0-9_]+]] = OpFunctionParameter [[ulong]]
; CHECK-SPIRV:         [[b_2:%[a-z0-9_]+]] = OpFunctionParameter [[ulong]]
; CHECK-SPIRV:     [[entry_2:%[a-z0-9_]+]] = OpLabel
; CHECK-SPIRV:      [[var_41:%[a-z0-9_]+]] = OpVariable [[_ptr_Function__struct_39]] Function
; CHECK-SPIRV:      [[var_42:%[a-z0-9_]+]] = OpISubBorrow [[_struct_39]] [[a_2]] [[b_2]]
; CHECK-SPIRV:                               OpStore [[var_41]] [[var_42]]
; CHECK-SPIRV:                               OpReturn
; CHECK-SPIRV:                               OpFunctionEnd

; CHECK-LLVM:   %0 = alloca [[structtype_2]], align 8
; CHECK-LLVM:   call spir_func void @_Z18__spirv_ISubBorrowll(ptr sret([[structtype_2]]) %0, i64 %a, i64 %b)
; CHECK-LLVM:   ret void
define spir_func void @test_builtin_isubborrowDv4_xS_(<4 x i32> %a, <4 x i32> %b) {
  entry:
  %0 = alloca {<4 x i32>, <4 x i32>}
  call void @_Z18__spirv_ISubBorrowDv4_iS_(ptr sret ({<4 x i32>, <4 x i32>}) %0, <4 x i32> %a, <4 x i32> %b)
  ret void
}
; CHECK-SPIRV:         [[a_3:%[a-z0-9_]+]] = OpFunctionParameter [[v4uint]]
; CHECK-SPIRV:         [[b_3:%[a-z0-9_]+]] = OpFunctionParameter [[v4uint]]
; CHECK-SPIRV:     [[entry_3:%[a-z0-9_]+]] = OpLabel
; CHECK-SPIRV:      [[var_51:%[a-z0-9_]+]] = OpVariable [[_ptr_Function__struct_49]] Function
; CHECK-SPIRV:      [[var_52:%[a-z0-9_]+]] = OpISubBorrow [[_struct_49]] [[a_3]] [[b_3]]
; CHECK-SPIRV:                               OpStore [[var_51]] [[var_52]]
; CHECK-SPIRV:                               OpReturn
; CHECK-SPIRV:                               OpFunctionEnd

; CHECK-LLVM:   %0 = alloca [[structtype_3]], align 16
; CHECK-LLVM:   call spir_func void @_Z18__spirv_ISubBorrowDv4_iS_(ptr sret([[structtype_3]]) %0, <4 x i32> %a, <4 x i32> %b)
; CHECK-LLVM:   ret void
declare void @_Z18__spirv_ISubBorrowcc(ptr sret({i8, i8}), i8, i8)
declare void @_Z18__spirv_ISubBorrowss(ptr sret({i16, i16}), i16, i16)
declare void @_Z18__spirv_ISubBorrowii(ptr sret({i32, i32}), i32, i32)
declare void @_Z18__spirv_ISubBorrowll(ptr sret({i64, i64}), i64, i64)
declare void @_Z18__spirv_ISubBorrowDv4_iS_(ptr sret ({<4 x i32>, <4 x i32>}), <4 x i32>, <4 x i32>)

