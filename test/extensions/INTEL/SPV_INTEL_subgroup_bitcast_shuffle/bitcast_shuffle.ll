; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_subgroup_bitcast_shuffle -o %t.spv
; RUN: llvm-spirv %t.spv --to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: not llvm-spirv %t.bc 2>&1 | FileCheck %s --check-prefix=CHECK-ERROR
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
; CHECK-SPIRV-DAG: TypeVector [[#TV2I16:]] [[#TI16]] 2
; CHECK-SPIRV-DAG: TypeVector [[#TV4I16:]] [[#TI16]] 4

; Scalar -> Vector
; CHECK-SPIRV: Load [[#TI16]] [[#S16:]]
; CHECK-SPIRV: Load [[#TI32]] [[#S32:]]
; CHECK-SPIRV: Load [[#TI64]] [[#S64:]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TV2I8]] {{.*}} [[#S16]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TV2I16]] {{.*}} [[#S32]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TV4I16]] {{.*}} [[#S64]]

; Vector -> Scalar
; CHECK-SPIRV: Load [[#TV2I8]] [[#V2I8:]]
; CHECK-SPIRV: Load [[#TV4I8]] [[#V4I8:]]
; CHECK-SPIRV: Load [[#TV4I16]] [[#V4I16:]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TI16]] {{.*}} [[#V2I8]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TI32]] {{.*}} [[#V4I8]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TI64]] {{.*}} [[#V4I16]]

; Vector -> Vector
; CHECK-SPIRV: Load [[#TV2I16]] [[#V2I16B:]]
; CHECK-SPIRV: SubgroupBitcastShuffleINTEL [[#TV4I8]] {{.*}} [[#V2I16B]]

; CHECK-LLVM: call spir_func <2 x i8> @{{.*SubgroupBitcastShuffleINTEL.*}}(i16
; CHECK-LLVM: call spir_func <2 x i16> @{{.*SubgroupBitcastShuffleINTEL.*}}(i32
; CHECK-LLVM: call spir_func <4 x i16> @{{.*SubgroupBitcastShuffleINTEL.*}}(i64
; CHECK-LLVM: call spir_func i16 @{{.*SubgroupBitcastShuffleINTEL.*}}(<2 x i8>
; CHECK-LLVM: call spir_func i32 @{{.*SubgroupBitcastShuffleINTEL.*}}(<4 x i8>
; CHECK-LLVM: call spir_func i64 @{{.*SubgroupBitcastShuffleINTEL.*}}(<4 x i16>
; CHECK-LLVM: call spir_func <4 x i8> @{{.*SubgroupBitcastShuffleINTEL.*}}(<2 x i16>

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

  %r16to2x8 = call spir_func <2 x i8> @_Z35__spirv_SubgroupBitcastShuffleINTELt(i16 %s16)
  %r32to2x16 = call spir_func <2 x i16> @_Z35__spirv_SubgroupBitcastShuffleINTELj(i32 %s32)
  %r64to4x16 = call spir_func <4 x i16> @_Z35__spirv_SubgroupBitcastShuffleINTELm(i64 %s64)
  ret void
}

define spir_kernel void @test_vector_to_scalar() {
entry:
  %v2i8.ptr = alloca <2 x i8>
  %v4i8.ptr = alloca <4 x i8>
  %v2i16.ptr = alloca <2 x i16>
  %v4i16.ptr = alloca <4 x i16>

  %v2i8 = load <2 x i8>, ptr %v2i8.ptr
  %v4i8 = load <4 x i8>, ptr %v4i8.ptr
  %v4i16 = load <4 x i16>, ptr %v4i16.ptr

  %r2x8to16 = call spir_func i16 @_Z35__spirv_SubgroupBitcastShuffleINTELDv2_h(<2 x i8> %v2i8)
  %r4x8to32 = call spir_func i32 @_Z35__spirv_SubgroupBitcastShuffleINTELDv4_h(<4 x i8> %v4i8)
  %r4x16to64 = call spir_func i64 @_Z35__spirv_SubgroupBitcastShuffleINTELDv4_t(<4 x i16> %v4i16)
  ret void
}

define spir_kernel void @test_vector_to_vector() {
entry:
  %v4i8.ptr = alloca <4 x i8>
  %v2i16.ptr = alloca <2 x i16>

  %v4i8 = load <4 x i8>, ptr %v4i8.ptr
  %v2i16 = load <2 x i16>, ptr %v2i16.ptr

  %r2x16to4x8 = call spir_func <4 x i8> @_Z35__spirv_SubgroupBitcastShuffleINTELDv2_t(<2 x i16> %v2i16)
  ret void
}

declare dso_local spir_func <2 x i8> @_Z35__spirv_SubgroupBitcastShuffleINTELt(i16)
declare dso_local spir_func <2 x i16> @_Z35__spirv_SubgroupBitcastShuffleINTELj(i32)
declare dso_local spir_func <4 x i16> @_Z35__spirv_SubgroupBitcastShuffleINTELm(i64)
declare dso_local spir_func i16 @_Z35__spirv_SubgroupBitcastShuffleINTELDv2_h(<2 x i8>)
declare dso_local spir_func i32 @_Z35__spirv_SubgroupBitcastShuffleINTELDv4_h(<4 x i8>)
declare dso_local spir_func i64 @_Z35__spirv_SubgroupBitcastShuffleINTELDv4_t(<4 x i16>)
declare dso_local spir_func <4 x i8> @_Z35__spirv_SubgroupBitcastShuffleINTELDv2_t(<2 x i16>)

!llvm.module.flags = !{!0}
!opencl.spir.version = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
