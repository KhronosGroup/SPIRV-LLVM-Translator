; Source:
;
; class cl {
; public:
;   class tt {
;   public:
;     template <class T, int size>
;     class vec {
;     public:
;       T var[size];
;     };
;   };
; };
; void kernel foo(__global cl::tt::vec<float, 4> *in)
; {
;   in->var[0] = 0.;
; }


; In LLVM -> SPIRV translation original names of types (typedefs) are missed,
; there is no defined possibility to keep a typedef name by SPIR-V spec.
; As a workaround we store original names in OpString instruction:
; OpString "kernel_arg_type.%kernel_name%.typename0,typename1,..."

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -preserve-ocl-kernel-arg-type-metadata-through-string %t.bc -spirv-text -o %t.spv.txt
; RUN: FileCheck < %t.spv.txt %s --check-prefix=CHECK-SPIRV-WORKAROUND
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spv.txt
; RUN: FileCheck < %t.spv.txt %s --check-prefix=CHECK-SPIRV-WORKAROUND-NEGATIVE
; RUN: llvm-spirv -preserve-ocl-kernel-arg-type-metadata-through-string %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r -preserve-ocl-kernel-arg-type-metadata-through-string %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM-WORKAROUND
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM-WORKAROUND-NEGATIVE

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir"

; CHECK-SPIRV-WORKAROUND: String 14 "kernel_arg_type.foo.cl::tt::vec<float, 4>*,"
; CHECK-SPIRV-WORKAROUND-NEGATIVE-NOT: String 14 "kernel_arg_type.foo.cl::tt::vec<float, 4>*,"

; CHECK-LLVM-WORKAROUND: !kernel_arg_type [[TYPE:![0-9]+]]
; CHECK-LLVM-WORKAROUND: [[TYPE]] = !{!"cl::tt::vec<float, 4>*"}
; CHECK-LLVM-WORKAROUND-NEGATIVE: !kernel_arg_type [[TYPE:![0-9]+]]
; CHECK-LLVM-WORKAROUND-NEGATIVE-NOT: [[TYPE]] = !{!"cl::tt::vec<float, 4>*"}

%"class.cl::tt::vec" = type { [4 x float] }

; Function Attrs: convergent noinline nounwind optnone

define dso_local spir_kernel void @foo(ptr addrspace(1) captures(none)) local_unnamed_addr #0 !kernel_arg_addr_space !4 !kernel_arg_access_qual !5 !kernel_arg_type !6 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 {
  store float 0.000000e+00, ptr addrspace(1) %0, align 4, !tbaa !8
  ret void
}

attributes #0 = { norecurse nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 0, i32 0}
!2 = !{i32 0, i32 2}
!3 = !{!"clang version 7.0.0"}
!4 = !{i32 1}
!5 = !{!"none"}
!6 = !{!"cl::tt::vec<float, 4>*"}
!7 = !{!""}
!8 = !{!9, !9, i64 0}
!9 = !{!"float", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C++ TBAA"}

