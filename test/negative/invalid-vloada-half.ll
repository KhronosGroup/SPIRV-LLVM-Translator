; RUN: llvm-as %s -o %t.bc
; RUN: not llvm-spirv %t.bc -o %t.spv 2>&1 | FileCheck %s

; CHECK: InvalidModule: Invalid SPIR-V module: vloada_half should be of a half vector type

; ModuleID = 'loada.bc'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024"
target triple = "spir64-unknown-unknown"

; Function Attrs: noinline nounwind
define spir_kernel void @test(half addrspace(1)* readonly %p, float addrspace(1)* %f) #0 {
entry:
  %p.addr = alloca half addrspace(1)*, align 8
  %f.addr = alloca float addrspace(1)*, align 8
  %i = alloca i64, align 8
  store half addrspace(1)* %p, half addrspace(1)** %p.addr, align 8
  store float addrspace(1)* %f, float addrspace(1)** %f.addr, align 8
  %0 = call spir_func i64 @_Z13get_global_idj(i32 0) #1
  %1 = insertelement <3 x i64> undef, i64 %0, i32 0
  %2 = call spir_func i64 @_Z13get_global_idj(i32 1) #1
  %3 = insertelement <3 x i64> %1, i64 %2, i32 1
  %4 = call spir_func i64 @_Z13get_global_idj(i32 2) #1
  %5 = insertelement <3 x i64> %3, i64 %4, i32 2
  %call = extractelement <3 x i64> %5, i32 0
  store i64 %call, i64* %i, align 8
  %6 = load i64, i64* %i, align 8
  %7 = load half addrspace(1)*, half addrspace(1)** %p.addr, align 8
  %8 = addrspacecast half addrspace(1)* %7 to half addrspace(4)*
  %call1 = call spir_func float @_Z12vloada_half1mPU3AS4KDh(i64 %6, half addrspace(4)* %8) #2
  %9 = load float addrspace(1)*, float addrspace(1)** %f.addr, align 8
  %10 = load i64, i64* %i, align 8
  %arrayidx = getelementptr inbounds float, float addrspace(1)* %9, i64 %10
  store float %call1, float addrspace(1)* %arrayidx, align 4
  ret void
}

; Function Attrs: nounwind readnone willreturn
declare spir_func i64 @_Z13get_global_idj(i32) #1

; Function Attrs: nounwind
declare spir_func float @_Z12vloada_half1mPU3AS4KDh(i64, half addrspace(4)*) #2

attributes #0 = { noinline nounwind }
attributes #1 = { nounwind readnone willreturn }
attributes #2 = { nounwind }

!spirv.MemoryModel = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!spirv.Source = !{!1}
!opencl.spir.version = !{!2}
!opencl.ocl.version = !{!3}
!opencl.used.extensions = !{!4}
!opencl.used.optional.core.features = !{!4}
!spirv.Generator = !{!5}

!0 = !{i32 2, i32 2}
!1 = !{i32 3, i32 300000}
!2 = !{i32 2, i32 0}
!3 = !{i32 3, i32 0}
!4 = !{}
!5 = !{i16 6, i16 14}
