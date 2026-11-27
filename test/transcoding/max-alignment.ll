; LLVM IR allows alignments up to 2^32, but SPIR-V encodes memory access
; alignments as 32-bit literals. Check that they are clamped to 2^31 instead of
; truncated to 0. InferAlignment gives accesses of null that alignment.

; Textual IR, because the bitcode reader drops align 4294967296 attributes.
; RUN: llvm-spirv %s --spirv-ext=+SPV_INTEL_masked_gather_scatter -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.spv -to-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; Only the temporary of @memmove is decorated.
; CHECK-SPIRV: Decorate [[#TMP:]] Alignment 2147483648
; CHECK-SPIRV-NOT: Alignment

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV: Load [[#]] [[#]] [[#]] 2 2147483648
; CHECK-SPIRV: Store [[#]] [[#]] 2 2147483648
; CHECK-LLVM: load float, ptr null, align 2147483648
; CHECK-LLVM: store float %{{.*}}, ptr null, align 2147483648
define spir_func void @scalar() {
  %v = load float, ptr null, align 4294967296
  store float %v, ptr null, align 4294967296
  ret void
}

; CHECK-SPIRV: CopyMemorySized [[#]] [[#]] [[#]] 2 2147483648
; CHECK-SPIRV: CopyMemorySized [[#]] [[#]] [[#]] 2 2147483648 2 4
; CHECK-LLVM: call void @llvm.memcpy.p1.p1.i64(ptr addrspace(1) align 2147483648 %{{.*}}, ptr addrspace(1) align 2147483648 %{{.*}}, i64 %n, i1 false)
; CHECK-LLVM: call void @llvm.memcpy.p1.p1.i64(ptr addrspace(1) align 2147483648 %{{.*}}, ptr addrspace(1) align 4 %{{.*}}, i64 %n, i1 false)
define spir_func void @memcpy(ptr addrspace(1) %dst, ptr addrspace(1) %src, i64 %n) {
  call void @llvm.memcpy.p1.p1.i64(ptr addrspace(1) align 4294967296 %dst, ptr addrspace(1) align 4294967296 %src, i64 %n, i1 false)
  call void @llvm.memcpy.p1.p1.i64(ptr addrspace(1) align 4294967296 %dst, ptr addrspace(1) align 4 %src, i64 %n, i1 false)
  ret void
}

; The temporary that memmove is lowered to is aligned to 2^31, as accessed.
; CHECK-SPIRV: Variable [[#]] [[#TMP]] 7
; CHECK-SPIRV: CopyMemorySized [[#TMP]] [[#]] [[#]] 2 2147483648
; CHECK-SPIRV: CopyMemorySized [[#]] [[#TMP]] [[#]] 2 2147483648
define spir_func void @memmove(ptr addrspace(1) %dst, ptr addrspace(1) %src) {
  call void @llvm.memmove.p1.p1.i64(ptr addrspace(1) align 4294967296 %dst, ptr addrspace(1) align 4294967296 %src, i64 16, i1 false)
  ret void
}

; CHECK-SPIRV: MaskedGatherINTEL [[#]] [[#]] [[#]] 2147483648
; CHECK-SPIRV: MaskedScatterINTEL [[#]] [[#]] 2147483648
; CHECK-LLVM: call <2 x i32> @llvm.masked.gather.v2i32.v2p1(<2 x ptr addrspace(1)> align 2147483648 %{{.*}}
; CHECK-LLVM: call void @llvm.masked.scatter.v2i32.v2p1(<2 x i32> %{{.*}}, <2 x ptr addrspace(1)> align 2147483648 %{{.*}}
define spir_func void @gather_scatter(<2 x ptr addrspace(1)> %p, <2 x i1> %m) {
  %v = call <2 x i32> @llvm.masked.gather.v2i32.v2p1(<2 x ptr addrspace(1)> align 4294967296 %p, <2 x i1> %m, <2 x i32> zeroinitializer)
  call void @llvm.masked.scatter.v2i32.v2p1(<2 x i32> %v, <2 x ptr addrspace(1)> align 4294967296 %p, <2 x i1> %m)
  ret void
}
