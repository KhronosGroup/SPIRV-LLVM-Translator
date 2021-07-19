; It is assumed that the test will not fail

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc

; ModuleID = 'lower-non-standard-types'
source_filename = "lower-non-standard-types.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown-sycldevice"

%"simd" = type { <8 x float> }

@__spirv_BuiltInGlobalInvocationId = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32

; Function Attrs: convergent norecurse
define dso_local spir_func void @vmult2(%"simd"* %a) local_unnamed_addr #0 !sycl_explicit_simd !4 !intel_reqd_sub_group_size !6 {
entry:
  %ref.tmp.i.i = alloca %"simd", align 32
  %ref.tmp.i = alloca %"simd", align 32
  %a.ascast = addrspacecast %"simd"* %a to %"simd" addrspace(4)*
  %0 = load <6 x i32>, <6 x i32> addrspace(4)* addrspacecast (<6 x i32> addrspace(1)* bitcast (<3 x i64> addrspace(1)* @__spirv_BuiltInGlobalInvocationId to <6 x i32> addrspace(1)*) to <6 x i32> addrspace(4)*), align 32
  %conv = extractelement <6 x i32> %0, i32 4
  %conv1 = sitofp i32 %conv to float
  ret void
}

attributes #0 = { convergent norecurse "frame-pointer"="all" "min-legal-vector-width"="256" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="lower-external-funcs-with-z.cpp" }

!llvm.module.flags = !{!0, !1}
!opencl.spir.version = !{!2}
!spirv.Source = !{!3}
!opencl.used.extensions = !{!4}
!opencl.used.optional.core.features = !{!4}
!opencl.compiler.options = !{!4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{i32 1, i32 2}
!3 = !{i32 0, i32 100000}
!4 = !{}
!5 = !{!"Compiler"}
!6 = !{i32 1}
