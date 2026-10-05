; Test that memset is lowered to a single OpStore of a composite constant.
; A non-zero fill value must write the byte values at the destination offset and
; preserve the volatile and alignment memory access flags, without creating a
; function-scope temporary to copy from.
;
; The pointer the composite is stored through must also keep the storage class
; of the translated destination. For the global_device/global_host address
; spaces that means honoring the lowering to the global address space that
; happens when SPV_INTEL_usm_storage_classes is not enabled, otherwise the
; module ends up with a USMStorageClassesINTEL capability it never declared an
; extension for, and with an OpBitcast that changes storage class.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV --implicit-check-not=Variable --implicit-check-not=CopyMemorySized --implicit-check-not="Capability USMStorageClassesINTEL"
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM
; RUN: llvm-spirv %t.bc -o %t.untyped.spv --spirv-ext=+SPV_KHR_untyped_pointers
; RUN: spirv-val %t.untyped.spv
; RUN: llvm-spirv %t.bc -spirv-text -o - --spirv-ext=+SPV_KHR_untyped_pointers | FileCheck %s --check-prefix=CHECK-SPIRV-UNTYPED
; No spirv-val for the run below: the translator does not emit the matching
; OpExtension, which is a pre-existing issue unrelated to memset.
; RUN: llvm-spirv %t.bc -spirv-text -o - --spirv-ext=+SPV_INTEL_usm_storage_classes | FileCheck %s --check-prefix=CHECK-SPIRV-USM

