; Translate SPIR-V friendly OpLoad and OpStore calls
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t
; RUN: FileCheck < %t %s
; RUN: llvm-spirv %t.bc -o %t.spv

; CHECK: TypeFloat [[#DOUBLE:]] 64
; CHECK: Load [[#DOUBLE]] [[#LOADED:]] [[#]]
; CHECK: Store [[#]] [[#LOADED]] 3 4

; ModuleID = 'before.bc'
source_filename = "test.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%"class.cl::sycl::range" = type { %"class.cl::sycl::detail::array" }
%"class.cl::sycl::detail::array" = type { [1 x i64] }
%"class.cl::sycl::id" = type { %"class.cl::sycl::detail::array" }

$_ZTSZZ4mainENKUlRT_E_clIN2cl4sycl7handlerEEEDaS0_EUlNS4_7nd_itemILi1EEEE_ = comdat any

@__spirv_BuiltInGlobalInvocationId = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32
@__spirv_BuiltInGlobalOffset = external dso_local local_unnamed_addr addrspace(1) constant <3 x i64>, align 32

; Function Attrs: convergent norecurse
define weak_odr dso_local spir_kernel void @_ZTSZZ4mainENKUlRT_E_clIN2cl4sycl7handlerEEEDaS0_EUlNS4_7nd_itemILi1EEEE_(double addrspace(1)* %_arg_) local_unnamed_addr #0 comdat {
entry:
  %0 = load <3 x i64>, <3 x i64> addrspace(4)* addrspacecast (<3 x i64> addrspace(1)* @__spirv_BuiltInGlobalInvocationId to <3 x i64> addrspace(4)*), align 32
  %1 = extractelement <3 x i64> %0, i64 0
  %2 = load <3 x i64>, <3 x i64> addrspace(4)* addrspacecast (<3 x i64> addrspace(1)* @__spirv_BuiltInGlobalOffset to <3 x i64> addrspace(4)*), align 32
  %3 = extractelement <3 x i64> %2, i64 0
  %sub.i.i.i.i = sub i64 %1, %3
  %cmp.i.i = icmp ult i64 %sub.i.i.i.i, 2147483648
  tail call void @llvm.assume(i1 %cmp.i.i)
  %add.ptr.i21 = getelementptr inbounds double, double addrspace(1)* %_arg_, i64 %sub.i.i.i.i
  %add.ptr.i = addrspacecast double addrspace(1)* %add.ptr.i21 to double addrspace(4)*
  %call2.i = tail call spir_func double @_Z12__spirv_LoadPd(double addrspace(4)* %add.ptr.i) #3
  %sub.i = sub nsw i64 1023, %sub.i.i.i.i
  %arrayidx.i22 = getelementptr inbounds double, double addrspace(1)* %_arg_, i64 %sub.i
  %arrayidx.i = addrspacecast double addrspace(1)* %arrayidx.i22 to double addrspace(4)*
  tail call spir_func void @_Z13__spirv_StorePddii(double addrspace(4)* %arrayidx.i, double %call2.i, i32 3, i32 4) #3
  ret void
}

; Function Attrs: convergent
declare dso_local spir_func double @_Z12__spirv_LoadPd(double addrspace(4)*) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func void @_Z13__spirv_StorePddii(double addrspace(4)*, double, i32, i32) local_unnamed_addr #1

; Function Attrs: inaccessiblememonly nofree nosync nounwind willreturn
declare void @llvm.assume(i1 noundef) #2

attributes #0 = { convergent norecurse "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="test.cpp" "uniform-work-group-size"="true" }
attributes #1 = { convergent "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { inaccessiblememonly nofree nosync nounwind willreturn }
attributes #3 = { convergent }

!llvm.module.flags = !{!0, !1}
!opencl.spir.version = !{!2}
!spirv.Source = !{!3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{i32 1, i32 2}
!3 = !{i32 4, i32 100000}
!4 = !{!"clang version 14.0.0 (https://github.com/intel/llvm.git)"}
