; Regression for llvm-spirv assert in SPIRVModule::getEntry when translating
; many freeze instructions with NonSemantic.Shader.DebugInfo.200 and
; SPV_KHR_poison_freeze disabled (default for -spirv-ext=-all,+... lists).
;
; RUN: llvm-spirv %s -o %t.spv --spirv-debug-info-version=nonsemantic-shader-200
; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_KHR_poison_freeze --spirv-debug-info-version=nonsemantic-shader-200
; RUN: llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV: FreezeKHR

!llvm.dbg.cu = !{!0}
!0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "clang", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, globals: !3, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "freeze-many-nonsemantic-debug.ll", directory: "/test")
!2 = !{}
!3 = !{}

!4 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !1, name: "ctx", scope: !0, elements: !5, identifier: "ctx")
!5 = !{!6}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed, flags: DIFlagPublic)

!7 = distinct !DISubprogram(name: "kernel_many_freeze", scope: !1, file: !1, line: 1, type: !8, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagMainSubprogram, unit: !0, retainedNodes: !9)
!8 = !DISubroutineType(types: !10)
!9 = !{!11}
!10 = !{null}
!11 = !DILocalVariable(name: "acc", scope: !7, file: !1, line: 2, type: !6)

define spir_kernel void @kernel_many_freeze() !dbg !7 {
entry:
  %acc = alloca i32, align 4
  store i32 0, ptr %acc, align 4, !dbg !12
  br label %loop, !dbg !13

loop:
  %x = load i32, ptr %acc, align 4, !dbg !14
  %cmp0 = icmp slt i32 %x, 100, !dbg !15
  %fr0 = freeze i1 %cmp0, !dbg !16
  %cmp1 = icmp sgt i32 %x, 0, !dbg !17
  %fr1 = freeze i1 %cmp1, !dbg !18
  %cmp2 = icmp eq i32 %x, 42, !dbg !19
  %fr2 = freeze i1 %cmp2, !dbg !20
  %cmp3 = icmp ne i32 %x, 7, !dbg !21
  %fr3 = freeze i1 %cmp3, !dbg !22
  %cmp4 = icmp slt i32 %x, 50, !dbg !23
  %fr4 = freeze i1 %cmp4, !dbg !24
  %cmp5 = icmp sgt i32 %x, 10, !dbg !25
  %fr5 = freeze i1 %cmp5, !dbg !26
  %cmp6 = icmp eq i32 %x, 3, !dbg !27
  %fr6 = freeze i1 %cmp6, !dbg !28
  %cmp7 = icmp ne i32 %x, 1, !dbg !29
  %fr7 = freeze i1 %cmp7, !dbg !30
  %cmp8 = icmp slt i32 %x, 80, !dbg !31
  %fr8 = freeze i1 %cmp8, !dbg !32
  %cmp9 = icmp sgt i32 %x, 5, !dbg !33
  %fr9 = freeze i1 %cmp9, !dbg !34
  call void @llvm.dbg.value(metadata i1 %fr0, metadata !11, metadata !DIExpression()), !dbg !35
  call void @llvm.dbg.value(metadata i1 %fr1, metadata !11, metadata !DIExpression()), !dbg !36
  call void @llvm.dbg.value(metadata i1 %fr2, metadata !11, metadata !DIExpression()), !dbg !37
  call void @llvm.dbg.value(metadata i1 %fr3, metadata !11, metadata !DIExpression()), !dbg !38
  call void @llvm.dbg.value(metadata i1 %fr4, metadata !11, metadata !DIExpression()), !dbg !39
  call void @llvm.dbg.value(metadata i1 %fr5, metadata !11, metadata !DIExpression()), !dbg !40
  call void @llvm.dbg.value(metadata i1 %fr6, metadata !11, metadata !DIExpression()), !dbg !41
  call void @llvm.dbg.value(metadata i1 %fr7, metadata !11, metadata !DIExpression()), !dbg !42
  call void @llvm.dbg.value(metadata i1 %fr8, metadata !11, metadata !DIExpression()), !dbg !43
  call void @llvm.dbg.value(metadata i1 %fr9, metadata !11, metadata !DIExpression()), !dbg !44
  %inc = add nsw i32 %x, 1, !dbg !45
  store i32 %inc, ptr %acc, align 4, !dbg !46
  %done = icmp eq i32 %inc, 100, !dbg !47
  br i1 %done, label %exit, label %loop, !dbg !13

exit:
  ret void, !dbg !48
}

!12 = !DILocation(line: 2, column: 3, scope: !7)
!13 = !DILocation(line: 3, column: 3, scope: !7)
!14 = !DILocation(line: 4, column: 10, scope: !7)
!15 = !DILocation(line: 5, column: 10, scope: !7)
!16 = !DILocation(line: 5, column: 10, scope: !7)
!17 = !DILocation(line: 6, column: 10, scope: !7)
!18 = !DILocation(line: 6, column: 10, scope: !7)
!19 = !DILocation(line: 7, column: 10, scope: !7)
!20 = !DILocation(line: 7, column: 10, scope: !7)
!21 = !DILocation(line: 8, column: 10, scope: !7)
!22 = !DILocation(line: 8, column: 10, scope: !7)
!23 = !DILocation(line: 9, column: 10, scope: !7)
!24 = !DILocation(line: 9, column: 10, scope: !7)
!25 = !DILocation(line: 10, column: 10, scope: !7)
!26 = !DILocation(line: 10, column: 10, scope: !7)
!27 = !DILocation(line: 11, column: 10, scope: !7)
!28 = !DILocation(line: 11, column: 10, scope: !7)
!29 = !DILocation(line: 12, column: 10, scope: !7)
!30 = !DILocation(line: 12, column: 10, scope: !7)
!31 = !DILocation(line: 13, column: 10, scope: !7)
!32 = !DILocation(line: 13, column: 10, scope: !7)
!33 = !DILocation(line: 14, column: 10, scope: !7)
!34 = !DILocation(line: 14, column: 10, scope: !7)
!35 = !DILocation(line: 15, column: 3, scope: !7)
!36 = !DILocation(line: 16, column: 3, scope: !7)
!37 = !DILocation(line: 17, column: 3, scope: !7)
!38 = !DILocation(line: 18, column: 3, scope: !7)
!39 = !DILocation(line: 19, column: 3, scope: !7)
!40 = !DILocation(line: 20, column: 3, scope: !7)
!41 = !DILocation(line: 21, column: 3, scope: !7)
!42 = !DILocation(line: 22, column: 3, scope: !7)
!43 = !DILocation(line: 23, column: 3, scope: !7)
!44 = !DILocation(line: 24, column: 3, scope: !7)
!45 = !DILocation(line: 25, column: 10, scope: !7)
!46 = !DILocation(line: 25, column: 8, scope: !7)
!47 = !DILocation(line: 26, column: 10, scope: !7)
!48 = !DILocation(line: 27, column: 3, scope: !7)

!opencl.spir.version = !{!49}
!spirv.Source = !{!50}
!49 = !{i32 1, i32 2}
!50 = !{i32 4, i32 100000}
