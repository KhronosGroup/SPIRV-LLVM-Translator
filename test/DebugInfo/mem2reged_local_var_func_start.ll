; Check if the translator handles #dbg_declare(ptr null ...) correctly:
; does not get placed after OpVariable, so that the following instructions 
; do not inherit the debug location (scope and line) from #dbg_declare.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: llvm-spirv %t.bc -o %t.spv --spirv-debug-info-version=nonsemantic-shader-100
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: llvm-spirv %t.bc -o %t.spv --spirv-debug-info-version=nonsemantic-shader-200
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-LLVM-NOT: , !dbg
; CHECK-LLVM: #dbg_declare(ptr null, ![[#LocalVar:]], !DIExpression(), ![[#Loc:]])
; CHECK-LLVM-NOT: , !dbg ![[#Loc]]
; CHECK-LLVM-DAG: ![[#LocalVar]] = !DILocalVariable(name: "total"
; CHECK-LLVM-DAG: ![[#Loc]] = !DILocation(line: 23

; ModuleID = 'reduced.bc'
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spir64"

define spir_func i32 @first_(ptr addrspace(4) %"first_$NUM1$argptr", ptr %"first_$NUM1$locptr") {
entry:
    #dbg_declare(ptr null, !4, !DIExpression(), !8)
  %"first_$NUM1$locptr1" = alloca ptr addrspace(4), align 8
  store ptr addrspace(4) %"first_$NUM1$argptr", ptr %"first_$NUM1$locptr", align 8
  ret i32 0
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3}

!0 = distinct !DICompileUnit(language: DW_LANG_Fortran95, file: !1, producer: "clang", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "test.f90", directory: "/path/to")
!2 = !{}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !DILocalVariable(name: "total", scope: !5, file: !1, line: 23, type: !7)
!5 = distinct !DISubprogram(name: "first", linkageName: "first_", scope: !1, file: !1, line: 23, type: !6, scopeLine: 23, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !2)
!6 = distinct !DISubroutineType(types: !2)
!7 = !DIBasicType(name: "INTEGER*4", size: 32, encoding: DW_ATE_signed)
!8 = !DILocation(line: 23, column: 36, scope: !5)
