; ModuleID = 'atomics_1.2'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s

; Check the mangling of 1.2 atomic functions. This test expects what
; most of the built-ins are promoted to OpenCL C 2.0 atomics.
; Most of atomics lost information about the sign of the integer operand
; but since this concerns only built-ins  with two-complement's ariphmetics
; it shouldn't cause any problems.

; CHECK: _Z10atomic_incPVU3AS1i
; CHECK: _Z10atomic_incPVU3AS1i
; CHECK: _Z25atomic_fetch_max_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z25atomic_fetch_max_explicitPVU3AS1U7_Atomicjjii
; CHECK: _Z25atomic_fetch_min_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z25atomic_fetch_min_explicitPVU3AS1U7_Atomicjjii
; CHECK: _Z25atomic_fetch_add_explicitPVU3AS1U7_A
; CHECK: _Z25atomic_fetch_add_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z25atomic_fetch_sub_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z25atomic_fetch_sub_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z24atomic_fetch_or_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z24atomic_fetch_or_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z25atomic_fetch_xor_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z25atomic_fetch_xor_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z25atomic_fetch_and_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z25atomic_fetch_and_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z39atomic_compare_exchange_strong_explicitPVU3AS1U7
; CHECK: _Z39atomic_compare_exchange_strong_explicitPVU3AS1U7
; CHECK: _Z24atomic_exchange_explicitPVU3AS1U7_Atomiciiii
; CHECK: _Z24atomic_exchange_explicitPVU3AS1U7_Atomiciiii

; Function Attrs: nounwind
define spir_kernel void @test_atomic_global(i32 addrspace(1)* %dst) #0 {
  ; atomic_inc
  %inc_ig = tail call spir_func i32 @_Z10atomic_incPVU3AS1i(i32 addrspace(1)* %dst) #0
  %inc_jg = tail call spir_func i32 @_Z10atomic_incPVU3AS1j(i32 addrspace(1)* %dst) #0
  ; atomic_max
  %max_ig = tail call spir_func i32 @_Z10atomic_maxPVU3AS1ii(i32 addrspace(1)* %dst, i32 0) #0
  %max_jg = tail call spir_func i32 @_Z10atomic_maxPVU3AS1jj(i32 addrspace(1)* %dst, i32 0) #0
  ; atomic_min
  %min_ig = tail call spir_func i32 @_Z10atomic_minPVU3AS1ii(i32 addrspace(1)* %dst, i32 0) #0
  %min_jg = tail call spir_func i32 @_Z10atomic_minPVU3AS1jj(i32 addrspace(1)* %dst, i32 0) #0
  ; atomic_add
  %add_ig = tail call spir_func i32 @_Z10atomic_addPVU3AS1ii(i32 addrspace(1)* %dst, i32 1) #0
  %add_jg = tail call spir_func i32 @_Z10atomic_addPVU3AS1jj(i32 addrspace(1)* %dst, i32 1) #0
  ; atomic_sub
  %sub_ig = tail call spir_func i32 @_Z10atomic_subPVU3AS1ii(i32 addrspace(1)* %dst, i32 1) #0
  %sub_jg = tail call spir_func i32 @_Z10atomic_subPVU3AS1jj(i32 addrspace(1)* %dst, i32 1) #0
  ; atomic_or
  %or_ig = tail call spir_func i32 @_Z9atomic_orPVU3AS1ii(i32 addrspace(1)* %dst, i32 1) #0
  %or_jg = tail call spir_func i32 @_Z9atomic_orPVU3AS1jj(i32 addrspace(1)* %dst, i32 1) #0
  ; atomic_xor
  %xor_ig = tail call spir_func i32 @_Z10atomic_xorPVU3AS1ii(i32 addrspace(1)* %dst, i32 1) #0
  %xor_jg = tail call spir_func i32 @_Z10atomic_xorPVU3AS1jj(i32 addrspace(1)* %dst, i32 1) #0
  ; atomic_and
  %and_ig = tail call spir_func i32 @_Z10atomic_andPVU3AS1ii(i32 addrspace(1)* %dst, i32 1) #0
  %and_jg = tail call spir_func i32 @_Z10atomic_andPVU3AS1jj(i32 addrspace(1)* %dst, i32 1) #0
  ; atomic_cmpxchg
  %cmpxchg_ig = call spir_func i32 @_Z14atomic_cmpxchgPVU3AS1iii(i32 addrspace(1)* %dst, i32 0, i32 1) #0
  %cmpxchg_jg = call spir_func i32 @_Z14atomic_cmpxchgPVU3AS1jjj(i32 addrspace(1)* %dst, i32 0, i32 1) #0
  ; atomic_xchg
  %xchg_ig = call spir_func i32 @_Z11atomic_xchgPVU3AS1ii(i32 addrspace(1)* %dst, i32 1) #0
  %xchg_jg = call spir_func i32 @_Z11atomic_xchgPVU3AS1jj(i32 addrspace(1)* %dst, i32 1) #0
  ret void
}

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z10atomic_incPVU3AS1i(i32 addrspace(1)*)

