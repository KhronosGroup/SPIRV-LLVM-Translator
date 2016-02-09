; ModuleID = '/tmp/aelizuno/AtomicCompareExchange_cl20.ll'
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s

; Check 'LLVM ==> SPIR-V ==> LLVM' conversion of atomic_compare_exchange_strong and atomic_compare_exchange_weak.

; Function Attrs: nounwind

; CHECK:         define spir_func void @test
; CHECK-LABEL:   entry
; CHECK:         [[PTR_STRONG:%expected[0-9]*]] = alloca i32, align 4
; CHECK:         store i32 {{.*}}, i32* [[PTR_STRONG]]
; CHECK:         call spir_func i1 @_Z39atomic_compare_exchange_strong_explicit{{.*}}(i32 {{.*}}* %object, i32* [[PTR_STRONG]], i32 %desired, i32 4, i32 4, i32 2)
; CHECK:         load i32* [[PTR_STRONG]]

; CHECK:         [[PTR_WEAK:%expected[0-9]*]] = alloca i32, align 4
; CHECK:         store i32 {{.*}}, i32* [[PTR_WEAK]]
; CHECK:         call spir_func i1 @_Z37atomic_compare_exchange_weak_explicitPVU3AS4U7_AtomiciPiiiii{{.*}}(i32 {{.*}}* %object, i32* [[PTR_WEAK]], i32 %desired, i32 4, i32 4, i32 2)
; CHECK:         load i32* [[PTR_WEAK]]

; Function Attrs: nounwind
define spir_func void @test(i32 addrspace(4)* %object, i32 addrspace(4)* %expected, i32 %desired) #0 {
entry:
  %call = tail call spir_func zeroext i1 @_Z30atomic_compare_exchange_strongPVU3AS4U7_AtomiciPU3AS4ii(i32 addrspace(4)* %object, i32 addrspace(4)* %expected, i32 %desired) #2
  %call2 = tail call spir_func zeroext i1 @_Z28atomic_compare_exchange_weakPVU3AS4U7_AtomiciPU3AS4ii(i32 addrspace(4)* %object, i32 addrspace(4)* %expected, i32 %desired) #2
  ret void
}

declare spir_func zeroext i1 @_Z30atomic_compare_exchange_strongPVU3AS4U7_AtomiciPU3AS4ii(i32 addrspace(4)*, i32 addrspace(4)*, i32) #1

declare spir_func zeroext i1 @_Z28atomic_compare_exchange_weakPVU3AS4U7_AtomiciPU3AS4ii(i32 addrspace(4)*, i32 addrspace(4)*, i32) #1

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind }

!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!0}
!opencl.ocl.version = !{!1}
!opencl.used.extensions = !{!2}
!opencl.used.optional.core.features = !{!2}
!opencl.compiler.options = !{!2}

!0 = !{i32 1, i32 2}
!1 = !{i32 2, i32 0}
!2 = !{}
