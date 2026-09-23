; REQUIRES: spirv-dis
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-dis --raw-id %t.spv | FileCheck --check-prefix CHECK-SPIRV %s
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r -o %t.rev.bc %t.spv
; RUN: llvm-dis -o - %t.rev.bc | FileCheck --check-prefix CHECK-LLVM %s

; OpSMulExtended produces the low and the high half of the full width signed
; product. The product fits into the operand width exactly when the high half
; is the sign extension of the low half.

target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG:  [[uint:%[a-z0-9_]+]] = OpTypeInt 32 0
; CHECK-SPIRV-DAG:  [[uint_31:%[a-z0-9_]+]] = OpConstant [[uint]] 31
; CHECK-SPIRV-DAG:  [[bool:%[a-z0-9_]+]] = OpTypeBool
; CHECK-SPIRV-DAG:  [[ext:%[a-z0-9_]+]] = OpTypeStruct [[uint]] [[uint]]
; CHECK-SPIRV-DAG:  [[struct:%[a-z0-9_]+]] = OpTypeStruct [[uint]] [[bool]]
; CHECK-SPIRV-DAG:  [[v4uint:%[a-z0-9_]+]] = OpTypeVector [[uint]] 4
; CHECK-SPIRV-DAG:  [[v4bool:%[a-z0-9_]+]] = OpTypeVector [[bool]] 4
; CHECK-SPIRV-DAG:  [[vext:%[a-z0-9_]+]] = OpTypeStruct [[v4uint]] [[v4uint]]
; CHECK-SPIRV-DAG:  [[vstruct:%[a-z0-9_]+]] = OpTypeStruct [[v4uint]] [[v4bool]]
; CHECK-SPIRV-DAG:  [[v4uint_31:%[a-z0-9_]+]] = OpConstantComposite [[v4uint]] [[uint_31]] [[uint_31]] [[uint_31]] [[uint_31]]

define spir_func i32 @smul_i32(i32 %a, i32 %b) {
entry:
  %res = call { i32, i1 } @llvm.smul.with.overflow.i32(i32 %a, i32 %b)
  %val = extractvalue { i32, i1 } %res, 0
  %ovf = extractvalue { i32, i1 } %res, 1
  %sel = select i1 %ovf, i32 0, i32 %val
  ret i32 %sel
}

; CHECK-SPIRV:  [[a:%[a-z0-9_]+]] = OpFunctionParameter [[uint]]
; CHECK-SPIRV:  [[b:%[a-z0-9_]+]] = OpFunctionParameter [[uint]]
; CHECK-SPIRV:  [[mul:%[a-z0-9_]+]] = OpSMulExtended [[ext]] [[a]] [[b]]
; CHECK-SPIRV:  [[low:%[a-z0-9_]+]] = OpCompositeExtract [[uint]] [[mul]] 0
; CHECK-SPIRV:  [[high:%[a-z0-9_]+]] = OpCompositeExtract [[uint]] [[mul]] 1
; CHECK-SPIRV:  [[sign:%[a-z0-9_]+]] = OpShiftRightArithmetic [[uint]] [[low]] [[uint_31]]
; CHECK-SPIRV:  [[ovf:%[a-z0-9_]+]] = OpINotEqual [[bool]] [[high]] [[sign]]
; CHECK-SPIRV:  {{%[a-z0-9_]+}} = OpCompositeConstruct [[struct]] [[low]] [[ovf]]

; CHECK-LLVM-LABEL: define spir_func i32 @smul_i32
; CHECK-LLVM:  call spir_func void @_Z20__spirv_SMulExtendedii(ptr sret({{%[a-z0-9_.]+}}) [[EXT:%[0-9]+]], i32 %a, i32 %b)
; CHECK-LLVM:  [[PAIR:%[0-9]+]] = load {{%[a-z0-9_.]+}}, ptr [[EXT]]
; CHECK-LLVM:  [[LOW:%[0-9]+]] = extractvalue {{%[a-z0-9_.]+}} [[PAIR]], 0
; CHECK-LLVM:  [[HIGH:%[0-9]+]] = extractvalue {{%[a-z0-9_.]+}} [[PAIR]], 1
; CHECK-LLVM:  [[SIGN:%[0-9]+]] = ashr i32 [[LOW]], 31
; CHECK-LLVM:  {{%[0-9]+}} = icmp ne i32 [[HIGH]], [[SIGN]]

define spir_func <4 x i32> @smul_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %res = call { <4 x i32>, <4 x i1> } @llvm.smul.with.overflow.v4i32(<4 x i32> %a, <4 x i32> %b)
  %val = extractvalue { <4 x i32>, <4 x i1> } %res, 0
  ret <4 x i32> %val
}

; CHECK-SPIRV:  [[va:%[a-z0-9_]+]] = OpFunctionParameter [[v4uint]]
; CHECK-SPIRV:  [[vb:%[a-z0-9_]+]] = OpFunctionParameter [[v4uint]]
; CHECK-SPIRV:  [[vmul:%[a-z0-9_]+]] = OpSMulExtended [[vext]] [[va]] [[vb]]
; CHECK-SPIRV:  [[vlow:%[a-z0-9_]+]] = OpCompositeExtract [[v4uint]] [[vmul]] 0
; CHECK-SPIRV:  [[vhigh:%[a-z0-9_]+]] = OpCompositeExtract [[v4uint]] [[vmul]] 1
; CHECK-SPIRV:  [[vsign:%[a-z0-9_]+]] = OpShiftRightArithmetic [[v4uint]] [[vlow]] [[v4uint_31]]
; CHECK-SPIRV:  [[vovf:%[a-z0-9_]+]] = OpINotEqual [[v4bool]] [[vhigh]] [[vsign]]
; CHECK-SPIRV:  {{%[a-z0-9_]+}} = OpCompositeConstruct [[vstruct]] [[vlow]] [[vovf]]

; CHECK-LLVM-LABEL: define spir_func <4 x i32> @smul_v4i32
; CHECK-LLVM:  [[VSIGN:%[0-9]+]] = ashr <4 x i32> {{%[0-9]+}}, splat (i32 31)
; CHECK-LLVM:  {{%[0-9]+}} = icmp ne <4 x i32> {{%[0-9]+}}, [[VSIGN]]

declare { i32, i1 } @llvm.smul.with.overflow.i32(i32, i32)
declare { <4 x i32>, <4 x i1> } @llvm.smul.with.overflow.v4i32(<4 x i32>, <4 x i32>)
