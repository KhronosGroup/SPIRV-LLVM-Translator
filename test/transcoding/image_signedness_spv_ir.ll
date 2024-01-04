; Test that signedness of calls to SPV-IR image builtin is preserved.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r --spirv-target-env=SPV-IR %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-SPV-IR

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024"
target triple = "spir64-unknown-unknown"

define dso_local spir_kernel void @reads() {
; CHECK-LABEL: spir_kernel void @reads(
; CHECK-SPV-IR: call spir_func i32 @_Z22__spirv_ImageRead_RintPU3AS133__spirv_Image__void_2_0_0_0_0_0_0Dv4_ii
; CHECK-SPV-IR: call spir_func <2 x i32> @_Z23__spirv_ImageRead_Rint2PU3AS133__spirv_Image__void_1_0_0_0_0_0_0Dv2_ii
; CHECK-SPV-IR: call spir_func <4 x i32> @_Z24__spirv_ImageRead_Ruint4PU3AS133__spirv_Image__void_2_0_0_0_0_0_0Dv4_ii
; CHECK-SPV-IR: call spir_func i16 @_Z24__spirv_ImageRead_RshortPU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii
; CHECK-SPV-IR: call spir_func i16 @_Z25__spirv_ImageRead_RushortPU3AS133__spirv_Image__void_2_0_0_0_0_0_0Dv4_ii
; CHECK-SPV-IR: call spir_func <2 x float> @_Z25__spirv_ImageRead_Rfloat2PU3AS133__spirv_Image__void_0_0_0_0_0_0_0i
; CHECK-SPV-IR: call spir_func half @_Z23__spirv_ImageRead_RhalfPU3AS133__spirv_Image__void_1_0_0_0_0_0_0Dv2_i

  %1 = tail call spir_func i32 @_Z17__spirv_ImageReadIi14ocl_image3d_roDv4_iET_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) undef, <4 x i32> zeroinitializer)
  %2 = tail call spir_func <2 x i32> @_Z17__spirv_ImageReadIDv2_i14ocl_image2d_roS0_ET_T0_T1_(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) undef, <2 x i32> zeroinitializer)
  %3 = tail call spir_func <4 x i32> @_Z17__spirv_ImageReadIDv4_j14ocl_image3d_roDv4_iET_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) undef, <4 x i32> zeroinitializer)
  %4 = tail call spir_func signext i16 @_Z17__spirv_ImageReadIs14ocl_image1d_roiET_T0_T1_(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)
  %5 = tail call spir_func zeroext i16 @_Z17__spirv_ImageReadIt14ocl_image3d_roDv4_iET_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) undef, <4 x i32> zeroinitializer)
  %6 = tail call spir_func <2 x float> @_Z17__spirv_ImageReadIDv2_f14ocl_image1d_roiET_T0_T1_(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)
  %7 = tail call spir_func half @_Z17__spirv_ImageReadIDF16_14ocl_image2d_roDv2_iET_T0_T1_(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) undef, <2 x i32> zeroinitializer)
  ret void
}

declare dso_local spir_func i32 @_Z17__spirv_ImageReadIi14ocl_image3d_roDv4_iET_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), <4 x i32>)
declare dso_local spir_func <2 x i32> @_Z17__spirv_ImageReadIDv2_i14ocl_image2d_roS0_ET_T0_T1_(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0), <2 x i32>)
declare dso_local spir_func <4 x i32> @_Z17__spirv_ImageReadIDv4_j14ocl_image3d_roDv4_iET_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), <4 x i32>)
declare dso_local spir_func signext i16 @_Z17__spirv_ImageReadIs14ocl_image1d_roiET_T0_T1_(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)
declare dso_local spir_func zeroext i16 @_Z17__spirv_ImageReadIt14ocl_image3d_roDv4_iET_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), <4 x i32>)
declare dso_local spir_func <2 x float> @_Z17__spirv_ImageReadIDv2_f14ocl_image1d_roiET_T0_T1_(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)
declare dso_local spir_func half @_Z17__spirv_ImageReadIDF16_14ocl_image2d_roDv2_iET_T0_T1_(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0), <2 x i32>)

