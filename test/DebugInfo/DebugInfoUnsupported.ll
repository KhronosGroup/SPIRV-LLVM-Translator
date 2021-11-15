; This test checks that metadata with unknown DWARF operations is translated
; to "empty" debug info to SPIR-V and back.
; TODO: remove this test as soon as more DWARF operations are supported.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: [[#DEBUG_NONE:]] [[#]] DebugInfoNone
; CHECK-SPIRV: [[#DEBUG_TYPE_FUNC:]] [[#]] DebugTypeFunction [[#]] [[#DEBUG_NONE]]
; CHECK-SPIRV: [[#DEBUG_FUNC:]] [[#]] DebugFunction [[#]] [[#DEBUG_TYPE_FUNC]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#DEBUG_NONE]]
; CHECK-SPIRV: [[#DEBUG_LOC_VAR:]] [[#]] DebugLocalVariable [[#]] [[#]] [[#]] [[#]] [[#]] [[#DEBUG_FUNC]]
; CHECK-SPIRV: [[#EXPRESSION:]] [[#]] DebugExpression
; CHECK-SPIRV: DebugValue [[#DEBUG_LOC_VAR]] [[#]] [[#EXPRESSION]]

target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "spir64-unknown-unknown"

declare void @llvm.dbg.value(metadata, metadata, metadata) nounwind readnone speculatable

define void @DbgIntrinsics() sanitize_memtag {
entry:
  %x = alloca i32, align 4
; CHECK-LLVM-NOT: DW_OP_LLVM_arg
; CHECK-LLVM: call void @llvm.dbg.value(metadata i32* %x, metadata ![[#]], metadata !DIExpression())
; CHECK-LLVM-NOT: DW_OP_LLVM_arg
  call void @llvm.dbg.value(metadata !DIArgList(i32* %x, i32* %x), metadata !6, metadata !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus)), !dbg !10
  store i32 42, i32* %x, align 4
  ret void
}


!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!8, !9}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "clang version 9.0.0", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, nameTableKind: None)
!1 = !DIFile(filename: "stack-tagging.cc", directory: "/tmp")
!2 = !{}
!3 = distinct !DISubprogram(name: "DbgIntrinsics", linkageName: "DbgIntrinsics", scope: !1, file: !1, line: 3, type: !4, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !2)
!4 = !DISubroutineType(types: !5)
!5 = !{null}
!6 = !DILocalVariable(name: "x", scope: !3, file: !1, line: 4, type: !7)
!7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!8 = !{i32 2, !"Dwarf Version", i32 4}
!9 = !{i32 2, !"Debug Info Version", i32 3}
!10 = !DILocation(line: 1, column: 2, scope: !3)
