; REQUIRES: spirv-dis
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-dis --raw-id %t.spv | FileCheck --check-prefix CHECK-SPIRV %s
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r -o %t.rev.bc %t.spv
; RUN: llvm-dis -o - %t.rev.bc | FileCheck --check-prefix CHECK-LLVM %s

; The scalar overloads of llvm.sadd.with.overflow are replaced by the hand
; written helper functions in SPIRVLowerLLVMIntrinsic, which are keyed on the
; exact intrinsic name and therefore do not cover the vector overloads. Those
; are lowered to an OpIAdd plus the sign comparison that detects the overflow:
; an addition overflows when both operands share a sign that the result does
; not have.

target triple = "spir64-unknown-unknown"

; CHECK-SPIRV-DAG:  [[uint:%[a-z0-9_]+]] = OpTypeInt 32 0
; CHECK-SPIRV-DAG:  [[bool:%[a-z0-9_]+]] = OpTypeBool
; CHECK-SPIRV-DAG:  [[v4uint:%[a-z0-9_]+]] = OpTypeVector [[uint]] 4
; CHECK-SPIRV-DAG:  [[v4bool:%[a-z0-9_]+]] = OpTypeVector [[bool]] 4
; CHECK-SPIRV-DAG:  [[vstruct:%[a-z0-9_]+]] = OpTypeStruct [[v4uint]] [[v4bool]]
; CHECK-SPIRV-DAG:  [[v4uint_0:%[a-z0-9_]+]] = OpConstantNull [[v4uint]]

define spir_func <4 x i32> @sadd_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %res = call { <4 x i32>, <4 x i1> } @llvm.sadd.with.overflow.v4i32(<4 x i32> %a, <4 x i32> %b)
  %val = extractvalue { <4 x i32>, <4 x i1> } %res, 0
  %ovf = extractvalue { <4 x i32>, <4 x i1> } %res, 1
  %sel = select <4 x i1> %ovf, <4 x i32> zeroinitializer, <4 x i32> %val
  ret <4 x i32> %sel
}

; CHECK-SPIRV:  [[a:%[a-z0-9_]+]] = OpFunctionParameter [[v4uint]]
; CHECK-SPIRV:  [[b:%[a-z0-9_]+]] = OpFunctionParameter [[v4uint]]
; CHECK-SPIRV:  [[sum:%[a-z0-9_]+]] = OpIAdd [[v4uint]] [[a]] [[b]]
; CHECK-SPIRV:  [[x1:%[a-z0-9_]+]] = OpBitwiseXor [[v4uint]] [[a]] [[sum]]
; CHECK-SPIRV:  [[x2:%[a-z0-9_]+]] = OpBitwiseXor [[v4uint]] [[b]] [[sum]]
; CHECK-SPIRV:  [[and:%[a-z0-9_]+]] = OpBitwiseAnd [[v4uint]] [[x1]] [[x2]]
; CHECK-SPIRV:  [[ovf:%[a-z0-9_]+]] = OpSLessThan [[v4bool]] [[and]] [[v4uint_0]]
; CHECK-SPIRV:  {{%[a-z0-9_]+}} = OpCompositeConstruct [[vstruct]] [[sum]] [[ovf]]

; CHECK-LLVM-LABEL: define spir_func <4 x i32> @sadd_v4i32
; CHECK-LLVM:  [[SUM:%[0-9]+]] = add <4 x i32> %a, %b
; CHECK-LLVM:  [[X1:%[0-9]+]] = xor <4 x i32> %a, [[SUM]]
; CHECK-LLVM:  [[X2:%[0-9]+]] = xor <4 x i32> %b, [[SUM]]
; CHECK-LLVM:  [[AND:%[0-9]+]] = and <4 x i32> [[X1]], [[X2]]
; CHECK-LLVM:  {{%[0-9]+}} = icmp slt <4 x i32> [[AND]], zeroinitializer

declare { <4 x i32>, <4 x i1> } @llvm.sadd.with.overflow.v4i32(<4 x i32>, <4 x i32>)