define dso_local spir_kernel void @writes() {
; CHECK-LABEL: spir_kernel void @writes(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_2_0_0_0_0_0_1Dv4_iii(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_1_0_0_0_0_0_1Dv2_iS2_i(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_2_0_0_0_0_0_1Dv4_iDv4_ji(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1isi(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_2_0_0_0_0_0_1Dv4_iti(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv2_f(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_1_0_0_0_0_0_1Dv2_iDh(

  call spir_func void @_Z18__spirv_ImageWriteI14ocl_image3d_woDv4_iiEvT_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 1) undef, <4 x i32> zeroinitializer, i32 zeroinitializer)
  call spir_func void @_Z18__spirv_ImageWriteI14ocl_image2d_woDv2_iS1_EvT_T0_T1_(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) undef, <2 x i32> zeroinitializer, <2 x i32> zeroinitializer)
  call spir_func void @_Z18__spirv_ImageWriteI14ocl_image3d_woDv4_iDv4_jEvT_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 1) undef, <4 x i32> zeroinitializer, <4 x i32> zeroinitializer)
  call spir_func void @_Z18__spirv_ImageWriteI14ocl_image1d_woisEvT_T0_T1_(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, i16 signext 0)
  call spir_func void @_Z18__spirv_ImageWriteI14ocl_image3d_woDv4_itEvT_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 1) undef, <4 x i32> zeroinitializer, i16 zeroext 0)
  call spir_func void @_Z18__spirv_ImageWriteI14ocl_image1d_woiDv2_fEvT_T0_T1_(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, <2 x float> zeroinitializer)
  call spir_func void @_Z18__spirv_ImageWriteI14ocl_image2d_woDv2_iDF16_EvT_T0_T1_(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) undef, <2 x i32> zeroinitializer, half zeroinitializer)
  ret void
}

declare dso_local spir_func void @_Z18__spirv_ImageWriteI14ocl_image3d_woDv4_iiEvT_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 1), <4 x i32>, i32)
declare dso_local spir_func void @_Z18__spirv_ImageWriteI14ocl_image2d_woDv2_iS1_EvT_T0_T1_(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1), <2 x i32>, <2 x i32>)
declare dso_local spir_func void @_Z18__spirv_ImageWriteI14ocl_image3d_woDv4_iDv4_jEvT_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 1), <4 x i32>, <4 x i32>)
declare dso_local spir_func void @_Z18__spirv_ImageWriteI14ocl_image1d_woisEvT_T0_T1_(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, i16 signext)
declare dso_local spir_func void @_Z18__spirv_ImageWriteI14ocl_image3d_woDv4_itEvT_T0_T1_(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 1), <4 x i32>, i16 zeroext)
declare dso_local spir_func void @_Z18__spirv_ImageWriteI14ocl_image1d_woiDv2_fEvT_T0_T1_(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, <2 x float>)
declare dso_local spir_func void @_Z18__spirv_ImageWriteI14ocl_image2d_woDv2_iDF16_EvT_T0_T1_(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1), <2 x i32>, half)

define dso_local spir_kernel void @reads2() {
; CHECK-LABE: spir_kernel void @reads2(
; CHECK-SPV-IR: call spir_func i32 @_Z22__spirv_ImageRead_RintPU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii(
; CHECK-SPV-IR: call spir_func i32 @_Z22__spirv_ImageRead_RintPU3AS133__spirv_Image__void_1_0_0_0_0_0_0Dv2_ii(
; CHECK-SPV-IR: call spir_func <2 x i32> @_Z23__spirv_ImageRead_Rint2PU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii(
; CHECK-SPV-IR: call spir_func i32 @_Z23__spirv_ImageRead_RuintPU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii(
; CHECK-SPV-IR: call spir_func i32 @_Z23__spirv_ImageRead_RuintPU3AS133__spirv_Image__void_1_0_0_0_0_0_0Dv2_ii(
; CHECK-SPV-IR: call spir_func <2 x i32> @_Z24__spirv_ImageRead_Ruint2PU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii(
; CHECK-SPV-IR: call spir_func i8 @_Z23__spirv_ImageRead_RcharPU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii(
; CHECK-SPV-IR: call spir_func i8 @_Z24__spirv_ImageRead_RucharPU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii(
; CHECK-SPV-IR: call spir_func i16 @_Z24__spirv_ImageRead_RshortPU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii(
; CHECK-SPV-IR: call spir_func <2 x i16> @_Z26__spirv_ImageRead_Rushort2PU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii(
; CHECK-SPV-IR: call spir_func <4 x float> @_Z25__spirv_ImageRead_Rfloat4PU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(
; CHECK-SPV-IR: call spir_func half @_Z23__spirv_ImageRead_RhalfPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(

  %1 = call spir_func i32 @_Z22__spirv_ImageRead_RintPU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0, i32 4096)
  %2 = call spir_func i32 @_Z22__spirv_ImageRead_RintPU3AS133__spirv_Image__void_1_0_0_0_0_0_0Dv2_i(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) undef, <2 x i32> zeroinitializer)
  %3 = call spir_func <2 x i32> @_Z23__spirv_ImageRead_Rint2PU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)

  %4 = call spir_func i32 @_Z23__spirv_ImageRead_RuintPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)
  %5 = call spir_func i32 @_Z23__spirv_ImageRead_RuintPU3AS133__spirv_Image__void_1_0_0_0_0_0_0Dv2_i(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) undef, <2 x i32> zeroinitializer)
  %6 = call spir_func <2 x i32> @_Z24__spirv_ImageRead_Ruint2PU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)

  %7 = call spir_func i8 @_Z23__spirv_ImageRead_RcharPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)
  %8 = call spir_func i8 @_Z24__spirv_ImageRead_RucharPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)
  %9 = call spir_func i16 @_Z24__spirv_ImageRead_RshortPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)
  %10 = call spir_func <2 x i16> @_Z26__spirv_ImageRead_Rushort2PU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)
  %11 = call spir_func <4 x float> @_Z25__spirv_ImageRead_Rfloat4PU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)
  %12 = call spir_func half @_Z23__spirv_ImageRead_RhalfPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) undef, i32 0)

  ret void
}

