; Test that addrspacecast for CodeSectionINTEL (addrspace 9) does not
; produce an error when SPV_INTEL_function_pointers is enabled.

; RUN: llvm-spirv %s -spirv-ext=+SPV_INTEL_function_pointers -spirv-emit-function-ptr-addr-space -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s

; CHECK: Bitcast {{[0-9]+}} [[#]] [[#]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir64-unknown-unknown"

define spir_func float @cosf(float %x) addrspace(9) #0 {
entry:
  ret float %x
}

define spir_kernel void @test(ptr addrspace(1) %out) #0 {
entry:
  %fp = addrspacecast ptr addrspace(9) @cosf to ptr
  store ptr %fp, ptr addrspace(1) %out, align 8
  ret void
}

attributes #0 = { noinline nounwind }

!spirv.MemoryModel = !{!0}
!spirv.Source = !{!1}
!opencl.spir.version = !{!2}
!opencl.ocl.version = !{!3}
!opencl.used.extensions = !{!4}
!opencl.used.optional.core.features = !{!4}
!spirv.Generator = !{!5}

!0 = !{i32 2, i32 2}
!1 = !{i32 3, i32 100000}
!2 = !{i32 1, i32 2}
!3 = !{i32 1, i32 0}
!4 = !{}
!5 = !{i16 6, i16 14}