; Without SPV_INTEL_usm_storage_classes both USM address spaces are lowered to
; CrossWorkgroup (storage class 5), so all three kernels share one destination
; pointer type, and fill_device and fill_host share one store pointer type.
; CHECK-SPIRV: TypeInt [[#ByteTy:]] 8 0
; CHECK-SPIRV: Constant [[#]] [[#Length:]] 3
; CHECK-SPIRV: Constant [[#ByteTy]] [[#Byte:]] 42
; CHECK-SPIRV: TypePointer [[#BytePtrTy:]] 5 [[#ByteTy]]
; CHECK-SPIRV: TypeArray [[#ArrayTy:]] [[#ByteTy]] [[#Length]]
; CHECK-SPIRV: TypePointer [[#StorePtrTy:]] 5 [[#ArrayTy]]
; CHECK-SPIRV: TypeArray [[#UsmArrayTy:]] [[#ByteTy]] [[#]]
; CHECK-SPIRV: TypePointer [[#UsmStorePtrTy:]] 5 [[#UsmArrayTy]]
; CHECK-SPIRV: ConstantComposite [[#ArrayTy]] [[#Init:]] [[#Byte]] [[#Byte]] [[#Byte]]
; CHECK-SPIRV: ConstantNull [[#UsmArrayTy]] [[#DeviceInit:]]
; CHECK-SPIRV: ConstantNull [[#UsmArrayTy]] [[#HostInit:]]

; CHECK-SPIRV: FunctionParameter [[#BytePtrTy]] [[#Base:]]
; CHECK-SPIRV: PtrAccessChain [[#BytePtrTy]] [[#OffsetPtr:]] [[#Base]] [[#]]
; CHECK-SPIRV: Bitcast [[#StorePtrTy]] [[#ArrayPtr:]] [[#OffsetPtr]]
; CHECK-SPIRV: Store [[#ArrayPtr]] [[#Init]] 3 1

; CHECK-SPIRV: FunctionParameter [[#BytePtrTy]] [[#Device:]]
; CHECK-SPIRV: Bitcast [[#UsmStorePtrTy]] [[#DeviceStorePtr:]] [[#Device]]
; CHECK-SPIRV: Store [[#DeviceStorePtr]] [[#DeviceInit]] 2 4

; CHECK-SPIRV: FunctionParameter [[#BytePtrTy]] [[#Host:]]
; CHECK-SPIRV: Bitcast [[#UsmStorePtrTy]] [[#HostStorePtr:]] [[#Host]]
; CHECK-SPIRV: Store [[#HostStorePtr]] [[#HostInit]] 2 4

; CHECK-LLVM: %[[Dest:[a-zA-Z0-9.]+]] = getelementptr i8, ptr addrspace(1) %base, i64 1
; CHECK-LLVM: %[[#StorePtr:]] = bitcast ptr addrspace(1) %[[Dest]] to ptr addrspace(1)
; CHECK-LLVM: store volatile [3 x i8] c"***", ptr addrspace(1) %[[#StorePtr]], align 1

; Pointers to arrays stay typed under SPV_KHR_untyped_pointers, so the store
; keeps the same shape there.
; CHECK-SPIRV-UNTYPED: TypeUntypedPointerKHR [[#BytePtrTyU:]] 5
; CHECK-SPIRV-UNTYPED: TypeArray [[#ArrayTyU:]] [[#]] [[#]]
; CHECK-SPIRV-UNTYPED: TypePointer [[#StorePtrTyU:]] 5 [[#ArrayTyU]]
; CHECK-SPIRV-UNTYPED: ConstantComposite [[#ArrayTyU]] [[#InitU:]] [[#]] [[#]] [[#]]
; CHECK-SPIRV-UNTYPED: FunctionParameter [[#BytePtrTyU]] [[#BaseU:]]
; CHECK-SPIRV-UNTYPED: UntypedPtrAccessChainKHR [[#BytePtrTyU]] [[#OffsetPtrU:]] [[#]] [[#BaseU]] [[#]]
; CHECK-SPIRV-UNTYPED: Bitcast [[#StorePtrTyU]] [[#ArrayPtrU:]] [[#OffsetPtrU]]
; CHECK-SPIRV-UNTYPED: Store [[#ArrayPtrU]] [[#InitU]] 3 1

; With SPV_INTEL_usm_storage_classes enabled each destination keeps its own
; storage class, DeviceOnlyINTEL (5936) and HostOnlyINTEL (5937), and so does
; its store pointer.
; CHECK-SPIRV-USM: TypePointer [[#DeviceBytePtrTy:]] 5936 [[#]]
; CHECK-SPIRV-USM: TypeArray [[#UsmArrayTyE:]] [[#]] [[#]]
; CHECK-SPIRV-USM: TypePointer [[#DeviceStorePtrTy:]] 5936 [[#UsmArrayTyE]]
; CHECK-SPIRV-USM: TypePointer [[#HostBytePtrTy:]] 5937 [[#]]
; CHECK-SPIRV-USM: TypePointer [[#HostStorePtrTy:]] 5937 [[#UsmArrayTyE]]
; CHECK-SPIRV-USM: FunctionParameter [[#DeviceBytePtrTy]] [[#DeviceE:]]
; CHECK-SPIRV-USM: Bitcast [[#DeviceStorePtrTy]] [[#DeviceStorePtrE:]] [[#DeviceE]]
; CHECK-SPIRV-USM: Store [[#DeviceStorePtrE]] [[#]] 2 4
; CHECK-SPIRV-USM: FunctionParameter [[#HostBytePtrTy]] [[#HostE:]]
; CHECK-SPIRV-USM: Bitcast [[#HostStorePtrTy]] [[#HostStorePtrE:]] [[#HostE]]
; CHECK-SPIRV-USM: Store [[#HostStorePtrE]] [[#]] 2 4

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @fill(ptr addrspace(1) %base) {
entry:
  %dst = getelementptr i8, ptr addrspace(1) %base, i64 1
  call void @llvm.memset.p1.i64(ptr addrspace(1) align 1 %dst, i8 42, i64 3, i1 true)
  ret void
}

define spir_kernel void @fill_device(ptr addrspace(5) %dst) {
entry:
  call void @llvm.memset.p5.i64(ptr addrspace(5) align 4 %dst, i8 0, i64 8, i1 false)
  ret void
}

define spir_kernel void @fill_host(ptr addrspace(6) %dst) {
entry:
  call void @llvm.memset.p6.i64(ptr addrspace(6) align 4 %dst, i8 0, i64 8, i1 false)
  ret void
}

declare void @llvm.memset.p1.i64(ptr addrspace(1), i8, i64, i1 immarg)
declare void @llvm.memset.p5.i64(ptr addrspace(5), i8, i64, i1 immarg)
declare void @llvm.memset.p6.i64(ptr addrspace(6), i8, i64, i1 immarg)
