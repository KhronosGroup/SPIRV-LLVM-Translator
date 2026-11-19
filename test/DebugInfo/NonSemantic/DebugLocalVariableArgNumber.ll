; RUN: llvm-spirv %s --spirv-debug-info-version=nonsemantic-shader-100 -spirv-text -o - | FileCheck %s --check-prefix CHECK-SPIRV
; RUN: llvm-spirv %s --spirv-debug-info-version=nonsemantic-shader-100 -o %t.100.spv
; RUN: spirv-val %t.100.spv
; RUN: llvm-spirv -r %t.100.spv -o - | llvm-dis | FileCheck %s --check-prefix CHECK-LLVM
; RUN: llvm-spirv %s --spirv-debug-info-version=nonsemantic-shader-200 -spirv-text -o - | FileCheck %s --check-prefix CHECK-SPIRV
; RUN: llvm-spirv %s --spirv-debug-info-version=nonsemantic-shader-200 -o %t.200.spv
; RUN: spirv-val %t.200.spv
; RUN: llvm-spirv -r %t.200.spv -o - | llvm-dis | FileCheck %s --check-prefix CHECK-LLVM

; Test that the DebugLocalVariable ArgNumber operand is the <id> of an
; OpConstant and is read back as the argument number.

; CHECK-SPIRV-DAG: String [[#NameA:]] "a"
; CHECK-SPIRV-DAG: String [[#NameB:]] "b"
; CHECK-SPIRV-DAG: Constant [[#]] [[#One:]] 1 {{$}}
; CHECK-SPIRV-DAG: Constant [[#]] [[#Two:]] 2 {{$}}
; CHECK-SPIRV: DebugLocalVariable [[#NameA]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#One]] {{$}}
; CHECK-SPIRV: DebugLocalVariable [[#NameB]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#]] [[#Two]] {{$}}

; CHECK-LLVM-DAG: DILocalVariable(name: "a", arg: 1,
; CHECK-LLVM-DAG: DILocalVariable(name: "b", arg: 2,

target triple = "spir64-unknown-unknown"

define spir_func i32 @foo(i32 %a, i32 %b) !dbg !5 {
entry:
    #dbg_value(i32 %a, !9, !DIExpression(), !11)
    #dbg_value(i32 %b, !12, !DIExpression(), !11)
  %r = add i32 %a, %b, !dbg !11
  ret i32 %r, !dbg !11
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3}

!0 = distinct !DICompileUnit(language: DW_LANG_OpenCL, file: !1, producer: "clang", emissionKind: FullDebug)
!1 = !DIFile(filename: "foo.cl", directory: "/")
!3 = !{i32 2, !"Debug Info Version", i32 3}
!5 = distinct !DISubprogram(name: "foo", scope: !1, file: !1, line: 3, type: !6, unit: !0, spFlags: DISPFlagDefinition, retainedNodes: !{})
!6 = !DISubroutineType(types: !{null})
!9 = !DILocalVariable(name: "a", arg: 1, scope: !5, file: !1, line: 3, type: !10)
!10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!11 = !DILocation(line: 4, scope: !5)
!12 = !DILocalVariable(name: "b", arg: 2, scope: !5, file: !1, line: 3, type: !10)
