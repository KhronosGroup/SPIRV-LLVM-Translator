; This tests checks if FP4 packed conversions specified by
; __builtin_spirv_* external function calls translated correctly.
; All conversion instructions are covered; packing container variety
; (i8/i16/i32/i64/<N x i8>) is exercised for the E2M1<->E4M3 pair only,
; the remaining instructions are tested with the 32-bit (i32) container.

; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_EXT_float8,+SPV_INTEL_float4,+SPV_KHR_bfloat16
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spv -o %t.rev.bc -r --spirv-target-env=SPV-IR
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: Capability Float8EXT
; CHECK-SPIRV-DAG: Capability Float4E2M1INTEL
; CHECK-SPIRV-DAG: Capability BFloat16TypeKHR
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_float4"
; CHECK-SPIRV-DAG: Extension "SPV_EXT_float8"
; CHECK-SPIRV-DAG: Extension "SPV_KHR_bfloat16"

; CHECK-SPIRV-DAG: Name [[#fp4e2m1_hf8_32:]] "fp4e2m1_hf8_32"
; CHECK-SPIRV-DAG: Name [[#fp4e2m1_hf8_16:]] "fp4e2m1_hf8_16"
; CHECK-SPIRV-DAG: Name [[#fp4e2m1_hf8_8:]] "fp4e2m1_hf8_8"
; CHECK-SPIRV-DAG: Name [[#fp4e2m1_hf8_v2xi8:]] "fp4e2m1_hf8_v2xi8"
; CHECK-SPIRV-DAG: Name [[#fp4e2m1_hf8_64:]] "fp4e2m1_hf8_64"
; CHECK-SPIRV-DAG: Name [[#fp4e2m1_bf8_32:]] "fp4e2m1_bf8_32"
; CHECK-SPIRV-DAG: Name [[#fp4e2m1_hf16_32:]] "fp4e2m1_hf16_32"
; CHECK-SPIRV-DAG: Name [[#fp4e2m1_bf16_32:]] "fp4e2m1_bf16_32"
; CHECK-SPIRV-DAG: Name [[#hf16_fp4e2m1_32:]] "hf16_fp4e2m1_32"
; CHECK-SPIRV-DAG: Name [[#hf16_fp4e2m1_8:]] "hf16_fp4e2m1_8"
; CHECK-SPIRV-DAG: Name [[#bf16_fp4e2m1_32:]] "bf16_fp4e2m1_32"

; CHECK-SPIRV-DAG: TypeInt [[#Int32Ty:]] 32 0
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Int32Const:]] 1

; CHECK-SPIRV-DAG: TypeInt [[#Int16Ty:]] 16 0
; CHECK-SPIRV-DAG: Constant [[#Int16Ty]] [[#Int16Const:]] 1

; CHECK-SPIRV-DAG: TypeInt [[#Int64Ty:]] 64 0
; CHECK-SPIRV-DAG: Constant [[#Int64Ty]] [[#Int64Const:]] 1

; CHECK-SPIRV-DAG: TypeInt [[#Int8Ty:]] 8 0
; CHECK-SPIRV-DAG: TypeVector [[#Int8Vec16Ty:]] [[#Int8Ty]] 16
; CHECK-SPIRV-DAG: TypeVector [[#Int8Vec8Ty:]] [[#Int8Ty]] 8
; CHECK-SPIRV-DAG: TypeVector [[#Int8Vec4Ty:]] [[#Int8Ty]] 4
; CHECK-SPIRV-DAG: TypeVector [[#Int8Vec2Ty:]] [[#Int8Ty]] 2
; CHECK-SPIRV-DAG: Constant [[#Int8Ty]] [[#Int8Const:]] 1
; CHECK-SPIRV-DAG: ConstantComposite [[#Int8Vec2Ty]] [[#Int8Vec2Const:]] [[#Int8Const]] [[#Int8Const]]

; CHECK-SPIRV-DAG: TypeFloat [[#E2M1Ty:]] 4 6214
; CHECK-SPIRV-DAG: TypeVector [[#E2M1Vec16Ty:]] [[#E2M1Ty]] 16
; CHECK-SPIRV-DAG: TypeVector [[#E2M1Vec8Ty:]] [[#E2M1Ty]] 8
; CHECK-SPIRV-DAG: TypeVector [[#E2M1Vec4Ty:]] [[#E2M1Ty]] 4
; CHECK-SPIRV-DAG: TypeVector [[#E2M1Vec2Ty:]] [[#E2M1Ty]] 2

; CHECK-SPIRV-DAG: TypeFloat [[#Float8E4M3Ty:]] 8 4214
; CHECK-SPIRV-DAG: TypeVector [[#Float8E4M3Vec16Ty:]] [[#Float8E4M3Ty]] 16
; CHECK-SPIRV-DAG: TypeVector [[#Float8E4M3Vec8Ty:]] [[#Float8E4M3Ty]] 8
; CHECK-SPIRV-DAG: TypeVector [[#Float8E4M3Vec4Ty:]] [[#Float8E4M3Ty]] 4
; CHECK-SPIRV-DAG: TypeVector [[#Float8E4M3Vec2Ty:]] [[#Float8E4M3Ty]] 2

; CHECK-SPIRV-DAG: TypeFloat [[#Float8E5M2Ty:]] 8 4215
; CHECK-SPIRV-DAG: TypeVector [[#Float8E5M2Vec8Ty:]] [[#Float8E5M2Ty]] 8

; CHECK-SPIRV-DAG: TypeFloat [[#HFloat16Ty:]] 16 {{$}}
; CHECK-SPIRV-DAG: TypeVector [[#HFloat16Vec8Ty:]] [[#HFloat16Ty]] 8
; CHECK-SPIRV-DAG: TypeVector [[#HFloat16Vec2Ty:]] [[#HFloat16Ty]] 2
; CHECK-SPIRV-DAG: Constant [[#HFloat16Ty]] [[#HFloat16Const:]] 15360
; CHECK-SPIRV-DAG: ConstantComposite [[#HFloat16Vec8Ty]] [[#HFloat16Vec8Const:]] [[#HFloat16Const]] [[#HFloat16Const]] [[#HFloat16Const]] [[#HFloat16Const]] [[#HFloat16Const]] [[#HFloat16Const]] [[#HFloat16Const]] [[#HFloat16Const]]
; CHECK-SPIRV-DAG: ConstantComposite [[#HFloat16Vec2Ty]] [[#HFloat16Vec2Const:]] [[#HFloat16Const]] [[#HFloat16Const]]

; CHECK-SPIRV-DAG: TypeFloat [[#BFloat16Ty:]] 16 0
; CHECK-SPIRV-DAG: TypeVector [[#BFloat16Vec8Ty:]] [[#BFloat16Ty]] 8
; CHECK-SPIRV-DAG: Constant [[#BFloat16Ty]] [[#BFloat16Const:]] 16256
; CHECK-SPIRV-DAG: ConstantComposite [[#BFloat16Vec8Ty]] [[#BFloat16Vec8Const:]] [[#BFloat16Const]] [[#BFloat16Const]] [[#BFloat16Const]] [[#BFloat16Const]] [[#BFloat16Const]] [[#BFloat16Const]] [[#BFloat16Const]] [[#BFloat16Const]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Packed in 32-bit integer

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_hf8_32]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Vec8Ty]] [[#Cast1:]] [[#Int32Const]]
; CHECK-SPIRV: FConvert [[#Float8E4M3Vec8Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec8Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: fp4e2m1_hf8_32
; CHECK-LLVM: %[[#Cast:]] = bitcast i32 1 to <8 x i4>
; CHECK-LLVM: %[[#Call:]] = call <8 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELDv8_i(<8 x i4> %[[#Cast]])
; CHECK-LLVM: ret <8 x i8> %[[#Call]]

define spir_func <8 x i8> @fp4e2m1_hf8_32() {
entry:
  %0 = call spir_func <8 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELi(i32 1)
  ret <8 x i8> %0
}

declare dso_local spir_func <8 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELi(i32)

; CHECK-SPIRV: Function [[#]] [[#hf16_fp4e2m1_32]] [[#]]
; CHECK-SPIRV: FConvert [[#E2M1Vec8Ty]] [[#Conv:]] [[#HFloat16Vec8Const]]
; CHECK-SPIRV: Bitcast [[#Int32Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: hf16_fp4e2m1_32
; CHECK-LLVM: %[[#Call:]] = call <8 x i4> @_Z38__builtin_spirv_ConvertFP16ToE2M1INTELDv8_Dh(<8 x half> splat (half 0xH3C00))
; CHECK-LLVM: %[[#Cast:]] = bitcast <8 x i4> %[[#Call]] to i32
; CHECK-LLVM: ret i32 %[[#Cast]]

define spir_func i32 @hf16_fp4e2m1_32() {
entry:
  %0 = call i32 @_Z38__builtin_spirv_ConvertFP16ToE2M1INTELDv8_Dh(<8 x half> <half 1.0, half 1.0, half 1.0, half 1.0, half 1.0, half 1.0, half 1.0, half 1.0>)
  ret i32 %0
}

declare dso_local spir_func i32 @_Z38__builtin_spirv_ConvertFP16ToE2M1INTELDv8_Dh(<8 x half>)

; Packed in 8-bit integer

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_hf8_8]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Vec2Ty]] [[#Cast1:]] [[#Int8Const]]
; CHECK-SPIRV: FConvert [[#Float8E4M3Vec2Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec2Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: fp4e2m1_hf8_8
; CHECK-LLVM: %[[#Cast:]] = bitcast i8 1 to <2 x i4>
; CHECK-LLVM: %[[#Call:]] = call <2 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELDv2_i(<2 x i4> %[[#Cast]])
; CHECK-LLVM: ret <2 x i8> %[[#Call]]

define spir_func <2 x i8> @fp4e2m1_hf8_8() {
entry:
  %0 = call spir_func <2 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELc(i8 1)
  ret <2 x i8> %0
}

declare dso_local spir_func <2 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELc(i8)

; CHECK-SPIRV: Function [[#]] [[#hf16_fp4e2m1_8]] [[#]]
; CHECK-SPIRV: FConvert [[#E2M1Vec2Ty]] [[#Conv:]] [[#HFloat16Vec2Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: hf16_fp4e2m1_8
; CHECK-LLVM: %[[#Call:]] = call <2 x i4> @_Z38__builtin_spirv_ConvertFP16ToE2M1INTELDv2_Dh(<2 x half> splat (half 0xH3C00))
; CHECK-LLVM: %[[#Cast:]] = bitcast <2 x i4> %[[#Call]] to i8
; CHECK-LLVM: ret i8 %[[#Cast]]

define spir_func i8 @hf16_fp4e2m1_8() {
entry:
  %0 = call i8 @_Z38__builtin_spirv_ConvertFP16ToE2M1INTELDv2_Dh(<2 x half> <half 1.0, half 1.0>)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z38__builtin_spirv_ConvertFP16ToE2M1INTELDv2_Dh(<2 x half>)

; Packed in 16-bit integer

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_hf8_16]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Vec4Ty]] [[#Cast1:]] [[#Int16Const]]
; CHECK-SPIRV: FConvert [[#Float8E4M3Vec4Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec4Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: fp4e2m1_hf8_16
; CHECK-LLVM: %[[#Cast:]] = bitcast i16 1 to <4 x i4>
; CHECK-LLVM: %[[#Call:]] = call <4 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELDv4_i(<4 x i4> %[[#Cast]])
; CHECK-LLVM: ret <4 x i8> %[[#Call]]

define spir_func <4 x i8> @fp4e2m1_hf8_16() {
entry:
  %0 = call spir_func <4 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELs(i16 1)
  ret <4 x i8> %0
}

declare dso_local spir_func <4 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELs(i16)

; Packed in <2 x i8> vector

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_hf8_v2xi8]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Vec4Ty]] [[#Cast1:]] [[#Int8Vec2Const]]
; CHECK-SPIRV: FConvert [[#Float8E4M3Vec4Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec4Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: fp4e2m1_hf8_v2xi8
; CHECK-LLVM: %[[#Cast:]] = bitcast <2 x i8> splat (i8 1) to <4 x i4>
; CHECK-LLVM: %[[#Call:]] = call <4 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELDv4_i(<4 x i4> %[[#Cast]])
; CHECK-LLVM: ret <4 x i8> %[[#Call]]

define spir_func <4 x i8> @fp4e2m1_hf8_v2xi8() {
entry:
  %0 = call spir_func <4 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELDv2_c(<2 x i8> <i8 1, i8 1>)
  ret <4 x i8> %0
}

declare dso_local spir_func <4 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELDv2_c(<2 x i8>)

; Packed in 64-bit integer

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_hf8_64]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Vec16Ty]] [[#Cast1:]] [[#Int64Const]]
; CHECK-SPIRV: FConvert [[#Float8E4M3Vec16Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec16Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: fp4e2m1_hf8_64
; CHECK-LLVM: %[[#Cast:]] = bitcast i64 1 to <16 x i4>
; CHECK-LLVM: %[[#Call:]] = call <16 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELDv16_i(<16 x i4> %[[#Cast]])
; CHECK-LLVM: ret <16 x i8> %[[#Call]]

define spir_func <16 x i8> @fp4e2m1_hf8_64() {
entry:
  %0 = call spir_func <16 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELl(i64 1)
  ret <16 x i8> %0
}

declare dso_local spir_func <16 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE4M3INTELl(i64)

; E2M1 to E5M2

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_bf8_32]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Vec8Ty]] [[#Cast1:]] [[#Int32Const]]
; CHECK-SPIRV: FConvert [[#Float8E5M2Vec8Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec8Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: fp4e2m1_bf8_32
; CHECK-LLVM: %[[#Cast:]] = bitcast i32 1 to <8 x i4>
; CHECK-LLVM: %[[#Call:]] = call <8 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE5M2INTELDv8_i(<8 x i4> %[[#Cast]])
; CHECK-LLVM: ret <8 x i8> %[[#Call]]

define spir_func <8 x i8> @fp4e2m1_bf8_32() {
entry:
  %0 = call spir_func <8 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE5M2INTELi(i32 1)
  ret <8 x i8> %0
}

declare dso_local spir_func <8 x i8> @_Z38__builtin_spirv_ConvertE2M1ToE5M2INTELi(i32)

; E2M1 to FP16

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_hf16_32]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Vec8Ty]] [[#Cast1:]] [[#Int32Const]]
; CHECK-SPIRV: FConvert [[#HFloat16Vec8Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: fp4e2m1_hf16_32
; CHECK-LLVM: %[[#Cast:]] = bitcast i32 1 to <8 x i4>
; CHECK-LLVM: %[[#Call:]] = call <8 x half> @_Z38__builtin_spirv_ConvertE2M1ToFP16INTELDv8_i(<8 x i4> %[[#Cast]])
; CHECK-LLVM: ret <8 x half> %[[#Call]]

define spir_func <8 x half> @fp4e2m1_hf16_32() {
entry:
  %0 = call spir_func <8 x half> @_Z38__builtin_spirv_ConvertE2M1ToFP16INTELi(i32 1)
  ret <8 x half> %0
}

declare dso_local spir_func <8 x half> @_Z38__builtin_spirv_ConvertE2M1ToFP16INTELi(i32)

; E2M1 to BF16

; CHECK-SPIRV: Function [[#]] [[#fp4e2m1_bf16_32]] [[#]]
; CHECK-SPIRV: Bitcast [[#E2M1Vec8Ty]] [[#Cast1:]] [[#Int32Const]]
; CHECK-SPIRV: FConvert [[#BFloat16Vec8Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: fp4e2m1_bf16_32
; CHECK-LLVM: %[[#Cast:]] = bitcast i32 1 to <8 x i4>
; CHECK-LLVM: %[[#Call:]] = call <8 x bfloat> @_Z38__builtin_spirv_ConvertE2M1ToBF16INTELDv8_i(<8 x i4> %[[#Cast]])
; CHECK-LLVM: ret <8 x bfloat> %[[#Call]]

define spir_func <8 x bfloat> @fp4e2m1_bf16_32() {
entry:
  %0 = call spir_func <8 x bfloat> @_Z38__builtin_spirv_ConvertE2M1ToBF16INTELi(i32 1)
  ret <8 x bfloat> %0
}

declare dso_local spir_func <8 x bfloat> @_Z38__builtin_spirv_ConvertE2M1ToBF16INTELi(i32)

; BF16 to E2M1

; CHECK-SPIRV: Function [[#]] [[#bf16_fp4e2m1_32]] [[#]]
; CHECK-SPIRV: FConvert [[#E2M1Vec8Ty]] [[#Conv:]] [[#BFloat16Vec8Const]]
; CHECK-SPIRV: Bitcast [[#Int32Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: bf16_fp4e2m1_32
; CHECK-LLVM: %[[#Call:]] = call <8 x i4> @_Z38__builtin_spirv_ConvertBF16ToE2M1INTELDv8_DF16b(<8 x bfloat> splat (bfloat 0xR3F80))
; CHECK-LLVM: %[[#Cast:]] = bitcast <8 x i4> %[[#Call]] to i32
; CHECK-LLVM: ret i32 %[[#Cast]]

define spir_func i32 @bf16_fp4e2m1_32() {
entry:
  %0 = call i32 @_Z38__builtin_spirv_ConvertBF16ToE2M1INTELDv8_DF16b(<8 x bfloat> <bfloat 1.0, bfloat 1.0, bfloat 1.0, bfloat 1.0, bfloat 1.0, bfloat 1.0, bfloat 1.0, bfloat 1.0>)
  ret i32 %0
}

declare dso_local spir_func i32 @_Z38__builtin_spirv_ConvertBF16ToE2M1INTELDv8_DF16b(<8 x bfloat>)
