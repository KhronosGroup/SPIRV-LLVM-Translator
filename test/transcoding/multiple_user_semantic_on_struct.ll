; This test is intended to check that we are actually using the
; ptr.annotation intrinsic call results during the reverse translation.

; Source (https://godbolt.org/z/qzhsKfPeq):
; class B {
; public:
;     int Val [[clang::annotate("ClassB")]];
; };
; class A {
; public:
;     int Val [[clang::annotate("ClassA")]];
;     int MultiDec [[clang::annotate("Dec1"), clang::annotate("Dec2"), clang::annotate("Dec3")]];
;     [[clang::annotate("ClassAfieldB")]]class B b;
; };
; void foo(int);
; int main() {
;     A a;
;     B b;
;     A c;
;     foo(a.Val);       // ClassA
;     foo(c.Val);       // Obj2ClassA
;     foo(a.MultiDec);  // ClassAMultiDec
;     foo(a.b.Val);     // ClassAFieldB
;     foo(b.Val);       // ClassB
;     return 0;
; }


; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; Check that even when FPGA memory extensions are enabled - yet we have
; UserSemantic decoration be generated
; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_fpga_memory_accesses,+SPV_INTEL_fpga_memory_attributes -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV

; CHECK-SPIRV: Name [[#ClassA:]] "class.A"
; CHECK-SPIRV: Name [[#ClassB:]] "class.B"
; CHECK-SPIRV: MemberDecorate [[#ClassA]] 0 UserSemantic "ClassA"
; CHECK-SPIRV: MemberDecorate [[#ClassA]] 0 UserSemantic "ClassA"
; CHECK-SPIRV: MemberDecorate [[#ClassA]] 1 UserSemantic "Dec1"
; CHECK-SPIRV: MemberDecorate [[#ClassA]] 1 UserSemantic "Dec2"
; CHECK-SPIRV: MemberDecorate [[#ClassA]] 1 UserSemantic "Dec3"
; CHECK-SPIRV: MemberDecorate [[#ClassA]] 2 UserSemantic "ClassAfieldB"
; CHECK-SPIRV: MemberDecorate [[#ClassB]] 0 UserSemantic "ClassB"
; CHECK-SPIRV: MemberDecorate [[#ClassB]] 0 UserSemantic "ClassB"

; CHECK-LLVM: @[[#StrStructA:]] = {{.*}}"ClassA\00"
; CHECK-LLVM: @[[#StrStructA2:]] = {{.*}}"ClassA\00"
; CHECK-LLVM: @[[#Dec1:]] = {{.*}}"Dec1\00"
; CHECK-LLVM: @[[#Dec2:]] = {{.*}}"Dec2\00"
; CHECK-LLVM: @[[#Dec3:]] = {{.*}}"Dec3\00"
; CHECK-LLVM: @[[#StrAfieldB:]] = {{.*}}"ClassAfieldB\00"
; CHECK-LLVM: @[[#StrStructB:]] = {{.*}}"ClassB\00"
; CHECK-LLVM: @[[#StrStructB2:]] = {{.*}}"ClassB\00"
; CHECK-LLVM: @[[#StrObj2StructA:]] = {{.*}}"ClassA\00"
; CHECK-LLVM: @[[#StrObj2StructA2:]] = {{.*}}"ClassA\00"

; CHECK-LLVM: %[[#ObjClassA:]] = alloca %class.A, align 4
; CHECK-LLVM: %[[#GepClassAVal:]] = getelementptr inbounds %class.A, %class.A* %[[#ObjClassA]], i32 0, i32 0
; CHECK-LLVM: %[[#PtrAnnClassAVal:]] = call i32* @llvm.ptr.annotation.p0i32.p0i8(i32* %[[#GepClassAVal]], i8* getelementptr inbounds ([7 x i8], [7 x i8]* @[[#StrStructA]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)
; CHECK-LLVM: %[[#PtrAnn2ClassAVal:]] = call i32* @llvm.ptr.annotation.p0i32.p0i8(i32* %[[#PtrAnnClassAVal]], i8* getelementptr inbounds ([7 x i8], [7 x i8]* @[[#StrStructA2]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)

; CHECK-LLVM: %[[#GepMultiDec:]] = getelementptr inbounds %class.A, %class.A* %[[#ObjClassA]], i32 0, i32 1
; CHECK-LLVM: %[[#PtrAnnMultiDec:]] = call i32* @llvm.ptr.annotation.p0i32.p0i8(i32* %[[#GepMultiDec]], i8* getelementptr inbounds ([5 x i8], [5 x i8]* @[[#Dec1]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)
; CHECK-LLVM: %[[#PtrAnn2MultiDec:]] = call i32* @llvm.ptr.annotation.p0i32.p0i8(i32* %[[#PtrAnnMultiDec]], i8* getelementptr inbounds ([5 x i8], [5 x i8]* @[[#Dec2]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)
; CHECK-LLVM: %[[#PtrAnn3MultiDec:]] = call i32* @llvm.ptr.annotation.p0i32.p0i8(i32* %[[#PtrAnn2MultiDec]], i8* getelementptr inbounds ([5 x i8], [5 x i8]* @[[#Dec3]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)

; CHECK-LLVM: %[[#GepClassAFieldB:]] = getelementptr inbounds %class.A, %class.A* %[[#ObjClassA]], i32 0, i32 2
; CHECK-LLVM: %[[#CastClassAFieldB:]] = bitcast %class.B* %[[#GepClassAFieldB]] to i8*
; CHECK-LLVM: %[[#PtrAnnClassAFieldB:]] = call i8* @llvm.ptr.annotation.p0i8.p0i8(i8* %[[#CastClassAFieldB]], i8* getelementptr inbounds ([13 x i8], [13 x i8]* @[[#StrAfieldB]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)

; CHECK-LLVM: %[[#ObjClassB:]] = alloca %class.B, align 4
; CHECK-LLVM: %[[#GEPClassB:]] = getelementptr inbounds %class.B, %class.B* %[[#ObjClassB]], i32 0, i32 0
; CHECK-LLVM: %[[#PtrAnnClassB:]] = call i32* @llvm.ptr.annotation.p0i32.p0i8(i32* %[[#GEPClassB]], i8* getelementptr inbounds ([7 x i8], [7 x i8]* @[[#StrStructB]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)
; CHECK-LLVM: %[[#PtrAnn2ClassB:]] = call i32* @llvm.ptr.annotation.p0i32.p0i8(i32* %[[#PtrAnnClassB]], i8* getelementptr inbounds ([7 x i8], [7 x i8]* @[[#StrStructB2]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)

; CHECK-LLVM: %[[#Obj2ClassA:]] = alloca %class.A, align 4
; CHECK-LLVM: %[[#GepObj2ClassA:]] = getelementptr inbounds %class.A, %class.A* %[[#Obj2ClassA]], i32 0, i32 0
; CHECK-LLVM: %[[#PtrAnnObj2ClassA:]] = call i32* @llvm.ptr.annotation.p0i32.p0i8(i32* %[[#GepObj2ClassA]], i8* getelementptr inbounds ([7 x i8], [7 x i8]* @[[#StrObj2StructA]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)
; CHECK-LLVM: %[[#PtrAnn2Obj2ClassA:]] = call i32* @llvm.ptr.annotation.p0i32.p0i8(i32* %[[#PtrAnnObj2ClassA]], i8* getelementptr inbounds ([7 x i8], [7 x i8]* @[[#StrObj2StructA2]], i32 0, i32 0), i8* undef, i32 undef, i8* undef)


; CHECK-LLVM: %[[#CastClassAVal:]] = bitcast i32* %[[#PtrAnn2ClassAVal]] to i8*
; CHECK-LLVM: %[[#LoadClassAVal:]] = bitcast i8* %[[#CastClassAVal]] to i32*
; CHECK-LLVM: %[[#CallClassA:]] = load i32, i32* %[[#LoadClassAVal]], align 4
; CHECK-LLVM: call spir_func void @_Z3fooi(i32 %[[#CallClassA]])

; CHECK-LLVM: %[[#CastObj2ClassA:]] = bitcast i32* %[[#PtrAnn2Obj2ClassA]] to i8*
; CHECK-LLVM: %[[#LoadObj2ClassA:]] = bitcast i8* %[[#CastObj2ClassA]] to i32*
; CHECK-LLVM: %[[#CallObj2ClassA:]] = load i32, i32* %[[#LoadObj2ClassA]], align 4
; CHECK-LLVM: call spir_func void @_Z3fooi(i32 %[[#CallObj2ClassA]])

; CHECK-LLVM: %[[#CastMultiDec:]] = bitcast i32* %[[#PtrAnn3MultiDec]] to i8*
; CHECK-LLVM: %[[#CastMultiDec1:]] = bitcast i8* %[[#CastMultiDec]] to i32*
; CHECK-LLVM: %[[#CastMultiDec2:]] = bitcast i32* %[[#CastMultiDec1]] to i8*
; CHECK-LLVM: %[[#CastMultiDec3:]] = bitcast i8* %[[#CastMultiDec2]] to i32*
; CHECK-LLVM: %[[#CastMultiDec4:]] = bitcast i32* %[[#CastMultiDec3]] to i8*
; CHECK-LLVM: %[[#LoadMultiDec:]] = bitcast i8* %[[#CastMultiDec4]] to i32*
; CHECK-LLVM: %[[#CallClassAMultiDec:]] = load i32, i32* %[[#LoadMultiDec]], align 4
; CHECK-LLVM: call spir_func void @_Z3fooi(i32 %[[#CallClassAMultiDec]])

; CHECK-LLVM: %[[#CastClassAFieldB:]] = bitcast i8* %[[#PtrAnnClassAFieldB]] to i8*
; CHECK-LLVM: %[[#Cast2ClassAFieldB:]] = bitcast i8* %[[#CastClassAFieldB]] to %class.B*
; CHECK-LLVM: %[[#GEPClassB:]] = getelementptr inbounds %class.B, %class.B* %[[#Cast2ClassAFieldB]], i32 0, i32 0
; CHECK-LLVM: %[[#CastClassB:]] = bitcast i32* %[[#GEPClassB]] to i8*
; CHECK-LLVM: %[[#Cast2ClassB:]] = bitcast i8* %[[#CastClassB]] to i32*
; CHECK-LLVM: %[[#CallClassAFieldB:]] = load i32, i32* %[[#Cast2ClassB]], align 4
; CHECK-LLVM: call spir_func void @_Z3fooi(i32 %[[#CallClassAFieldB]])

; CHECK-LLVM: %[[#CastClassB:]] = bitcast i32* %[[#PtrAnn2ClassB]] to i8*
; CHECK-LLVM: %[[#Cast2ClassB:]] = bitcast i8* %[[#CastClassB]] to i32*
; CHECK-LLVM: %[[#CallClassB:]] = load i32, i32* %[[#Cast2ClassB]], align 4
; CHECK-LLVM: call spir_func void @_Z3fooi(i32 %[[#CallClassB]])

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64"

%class.A = type { i32, i32, %class.B }
%class.B = type { i32 }

@.str = private unnamed_addr constant [7 x i8] c"ClassA\00", section "llvm.metadata"
@.str.1 = private unnamed_addr constant [17 x i8] c"/app/example.cpp\00", section "llvm.metadata"
@.str.2 = private unnamed_addr constant [5 x i8] c"Dec1\00", section "llvm.metadata"
@.str.3 = private unnamed_addr constant [5 x i8] c"Dec2\00", section "llvm.metadata"
@.str.4 = private unnamed_addr constant [5 x i8] c"Dec3\00", section "llvm.metadata"
@.str.5 = private unnamed_addr constant [13 x i8] c"ClassAfieldB\00", section "llvm.metadata"
@.str.6 = private unnamed_addr constant [7 x i8] c"ClassB\00", section "llvm.metadata"

define dso_local noundef i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca %class.A, align 4
  %3 = alloca %class.B, align 4
  %4 = alloca %class.A, align 4
  store i32 0, i32* %1, align 4
  %5 = getelementptr inbounds %class.A, %class.A* %2, i32 0, i32 0
  %6 = bitcast i32* %5 to i8*
  %7 = call i8* @llvm.ptr.annotation.p0i8(i8* %6, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str.1, i32 0, i32 0), i32 12, i8* null)
  %8 = bitcast i8* %7 to i32*
  %9 = load i32, i32* %8, align 4
  call void @_Z3fooi(i32 noundef %9)
  %10 = getelementptr inbounds %class.A, %class.A* %4, i32 0, i32 0
  %11 = bitcast i32* %10 to i8*
  %12 = call i8* @llvm.ptr.annotation.p0i8(i8* %11, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str.1, i32 0, i32 0), i32 12, i8* null)
  %13 = bitcast i8* %12 to i32*
  %14 = load i32, i32* %13, align 4
  call void @_Z3fooi(i32 noundef %14)
  %15 = getelementptr inbounds %class.A, %class.A* %2, i32 0, i32 1
  %16 = bitcast i32* %15 to i8*
  %17 = call i8* @llvm.ptr.annotation.p0i8(i8* %16, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str.1, i32 0, i32 0), i32 13, i8* null)
  %18 = bitcast i8* %17 to i32*
  %19 = bitcast i32* %18 to i8*
  %20 = call i8* @llvm.ptr.annotation.p0i8(i8* %19, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str.3, i32 0, i32 0), i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str.1, i32 0, i32 0), i32 13, i8* null)
  %21 = bitcast i8* %20 to i32*
  %22 = bitcast i32* %21 to i8*
  %23 = call i8* @llvm.ptr.annotation.p0i8(i8* %22, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str.4, i32 0, i32 0), i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str.1, i32 0, i32 0), i32 13, i8* null)
  %24 = bitcast i8* %23 to i32*
  %25 = load i32, i32* %24, align 4
  call void @_Z3fooi(i32 noundef %25)
  %26 = getelementptr inbounds %class.A, %class.A* %2, i32 0, i32 2
  %27 = bitcast %class.B* %26 to i8*
  %28 = call i8* @llvm.ptr.annotation.p0i8(i8* %27, i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.str.5, i32 0, i32 0), i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str.1, i32 0, i32 0), i32 14, i8* null)
  %29 = bitcast i8* %28 to %class.B*
  %30 = getelementptr inbounds %class.B, %class.B* %29, i32 0, i32 0
  %31 = bitcast i32* %30 to i8*
  %32 = call i8* @llvm.ptr.annotation.p0i8(i8* %31, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.6, i32 0, i32 0), i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str.1, i32 0, i32 0), i32 6, i8* null)
  %33 = bitcast i8* %32 to i32*
  %34 = load i32, i32* %33, align 4
  call void @_Z3fooi(i32 noundef %34)
  %35 = getelementptr inbounds %class.B, %class.B* %3, i32 0, i32 0
  %36 = bitcast i32* %35 to i8*
  %37 = call i8* @llvm.ptr.annotation.p0i8(i8* %36, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.6, i32 0, i32 0), i8* getelementptr inbounds ([17 x i8], [17 x i8]* @.str.1, i32 0, i32 0), i32 6, i8* null)
  %38 = bitcast i8* %37 to i32*
  %39 = load i32, i32* %38, align 4
  call void @_Z3fooi(i32 noundef %39)
  ret i32 0
}

declare void @_Z3fooi(i32 noundef) #2

declare i8* @llvm.ptr.annotation.p0i8(i8*, i8*, i8*, i32, i8*) #3

attributes #0 = { mustprogress noinline norecurse optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }