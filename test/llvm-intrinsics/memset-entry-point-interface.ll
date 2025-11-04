; Test for issue #3402: memset with constant value creates SPIRV variables
; that must be included in entry point interfaces for validation to pass.
; https://github.com/KhronosGroup/SPIRV-LLVM-Translator/issues/3402
;
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; Check that the constant array variable is included in the entry point interface
; CHECK-SPIRV: EntryPoint 6 [[#EntryPoint:]] "f" [[#MemsetVar:]]
; CHECK-SPIRV: TypeInt [[#Int8:]] 8 0
; CHECK-SPIRV: Constant [[#]] [[#ArrayLen:]] 1
; CHECK-SPIRV: TypeArray [[#Int8Array:]] [[#Int8]] [[#ArrayLen]]
; CHECK-SPIRV: Variable [[#]] [[#MemsetVar]] 0

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir64-unknown-unknown"

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #0

define spir_kernel void @f() {
conversion:
  call void @llvm.memset.p0.i64(ptr null, i8 0, i64 0, i1 false)
  %0 = add nsw i64 0, 0
  ret void
}

attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: write) }
