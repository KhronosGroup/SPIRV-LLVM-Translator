; The decoration must stay on the pointer the builtin consumes, not on a copy
; that is then cast to the builtin's pointer parameter type.

; RUN: llvm-spirv --spirv-ext=+SPV_INTEL_cache_controls,+SPV_INTEL_subgroups -spirv-text %s -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv --spirv-ext=+SPV_INTEL_cache_controls,+SPV_INTEL_subgroups %t.bc -o %s
; RUN: llvm-spirv -r %t.spv --spirv-target-env=SPV-IR -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: Decorate [[#GEP:]] CacheControlLoadINTEL 0 0
; CHECK-SPIRV: TypeInt [[#Int32Ty:]] 32 0
; CHECK-SPIRV: TypePointer [[#Int32PtrTy:]] [[#]] [[#Int32Ty]]
; CHECK-SPIRV: PtrAccessChain [[#Int32PtrTy]] [[#GEP]] [[#]] [[#]]
; CHECK-SPIRV-NOT: Bitcast
; CHECK-SPIRV: SubgroupBlockReadINTEL [[#Int32Ty]] [[#]] [[#GEP]]

; CHECK-LLVM: %[[#GEP:]] = getelementptr i32, ptr addrspace(1) %buffer, i32 0, !spirv.Decorations ![[#Cache:]]
; CHECK-LLVM: call spir_func i32 @_Z35__spirv_SubgroupBlockReadINTEL_RintPU3AS1Kj(ptr addrspace(1) %[[#GEP]])
; CHECK-LLVM: ![[#Cache]] = !{![[#LoadCache:]]}
; CHECK-LLVM: ![[#LoadCache]] = !{i32 6442, i32 0, i32 0}

target triple = "spir64-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %buffer, ptr addrspace(1) %out) {
entry:
  %v = call spir_func i32 @_Z29intel_sub_group_block_read_uiPU3AS1j(ptr addrspace(1) %buffer), !spirv.DecorationCacheControlINTEL !3
  store i32 %v, ptr addrspace(1) %out
  ret void
}

declare spir_func i32 @_Z29intel_sub_group_block_read_uiPU3AS1j(ptr addrspace(1))

!spirv.MemoryModel = !{!0}
!spirv.Source = !{!1}
!opencl.spir.version = !{!2}
!opencl.ocl.version = !{!2}

!0 = !{i32 2, i32 2}
!1 = !{i32 3, i32 102000}
!2 = !{i32 1, i32 2}
!3 = !{!4}
!4 = !{i32 6442, i32 0, i32 0, i32 0}
