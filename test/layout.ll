; RUN: llvm-as < %s | llvm-spirv -spirv-text -o %t
; RUN: FileCheck < %t %s

; CHECK: 119734787 {{[0-9]*}} {{[0-9]*}} {{[0-9]*}} 0
; CHECK-NEXT: {{[0-9]*}} Capability
; CHECK-NEXT: {{[0-9]*}} ExtInstImport
; CHECK-NEXT: {{[0-9]*}} MemoryModel
; CHECK-NEXT: {{[0-9]*}} EntryPoint
; CHECK-NEXT: {{[0-9]*}} Source

; CHECK-NOT: {{[0-9]*}} Capability
; CHECK-NOT: {{[0-9]*}} ExtInstImport
; CHECK-NOT: {{[0-9]*}} MemoryModel
; CHECK-NOT: {{[0-9]*}} EntryPoint
; CHECK-NOT: {{[0-9]*}} Source
; CHECK-NOT: {{[0-9]*}} Decorate
; CHECK-NOT: {{[0-9]*}} Type
; CHECK-NOT: {{[0-9]*}} Variable
; CHECK-NOT: {{[0-9]*}} Function

; CHECK: {{[0-9]*}} Name

; CHECK-NOT: {{[0-9]*}} Capability
; CHECK-NOT: {{[0-9]*}} ExtInstImport
; CHECK-NOT: {{[0-9]*}} MemoryModel
; CHECK-NOT: {{[0-9]*}} EntryPoint
; CHECK-NOT: {{[0-9]*}} Source
; CHECK-NOT: {{[0-9]*}} Type
; CHECK-NOT: {{[0-9]*}} Variable
; CHECK-NOT: {{[0-9]*}} Function

; CHECK: {{[0-9]*}} Decorate

; CHECK-NOT: {{[0-9]*}} Capability
; CHECK-NOT: {{[0-9]*}} ExtInstImport
; CHECK-NOT: {{[0-9]*}} MemoryModel
; CHECK-NOT: {{[0-9]*}} EntryPoint
; CHECK-NOT: {{[0-9]*}} Source
; CHECK-NOT: {{[0-9]*}} Name
; CHECK-NOT: {{[0-9]*}} Variable
; CHECK-NOT: {{[0-9]*}} Function

; CHECK-DAG: {{[0-9]*}} TypeInt
; CHECK-DAG: {{[0-9]*}} TypeVector
; CHECK-DAG: {{[0-9]*}} TypePointer
; CHECK-DAG: {{[0-9]*}} TypeVoid
; CHECK-DAG: {{[0-9]*}} TypeFunction

; CHECK-NOT: {{[0-9]*}} Capability
; CHECK-NOT: {{[0-9]*}} ExtInstImport
; CHECK-NOT: {{[0-9]*}} MemoryModel
; CHECK-NOT: {{[0-9]*}} EntryPoint
; CHECK-NOT: {{[0-9]*}} Source
; CHECK-NOT: {{[0-9]*}} Name
; CHECK-NOT: {{[0-9]*}} Decorate

; CHECK: {{[0-9]*}} Variable

; CHECK-NOT: {{[0-9]*}} Capability
; CHECK-NOT: {{[0-9]*}} ExtInstImport
; CHECK-NOT: {{[0-9]*}} MemoryModel
; CHECK-NOT: {{[0-9]*}} EntryPoint
; CHECK-NOT: {{[0-9]*}} Source
; CHECK-NOT: {{[0-9]*}} Name
; CHECK-NOT: {{[0-9]*}} Type
; CHECK-NOT: {{[0-9]*}} Decorate

; CHECK: {{[0-9]*}} Function
; CHECK: {{[0-9]*}} FunctionParameter
; CHECK-NOT: {{[0-9]*}} Return
; CHECK: {{[0-9]*}} FunctionEnd

