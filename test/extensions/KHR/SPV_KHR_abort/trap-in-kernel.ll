; Kernel function with assert-like trap pattern.
; Models the real-world HIP assert() use case:
;   kernel calls __assert_fail which calls llvm.trap.
;
; Verifies that OpAbortKHR works correctly inside callee functions
; invoked from kernel entry points.
;
; Note: The kernel's assert.fail block has FunctionCall + Unreachable
; (the unreachable is after the call, not after a trap — this is correct
; because the trap is inside the callee, not the caller).

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_KHR_abort -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; FIXME: enable the following run when the translator CI is updated to a new
; verion of the SPIR-V Tools that includes the support for the SPV_KHR_abort
; extension.
; RUN: not spirv-val %t.spv

; Round-trip
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; ---- SPIR-V ----
; CHECK-SPIRV-DAG: Capability AbortKHR
; CHECK-SPIRV-DAG: Extension "SPV_KHR_abort"
; CHECK-SPIRV-DAG: EntryPoint 6 {{[0-9]+}} "test_kernel"

; __assert_fail_internal: contains the trap → OpAbortKHR
; CHECK-SPIRV: Function
; CHECK-SPIRV: AbortKHR
; CHECK-SPIRV: FunctionEnd

; test_kernel: calls __assert_fail_internal, then unreachable (in caller)
; CHECK-SPIRV: Function
; CHECK-SPIRV: BranchConditional
; CHECK-SPIRV: Return
; CHECK-SPIRV: FunctionCall
; CHECK-SPIRV: Unreachable
; CHECK-SPIRV: FunctionEnd

; ---- Round-trip ----
; CHECK-LLVM: define spir_func void @__assert_fail_internal
; CHECK-LLVM: call spir_func void @{{.*__spirv_AbortKHR.*}}(i32 -1)
; CHECK-LLVM-NEXT: unreachable
;
; CHECK-LLVM: define spir_kernel void @test_kernel

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; Models __assert_fail from device libraries
define spir_func void @__assert_fail_internal() #0 {
entry:
  call void @llvm.trap()
  unreachable
}

; Kernel entry point with conditional assert
define spir_kernel void @test_kernel(ptr addrspace(1) %in, i32 %N) #1
  !kernel_arg_addr_space !1 !kernel_arg_access_qual !2
  !kernel_arg_type !3 !kernel_arg_base_type !3 !kernel_arg_type_qual !4 {
entry:
  %gid = call spir_func i64 @_Z13get_global_idj(i32 0)
  %gid32 = trunc i64 %gid to i32
  %cmp = icmp slt i32 %gid32, %N
  br i1 %cmp, label %ok, label %assert.fail

ok:
  ret void

assert.fail:
  call spir_func void @__assert_fail_internal()
  unreachable
}

declare spir_func i64 @_Z13get_global_idj(i32) #2
declare void @llvm.trap() #3

attributes #0 = { noinline noreturn nounwind }
attributes #1 = { nounwind }
attributes #2 = { nounwind }
attributes #3 = { cold noreturn nounwind }

!1 = !{i32 1, i32 0}
!2 = !{!"none", !"none"}
!3 = !{!"int*", !"int"}
!4 = !{!"", !""}
