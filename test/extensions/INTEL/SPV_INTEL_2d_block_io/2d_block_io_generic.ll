; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv --spirv-ext=+SPV_INTEL_2d_block_io
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv %t.spv -o %t.rev.bc -r --spirv-target-env=SPV-IR
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; RUN: not llvm-spirv %t.bc 2>&1 | FileCheck %s --check-prefix=CHECK-ERROR
; CHECK-ERROR: RequiresExtension: Feature requires the following SPIR-V extension:
; CHECK-ERROR-NEXT: SPV_INTEL_2d_block_io

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV: Capability Subgroup2DBlockIOINTEL
; CHECK-SPIRV: Capability Subgroup2DBlockTransformINTEL
; CHECK-SPIRV: Capability Subgroup2DBlockTransposeINTEL
; CHECK-SPIRV: Extension "SPV_INTEL_2d_block_io"
; CHECK-SPIRV-DAG: TypeInt [[#Int8Ty:]] 8 0
; CHECK-SPIRV-DAG: TypeInt [[#Int32Ty:]] 32 0
; CHECK-SPIRV-DAG: Constant [[#Int32Ty]] [[#Const42:]] 42
; CHECK-SPIRV-DAG: TypeVoid [[#VoidTy:]]
; CHECK-SPIRV-DAG: TypePointer [[#GlbPtrTy:]] 5 [[#Int8Ty]]
; CHECK-SPIRV-DAG: TypeVector [[#VectorTy:]] [[#Int32Ty]] 2
; CHECK-SPIRV-DAG: TypePointer [[#PrvPtrTy:]] 7 [[#Int8Ty]]
; CHECK-SPIRV: FunctionParameter [[#GlbPtrTy]] [[#BaseSrc:]]
; CHECK-SPIRV: FunctionParameter [[#GlbPtrTy]] [[#BaseDst:]]
; CHECK-SPIRV: FunctionParameter [[#Int32Ty]] [[#Width:]]
; CHECK-SPIRV: FunctionParameter [[#Int32Ty]] [[#Height:]]
; CHECK-SPIRV: FunctionParameter [[#Int32Ty]] [[#Pitch:]]
; CHECK-SPIRV: FunctionParameter [[#VectorTy]] [[#Coord:]]
; CHECK-SPIRV: FunctionParameter [[#PrvPtrTy]] [[#Dst:]]
; CHECK-SPIRV: FunctionParameter [[#PrvPtrTy]] [[#Src:]]
; CHECK-SPIRV: Subgroup2DBlockLoadINTEL [[#Const42]] [[#Const42]] [[#Const42]] [[#Const42]] [[#BaseSrc]] [[#Width]] [[#Height]] [[#Pitch]] [[#Coord]] [[#Dst]]
; CHECK-SPIRV: Subgroup2DBlockLoadTransformINTEL [[#Const42]] [[#Const42]] [[#Const42]] [[#Const42]] [[#BaseSrc]] [[#Width]] [[#Height]] [[#Pitch]] [[#Coord]] [[#Dst]]
; CHECK-SPIRV: Subgroup2DBlockLoadTransposeINTEL [[#Const42]] [[#Const42]] [[#Const42]] [[#Const42]] [[#BaseSrc]] [[#Width]] [[#Height]] [[#Pitch]] [[#Coord]] [[#Dst]]
; CHECK-SPIRV: Subgroup2DBlockPrefetchINTEL [[#Const42]] [[#Const42]] [[#Const42]] [[#Const42]] [[#BaseSrc]] [[#Width]] [[#Height]] [[#Pitch]] [[#Coord]]
; CHECK-SPIRV: Subgroup2DBlockStoreINTEL [[#Const42]] [[#Const42]] [[#Const42]] [[#Const42]] [[#Src]] [[#BaseDst]] [[#Width]] [[#Height]] [[#Pitch]] [[#Coord]]

; CHECK-LLVM: call spir_func void @_Z32__spirv_Subgroup2DBlockLoadINTELiiiiPU3AS1ciiiDv2_iPc(i32 42, i32 42, i32 42, i32 42, ptr addrspace(1) %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, <2 x i32> %{{.*}}, ptr %{{.*}})
; CHECK-LLVM: call spir_func void @_Z41__spirv_Subgroup2DBlockLoadTransformINTELiiiiPU3AS1ciiiDv2_iPc(i32 42, i32 42, i32 42, i32 42, ptr addrspace(1) %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, <2 x i32> %{{.*}}, ptr %{{.*}})
; CHECK-LLVM: call spir_func void @_Z41__spirv_Subgroup2DBlockLoadTransposeINTELiiiiPU3AS1ciiiDv2_iPc(i32 42, i32 42, i32 42, i32 42, ptr addrspace(1) %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, <2 x i32> %{{.*}}, ptr %{{.*}})
; CHECK-LLVM: call spir_func void @_Z36__spirv_Subgroup2DBlockPrefetchINTELiiiiPU3AS1ciiiDv2_i(i32 42, i32 42, i32 42, i32 42, ptr addrspace(1) %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, <2 x i32> %{{.*}})
; CHECK-LLVM: call spir_func void @_Z33__spirv_Subgroup2DBlockStoreINTELiiiiPcPU3AS1ciiiDv2_i(i32 42, i32 42, i32 42, i32 42, ptr %{{.*}}, ptr addrspace(1) %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, <2 x i32> %{{.*}})

define spir_func void @foo(ptr addrspace(1) %base_address, ptr addrspace(1) %dst_base_pointer, i32 %width, i32 %height, i32 %pitch, <2 x i32> %coord, ptr %dst_pointer, ptr %src_pointer) {
entry:
  call spir_func void @_Z32__spirv_Subgroup2DBlockLoadINTELjjjjPU3AS1KvjjjDv2_jPv(i32 42, i32 42, i32 42, i32 42, ptr addrspace(1) %base_address, i32 %width, i32 %height, i32 %pitch, <2 x i32> %coord, ptr %dst_pointer)
  call spir_func void @_Z41__spirv_Subgroup2DBlockLoadTransformINTELjjjjPU3AS1KvjjjDv2_jPv(i32 42, i32 42, i32 42, i32 42, ptr addrspace(1) %base_address, i32 %width, i32 %height, i32 %pitch, <2 x i32> %coord, ptr %dst_pointer)
  call spir_func void @_Z41__spirv_Subgroup2DBlockLoadTransposeINTELjjjjPU3AS1KvjjjDv2_jPv(i32 42, i32 42, i32 42, i32 42, ptr addrspace(1) %base_address, i32 %width, i32 %height, i32 %pitch, <2 x i32> %coord, ptr %dst_pointer)
  call spir_func void @_Z36__spirv_Subgroup2DBlockPrefetchINTELjjjjPU3AS1KvjjjDv2_j(i32 42, i32 42, i32 42, i32 42, ptr addrspace(1) %base_address, i32 %width, i32 %height, i32 %pitch, <2 x i32> %coord)
  call spir_func void @_Z33__spirv_Subgroup2DBlockStoreINTELjjjjPKvPU3AS1vjjjDv2_j(i32 42, i32 42, i32 42, i32 42, ptr %src_pointer, ptr addrspace(1) %dst_base_pointer, i32 %width, i32 %height, i32 %pitch, <2 x i32> %coord)
  ret void
}

declare spir_func void @_Z32__spirv_Subgroup2DBlockLoadINTELjjjjPU3AS1KvjjjDv2_jPv(i32, i32, i32, i32, ptr addrspace(1), i32, i32, i32, <2 x i32>, ptr)
declare spir_func void @_Z41__spirv_Subgroup2DBlockLoadTransformINTELjjjjPU3AS1KvjjjDv2_jPv(i32, i32, i32, i32, ptr addrspace(1), i32, i32, i32, <2 x i32>, ptr)
declare spir_func void @_Z41__spirv_Subgroup2DBlockLoadTransposeINTELjjjjPU3AS1KvjjjDv2_jPv(i32, i32, i32, i32, ptr addrspace(1), i32, i32, i32, <2 x i32>, ptr)
declare spir_func void @_Z36__spirv_Subgroup2DBlockPrefetchINTELjjjjPU3AS1KvjjjDv2_j(i32, i32, i32, i32, ptr addrspace(1), i32, i32, i32, <2 x i32>)
declare spir_func void @_Z33__spirv_Subgroup2DBlockStoreINTELjjjjPKvPU3AS1vjjjDv2_j(i32, i32, i32, i32, ptr, ptr addrspace(1), i32, i32, i32, <2 x i32>)

!opencl.spir.version = !{!0}
!spirv.Source = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, i32 0}
!1 = !{i32 4, i32 100000}
!2 = !{!"clang version 17.0.0"}
