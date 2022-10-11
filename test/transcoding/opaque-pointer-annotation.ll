; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV

; CHECK-SPIRV: Decorate [[#]] UserSemantic "var_annotation"
; CHECK-SPIRV: MemberDecorate [[#]] 0 UserSemantic "struct_annotation"

source_filename = "llvm-link"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64"

%struct.Example = type { i32 }

@.str = private unnamed_addr constant [15 x i8] c"var_annotation\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [17 x i8] c"/app/example.cpp\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [18 x i8] c"struct_annotation\00", section "llvm.metadata"

define spir_func void @test() {
  %1 = alloca i32, align 4
  %2 = alloca %struct.Example, align 4
  call void @llvm.var.annotation(ptr %1, ptr @.str, ptr @.str.1, i32 8, ptr null)
  store i32 0, ptr %1, align 4
  %3 = load i32, ptr %1, align 4
  call void @_Z3fooi(i32 noundef %3)
  %4 = getelementptr inbounds %struct.Example, ptr %2, i32 0, i32 0
  %5 = call ptr @llvm.ptr.annotation.p0(ptr %4, ptr @.str.2, ptr @.str.1, i32 4, ptr null)
  %6 = load i32, ptr %5, align 4
  call void @_Z3fooi(i32 noundef %6)
  ret void
}

declare void @llvm.var.annotation(ptr, ptr, ptr, i32, ptr) #2

declare void @_Z3fooi(i32 noundef) #3

declare ptr @llvm.ptr.annotation.p0(ptr, ptr, ptr, i32, ptr) #2
