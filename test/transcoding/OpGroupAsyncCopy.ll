; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM
; RUN: llvm-spirv -r --spirv-target-env=SPV-IR %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-SPV-IR

; CHECK-LLVM: call spir_func ptr @_Z29async_work_group_strided_copyPU3AS1Dv2_hPU3AS3KS_jj9ocl_event(
; CHECK-LLVM: call spir_func void @_Z17wait_group_eventsiPU3AS49ocl_event(
; CHECK-LLVM: declare spir_func ptr @_Z29async_work_group_strided_copyPU3AS1Dv2_hPU3AS3KS_jj9ocl_event(ptr addrspace(1), ptr addrspace(3), i32, i32, ptr)
; CHECK-LLVM: declare spir_func void @_Z17wait_group_eventsiPU3AS49ocl_event(i32, ptr addrspace(4))

; CHECK-SPV-IR: call spir_func target("spirv.Event") @_Z22__spirv_GroupAsyncCopyiPU3AS1Dv2_cPU3AS3S_jjP13__spirv_Event(i32 2
; CHECK-SPV-IR: call spir_func void @_Z23__spirv_GroupWaitEventsiiPU3AS4P13__spirv_Event(i32 2
; CHECK-SPV-IR: declare spir_func target("spirv.Event") @_Z22__spirv_GroupAsyncCopyiPU3AS1Dv2_cPU3AS3S_jjP13__spirv_Event(i32, ptr addrspace(1), ptr addrspace(3), i32, i32, target("spirv.Event")
; CHECK-SPV-IR: declare spir_func void @_Z23__spirv_GroupWaitEventsiiPU3AS4P13__spirv_Event(i32, i32, ptr addrspace(4))

; CHECK-SPIRV-DAG: GroupAsyncCopy {{[0-9]+}} {{[0-9]+}} [[Scope:[0-9]+]]
; CHECK-SPIRV-DAG: Constant {{[0-9]+}} [[Scope]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.event_t = type opaque

; Function Attrs: nounwind
define spir_kernel void @test_fn(ptr addrspace(1) %src, ptr addrspace(1) %dst, ptr addrspace(3) %localBuffer, i32 %copiesPerWorkgroup, i32 %copiesPerWorkItem) #0 !kernel_arg_addr_space !1 !kernel_arg_access_qual !2 !kernel_arg_type !3 !kernel_arg_base_type !4 !kernel_arg_type_qual !5 {
entry:
  %src.addr = alloca ptr addrspace(1), align 4
  %dst.addr = alloca ptr addrspace(1), align 4
  %localBuffer.addr = alloca ptr addrspace(3), align 4
  %copiesPerWorkgroup.addr = alloca i32, align 4
  %copiesPerWorkItem.addr = alloca i32, align 4
  %i = alloca i32, align 4
  %event = alloca ptr, align 4
  store ptr addrspace(1) %src, ptr %src.addr, align 4
  store ptr addrspace(1) %dst, ptr %dst.addr, align 4
  store ptr addrspace(3) %localBuffer, ptr %localBuffer.addr, align 4
  store i32 %copiesPerWorkgroup, ptr %copiesPerWorkgroup.addr, align 4
  store i32 %copiesPerWorkItem, ptr %copiesPerWorkItem.addr, align 4
  store i32 0, ptr %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4
  %1 = load i32, ptr %copiesPerWorkItem.addr, align 4
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %call = call spir_func i32 @_Z12get_local_idj(i32 0)
  %2 = load i32, ptr %copiesPerWorkItem.addr, align 4
  %mul = mul i32 %call, %2
  %3 = load i32, ptr %i, align 4
  %add = add i32 %mul, %3
  %4 = load ptr addrspace(3), ptr %localBuffer.addr, align 4
  %arrayidx = getelementptr inbounds <2 x i8>, ptr addrspace(3) %4, i32 %add
  store <2 x i8> zeroinitializer, ptr addrspace(3) %arrayidx, align 2
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %5 = load i32, ptr %i, align 4
  %inc = add nsw i32 %5, 1
  store i32 %inc, ptr %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  call spir_func void @_Z7barrierj(i32 1)
  store i32 0, ptr %i, align 4
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc12, %for.end
  %6 = load i32, ptr %i, align 4
  %7 = load i32, ptr %copiesPerWorkItem.addr, align 4
  %cmp2 = icmp slt i32 %6, %7
  br i1 %cmp2, label %for.body3, label %for.end14

for.body3:                                        ; preds = %for.cond1
  %call4 = call spir_func i32 @_Z13get_global_idj(i32 0)
  %8 = load i32, ptr %copiesPerWorkItem.addr, align 4
  %mul5 = mul i32 %call4, %8
  %9 = load i32, ptr %i, align 4
  %add6 = add i32 %mul5, %9
  %10 = load ptr addrspace(1), ptr %src.addr, align 4
  %arrayidx7 = getelementptr inbounds <2 x i8>, ptr addrspace(1) %10, i32 %add6
  %11 = load <2 x i8>, ptr addrspace(1) %arrayidx7, align 2
  %call8 = call spir_func i32 @_Z12get_local_idj(i32 0)
  %12 = load i32, ptr %copiesPerWorkItem.addr, align 4
  %mul9 = mul i32 %call8, %12
  %13 = load i32, ptr %i, align 4
  %add10 = add i32 %mul9, %13
  %14 = load ptr addrspace(3), ptr %localBuffer.addr, align 4
  %arrayidx11 = getelementptr inbounds <2 x i8>, ptr addrspace(3) %14, i32 %add10
  store <2 x i8> %11, ptr addrspace(3) %arrayidx11, align 2
  br label %for.inc12

for.inc12:                                        ; preds = %for.body3
  %15 = load i32, ptr %i, align 4
  %inc13 = add nsw i32 %15, 1
  store i32 %inc13, ptr %i, align 4
  br label %for.cond1

for.end14:                                        ; preds = %for.cond1
  call spir_func void @_Z7barrierj(i32 1)
  %16 = load ptr addrspace(1), ptr %dst.addr, align 4
  %17 = load i32, ptr %copiesPerWorkgroup.addr, align 4
  %call15 = call spir_func i32 @_Z12get_group_idj(i32 0)
  %mul16 = mul i32 %17, %call15
  %add.ptr = getelementptr inbounds <2 x i8>, ptr addrspace(1) %16, i32 %mul16
  %18 = load ptr addrspace(3), ptr %localBuffer.addr, align 4
  %19 = load i32, ptr %copiesPerWorkgroup.addr, align 4
  %call17 = call spir_func ptr @_Z21async_work_group_copyPU3AS1Dv2_cPKU3AS3S_j9ocl_event(ptr addrspace(1) %add.ptr, ptr addrspace(3) %18, i32 %19, ptr null)
  store ptr %call17, ptr %event, align 4
  %20 = addrspacecast ptr %event to ptr addrspace(4)
  call spir_func void @_Z17wait_group_eventsiPU3AS49ocl_event(i32 1, ptr addrspace(4) %20)
  ret void
}

declare spir_func i32 @_Z12get_local_idj(i32) #1

declare spir_func void @_Z7barrierj(i32) #1

declare spir_func i32 @_Z13get_global_idj(i32) #1

declare spir_func ptr @_Z21async_work_group_copyPU3AS1Dv2_cPKU3AS3S_j9ocl_event(ptr addrspace(1), ptr addrspace(3), i32, ptr) #1

declare spir_func i32 @_Z12get_group_idj(i32) #1

declare spir_func void @_Z17wait_group_eventsiPU3AS49ocl_event(i32, ptr addrspace(4)) #1

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!opencl.enable.FP_CONTRACT = !{}
!opencl.spir.version = !{!6}
!opencl.ocl.version = !{!7}
!opencl.used.extensions = !{!8}
!opencl.used.optional.core.features = !{!8}
!opencl.compiler.options = !{!8}

!1 = !{i32 1, i32 1, i32 3, i32 0, i32 0}
!2 = !{!"none", !"none", !"none", !"none", !"none"}
!3 = !{!"char2*", !"char2*", !"char2*", !"int", !"int"}
!4 = !{!"char2*", !"char2*", !"char2*", !"int", !"int"}
!5 = !{!"const", !"", !"", !"", !""}
!6 = !{i32 1, i32 2}
!7 = !{i32 2, i32 0}
!8 = !{}
