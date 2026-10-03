; llvm.minimum/llvm.maximum return NaN if either operand is NaN and order -0.0
; before +0.0. OpenCL.std fmin/fmax instead return the non-NaN operand and may
; return either zero, so the translator adds the missing fix-ups around them,
; skipping the ones made unnecessary by the nnan/nsz fast-math flags.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; The declarations precede their uses, so they are still used when visited by
; SPIRVRegularizeLLVM. Make sure they don't end up as imported functions.
; RUN: llvm-spirv %t.bc -spirv-allow-unknown-intrinsics -spirv-text -o - \
; RUN:   | FileCheck %s --check-prefix=CHECK-SPIRV \
; RUN:     --implicit-check-not=llvm.minimum --implicit-check-not=llvm.maximum

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

declare float @llvm.minimum.f32(float, float)
declare float @llvm.maximum.f32(float, float)
declare half @llvm.minimum.f16(half, half)
declare double @llvm.maximum.f64(double, double)
declare <4 x float> @llvm.minimum.v4f32(<4 x float>, <4 x float>)
declare <2 x double> @llvm.maximum.v2f64(<2 x double>, <2 x double>)
declare <2 x half> @llvm.minimum.v2f16(<2 x half>, <2 x half>)
declare <2 x half> @llvm.maximum.v2f16(<2 x half>, <2 x half>)

