; REQUIRES: spirv-dis
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-dis --raw-id %t.spv | FileCheck --check-prefix CHECK-SPIRV %s
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r -o %t.rev.bc %t.spv
; RUN: llvm-dis -o - %t.rev.bc | FileCheck --check-prefix CHECK-LLVM %s

; SPIR-V has OpISubBorrow for the unsigned case only, so the signed case is
; the difference plus the sign comparison that detects the overflow:
; a subtraction overflows when the operands have different signs and the
; result does not have the sign of the minuend.

target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG:  [[uint:%[a-z0-9_]+]] = OpTypeInt 32 0
; CHECK-SPIRV-DAG:  [[uint_0:%[a-z0-9_]+]] = OpConstant [[uint]] 0
; CHECK-SPIRV-DAG:  [[bool:%[a-z0-9_]+]] = OpTypeBool
; CHECK-SPIRV-DAG:  [[struct:%[a-z0-9_]+]] = OpTypeStruct [[uint]] [[bool]]
; CHECK-SPIRV-DAG:  [[v4uint:%[a-z0-9_]+]] = OpTypeVector [[uint]] 4
; CHECK-SPIRV-DAG:  [[v4bool:%[a-z0-9_]+]] = OpTypeVector [[bool]] 4
; CHECK-SPIRV-DAG:  [[vstruct:%[a-z0-9_]+]] = OpTypeStruct [[v4uint]] [[v4bool]]
; CHECK-SPIRV-DAG:  [[v4uint_0:%[a-z0-9_]+]] = OpConstantNull [[v4uint]]

define spir_func i32 @ssub_i32(i32 %a, i32 %b) {
entry:
  %res = call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 %a, i32 %b)
  %val = extractvalue { i32, i1 } %res, 0
  %ovf = extractvalue { i32, i1 } %res, 1
  %sel = select i1 %ovf, i32 0, i32 %val
  ret i32 %sel
}

; CHECK-SPIRV:  [[a:%[a-z0-9_]+]] = OpFunctionParameter [[uint]]
; CHECK-SPIRV:  [[b:%[a-z0-9_]+]] = OpFunctionParameter [[uint]]
; CHECK-SPIRV:  [[diff:%[a-z0-9_]+]] = OpISub [[uint]] [[a]] [[b]]
; CHECK-SPIRV:  [[x1:%[a-z0-9_]+]] = OpBitwiseXor [[uint]] [[a]] [[b]]
; CHECK-SPIRV:  [[x2:%[a-z0-9_]+]] = OpBitwiseXor [[uint]] [[a]] [[diff]]
; CHECK-SPIRV:  [[and:%[a-z0-9_]+]] = OpBitwiseAnd [[uint]] [[x1]] [[x2]]
; CHECK-SPIRV:  [[ovf:%[a-z0-9_]+]] = OpSLessThan [[bool]] [[and]] [[uint_0]]
; CHECK-SPIRV:  {{%[a-z0-9_]+}} = OpCompositeConstruct [[struct]] [[diff]] [[ovf]]

; CHECK-LLVM-LABEL: define spir_func i32 @ssub_i32
; CHECK-LLVM:  [[LDIFF:%[0-9]+]] = sub i32 %a, %b
; CHECK-LLVM:  [[LX1:%[0-9]+]] = xor i32 %a, %b
; CHECK-LLVM:  [[LX2:%[0-9]+]] = xor i32 %a, [[LDIFF]]
; CHECK-LLVM:  [[LAND:%[0-9]+]] = and i32 [[LX1]], [[LX2]]
; CHECK-LLVM:  {{%[0-9]+}} = icmp slt i32 [[LAND]], 0

define spir_func <4 x i32> @ssub_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %res = call { <4 x i32>, <4 x i1> } @llvm.ssub.with.overflow.v4i32(<4 x i32> %a, <4 x i32> %b)
  %val = extractvalue { <4 x i32>, <4 x i1> } %res, 0
  ret <4 x i32> %val
}

; CHECK-SPIRV:  [[va:%[a-z0-9_]+]] = OpFunctionParameter [[v4uint]]
; CHECK-SPIRV:  [[vb:%[a-z0-9_]+]] = OpFunctionParameter [[v4uint]]
; CHECK-SPIRV:  [[vdiff:%[a-z0-9_]+]] = OpISub [[v4uint]] [[va]] [[vb]]
; CHECK-SPIRV:  [[vx1:%[a-z0-9_]+]] = OpBitwiseXor [[v4uint]] [[va]] [[vb]]
; CHECK-SPIRV:  [[vx2:%[a-z0-9_]+]] = OpBitwiseXor [[v4uint]] [[va]] [[vdiff]]
; CHECK-SPIRV:  [[vand:%[a-z0-9_]+]] = OpBitwiseAnd [[v4uint]] [[vx1]] [[vx2]]
; CHECK-SPIRV:  [[vovf:%[a-z0-9_]+]] = OpSLessThan [[v4bool]] [[vand]] [[v4uint_0]]
; CHECK-SPIRV:  {{%[a-z0-9_]+}} = OpCompositeConstruct [[vstruct]] [[vdiff]] [[vovf]]

; CHECK-LLVM-LABEL: define spir_func <4 x i32> @ssub_v4i32
; CHECK-LLVM:  [[VDIFF:%[0-9]+]] = sub <4 x i32> %a, %b
; CHECK-LLVM:  [[VX1:%[0-9]+]] = xor <4 x i32> %a, %b
; CHECK-LLVM:  [[VX2:%[0-9]+]] = xor <4 x i32> %a, [[VDIFF]]
; CHECK-LLVM:  [[VAND:%[0-9]+]] = and <4 x i32> [[VX1]], [[VX2]]
; CHECK-LLVM:  {{%[0-9]+}} = icmp slt <4 x i32> [[VAND]], zeroinitializer

declare { i32, i1 } @llvm.ssub.with.overflow.i32(i32, i32)
declare { <4 x i32>, <4 x i1> } @llvm.ssub.with.overflow.v4i32(<4 x i32>, <4 x i32>)
