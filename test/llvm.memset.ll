; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s

; CHECK-NOT: llvm.memset

; CHECK: TypeInt [[int32:[0-9]+]] 32
; CHECK: Constant [[int32]] [[fiftieen:[0-9]+]] 15
; CHECK: TypeArray [[int32x15:[0-9]+]] [[int32]] [[fiftieen]]
; CHECK: TypePointer [[int32x15Ptr:[0-9]+]] 7 [[int32x15]]
; CHECK: ConstantNull [[int32x15]] [[ConstantNull:[0-9]+]]

; CHECK: Variable [[int32x15Ptr:[0-9]+]] [[mem:[0-9]+]] 7
; CHECK: Store [[mem]] [[ConstantNull]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir"

; Function Attrs: nounwind
define spir_func void @test() #0 {
entry:
  %mem = alloca [15 x i32], align 4
  %0 = bitcast [15 x i32]* %mem to i8*
  call void @llvm.memset.p0i8.i32(i8* %0, i8 0, i32 60, i32 4, i1 false)
  ret void
}

; Function Attrs: nounwind
declare void @llvm.memset.p0i8.i32(i8* nocapture, i8, i32, i32, i1) #1

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind }

!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!0}
!opencl.ocl.version = !{!1}
!opencl.used.extensions = !{!2}
!opencl.used.optional.core.features = !{!2}
!opencl.compiler.options = !{!2}

!0 = !{i32 1, i32 2}
!1 = !{i32 2, i32 0}
!2 = !{}
