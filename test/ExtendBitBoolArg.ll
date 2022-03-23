; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -s %t.bc -o %t.regulzarized.bc
; RUN: llvm-dis %t.regulzarized.bc -o %t.regulzarized.ll
; RUN: FileCheck < %t.regulzarized.ll %s

; Translation cycle should be successfull:
; RUN: llvm-spirv %t.regulzarized.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc

; CHECK: %[[#Base:]] = load i1, i1 addrspace(4)*{{.*}}, align 1
; CHECK: %[[#Shift:]] = load i32, i32 addrspace(4)*{{.*}} align 4
; CHECK: %[[#ExtBase:]] = select i1 %[[#Base]], i32 1, i32 0
; CHECK: %[[#LSHR:]] = lshr i32 %[[#ExtBase]], %[[#Shift]]
; CHECK: and i32 %[[#LSHR]], 1

; ModuleID = 'source.bc'
source_filename = "source.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%"class.ac" = type { i1 }

; Function Attrs: convergent mustprogress norecurse nounwind
define linkonce_odr dso_local spir_func void @foo() align 2 {
  %1 = alloca %"class.ac" addrspace(4)*, align 8
  %2 = alloca i32, align 4
  %3 = addrspacecast %"class.ac" addrspace(4)** %1 to %"class.ac" addrspace(4)* addrspace(4)*
  %4 = addrspacecast i32* %2 to i32 addrspace(4)*
  %5 = load %"class.ac" addrspace(4)*, %"class.ac" addrspace(4)* addrspace(4)* %3, align 8
  %6 = getelementptr inbounds %"class.ac", %"class.ac" addrspace(4)* %5, i32 0, i32 0
  %7 = load i1, i1 addrspace(4)* %6, align 1
  %8 = load i32, i32 addrspace(4)* %4, align 4
  %9 = trunc i32 %8 to i1
  %10 = lshr i1 %7, %9
  %11 = zext i1 %10 to i32
  %12 = and i32 %11, 1
  ret void
}
