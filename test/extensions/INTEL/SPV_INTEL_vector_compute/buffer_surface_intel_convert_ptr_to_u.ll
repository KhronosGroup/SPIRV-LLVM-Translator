; Reverse translation of OpConvertPtrToU with an OpTypeBufferSurfaceINTEL
; operand, with and without target extension types.
;
; transType() is called twice per SPIR-V type, with UseTPT=true for the mangled
; builtin name and with UseTPT=false for the type the value actually gets.
; OpTypeBufferSurfaceINTEL tested UseTPT before UseTargetTypes, so with target
; extension types enabled the two disagreed. The __spirv_ConvertPtrToU signature
; took a ptr addrspace(1) while the argument was a
; target("spirv.BufferSurfaceINTEL", 2), hitting "Calling a function with a bad
; signature!".

; RUN: llvm-as -opaque-pointers=0 %s -o %t.bc
; RUN: llvm-spirv %t.bc -opaque-pointers=0 -o %t.spv --spirv-ext=+SPV_INTEL_vector_compute --spirv-allow-unknown-intrinsics
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck %s --input-file %t.spt -check-prefix=SPV

; Opaque pointers: the surface is a target extension type, the conversion a call.
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc --spirv-target-env=SPV-IR -emit-opaque-pointers
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck %s --input-file %t.rev.ll -check-prefix=LLVM

; Typed pointers: the surface stays a pointer, the conversion a ptrtoint.
; RUN: llvm-spirv -r %t.spv -o %t.typed.bc --spirv-target-env=SPV-IR
; RUN: llvm-dis -opaque-pointers=0 %t.typed.bc -o %t.typed.ll
; RUN: FileCheck %s --input-file %t.typed.ll -check-prefix=LLVM-TYPED

; SPV-DAG: TypeInt [[INT:[0-9]+]] 32 0
; SPV-DAG: TypeBufferSurfaceINTEL {{[0-9]+}} 2{{(^|[^0-9])}}
; SPV: ConvertPtrToU [[INT]]

; LLVM: define spir_kernel void @test(target("spirv.BufferSurfaceINTEL", 2) %buf)
; LLVM-TYPED: define spir_kernel void @test(%intel.buffer_rw_t addrspace(1)* %buf)

target triple = "spir64"

%intel.buffer_rw_t = type opaque

declare void @llvm.some.unknown.intrinsic.i32(i32)

define spir_kernel void @test(%intel.buffer_rw_t addrspace(1)* %buf) #0 {
entry:
; LLVM: call spir_func i32 @_Z26__spirv_ConvertPtrToU_RintPU3AS129__spirv_BufferSurfaceINTEL__2(target("spirv.BufferSurfaceINTEL", 2) %buf)
; LLVM-TYPED: ptrtoint %intel.buffer_rw_t addrspace(1)* %buf to i32
  %0 = ptrtoint %intel.buffer_rw_t addrspace(1)* %buf to i32
  call void @llvm.some.unknown.intrinsic.i32(i32 %0)
  ret void
}

attributes #0 = { "VCFunction" }
