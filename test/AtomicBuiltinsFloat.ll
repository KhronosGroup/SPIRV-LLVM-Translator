; Check that translator generate atomic instructions for atomic builtins
; FP-typed atomic_fetch_sub and atomic_fetch_sub_explicit should be translated
; to FunctionCall
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

; CHECK-LABEL: Label
; CHECK: Store
; CHECK-COUNT-3: AtomicStore
; CHECK-COUNT-3: AtomicLoad
; CHECK-COUNT-3: AtomicExchange
; CHECK-COUNT-3: FunctionCall

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: convergent nounwind
define spir_kernel void @test_atomic_kernel(float addrspace(3)* %ff) local_unnamed_addr #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 {
entry:
  %0 = addrspacecast float addrspace(3)* %ff to float addrspace(4)*
  tail call spir_func void @_Z11atomic_initPU3AS4VU7_Atomicff(float addrspace(4)* %0, float 1.000000e+00) #2
  tail call spir_func void @_Z12atomic_storePU3AS4VU7_Atomicff(float addrspace(4)* %0, float 1.000000e+00) #2
  tail call spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicff12memory_order(float addrspace(4)* %0, float 1.000000e+00, i32 0) #2
  tail call spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicff12memory_order12memory_scope(float addrspace(4)* %0, float 1.000000e+00, i32 0, i32 1) #2
  %call = tail call spir_func float @_Z11atomic_loadPU3AS4VU7_Atomicf(float addrspace(4)* %0) #2
  %call1 = tail call spir_func float @_Z20atomic_load_explicitPU3AS4VU7_Atomicf12memory_order(float addrspace(4)* %0, i32 0) #2
  %call2 = tail call spir_func float @_Z20atomic_load_explicitPU3AS4VU7_Atomicf12memory_order12memory_scope(float addrspace(4)* %0, i32 0, i32 1) #2
  %call3 = tail call spir_func float @_Z15atomic_exchangePU3AS4VU7_Atomicff(float addrspace(4)* %0, float 1.000000e+00) #2
  %call4 = tail call spir_func float @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicff12memory_order(float addrspace(4)* %0, float 1.000000e+00, i32 0) #2
  %call5 = tail call spir_func float @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicff12memory_order12memory_scope(float addrspace(4)* %0, float 1.000000e+00, i32 0, i32 1) #2
  %call6 = tail call spir_func float @_Z16atomic_fetch_subPU3AS3VU7_Atomicff(float addrspace(3)* %ff, float 1.000000e+00) #2
  %call7 = tail call spir_func float @_Z25atomic_fetch_sub_explicitPU3AS3VU7_Atomicff12memory_order(float addrspace(3)* %ff, float 1.000000e+00, i32 0) #2
  %call8 = tail call spir_func float @_Z25atomic_fetch_sub_explicitPU3AS3VU7_Atomicff12memory_order12memory_scope(float addrspace(3)* %ff, float 1.000000e+00, i32 0, i32 1) #2
  ret void
}

; Function Attrs: convergent
declare spir_func void @_Z11atomic_initPU3AS4VU7_Atomicff(float addrspace(4)*, float) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func void @_Z12atomic_storePU3AS4VU7_Atomicff(float addrspace(4)*, float) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicff12memory_order(float addrspace(4)*, float, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicff12memory_order12memory_scope(float addrspace(4)*, float, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func float @_Z11atomic_loadPU3AS4VU7_Atomicf(float addrspace(4)*) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func float @_Z20atomic_load_explicitPU3AS4VU7_Atomicf12memory_order(float addrspace(4)*, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func float @_Z20atomic_load_explicitPU3AS4VU7_Atomicf12memory_order12memory_scope(float addrspace(4)*, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func float @_Z15atomic_exchangePU3AS4VU7_Atomicff(float addrspace(4)*, float) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func float @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicff12memory_order(float addrspace(4)*, float, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func float @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicff12memory_order12memory_scope(float addrspace(4)*, float, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func float @_Z16atomic_fetch_subPU3AS3VU7_Atomicff(float addrspace(3)*, float) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func float @_Z25atomic_fetch_sub_explicitPU3AS3VU7_Atomicff12memory_order(float addrspace(3)*, float, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func float @_Z25atomic_fetch_sub_explicitPU3AS3VU7_Atomicff12memory_order12memory_scope(float addrspace(3)*, float, i32, i32) local_unnamed_addr #1

attributes #0 = { convergent nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { convergent "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { convergent nounwind }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 2, i32 0}
!2 = !{!"clang version 10.0.1 (8560093eba963fba2edd47ca85404cdaff22f174)"}
!3 = !{i32 3}
!4 = !{!"none"}
!5 = !{!"atomic_float*"}
!6 = !{!"_Atomic(float)*"}
!7 = !{!"volatile"}
