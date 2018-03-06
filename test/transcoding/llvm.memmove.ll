; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-NOT: llvm.memmove

; CHECK-SPIRV: Variable {{[0-9]+}} [[mem:[0-9]+]] 7

; CHECK-SPIRV: LifetimeStart [[mem]] [[size:[0-9]+]]
; CHECK-SPIRV: Bitcast [[i8Ty:[0-9]+]] [[tmp1:[0-9]+]] [[mem]]
; CHECK-SPIRV: CopyMemorySized [[tmp1]] {{[0-9]+}} {{[0-9]+}}
; CHECK-SPIRV: Bitcast [[i8Ty]] [[tmp2:[0-9]+]] [[mem]]
; CHECK-SPIRV: CopyMemorySized {{[0-9]+}} [[tmp2]] {{[0-9]+}}
; CHECK-SPIRV: LifetimeStop [[mem]] [[size]]

; CHECK-LLVM-NOT: llvm.memmove

; CHECK-LLVM: [[local:%[0-9]+]] = alloca %struct.SomeStruct
; CHECK-LLVM: [[tmp1:%[0-9]+]] = bitcast %struct.SomeStruct* [[local]] to [[type:i[0-9]+\*]]
; CHECK-LLVM: call void @llvm.lifetime.start.p0i8({{i[0-9]+}} {{-?[0-9]+}}, [[type]] [[tmp1]])
; CHECK-LLVM: [[tmp2:%[0-9]+]] = bitcast %struct.SomeStruct* [[local]] to [[type]]
; CHECK-LLVM: call void @llvm.memcpy
; CHECK-LLVM:  ([[type]] align 64 [[tmp2]],
; CHECK-LLVM:  {{i[0-9]+}} [[size:[0-9]+]]
; CHECK-LLVM: [[tmp3:%[0-9]+]] = bitcast %struct.SomeStruct* [[local]] to [[type]]
; CHECK-LLVM: call void @llvm.memcpy
; CHECK-LLVM:  , [[type]] align 64 [[tmp3]], {{i[0-9]+}} [[size]]
; CHECK-LLVM: call void @llvm.lifetime.end.p0i8({{i[0-9]+}} {{-?[0-9]+}}, [[type]] [[tmp1]])

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir-unknown-unknown"

%struct.SomeStruct = type { <16 x float>, i32, [60 x i8] }

; Function Attrs: nounwind
define spir_kernel void @test_struct(%struct.SomeStruct addrspace(1)* nocapture readonly %in, %struct.SomeStruct addrspace(1)* nocapture %out) #0 {
  %1 = bitcast %struct.SomeStruct addrspace(1)* %in to i8 addrspace(1)*
  %2 = bitcast %struct.SomeStruct addrspace(1)* %out to i8 addrspace(1)*
  call void @llvm.memmove.p1i8.p1i8.i32(i8 addrspace(1)* %2, i8 addrspace(1)* %1, i32 128, i32 64, i1 false)
  ret void
}

; Function Attrs: nounwind
declare void @llvm.memmove.p1i8.p1i8.i32(i8 addrspace(1)* nocapture, i8 addrspace(1)* nocapture readonly, i32, i32, i1) #1

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind }

!opencl.kernels = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!7}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}
!llvm.ident = !{!9}

!0 = !{void (%struct.SomeStruct addrspace(1)*, %struct.SomeStruct addrspace(1)*)* @test_struct, !1, !2, !3, !4, !5, !6}
!1 = !{!"kernel_arg_addr_space", i32 1, i32 1}
!2 = !{!"kernel_arg_access_qual", !"none", !"none"}
!3 = !{!"kernel_arg_type", !"struct SomeStruct*", !"struct SomeStruct*"}
!4 = !{!"kernel_arg_base_type", !"struct SomeStruct*", !"struct SomeStruct*"}
!5 = !{!"kernel_arg_type_qual", !"const", !""}
!6 = !{!"kernel_arg_name", !"in", !"out"}
!7 = !{i32 1, i32 2}
!8 = !{}
!9 = !{!"clang version 3.6.1 (https://github.com/KhronosGroup/SPIR d7e44c3b27581e54ca0e522987d1ade2bd29b70d) (https://github.com/KhronosGroup/SPIRV-LLVM.git d42743684ea8338358504e44ef8363b9dc675c66)"}
