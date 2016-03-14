; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.Node = type { %struct.Node addrspace(1)*, i32 }
; CHECK-SPIRV: TypeStruct [[RET:[0-9]+]] [[FWDID:[0-9]+]] {{[0-9]+}}
; CHECK-SPIRV: TypePointer [[FWDID]] [[RET]]

; CHECK-LLVM: %struct.Node = type { %struct.Node addrspace(1)*, i32 }

; Function Attrs: nounwind
define spir_kernel void @test(i32 addrspace(1)* %result, %struct.Node addrspace(1)* %node) #0 {
  ret void
}

attributes #0 = { nounwind "less-precise-fpmad"="true" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!7}
!opencl.ocl.version = !{!8}
!opencl.used.extensions = !{!9}
!opencl.used.optional.core.features = !{!9}
!opencl.compiler.options = !{!9}
!llvm.ident = !{!10}

!0 = !{void (i32 addrspace(1)*, %struct.Node addrspace(1)*)* @test, !1, !2, !3, !4, !5, !6}
!1 = !{!"kernel_arg_addr_space", i32 1, i32 1}
!2 = !{!"kernel_arg_access_qual", !"none", !"none"}
!3 = !{!"kernel_arg_type", !"uint*", !"struct Node*"}
!4 = !{!"kernel_arg_base_type", !"uint*", !"struct Node*"}
!5 = !{!"kernel_arg_type_qual", !"", !""}
!6 = !{!"kernel_arg_name", !"result", !"node"}
!7 = !{i32 1, i32 2}
!8 = !{i32 2, i32 0}
!9 = !{}
!10 = !{!"clang version 3.6.1 "}