declare spir_func i32 @_Z22__spirv_ImageRead_RintPU3AS133__spirv_Image__void_0_0_0_0_0_0_0ii(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32, i32)
declare spir_func i32 @_Z22__spirv_ImageRead_RintPU3AS133__spirv_Image__void_1_0_0_0_0_0_0Dv2_i(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0), <2 x i32>)
declare spir_func <2 x i32> @_Z23__spirv_ImageRead_Rint2PU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)

declare spir_func i32 @_Z23__spirv_ImageRead_RuintPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)
declare spir_func i32 @_Z23__spirv_ImageRead_RuintPU3AS133__spirv_Image__void_1_0_0_0_0_0_0Dv2_i(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0), <2 x i32>)
declare spir_func <2 x i32> @_Z24__spirv_ImageRead_Ruint2PU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)

declare spir_func i8 @_Z23__spirv_ImageRead_RcharPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)
declare spir_func i8 @_Z24__spirv_ImageRead_RucharPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)
declare spir_func i16 @_Z24__spirv_ImageRead_RshortPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)
declare spir_func <2 x i16> @_Z26__spirv_ImageRead_Rushort2PU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)
declare spir_func <4 x float> @_Z25__spirv_ImageRead_Rfloat4PU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)
declare spir_func half @_Z23__spirv_ImageRead_RhalfPU3AS133__spirv_Image__void_0_0_0_0_0_0_0i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), i32)

define dso_local spir_kernel void @writes2() {
; CHECK-LABE: spir_kernel void @writes2(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iii(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_1_0_0_0_0_0_1Dv2_iii(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv2_ii(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iji(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_1_0_0_0_0_0_1Dv2_iji(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv2_ji(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1ici(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1ihi(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1isi(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv2_ti(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv4_f(
; CHECK-SPV-IR: call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDh(

  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iii(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, i32 0, i32 4096)
  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_1_0_0_0_0_0_1Dv2_ii(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) undef, <2 x i32> zeroinitializer, i32 0)
  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv2_i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, <2 x i32> zeroinitializer)

  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1ij(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, i32 0)
  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_1_0_0_0_0_0_1Dv2_ij(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) undef, <2 x i32> zeroinitializer, i32 0)
  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv2_j(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, <2 x i32> zeroinitializer)

  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1ic(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, i8 0)
  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1ih(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, i8 0)
  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1is(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, i16 0)
  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv2_t(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, <2 x i16> zeroinitializer)
  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv4_f(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, <4 x float> zeroinitializer)
  call spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDh(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) undef, i32 0, half zeroinitializer)

  ret void
}

declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iii(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, i32, i32)
declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_1_0_0_0_0_0_1Dv2_ii(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1), <2 x i32>, i32)
declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv2_i(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, <2 x i32>)

declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1ij(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, i32)
declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_1_0_0_0_0_0_1Dv2_ij(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1), <2 x i32>, i32)
declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv2_j(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, <2 x i32>)

declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1ic(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, i8)
declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1ih(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, i8)
declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1is(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, i16)
declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv2_t(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, <2 x i16>)
declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDv4_f(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, <4 x float>)
declare spir_func void @_Z18__spirv_ImageWritePU3AS133__spirv_Image__void_0_0_0_0_0_0_1iDh(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, half)
