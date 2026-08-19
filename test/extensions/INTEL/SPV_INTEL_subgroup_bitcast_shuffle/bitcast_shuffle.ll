; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_subgroup_bitcast_shuffle -o %t.spv
; RUN: llvm-spirv %t.spv --to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: not llvm-spirv %t.bc 2>&1 -o %t.err.spv | FileCheck %s --check-prefix=CHECK-ERROR
; CHECK-ERROR: RequiresExtension: Feature requires the following SPIR-V extension:
; CHECK-ERROR-NEXT: SPV_INTEL_subgroup_bitcast_shuffle

; CHECK-SPIRV-DAG: Capability SubgroupBitcastShuffleINTEL
; CHECK-SPIRV-DAG: Extension "SPV_INTEL_subgroup_bitcast_shuffle"

; CHECK-SPIRV-DAG: TypeInt [[#TI8:]] 8 0
; CHECK-SPIRV-DAG: TypeInt [[#TI16:]] 16 0
; CHECK-SPIRV-DAG: TypeInt [[#TI32:]] 32 0
; CHECK-SPIRV-DAG: TypeInt [[#TI64:]] 64 0
; CHECK-SPIRV-DAG: TypeVector [[#TV2I8:]] [[#TI8]] 2
; CHECK-SPIRV-DAG: TypeVector [[#TV4I8:]] [[#TI8]] 4
; CHECK-SPIRV-DAG: TypeVector [[#TV8I8:]] [[#TI8]] 8
; CHECK-SPIRV-DAG: TypeVector [[#TV2I16:]] [[#TI16]] 2
; CHECK-SPIRV-DAG: TypeVector [[#TV4I16:]] [[#TI16]] 4
; CHECK-SPIRV-DAG: TypeVector [[#TV2I32:]] [[#TI32]] 2

; Scalar -> Vector
; CHECK-SPIRV: Load [[#TI16]] [[#S16:]]
; CHECK-SPIRV: Load [[#TI32]] [[#S32:]]
; CHECK-SPIRV: Load [[#TI64]] [[#S64:]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TV2I8]] {{.*}} [[#S16]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TV4I8]] {{.*}} [[#S32]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TV2I16]] {{.*}} [[#S32]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TV8I8]] {{.*}} [[#S64]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TV4I16]] {{.*}} [[#S64]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TV2I32]] {{.*}} [[#S64]]

; Vector -> Scalar
; CHECK-SPIRV: Load [[#TV2I8]] [[#V2I8:]]
; CHECK-SPIRV: Load [[#TV4I8]] [[#V4I8:]]
; CHECK-SPIRV: Load [[#TV8I8]] [[#V8I8:]]
; CHECK-SPIRV: Load [[#TV2I16]] [[#V2I16:]]
; CHECK-SPIRV: Load [[#TV4I16]] [[#V4I16:]]
; CHECK-SPIRV: Load [[#TV2I32]] [[#V2I32:]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TI16]] {{.*}} [[#V2I8]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TI32]] {{.*}} [[#V4I8]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TI64]] {{.*}} [[#V8I8]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TI32]] {{.*}} [[#V2I16]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TI64]] {{.*}} [[#V4I16]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TI64]] {{.*}} [[#V2I32]]

; CHECK-LLVM: call spir_func <2 x i8> @{{.*SubgroupBitcastShuffleINTEL_Ruchar2.*}}(i16
; CHECK-LLVM: call spir_func <4 x i8> @{{.*SubgroupBitcastShuffleINTEL_Ruchar4.*}}(i32
; CHECK-LLVM: call spir_func <2 x i16> @{{.*SubgroupBitcastShuffleINTEL_Rushort2.*}}(i32
; CHECK-LLVM: call spir_func <8 x i8> @{{.*SubgroupBitcastShuffleINTEL_Ruchar8.*}}(i64
; CHECK-LLVM: call spir_func <4 x i16> @{{.*SubgroupBitcastShuffleINTEL_Rushort4.*}}(i64
; CHECK-LLVM: call spir_func <2 x i32> @{{.*SubgroupBitcastShuffleINTEL_Ruint2.*}}(i64
; CHECK-LLVM: call spir_func i16 @{{.*SubgroupBitcastShuffleINTEL_Rushort.*}}(<2 x i8>
; CHECK-LLVM: call spir_func i32 @{{.*SubgroupBitcastShuffleINTEL_Ruint.*}}(<4 x i8>
; CHECK-LLVM: call spir_func i64 @{{.*SubgroupBitcastShuffleINTEL_Rulong.*}}(<8 x i8>
; CHECK-LLVM: call spir_func i32 @{{.*SubgroupBitcastShuffleINTEL_Ruint.*}}(<2 x i16>
; CHECK-LLVM: call spir_func i64 @{{.*SubgroupBitcastShuffleINTEL_Rulong.*}}(<4 x i16>
; CHECK-LLVM: call spir_func i64 @{{.*SubgroupBitcastShuffleINTEL_Rulong.*}}(<2 x i32>

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir"

define spir_kernel void @test_scalar_to_vector() {
entry:
  %s16.ptr = alloca i16
  %s32.ptr = alloca i32
  %s64.ptr = alloca i64

  %s16 = load i16, ptr %s16.ptr
  %s32 = load i32, ptr %s32.ptr
  %s64 = load i64, ptr %s64.ptr

  %r16to2x8 = call spir_func <2 x i8> @_Z43__spirv_SubgroupBitcastShuffleINTEL_Ruchar2s(i16 %s16)
  %r32to4x8 = call spir_func <4 x i8> @_Z43__spirv_SubgroupBitcastShuffleINTEL_Ruchar4i(i32 %s32)
  %r32to2x16 = call spir_func <2 x i16> @_Z44__spirv_SubgroupBitcastShuffleINTEL_Rushort2i(i32 %s32)
  %r64to8x8 = call spir_func <8 x i8> @_Z43__spirv_SubgroupBitcastShuffleINTEL_Ruchar8l(i64 %s64)
  %r64to4x16 = call spir_func <4 x i16> @_Z44__spirv_SubgroupBitcastShuffleINTEL_Rushort4l(i64 %s64)
  %r64to2x32 = call spir_func <2 x i32> @_Z42__spirv_SubgroupBitcastShuffleINTEL_Ruint2l(i64 %s64)
  ret void
}

define spir_kernel void @test_vector_to_scalar() {
entry:
  %v2i8.ptr = alloca <2 x i8>
  %v4i8.ptr = alloca <4 x i8>
  %v8i8.ptr = alloca <8 x i8>
  %v2i16.ptr = alloca <2 x i16>
  %v4i16.ptr = alloca <4 x i16>
  %v2i32.ptr = alloca <2 x i32>

  %v2i8 = load <2 x i8>, ptr %v2i8.ptr
  %v4i8 = load <4 x i8>, ptr %v4i8.ptr
  %v8i8 = load <8 x i8>, ptr %v8i8.ptr
  %v2i16 = load <2 x i16>, ptr %v2i16.ptr
  %v4i16 = load <4 x i16>, ptr %v4i16.ptr
  %v2i32 = load <2 x i32>, ptr %v2i32.ptr

  %r2x8to16 = call spir_func i16 @_Z43__spirv_SubgroupBitcastShuffleINTEL_RushortDv2_c(<2 x i8> %v2i8)
  %r4x8to32 = call spir_func i32 @_Z41__spirv_SubgroupBitcastShuffleINTEL_RuintDv4_c(<4 x i8> %v4i8)
  %r8x8to64 = call spir_func i64 @_Z42__spirv_SubgroupBitcastShuffleINTEL_RulongDv8_c(<8 x i8> %v8i8)
  %r2x16to32 = call spir_func i32 @_Z41__spirv_SubgroupBitcastShuffleINTEL_RuintDv2_s(<2 x i16> %v2i16)
  %r4x16to64 = call spir_func i64 @_Z42__spirv_SubgroupBitcastShuffleINTEL_RulongDv4_s(<4 x i16> %v4i16)
  %r2x32to64 = call spir_func i64 @_Z42__spirv_SubgroupBitcastShuffleINTEL_RulongDv2_i(<2 x i32> %v2i32)
  ret void
}

declare dso_local spir_func <2 x i8> @_Z43__spirv_SubgroupBitcastShuffleINTEL_Ruchar2s(i16)
declare dso_local spir_func <4 x i8> @_Z43__spirv_SubgroupBitcastShuffleINTEL_Ruchar4i(i32)
declare dso_local spir_func <2 x i16> @_Z44__spirv_SubgroupBitcastShuffleINTEL_Rushort2i(i32)
declare dso_local spir_func <8 x i8> @_Z43__spirv_SubgroupBitcastShuffleINTEL_Ruchar8l(i64)
declare dso_local spir_func <4 x i16> @_Z44__spirv_SubgroupBitcastShuffleINTEL_Rushort4l(i64)
declare dso_local spir_func <2 x i32> @_Z42__spirv_SubgroupBitcastShuffleINTEL_Ruint2l(i64)
declare dso_local spir_func i16 @_Z43__spirv_SubgroupBitcastShuffleINTEL_RushortDv2_c(<2 x i8>)
declare dso_local spir_func i32 @_Z41__spirv_SubgroupBitcastShuffleINTEL_RuintDv4_c(<4 x i8>)
declare dso_local spir_func i64 @_Z42__spirv_SubgroupBitcastShuffleINTEL_RulongDv8_c(<8 x i8>)
declare dso_local spir_func i32 @_Z41__spirv_SubgroupBitcastShuffleINTEL_RuintDv2_s(<2 x i16>)
declare dso_local spir_func i64 @_Z42__spirv_SubgroupBitcastShuffleINTEL_RulongDv4_s(<4 x i16>)
declare dso_local spir_func i64 @_Z42__spirv_SubgroupBitcastShuffleINTEL_RulongDv2_i(<2 x i32>)

!llvm.module.flags = !{!0}
!opencl.spir.version = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
