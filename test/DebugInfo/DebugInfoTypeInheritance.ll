; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; RUN: FileCheck %s --input-file %t.spt --check-prefixes=CHECK-SPIRV,CHECK-SPIRV-OCL
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck %s --input-file %t.rev.ll --check-prefix CHECK-LLVM

; RUN: llvm-spirv %t.bc -spirv-text --spirv-debug-info-version=nonsemantic-shader-100 -o %t.spt
; RUN: FileCheck %s --input-file %t.spt --check-prefixes=CHECK-SPIRV,CHECK-SPIRV-NONSEM
; RUN: llvm-spirv %t.bc --spirv-debug-info-version=nonsemantic-shader-100 -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck %s --input-file %t.rev.ll --check-prefix CHECK-LLVM

; CHECK-SPIRV: String [[#Str_C:]] "C"
; CHECK-SPIRV: String [[#Str_B:]] "B"
; CHECK-SPIRV: String [[#Str_A:]] "A"

; CHECK-SPIRV: [[#Class_A:]] [[#]] DebugTypeComposite [[#Str_A]]

; CHECK-SPIRV-OCL: [[#B_inherits_A:]] [[#]] DebugTypeInheritance [[#Class_B:]] [[#Class_A]] [[#]] [[#]] [[#]] {{$}}
; CHECK-SPIRV-NONSEM: [[#B_inherits_A:]] [[#]] DebugTypeInheritance [[#Class_A]] [[#]] [[#]] [[#]] {{$}}
; CHECK-SPIRV: [[#Class_B:]] [[#]] DebugTypeComposite [[#Str_B]] {{.*}} [[#B_inherits_A]]

; CHECK-SPIRV-OCL: [[#C_inherits_B:]] [[#]] DebugTypeInheritance [[#Class_C:]] [[#Class_B]] [[#]] [[#]] [[#]] {{$}}
; CHECK-SPIRV-NONSEM: [[#C_inherits_B:]] [[#]] DebugTypeInheritance [[#Class_B]] [[#]] [[#]] [[#]] {{$}}
; CHECK-SPIRV: [[#Class_C:]] [[#]] DebugTypeComposite [[#Str_C]] {{.*}} [[#C_inherits_B]]

; CHECK-LLVM: ![[#Class_C:]] = distinct !DICompositeType(tag: DW_TAG_class_type, name: "C"{{.*}}identifier: "_ZTS1C")
; CHECK-LLVM: !DIDerivedType(tag: DW_TAG_inheritance, scope: ![[#Class_C]], baseType: ![[#Class_B:]]
; CHECK-LLVM: ![[#Class_B]] = distinct !DICompositeType(tag: DW_TAG_class_type, name: "B"{{.*}}identifier: "_ZTS1B")
; CHECK-LLVM: !DIDerivedType(tag: DW_TAG_inheritance, scope: ![[#Class_B]], baseType: ![[#Class_A:]]
; CHECK-LLVM: ![[#Class_A]] = distinct !DICompositeType(tag: DW_TAG_class_type, name: "A"{{.*}}identifier: "_ZTS1A")

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "spir64-unknown-unknown"

%class.C = type { i8 }

; Function Attrs: mustprogress noinline nounwind optnone uwtable
define dso_local noundef i32 @_Z3foov() #0 !dbg !8 {
  %1 = alloca %class.C, align 1
  call void @llvm.dbg.declare(metadata %class.C* %1, metadata !14, metadata !DIExpression()), !dbg !22
  ret i32 0, !dbg !23
}

; Function Attrs: nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

attributes #0 = { mustprogress noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nosync nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6}
!llvm.ident = !{!7}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !1, producer: "clang version 14.0.0 (https://github.com/llvm/llvm-project.git 329fda39c507e8740978d10458451dcdb21563be)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/app/example.cpp", directory: "/app")
!2 = !{i32 7, !"Dwarf Version", i32 4}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"uwtable", i32 1}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = !{!"clang version 14.0.0 (https://github.com/llvm/llvm-project.git 329fda39c507e8740978d10458451dcdb21563be)"}
!8 = distinct !DISubprogram(name: "foo", linkageName: "_Z3foov", scope: !9, file: !9, line: 4, type: !10, scopeLine: 4, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !13)
!9 = !DIFile(filename: "example.cpp", directory: "/app")
!10 = !DISubroutineType(types: !11)
!11 = !{!12}
!12 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!13 = !{}
!14 = !DILocalVariable(name: "c", scope: !8, file: !9, line: 7, type: !15)
!15 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "C", file: !9, line: 3, size: 8, flags: DIFlagTypePassByValue, elements: !16, identifier: "_ZTS1C")
!16 = !{!17}
!17 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !15, baseType: !18, flags: DIFlagPublic, extraData: i32 0)
!18 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "B", file: !9, line: 2, size: 8, flags: DIFlagTypePassByValue, elements: !19, identifier: "_ZTS1B")
!19 = !{!20}
!20 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !18, baseType: !21, flags: DIFlagPublic, extraData: i32 0)
!21 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "A", file: !9, line: 1, size: 8, flags: DIFlagTypePassByValue, elements: !13, identifier: "_ZTS1A")
!22 = !DILocation(line: 7, column: 11, scope: !8)
!23 = !DILocation(line: 8, column: 3, scope: !8)
