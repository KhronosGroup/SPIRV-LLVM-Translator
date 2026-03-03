; This test checks if Int4 packed conversions specified by
; __builtin_spirv_* external function calls are translated correctly.
; All conversion instructions are covered; packing container variety
; (i8/i16/i32/i64/<N x i8>) is exercised for the Int4<->E4M3 pair only,
; the remaining instructions are tested with the 32-bit (i32) container.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_EXT_float8,+SPV_INTEL_int4,+SPV_KHR_bfloat16
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spv -o %t.rev.bc -r --spirv-target-env=SPV-IR
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; TODO: RUNx: spirv-val

; CHECK-SPIRV-DAG: Capability Float8EXT
; CHECK-SPIRV-DAG: Capability Int4TypeINTEL
; CHECK-SPIRV-DAG: Capability BFloat16TypeKHR
; CHECK-SPIRV-DAG: Extension "SPV_EXT_float8"
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_int4"
; CHECK-SPIRV-DAG: Extension "SPV_KHR_bfloat16"

; CHECK-SPIRV-DAG: Name [[#int4_e4m3_32:]] "int4_e4m3_32"
; CHECK-SPIRV-DAG: Name [[#int4_e4m3_16:]] "int4_e4m3_16"
; CHECK-SPIRV-DAG: Name [[#int4_e4m3_8:]] "int4_e4m3_8"
; CHECK-SPIRV-DAG: Name [[#int4_e4m3_v2xi8:]] "int4_e4m3_v2xi8"
; CHECK-SPIRV-DAG: Name [[#int4_e4m3_64:]] "int4_e4m3_64"
; CHECK-SPIRV-DAG: Name [[#int4_e5m2_32:]] "int4_e5m2_32"
; CHECK-SPIRV-DAG: Name [[#int4_hf16_32:]] "int4_hf16_32"
; CHECK-SPIRV-DAG: Name [[#int4_bf16_32:]] "int4_bf16_32"
; CHECK-SPIRV-DAG: Name [[#int4_int8_32:]] "int4_int8_32"
; CHECK-SPIRV-DAG: Name [[#hf16_int4_32:]] "hf16_int4_32"
; CHECK-SPIRV-DAG: Name [[#hf16_int4_8:]] "hf16_int4_8"
; CHECK-SPIRV-DAG: Name [[#bf16_int4_32:]] "bf16_int4_32"

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

; CHECK-SPIRV-DAG: TypeInt [[#Int4Ty:]] 4 0
; CHECK-SPIRV-DAG: TypeVector [[#Int4Vec16Ty:]] [[#Int4Ty]] 16
; CHECK-SPIRV-DAG: TypeVector [[#Int4Vec8Ty:]] [[#Int4Ty]] 8
; CHECK-SPIRV-DAG: TypeVector [[#Int4Vec4Ty:]] [[#Int4Ty]] 4
; CHECK-SPIRV-DAG: TypeVector [[#Int4Vec2Ty:]] [[#Int4Ty]] 2

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

; CHECK-SPIRV: Function [[#]] [[#int4_e4m3_32]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Vec8Ty]] [[#Cast1:]] [[#Int32Const]]
; CHECK-SPIRV: ConvertSToF [[#Float8E4M3Vec8Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec8Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: int4_e4m3_32
; CHECK-LLVM: %[[#Cast:]] = bitcast i32 1 to <8 x i4>
; CHECK-LLVM: %[[#Conv:]] = call <8 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELDv8_i(<8 x i4> %[[#Cast]])
; CHECK-LLVM: ret <8 x i8> %[[#Conv]]

; Function Attrs: nounwind readnone
define spir_func <8 x i8> @int4_e4m3_32() {
entry:
  %0 = call spir_func <8 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELi(i32 1)
  ret <8 x i8> %0
}

declare dso_local spir_func <8 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELi(i32)

; CHECK-SPIRV: Function [[#]] [[#hf16_int4_32]] [[#]]
; CHECK-SPIRV: ConvertFToS [[#Int4Vec8Ty]] [[#Conv:]] [[#HFloat16Vec8Const]]
; CHECK-SPIRV: Bitcast [[#Int32Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: hf16_int4_32
; CHECK-LLVM: %[[#Conv:]] = call <8 x i4> @_Z38__builtin_spirv_ConvertFP16ToInt4INTELDv8_Dh(<8 x half> splat (half 0xH3C00))
; CHECK-LLVM: %[[#Cast:]] = bitcast <8 x i4> %[[#Conv]] to i32
; CHECK-LLVM: ret i32 %[[#Cast]]

; Function Attrs: nounwind readnone
define spir_func i32 @hf16_int4_32() {
entry:
  %0 = call spir_func i32 @_Z38__builtin_spirv_ConvertFP16ToInt4INTELi(<8 x half> <half 1.0, half 1.0, half 1.0, half 1.0, half 1.0, half 1.0, half 1.0, half 1.0>)
  ret i32 %0
}

declare dso_local spir_func i32 @_Z38__builtin_spirv_ConvertFP16ToInt4INTELi(<8 x half>)

; Packed in 8-bit integer

; CHECK-SPIRV: Function [[#]] [[#int4_e4m3_8]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Vec2Ty]] [[#Cast1:]] [[#Int8Const]]
; CHECK-SPIRV: ConvertSToF [[#Float8E4M3Vec2Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec2Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: int4_e4m3_8
; CHECK-LLVM: %[[#Cast:]] = bitcast i8 1 to <2 x i4>
; CHECK-LLVM: %[[#Conv:]] = call <2 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELDv2_i(<2 x i4> %[[#Cast]])
; CHECK-LLVM: ret <2 x i8> %[[#Conv]]

; Function Attrs: nounwind readnone
define spir_func <2 x i8> @int4_e4m3_8() {
entry:
  %0 = call spir_func <2 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELc(i8 1)
  ret <2 x i8> %0
}

declare dso_local spir_func <2 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELc(i8)

; CHECK-SPIRV: Function [[#]] [[#hf16_int4_8]] [[#]]
; CHECK-SPIRV: ConvertFToS [[#Int4Vec2Ty]] [[#Conv:]] [[#HFloat16Vec2Const]]
; CHECK-SPIRV: Bitcast [[#Int8Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: hf16_int4_8
; CHECK-LLVM: %[[#Conv:]] = call <2 x i4> @_Z38__builtin_spirv_ConvertFP16ToInt4INTELDv2_Dh(<2 x half> splat (half 0xH3C00))
; CHECK-LLVM: %[[#Cast:]] = bitcast <2 x i4> %[[#Conv]] to i8
; CHECK-LLVM: ret i8 %[[#Cast]]

; Function Attrs: nounwind readnone
define spir_func i8 @hf16_int4_8() {
entry:
  %0 = call spir_func i8 @_Z38__builtin_spirv_ConvertFP16ToInt4INTELc(<2 x half> <half 1.0, half 1.0>)
  ret i8 %0
}

declare dso_local spir_func i8 @_Z38__builtin_spirv_ConvertFP16ToInt4INTELc(<2 x half>)

; Packed in 16-bit integer

; CHECK-SPIRV: Function [[#]] [[#int4_e4m3_16]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Vec4Ty]] [[#Cast1:]] [[#Int16Const]]
; CHECK-SPIRV: ConvertSToF [[#Float8E4M3Vec4Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec4Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: int4_e4m3_16
; CHECK-LLVM: %[[#Cast:]] = bitcast i16 1 to <4 x i4>
; CHECK-LLVM: %[[#Conv:]] = call <4 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELDv4_i(<4 x i4> %[[#Cast]])
; CHECK-LLVM: ret <4 x i8> %[[#Conv]]

define spir_func <4 x i8> @int4_e4m3_16() {
entry:
  %0 = call spir_func <4 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELs(i16 1)
  ret <4 x i8> %0
}

declare dso_local spir_func <4 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELs(i16)

; Packed in <2 x i8> vector

; CHECK-SPIRV: Function [[#]] [[#int4_e4m3_v2xi8]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Vec4Ty]] [[#Cast1:]] [[#Int8Vec2Const]]
; CHECK-SPIRV: ConvertSToF [[#Float8E4M3Vec4Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec4Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: int4_e4m3_v2xi8
; CHECK-LLVM: %[[#Cast:]] = bitcast <2 x i8> splat (i8 1) to <4 x i4>
; CHECK-LLVM: %[[#Conv:]] = call <4 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELDv4_i(<4 x i4> %[[#Cast]])
; CHECK-LLVM: ret <4 x i8> %[[#Conv]]

define spir_func <4 x i8> @int4_e4m3_v2xi8() {
entry:
  %0 = call spir_func <4 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELDv2_c(<2 x i8> <i8 1, i8 1>)
  ret <4 x i8> %0
}

declare dso_local spir_func <4 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELDv2_c(<2 x i8>)

; Packed in 64-bit integer

; CHECK-SPIRV: Function [[#]] [[#int4_e4m3_64]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Vec16Ty]] [[#Cast1:]] [[#Int64Const]]
; CHECK-SPIRV: ConvertSToF [[#Float8E4M3Vec16Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec16Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: int4_e4m3_64
; CHECK-LLVM: %[[#Cast:]] = bitcast i64 1 to <16 x i4>
; CHECK-LLVM: %[[#Conv:]] = call <16 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELDv16_i(<16 x i4> %[[#Cast]])
; CHECK-LLVM: ret <16 x i8> %[[#Conv]]

define spir_func <16 x i8> @int4_e4m3_64() {
entry:
  %0 = call spir_func <16 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELl(i64 1)
  ret <16 x i8> %0
}

declare dso_local spir_func <16 x i8> @_Z38__builtin_spirv_ConvertInt4ToE4M3INTELl(i64)

; Int4 to E5M2

; CHECK-SPIRV: Function [[#]] [[#int4_e5m2_32]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Vec8Ty]] [[#Cast1:]] [[#Int32Const]]
; CHECK-SPIRV: ConvertSToF [[#Float8E5M2Vec8Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: Bitcast [[#Int8Vec8Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: int4_e5m2_32
; CHECK-LLVM: %[[#Cast:]] = bitcast i32 1 to <8 x i4>
; CHECK-LLVM: %[[#Conv:]] = call <8 x i8> @_Z38__builtin_spirv_ConvertInt4ToE5M2INTELDv8_i(<8 x i4> %[[#Cast]])
; CHECK-LLVM: ret <8 x i8> %[[#Conv]]

define spir_func <8 x i8> @int4_e5m2_32() {
entry:
  %0 = call spir_func <8 x i8> @_Z38__builtin_spirv_ConvertInt4ToE5M2INTELi(i32 1)
  ret <8 x i8> %0
}

declare dso_local spir_func <8 x i8> @_Z38__builtin_spirv_ConvertInt4ToE5M2INTELi(i32)

; Int4 to FP16

; CHECK-SPIRV: Function [[#]] [[#int4_hf16_32]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Vec8Ty]] [[#Cast1:]] [[#Int32Const]]
; CHECK-SPIRV: ConvertSToF [[#HFloat16Vec8Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: int4_hf16_32
; CHECK-LLVM: %[[#Cast:]] = bitcast i32 1 to <8 x i4>
; CHECK-LLVM: %[[#Conv:]] = call <8 x half> @_Z38__builtin_spirv_ConvertInt4ToFP16INTELDv8_i(<8 x i4> %[[#Cast]])
; CHECK-LLVM: ret <8 x half> %[[#Conv]]

define spir_func <8 x half> @int4_hf16_32() {
entry:
  %0 = call spir_func <8 x half> @_Z38__builtin_spirv_ConvertInt4ToFP16INTELi(i32 1)
  ret <8 x half> %0
}

declare dso_local spir_func <8 x half> @_Z38__builtin_spirv_ConvertInt4ToFP16INTELi(i32)

; Int4 to BF16

; CHECK-SPIRV: Function [[#]] [[#int4_bf16_32]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Vec8Ty]] [[#Cast1:]] [[#Int32Const]]
; CHECK-SPIRV: ConvertSToF [[#BFloat16Vec8Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: int4_bf16_32
; CHECK-LLVM: %[[#Cast:]] = bitcast i32 1 to <8 x i4>
; CHECK-LLVM: %[[#Conv:]] = call <8 x bfloat> @_Z38__builtin_spirv_ConvertInt4ToBF16INTELDv8_i(<8 x i4> %[[#Cast]])
; CHECK-LLVM: ret <8 x bfloat> %[[#Conv]]

define spir_func <8 x bfloat> @int4_bf16_32() {
entry:
  %0 = call spir_func <8 x bfloat> @_Z38__builtin_spirv_ConvertInt4ToBF16INTELi(i32 1)
  ret <8 x bfloat> %0
}

declare dso_local spir_func <8 x bfloat> @_Z38__builtin_spirv_ConvertInt4ToBF16INTELi(i32)

; Int4 to Int8

; CHECK-SPIRV: Function [[#]] [[#int4_int8_32]] [[#]]
; CHECK-SPIRV: Bitcast [[#Int4Vec8Ty]] [[#Cast1:]] [[#Int32Const]]
; CHECK-SPIRV: SConvert [[#Int8Vec8Ty]] [[#Conv:]] [[#Cast1]]
; CHECK-SPIRV: ReturnValue [[#Conv]]

; CHECK-LLVM-LABEL: int4_int8_32
; CHECK-LLVM: %[[#Cast:]] = bitcast i32 1 to <8 x i4>
; CHECK-LLVM: %[[#Conv:]] = call <8 x i8> @_Z38__builtin_spirv_ConvertInt4ToInt8INTELDv8_i(<8 x i4> %[[#Cast]])
; CHECK-LLVM: ret <8 x i8> %[[#Conv]]

define spir_func <8 x i8> @int4_int8_32() {
entry:
  %0 = call spir_func <8 x i8> @_Z38__builtin_spirv_ConvertInt4ToInt8INTELi(i32 1)
  ret <8 x i8> %0
}

declare dso_local spir_func <8 x i8> @_Z38__builtin_spirv_ConvertInt4ToInt8INTELi(i32)

; BF16 to Int4

; CHECK-SPIRV: Function [[#]] [[#bf16_int4_32]] [[#]]
; CHECK-SPIRV: ConvertFToS [[#Int4Vec8Ty]] [[#Conv:]] [[#BFloat16Vec8Const]]
; CHECK-SPIRV: Bitcast [[#Int32Ty]] [[#Cast2:]] [[#Conv]]
; CHECK-SPIRV: ReturnValue [[#Cast2]]

; CHECK-LLVM-LABEL: bf16_int4_32
; CHECK-LLVM: %[[#Call:]] = call <8 x i4> @_Z38__builtin_spirv_ConvertBF16ToInt4INTELDv8_DF16b(<8 x bfloat> splat (bfloat 0xR3F80))
; CHECK-LLVM: %[[#Cast:]] = bitcast <8 x i4> %[[#Call]] to i32
; CHECK-LLVM: ret i32 %[[#Cast]]

define spir_func i32 @bf16_int4_32() {
entry:
  %0 = call i32 @_Z38__builtin_spirv_ConvertBF16ToInt4INTELDv8_DF16b(<8 x bfloat> <bfloat 1.0, bfloat 1.0, bfloat 1.0, bfloat 1.0, bfloat 1.0, bfloat 1.0, bfloat 1.0, bfloat 1.0>)
  ret i32 %0
}

declare dso_local spir_func i32 @_Z38__builtin_spirv_ConvertBF16ToInt4INTELDv8_DF16b(<8 x bfloat>)