; CHECK-SPIRV-DAG: TypeBool [[#Bool:]]
; CHECK-SPIRV-DAG: TypeFloat [[#Half:]] 16
; CHECK-SPIRV-DAG: TypeFloat [[#Float:]] 32
; CHECK-SPIRV-DAG: TypeFloat [[#Double:]] 64
; CHECK-SPIRV-DAG: TypeVector [[#Bool2:]] [[#Bool]] 2
; CHECK-SPIRV-DAG: TypeVector [[#Bool4:]] [[#Bool]] 4
; CHECK-SPIRV-DAG: TypeVector [[#Half2:]] [[#Half]] 2
; CHECK-SPIRV-DAG: TypeVector [[#Float4:]] [[#Float]] 4
; CHECK-SPIRV-DAG: TypeVector [[#Double2:]] [[#Double]] 2
; CHECK-SPIRV-DAG: Constant [[#Half]] [[#HalfOne:]] 15360
; CHECK-SPIRV-DAG: Constant [[#Half]] [[#HalfZero:]] 0{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Half]] [[#HalfNaN:]] 32256
; CHECK-SPIRV-DAG: Constant [[#Float]] [[#FloatOne:]] 1065353216
; CHECK-SPIRV-DAG: Constant [[#Float]] [[#FloatZero:]] 0{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Float]] [[#FloatNaN:]] 2143289344
; CHECK-SPIRV-DAG: Constant [[#Double]] [[#DoubleOne:]] 0 1072693248
; CHECK-SPIRV-DAG: Constant [[#Double]] [[#DoubleZero:]] 0 0{{ *$}}
; CHECK-SPIRV-DAG: Constant [[#Double]] [[#DoubleNaN:]] 0 2146959360
; CHECK-SPIRV-DAG: ConstantComposite [[#Half2]] [[#Half2One:]] [[#HalfOne]] [[#HalfOne]]
; CHECK-SPIRV-DAG: ConstantNull [[#Half2]] [[#Half2Zero:]]
; CHECK-SPIRV-DAG: ConstantComposite [[#Half2]] [[#Half2NaN:]] [[#HalfNaN]] [[#HalfNaN]]
; CHECK-SPIRV-DAG: ConstantComposite [[#Float4]] [[#Float4One:]] [[#FloatOne]] [[#FloatOne]] [[#FloatOne]] [[#FloatOne]]
; CHECK-SPIRV-DAG: ConstantNull [[#Float4]] [[#Float4Zero:]]
; CHECK-SPIRV-DAG: ConstantComposite [[#Float4]] [[#Float4NaN:]] [[#FloatNaN]] [[#FloatNaN]] [[#FloatNaN]] [[#FloatNaN]]
; CHECK-SPIRV-DAG: ConstantComposite [[#Double2]] [[#Double2One:]] [[#DoubleOne]] [[#DoubleOne]]
; CHECK-SPIRV-DAG: ConstantNull [[#Double2]] [[#Double2Zero:]]
; CHECK-SPIRV-DAG: ConstantComposite [[#Double2]] [[#Double2NaN:]] [[#DoubleNaN]] [[#DoubleNaN]]

; CHECK-SPIRV: Function [[#Float]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Float]] [[#M:]] [[#]] fmin [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: FOrdEqual [[#Bool]] [[#Eq:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: ExtInst [[#Float]] [[#XSign:]] [[#]] copysign [[#FloatOne]] [[#X]]
; CHECK-SPIRV-NEXT: FOrdLessThan [[#Bool]] [[#XNeg:]] [[#XSign]] [[#FloatZero]]
; CHECK-SPIRV-NEXT: Select [[#Float]] [[#Zero:]] [[#XNeg]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Float]] [[#MZero:]] [[#Eq]] [[#Zero]] [[#M]]
; CHECK-SPIRV-NEXT: Unordered [[#Bool]] [[#Uno:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Float]] [[#Res:]] [[#Uno]] [[#FloatNaN]] [[#MZero]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]

; CHECK-LLVM-LABEL: define spir_func float @minimum_f32(
; CHECK-LLVM-NEXT: %[[M:[0-9]+]] = call spir_func float @_Z4fminff(float %x, float %y)
; CHECK-LLVM-NEXT: %[[EQ:[0-9]+]] = fcmp oeq float %x, %y
; CHECK-LLVM-NEXT: %[[XSIGN:[0-9]+]] = call spir_func float @_Z8copysignff(float 1.000000e+00, float %x)
; CHECK-LLVM-NEXT: %[[XNEG:[0-9]+]] = fcmp olt float %[[XSIGN]], 0.000000e+00
; CHECK-LLVM-NEXT: %[[ZERO:[0-9]+]] = select i1 %[[XNEG]], float %x, float %y
; CHECK-LLVM-NEXT: %[[MZERO:[0-9]+]] = select i1 %[[EQ]], float %[[ZERO]], float %[[M]]
; CHECK-LLVM-NEXT: %[[UNO:[0-9]+]] = fcmp uno float %x, %y
; CHECK-LLVM-NEXT: %r = select i1 %[[UNO]], float +qnan, float %[[MZERO]]
; CHECK-LLVM-NEXT: ret float %r
define spir_func float @minimum_f32(float %x, float %y) {
  %r = call float @llvm.minimum.f32(float %x, float %y)
  ret float %r
}

; CHECK-SPIRV: Function [[#Float]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Float]] [[#M:]] [[#]] fmax [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: FOrdEqual [[#Bool]] [[#Eq:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: ExtInst [[#Float]] [[#XSign:]] [[#]] copysign [[#FloatOne]] [[#X]]
; CHECK-SPIRV-NEXT: FOrdLessThan [[#Bool]] [[#XNeg:]] [[#XSign]] [[#FloatZero]]
; CHECK-SPIRV-NEXT: Select [[#Float]] [[#Zero:]] [[#XNeg]] [[#Y]] [[#X]]
; CHECK-SPIRV-NEXT: Select [[#Float]] [[#MZero:]] [[#Eq]] [[#Zero]] [[#M]]
; CHECK-SPIRV-NEXT: Unordered [[#Bool]] [[#Uno:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Float]] [[#Res:]] [[#Uno]] [[#FloatNaN]] [[#MZero]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]

; CHECK-LLVM-LABEL: define spir_func float @maximum_f32(
; CHECK-LLVM-NEXT: %[[M:[0-9]+]] = call spir_func float @_Z4fmaxff(float %x, float %y)
; CHECK-LLVM-NEXT: %[[EQ:[0-9]+]] = fcmp oeq float %x, %y
; CHECK-LLVM-NEXT: %[[XSIGN:[0-9]+]] = call spir_func float @_Z8copysignff(float 1.000000e+00, float %x)
; CHECK-LLVM-NEXT: %[[XNEG:[0-9]+]] = fcmp olt float %[[XSIGN]], 0.000000e+00
; CHECK-LLVM-NEXT: %[[ZERO:[0-9]+]] = select i1 %[[XNEG]], float %y, float %x
; CHECK-LLVM-NEXT: %[[MZERO:[0-9]+]] = select i1 %[[EQ]], float %[[ZERO]], float %[[M]]
; CHECK-LLVM-NEXT: %[[UNO:[0-9]+]] = fcmp uno float %x, %y
; CHECK-LLVM-NEXT: %r = select i1 %[[UNO]], float +qnan, float %[[MZERO]]
; CHECK-LLVM-NEXT: ret float %r
define spir_func float @maximum_f32(float %x, float %y) {
  %r = call float @llvm.maximum.f32(float %x, float %y)
  ret float %r
}

; CHECK-SPIRV: Function [[#Half]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Half]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Half]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Half]] [[#M:]] [[#]] fmin [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: FOrdEqual [[#Bool]] [[#Eq:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: ExtInst [[#Half]] [[#XSign:]] [[#]] copysign [[#HalfOne]] [[#X]]
; CHECK-SPIRV-NEXT: FOrdLessThan [[#Bool]] [[#XNeg:]] [[#XSign]] [[#HalfZero]]
; CHECK-SPIRV-NEXT: Select [[#Half]] [[#Zero:]] [[#XNeg]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Half]] [[#MZero:]] [[#Eq]] [[#Zero]] [[#M]]
; CHECK-SPIRV-NEXT: Unordered [[#Bool]] [[#Uno:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Half]] [[#Res:]] [[#Uno]] [[#HalfNaN]] [[#MZero]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]
define spir_func half @minimum_f16(half %x, half %y) {
  %r = call half @llvm.minimum.f16(half %x, half %y)
  ret half %r
}

; CHECK-SPIRV: Function [[#Double]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Double]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Double]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Double]] [[#M:]] [[#]] fmax [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: FOrdEqual [[#Bool]] [[#Eq:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: ExtInst [[#Double]] [[#XSign:]] [[#]] copysign [[#DoubleOne]] [[#X]]
; CHECK-SPIRV-NEXT: FOrdLessThan [[#Bool]] [[#XNeg:]] [[#XSign]] [[#DoubleZero]]
; CHECK-SPIRV-NEXT: Select [[#Double]] [[#Zero:]] [[#XNeg]] [[#Y]] [[#X]]
; CHECK-SPIRV-NEXT: Select [[#Double]] [[#MZero:]] [[#Eq]] [[#Zero]] [[#M]]
; CHECK-SPIRV-NEXT: Unordered [[#Bool]] [[#Uno:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Double]] [[#Res:]] [[#Uno]] [[#DoubleNaN]] [[#MZero]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]
define spir_func double @maximum_f64(double %x, double %y) {
  %r = call double @llvm.maximum.f64(double %x, double %y)
  ret double %r
}

; CHECK-SPIRV: Function [[#Float4]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float4]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float4]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Float4]] [[#M:]] [[#]] fmin [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: FOrdEqual [[#Bool4]] [[#Eq:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: ExtInst [[#Float4]] [[#XSign:]] [[#]] copysign [[#Float4One]] [[#X]]
; CHECK-SPIRV-NEXT: FOrdLessThan [[#Bool4]] [[#XNeg:]] [[#XSign]] [[#Float4Zero]]
; CHECK-SPIRV-NEXT: Select [[#Float4]] [[#Zero:]] [[#XNeg]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Float4]] [[#MZero:]] [[#Eq]] [[#Zero]] [[#M]]
; CHECK-SPIRV-NEXT: Unordered [[#Bool4]] [[#Uno:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Float4]] [[#Res:]] [[#Uno]] [[#Float4NaN]] [[#MZero]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]
define spir_func <4 x float> @minimum_v4f32(<4 x float> %x, <4 x float> %y) {
  %r = call <4 x float> @llvm.minimum.v4f32(<4 x float> %x, <4 x float> %y)
  ret <4 x float> %r
}

; CHECK-SPIRV: Function [[#Double2]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Double2]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Double2]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Double2]] [[#M:]] [[#]] fmax [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: FOrdEqual [[#Bool2]] [[#Eq:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: ExtInst [[#Double2]] [[#XSign:]] [[#]] copysign [[#Double2One]] [[#X]]
; CHECK-SPIRV-NEXT: FOrdLessThan [[#Bool2]] [[#XNeg:]] [[#XSign]] [[#Double2Zero]]
; CHECK-SPIRV-NEXT: Select [[#Double2]] [[#Zero:]] [[#XNeg]] [[#Y]] [[#X]]
; CHECK-SPIRV-NEXT: Select [[#Double2]] [[#MZero:]] [[#Eq]] [[#Zero]] [[#M]]
; CHECK-SPIRV-NEXT: Unordered [[#Bool2]] [[#Uno:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Double2]] [[#Res:]] [[#Uno]] [[#Double2NaN]] [[#MZero]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]
define spir_func <2 x double> @maximum_v2f64(<2 x double> %x, <2 x double> %y) {
  %r = call <2 x double> @llvm.maximum.v2f64(<2 x double> %x, <2 x double> %y)
  ret <2 x double> %r
}

; CHECK-SPIRV: Function [[#Half2]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Half2]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Half2]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Half2]] [[#M:]] [[#]] fmax [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: FOrdEqual [[#Bool2]] [[#Eq:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: ExtInst [[#Half2]] [[#XSign:]] [[#]] copysign [[#Half2One]] [[#X]]
; CHECK-SPIRV-NEXT: FOrdLessThan [[#Bool2]] [[#XNeg:]] [[#XSign]] [[#Half2Zero]]
; CHECK-SPIRV-NEXT: Select [[#Half2]] [[#Zero:]] [[#XNeg]] [[#Y]] [[#X]]
; CHECK-SPIRV-NEXT: Select [[#Half2]] [[#MZero:]] [[#Eq]] [[#Zero]] [[#M]]
; CHECK-SPIRV-NEXT: Unordered [[#Bool2]] [[#Uno:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Half2]] [[#Res:]] [[#Uno]] [[#Half2NaN]] [[#MZero]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]
define spir_func <2 x half> @maximum_v2f16(<2 x half> %x, <2 x half> %y) {
  %r = call <2 x half> @llvm.maximum.v2f16(<2 x half> %x, <2 x half> %y)
  ret <2 x half> %r
}

; nnan: no NaN fix-up.
; CHECK-SPIRV: Function [[#Float]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Float]] [[#M:]] [[#]] fmin [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: FOrdEqual [[#Bool]] [[#Eq:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: ExtInst [[#Float]] [[#XSign:]] [[#]] copysign [[#FloatOne]] [[#X]]
; CHECK-SPIRV-NEXT: FOrdLessThan [[#Bool]] [[#XNeg:]] [[#XSign]] [[#FloatZero]]
; CHECK-SPIRV-NEXT: Select [[#Float]] [[#Zero:]] [[#XNeg]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Float]] [[#Res:]] [[#Eq]] [[#Zero]] [[#M]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]

; CHECK-LLVM-LABEL: define spir_func float @minimum_f32_nnan(
; CHECK-LLVM-NEXT: %[[M:[0-9]+]] = call nnan spir_func float @_Z4fminff(float %x, float %y)
; CHECK-LLVM-NOT: fcmp uno
; CHECK-LLVM: %r = select i1 %{{[0-9]+}}, float %{{[0-9]+}}, float %[[M]]
; CHECK-LLVM-NEXT: ret float %r
define spir_func float @minimum_f32_nnan(float %x, float %y) {
  %r = call nnan float @llvm.minimum.f32(float %x, float %y)
  ret float %r
}

; nsz: no signed-zero fix-up.
; CHECK-SPIRV: Function [[#Float]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Float]] [[#M:]] [[#]] fmax [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Unordered [[#Bool]] [[#Uno:]] [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: Select [[#Float]] [[#Res:]] [[#Uno]] [[#FloatNaN]] [[#M]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]

; CHECK-LLVM-LABEL: define spir_func float @maximum_f32_nsz(
; CHECK-LLVM-NEXT: %[[M:[0-9]+]] = call nsz spir_func float @_Z4fmaxff(float %x, float %y)
; CHECK-LLVM-NEXT: %[[UNO:[0-9]+]] = fcmp uno float %x, %y
; CHECK-LLVM-NEXT: %r = select i1 %[[UNO]], float +qnan, float %[[M]]
; CHECK-LLVM-NEXT: ret float %r
define spir_func float @maximum_f32_nsz(float %x, float %y) {
  %r = call nsz float @llvm.maximum.f32(float %x, float %y)
  ret float %r
}

; nnan nsz: plain fmin.
; CHECK-SPIRV: Function [[#Half2]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Half2]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Half2]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Half2]] [[#Res:]] [[#]] fmin [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]

; CHECK-LLVM-LABEL: define spir_func <2 x half> @minimum_v2f16_nnan_nsz(
; CHECK-LLVM-NEXT: %r = call nnan nsz spir_func <2 x half> @_Z4fminDv2_DhS_(<2 x half> %x, <2 x half> %y)
; CHECK-LLVM-NEXT: ret <2 x half> %r
define spir_func <2 x half> @minimum_v2f16_nnan_nsz(<2 x half> %x, <2 x half> %y) {
  %r = call nnan nsz <2 x half> @llvm.minimum.v2f16(<2 x half> %x, <2 x half> %y)
  ret <2 x half> %r
}

; CHECK-SPIRV: Function [[#Float]] [[#]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float]] [[#X:]]
; CHECK-SPIRV-NEXT: FunctionParameter [[#Float]] [[#Y:]]
; CHECK-SPIRV: ExtInst [[#Float]] [[#Res:]] [[#]] fmax [[#X]] [[#Y]]
; CHECK-SPIRV-NEXT: ReturnValue [[#Res]]

; CHECK-LLVM-LABEL: define spir_func float @maximum_f32_fast(
; CHECK-LLVM-NEXT: %r = call fast spir_func float @_Z4fmaxff(float %x, float %y)
; CHECK-LLVM-NEXT: ret float %r
define spir_func float @maximum_f32_fast(float %x, float %y) {
  %r = call fast float @llvm.maximum.f32(float %x, float %y)
  ret float %r
}
