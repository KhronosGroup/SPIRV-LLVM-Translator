; RUN: llvm-as < %s > %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s --check-prefix=SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=BACK-TO-LLVM

; ModuleID = 'c:/work/tmp/testLink.c'
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; SPIRV: EntryPoint 6 [[kern:[0-9]+]] "kern"

@i1 = addrspace(1) global i32 1, align 4
; SPIRV: Name [[i1:[0-9]+]] "i1"
; BACK-TO-LLVM: @i1 = addrspace(1) global i32 1, align 4

@i2 = internal addrspace(1) global i32 2, align 4
; SPIRV: Name [[i2:[0-9]+]] "i2"
; BACK-TO-LLVM: @i2 = internal addrspace(1) global i32 2, align 4

@i3 = addrspace(1) global i32 3, align 4
; SPIRV: Name [[i3:[0-9]+]] "i3"
; BACK-TO-LLVM: @i3 = addrspace(1) global i32 3, align 4

@i4 = common addrspace(1) global i32 0, align 4
; SPIRV: Name [[i4:[0-9]+]] "i4"
; BACK-TO-LLVM: @i4 = addrspace(1) global i32 0, align 4
; "common" is lost in translation

@i5 = internal addrspace(1) global i32 0, align 4
; SPIRV: Name [[i5:[0-9]+]] "i5"
; BACK-TO-LLVM: @i5 = internal addrspace(1) global i32 0, align 4

@color_table = addrspace(2) constant [2 x i32] [i32 0, i32 1], align 4
; SPIRV: Name [[color_table:[0-9]+]] "color_table"
; BACK-TO-LLVM: @color_table = addrspace(2) constant [2 x i32] [i32 0, i32 1], align 4

@noise_table = external addrspace(2) constant [256 x i32]
; SPIRV: Name [[noise_table:[0-9]+]] "noise_table"
; BACK-TO-LLVM: @noise_table = external addrspace(2) constant [256 x i32]

@w = addrspace(1) constant i32 0, align 4
; SPIRV: Name [[w:[0-9]+]] "w"
; BACK-TO-LLVM: @w = addrspace(1) constant i32 0, align 4

@f.color_table = internal addrspace(2) constant [2 x i32] [i32 2, i32 3], align 4
; SPIRV: Name [[f_color_table:[0-9]+]] "f.color_table"
; BACK-TO-LLVM: @f.color_table = internal addrspace(2) constant [2 x i32] [i32 2, i32 3], align 4

@e = external addrspace(1) global i32
; SPIRV: Name [[e:[0-9]+]] "e"
; BACK-TO-LLVM: @e = external addrspace(1) global i32

@f.t = internal addrspace(1) global i32 5, align 4
; SPIRV: Name [[f_t:[0-9]+]] "f.t"
; BACK-TO-LLVM: @f.t = internal addrspace(1) global i32 5, align 4

@f.stint = internal addrspace(1) global i32 0, align 4
; SPIRV: Name [[f_stint:[0-9]+]] "f.stint"
; BACK-TO-LLVM: @f.stint = internal addrspace(1) global i32 0, align 4

@f.inside = internal addrspace(1) global i32 0, align 4
; SPIRV: Name [[f_inside:[0-9]+]] "f.inside"
; BACK-TO-LLVM: @f.inside = internal addrspace(1) global i32 0, align 4

@f.b = internal addrspace(2) constant float 1.000000e+00, align 4
; SPIRV: Name [[f_b:[0-9]+]] "f.b"
; BACK-TO-LLVM: @f.b = internal addrspace(2) constant float 1.000000e+00, align 4

; SPIRV: Name [[f:[0-9]+]] "f"
; SPIRV: Name [[g:[0-9]+]] "g"
; SPIRV: Name [[inline_fun:[0-9]+]] "inline_fun"
; SPIRV: Name [[foo:[0-9]+]] "foo"

; SPIRV: 4 Decorate [[EXPORT:[0-9]+]] LinkageAttributes 0
; SPIRV: 2 DecorationGroup [[EXPORT]]
; SPIRV: 4 Decorate [[IMPORT:[0-9]+]] LinkageAttributes 1
; SPIRV: 2 DecorationGroup [[IMPORT]]

; SPIRV: GroupDecorate [[EXPORT]] [[i1]] [[i3]] [[i4]] [[color_table]] [[w]] [[f]] [[inline_fun]]
; SPIRV: GroupDecorate [[IMPORT]] [[noise_table]] [[e]] [[foo]]


; SPIRV: Function {{[0-9]+}} [[f]]
; BACK-TO-LLVM: define spir_func void @f()
; Function Attrs: nounwind
define spir_func void @f() #0 {
entry:
  %q = alloca i32, align 4
  %r = alloca i32, align 4
  %0 = load i32 addrspace(1)* @i2, align 4
  store i32 %0, i32* %q, align 4
  %1 = load i32 addrspace(1)* @i3, align 4
  store i32 %1, i32 addrspace(1)* @i5, align 4
  %2 = load i32 addrspace(1)* @e, align 4
  store i32 %2, i32* %r, align 4
  %3 = load i32 addrspace(2)* getelementptr inbounds ([256 x i32] addrspace(2)* @noise_table, i32 0, i32 0), align 4
  store i32 %3, i32* %r, align 4
  %4 = load i32 addrspace(2)* getelementptr inbounds ([2 x i32] addrspace(2)* @f.color_table, i32 0, i32 0), align 4
  store i32 %4, i32* %r, align 4
  %call = call spir_func i32 @g()
  call spir_func void @inline_fun()
  ret void
}

; SPIRV: Function {{[0-9]+}} [[g]]
; BACK-TO-LLVM: define internal spir_func i32 @g()
; Function Attrs: nounwind
define internal spir_func i32 @g() #0 {
entry:
  call spir_func void @foo()
  ret i32 25
}

; SPIRV: Function {{[0-9]+}} [[inline_fun]]

; SPIRV: Function {{[0-9]+}} [[foo]]
; BACK-TO-LLVM: declare spir_func void @foo()
declare spir_func void @foo() #2

; BACK-TO-LLVM: define spir_func void @inline_fun()
; "linkonce_odr" is lost in translation !
; Function Attrs: inlinehint nounwind
define linkonce_odr spir_func void @inline_fun() #1 {
entry:
  %t = alloca i32 addrspace(1)*, align 4
  store i32 addrspace(1)* @i1, i32 addrspace(1)** %t, align 4
  ret void
}

; SPIRV: Function {{[0-9]+}} [[kern]]
; BACK-TO-LLVM: define spir_kernel void @kern()
; Function Attrs: nounwind
define spir_kernel void @kern() #0 {
entry:
  call spir_func void @f()
  ret void
}


attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { inlinehint nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}

!0 = !{void ()* @kern, !1, !2, !3, !4, !5}
!1 = !{!"kernel_arg_addr_space"}
!2 = !{!"kernel_arg_access_qual"}
!3 = !{!"kernel_arg_type"}
!4 = !{!"kernel_arg_base_type"}
!5 = !{!"kernel_arg_type_qual"}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