declare spir_func i32 @_Z10atomic_incPVU3AS1j(i32 addrspace(1)*)

declare spir_func i32 @_Z10atomic_maxPVU3AS1ii(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_maxPVU3AS1jj(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_minPVU3AS1ii(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_minPVU3AS1jj(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_addPVU3AS1ii(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_addPVU3AS1jj(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_subPVU3AS1ii(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_subPVU3AS1jj(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z9atomic_orPVU3AS1ii(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z9atomic_orPVU3AS1jj(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_xorPVU3AS1ii(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_xorPVU3AS1jj(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_andPVU3AS1ii(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z10atomic_andPVU3AS1jj(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z14atomic_cmpxchgPVU3AS1iii(i32 addrspace(1)*, i32, i32)

declare spir_func i32 @_Z14atomic_cmpxchgPVU3AS1jjj(i32 addrspace(1)*, i32, i32)

declare spir_func i32 @_Z11atomic_xchgPVU3AS1ii(i32 addrspace(1)*, i32)

declare spir_func i32 @_Z11atomic_xchgPVU3AS1jj(i32 addrspace(1)*, i32)

; CHECK: _Z10atomic_incPVU3AS3i
; CHECK: _Z10atomic_incPVU3AS3i
; CHECK: _Z25atomic_fetch_max_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z25atomic_fetch_max_explicitPVU3AS3U7_Atomicjjii
; CHECK: _Z25atomic_fetch_min_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z25atomic_fetch_min_explicitPVU3AS3U7_Atomicjjii
; CHECK: _Z25atomic_fetch_add_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z25atomic_fetch_add_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z25atomic_fetch_sub_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z25atomic_fetch_sub_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z24atomic_fetch_or_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z24atomic_fetch_or_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z25atomic_fetch_xor_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z25atomic_fetch_xor_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z25atomic_fetch_and_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z25atomic_fetch_and_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z39atomic_compare_exchange_strong_explicitPVU3AS3U7
; CHECK: _Z39atomic_compare_exchange_strong_explicitPVU3AS3U7
; CHECK: _Z24atomic_exchange_explicitPVU3AS3U7_Atomiciiii
; CHECK: _Z24atomic_exchange_explicitPVU3AS3U7_Atomiciiii

; Function Attrs: nounwind
define spir_kernel void @test_atomic_local(i32 addrspace(3)* %dst) #0 {
  ; atomic_inc
  %inc_il = tail call spir_func i32 @_Z10atomic_incPVU3AS3i(i32 addrspace(3)* %dst) #0
  %inc_jl = tail call spir_func i32 @_Z10atomic_incPVU3AS3j(i32 addrspace(3)* %dst) #0
  ; atomic_max
  %max_il = tail call spir_func i32 @_Z10atomic_maxPVU3AS3ii(i32 addrspace(3)* %dst, i32 0) #0
  %max_jl = tail call spir_func i32 @_Z10atomic_maxPVU3AS3jj(i32 addrspace(3)* %dst, i32 0) #0
  ; atomic_min
    %min_il = tail call spir_func i32 @_Z10atomic_minPVU3AS3ii(i32 addrspace(3)* %dst, i32 0) #0
  %min_jl = tail call spir_func i32 @_Z10atomic_minPVU3AS3jj(i32 addrspace(3)* %dst, i32 0) #0
  ; atomic_add
  %add_il = tail call spir_func i32 @_Z10atomic_addPVU3AS3ii(i32 addrspace(3)* %dst, i32 1) #0
  %add_jl = tail call spir_func i32 @_Z10atomic_addPVU3AS3jj(i32 addrspace(3)* %dst, i32 1) #0
  ; atomic_sub
  %sub_il = tail call spir_func i32 @_Z10atomic_subPVU3AS3ii(i32 addrspace(3)* %dst, i32 1) #0
  %sub_jl = tail call spir_func i32 @_Z10atomic_subPVU3AS3jj(i32 addrspace(3)* %dst, i32 1) #0
  ; atomic_or
  %or_il = tail call spir_func i32 @_Z9atomic_orPVU3AS3ii(i32 addrspace(3)* %dst, i32 1) #0
  %or_jl = tail call spir_func i32 @_Z9atomic_orPVU3AS3jj(i32 addrspace(3)* %dst, i32 1) #0
  ; atomic_xor
  %xor_il = tail call spir_func i32 @_Z10atomic_xorPVU3AS3ii(i32 addrspace(3)* %dst, i32 1) #0
  %xor_jl = tail call spir_func i32 @_Z10atomic_xorPVU3AS3jj(i32 addrspace(3)* %dst, i32 1) #0
  ; atomic_and
  %and_il = tail call spir_func i32 @_Z10atomic_andPVU3AS3ii(i32 addrspace(3)* %dst, i32 1) #0
  %and_jl = tail call spir_func i32 @_Z10atomic_andPVU3AS3jj(i32 addrspace(3)* %dst, i32 1) #0
  ; atomic_cmpxchg
  %cmpxchg_il = call spir_func i32 @_Z14atomic_cmpxchgPVU3AS3iii(i32 addrspace(3)* %dst, i32 0, i32 1) #0
  %cmpxchg_jl = call spir_func i32 @_Z14atomic_cmpxchgPVU3AS3jjj(i32 addrspace(3)* %dst, i32 0, i32 1) #0
  ; atomic_xchg
  %xchg_il = call spir_func i32 @_Z11atomic_xchgPVU3AS3ii(i32 addrspace(3)* %dst, i32 1) #0
  %xchg_jl = call spir_func i32 @_Z11atomic_xchgPVU3AS3jj(i32 addrspace(3)* %dst, i32 1) #0
  ret void
}

; Function Attrs: nounwind readnone
declare spir_func i32 @_Z10atomic_incPVU3AS3i(i32 addrspace(3)*)

declare spir_func i32 @_Z10atomic_incPVU3AS3j(i32 addrspace(3)*)

declare spir_func i32 @_Z10atomic_maxPVU3AS3ii(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_maxPVU3AS3jj(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_minPVU3AS3ii(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_minPVU3AS3jj(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_addPVU3AS3ii(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_addPVU3AS3jj(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_subPVU3AS3ii(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_subPVU3AS3jj(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z9atomic_orPVU3AS3ii(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z9atomic_orPVU3AS3jj(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_xorPVU3AS3ii(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_xorPVU3AS3jj(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_andPVU3AS3ii(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z10atomic_andPVU3AS3jj(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z14atomic_cmpxchgPVU3AS3iii(i32 addrspace(3)*, i32, i32)

declare spir_func i32 @_Z14atomic_cmpxchgPVU3AS3jjj(i32 addrspace(3)*, i32, i32)

declare spir_func i32 @_Z11atomic_xchgPVU3AS3ii(i32 addrspace(3)*, i32)

declare spir_func i32 @_Z11atomic_xchgPVU3AS3jj(i32 addrspace(3)*, i32)

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone }

!opencl.kernels = !{!0, !10}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!7}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!9}

!0 = !{void (i32 addrspace(1)*)* @test_atomic_global, !1, !2, !3, !4, !5, !6}
!1 = !{!"kernel_arg_addr_space", i32 1}
!2 = !{!"kernel_arg_access_qual", !"none"}
!3 = !{!"kernel_arg_type", !"int*"}
!4 = !{!"kernel_arg_type_qual", !"volatile"}
!5 = !{!"kernel_arg_base_type", !"int*"}
!6 = !{!"kernel_arg_name", !"dst"}
!7 = !{i32 1, i32 2}
!8 = !{}
!9 = !{!"-cl-kernel-arg-info"}
!10 = !{void (i32 addrspace(3)*)* @test_atomic_local, !11, !2, !3, !4, !5, !6}
!11 = !{!"kernel_arg_addr_space", i32 1}