; CHECK-NOT: {{[0-9]*}} Capability
; CHECK-NOT: {{[0-9]*}} ExtInstImport
; CHECK-NOT: {{[0-9]*}} MemoryModel
; CHECK-NOT: {{[0-9]*}} EntryPoint
; CHECK-NOT: {{[0-9]*}} Source
; CHECK-NOT: {{[0-9]*}} Name
; CHECK-NOT: {{[0-9]*}} Type
; CHECK-NOT: {{[0-9]*}} Decorate
; CHECK-NOT: {{[0-9]*}} Variable

; CHECK: {{[0-9]*}} Function
; CHECK: {{[0-9]*}} FunctionParameter
; CHECK: {{[0-9]*}} FunctionParameter
; CHECK-NOT: {{[0-9]*}} Return
; CHECK: {{[0-9]*}} FunctionEnd

; CHECK-NOT: {{[0-9]*}} Capability
; CHECK-NOT: {{[0-9]*}} ExtInstImport
; CHECK-NOT: {{[0-9]*}} MemoryModel
; CHECK-NOT: {{[0-9]*}} EntryPoint
; CHECK-NOT: {{[0-9]*}} Source
; CHECK-NOT: {{[0-9]*}} Name
; CHECK-NOT: {{[0-9]*}} Type
; CHECK-NOT: {{[0-9]*}} Decorate
; CHECK-NOT: {{[0-9]*}} Variable

; CHECK: {{[0-9]*}} Function
; CHECK: {{[0-9]*}} FunctionParameter
; CHECK: {{[0-9]*}} Label
; CHECK: {{[0-9]*}} FunctionCall
; CHECK: {{[0-9]*}} FunctionCall
; CHECK: {{[0-9]*}} Return
; CHECK: {{[0-9]*}} FunctionEnd

; CHECK-NOT: {{[0-9]*}} Capability
; CHECK-NOT: {{[0-9]*}} ExtInstImport
; CHECK-NOT: {{[0-9]*}} MemoryModel
; CHECK-NOT: {{[0-9]*}} EntryPoint
; CHECK-NOT: {{[0-9]*}} Source
; CHECK-NOT: {{[0-9]*}} Name
; CHECK-NOT: {{[0-9]*}} Type
; CHECK-NOT: {{[0-9]*}} Decorate
; CHECK-NOT: {{[0-9]*}} Variable

; ModuleID = 'layout.bc'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

@b = external addrspace(2) global <3 x i32>

; Function Attrs: nounwind
define spir_kernel void @foo(<3 x i32> addrspace(1)* %a) #0 {
entry:
  tail call spir_func void @bar1(<3 x i32> addrspace(1)* %a) #2
  %loadVec4 = load <4 x i32> addrspace(2)* bitcast (<3 x i32> addrspace(2)* @b to <4 x i32> addrspace(2)*), align 16
  %extractVec = shufflevector <4 x i32> %loadVec4, <4 x i32> undef, <3 x i32> <i32 0, i32 1, i32 2>
  tail call spir_func void @bar2(<3 x i32> addrspace(1)* %a, <3 x i32> %extractVec) #2
  ret void
}

declare spir_func void @bar1(<3 x i32> addrspace(1)*) #1

declare spir_func void @bar2(<3 x i32> addrspace(1)*, <3 x i32>) #1

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!6}
!opencl.used.extensions = !{!7}
!opencl.used.optional.core.features = !{!7}
!opencl.compiler.options = !{!7}
!llvm.ident = !{!8}

!0 = !{void (<3 x i32> addrspace(1)*)* @foo, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space", i32 1}
!2 = !{!"kernel_arg_access_qual", !"none"}
!3 = !{!"kernel_arg_type", !"int3*"}
!4 = !{!"kernel_arg_type_qual", !""}
!5 = !{!"kernel_arg_base_type", !"int3*"}
!6 = !{i32 2, i32 0}
!7 = !{}
!8 = !{!"clang version 3.4 "}
