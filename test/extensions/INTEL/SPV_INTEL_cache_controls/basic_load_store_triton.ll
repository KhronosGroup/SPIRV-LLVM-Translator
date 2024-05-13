; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv --spirv-ext=+SPV_INTEL_cache_controls -spirv-text %t.bc -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv --spirv-ext=+SPV_INTEL_cache_controls %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv --spirv-target-env=SPV-IR -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: TypeInt [[#Int32:]] 32 0
; CHECK-SPIRV-DAG: Constant [[#Int32]] [[#Zero:]] 0
; CHECK-SPIRV-DAG: Decorate [[#Load1Ptr:]] CacheControlLoadINTEL 0 1
; CHECK-SPIRV-DAG: Decorate [[#Load2Ptr:]] CacheControlLoadINTEL 1 1
; CHECK-SPIRV-DAG: Decorate [[#Store1Ptr:]] CacheControlStoreINTEL 0 1
; CHECK-SPIRV-DAG: Decorate [[#Store2Ptr:]] CacheControlStoreINTEL 1 1

; CHECK-SPIRV: PtrAccessChain [[#]] [[#Load1GEPPtr:]] [[#]] [[#Zero]]
; CHECK-SPIRV: PtrAccessChain [[#]] [[#Load2GEPPtr:]] [[#]] [[#Zero]]
; CHECK-SPIRV: Bitcast [[#]] [[#Load1Ptr]] [[#Load1GEPPtr]]
; CHECK-SPIRV: Load [[#]] [[#]] [[#Load1Ptr]]
; CHECK-SPIRV: Bitcast [[#]] [[#Load2Ptr]] [[#Load2GEPPtr]]
; CHECK-SPIRV: Load [[#]] [[#]] [[#Load2Ptr]]
; CHECK-SPIRV: PtrAccessChain [[#]] [[#Store1GEPPtr:]] [[#]] [[#Zero]]
; CHECK-SPIRV: PtrAccessChain [[#]] [[#Store2GEPPtr:]] [[#]] [[#Zero]]
; CHECK-SPIRV: Bitcast [[#]] [[#Store1Ptr]] [[#Store1GEPPtr]]
; CHECK-SPIRV: Store [[#Store1Ptr]]
; CHECK-SPIRV: Bitcast [[#]] [[#Store2Ptr]] [[#Store2GEPPtr]]
; CHECK-SPIRV: Store [[#Store2Ptr]]

; CHECK-LLVM: %[[#GEPLoad1:]] = getelementptr ptr addrspace(1), ptr addrspace(1) %[[#]], i32 0
; CHECK-LLVM: %[[#GEPLoad2:]] = getelementptr ptr addrspace(1), ptr addrspace(1) %[[#]], i32 0
; CHECK-LLVM: %[[#LoadPtr1:]] = bitcast ptr addrspace(1) %[[#GEPLoad1]] to ptr addrspace(1), !spirv.Decorations ![[#Cache1:]]
; CHECK-LLVM: load i32, ptr addrspace(1) %[[#LoadPtr1]], align 4
; CHECK-LLVM: %[[#LoadPtr2:]] = bitcast ptr addrspace(1) %[[#GEPLoad2:]] to ptr addrspace(1), !spirv.Decorations ![[#Cache2:]]
; CHECK-LLVM: load i32, ptr addrspace(1) %[[#LoadPtr2]], align 4
; CHECK-LLVM: %[[#GEPStore1:]] = getelementptr ptr addrspace(1), ptr addrspace(1) %[[#]], i32 0
; CHECK-LLVM: %[[#GEPStore2:]] = getelementptr ptr addrspace(1), ptr addrspace(1) %[[#]], i32 0
; CHECK-LLVM: %[[#StorePtr1:]] = bitcast ptr addrspace(1) %[[#GEPStore1]] to ptr addrspace(1), !spirv.Decorations ![[#Cache3:]]
; CHECK-LLVM: store i32 %[[#]], ptr addrspace(1) %[[#StorePtr1]], align 4
; CHECK-LLVM: [[#StorePtr2:]] = bitcast ptr addrspace(1) %[[#GEPStore2]] to ptr addrspace(1), !spirv.Decorations ![[#Cache4:]]
; CHECK-LLVM: store i32 %[[#]], ptr addrspace(1) %[[#StorePtr2]], align 4
; CHECK-LLVM: ![[#Cache1]] = !{![[#DecLoad1:]]}
; CHECK-LLVM: ![[#DecLoad1]] = !{i32 6442, i32 0, i32 1}
; CHECK-LLVM: ![[#Cache2]] = !{![[#DecLoad2:]]}
; CHECK-LLVM: ![[#DecLoad2]] = !{i32 6442, i32 1, i32 1}
; CHECK-LLVM: ![[#Cache3:]] = !{![[#DecStore1:]]}
; CHECK-LLVM: ![[#DecStore1]] = !{i32 6443, i32 0, i32 1}
; CHECK-LLVM: ![[#Cache4:]] = !{![[#DecStore2:]]}
; CHECK-LLVM: ![[#DecStore2]] = !{i32 6443, i32 1, i32 1}

target triple = "spir64-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %buffer) {
entry:
  %arrayidx = getelementptr inbounds i32, ptr addrspace(1) %buffer, i64 1
  %arrayidx_ann_1 = call ptr addrspace(1) @__spirv_DecorationCacheControlLoadINTEL(ptr addrspace(1) %arrayidx, i32 0, i32 1)
  %arrayidx_ann_2 = call ptr addrspace(1) @__spirv_DecorationCacheControlLoadINTEL(ptr addrspace(1) %arrayidx, i32 1, i32 1)
  %0 = load i32, ptr addrspace(1) %arrayidx_ann_1, align 4
  %1 = load i32, ptr addrspace(1) %arrayidx_ann_2, align 4
  %arrayidx1 = getelementptr inbounds i32, ptr addrspace(1) %buffer, i64 0
  %arrayidx1_ann_1 = call ptr addrspace(1) @__spirv_DecorationCacheControlStoreINTEL(ptr addrspace(1) %arrayidx1, i32 0, i32 1)
  %arrayidx1_ann_2 = call ptr addrspace(1) @__spirv_DecorationCacheControlStoreINTEL(ptr addrspace(1) %arrayidx1, i32 1, i32 1)
  store i32 %0, ptr addrspace(1) %arrayidx1_ann_1, align 4
  store i32 %1, ptr addrspace(1) %arrayidx1_ann_2, align 4
  ret void
}

declare ptr @__spirv_DecorationCacheControlLoadINTEL(ptr addrspace(1), i32, i32)

declare ptr @__spirv_DecorationCacheControlStoreINTEL(ptr addrspace(1), i32, i32)

!spirv.MemoryModel = !{!0}
!spirv.Source = !{!1}
!opencl.spir.version = !{!2}
!opencl.ocl.version = !{!2}

!0 = !{i32 2, i32 2}
!1 = !{i32 3, i32 102000}
!2 = !{i32 1, i32 2}
