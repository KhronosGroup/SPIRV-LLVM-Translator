;; Ensure that DIExpressions are preserved in DIGlobalVariableExpressions
;; This utilizes SPIRV DebugGlobalVariable's optional field DIExpression

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -o %t.spv %t.bc --spirv-debug-info-version=nonsemantic-shader-200
; RUN: llvm-spirv -r -o %t.rev.bc %t.spv
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck %s --input-file %t.rev.ll

; CHECK: ![[#]] = !DIGlobalVariableExpression(var: ![[#GV:]], expr: !DIExpression(DW_OP_constu, 1, DW_OP_stack_value))
; CHECK: ![[#GV]] = distinct !DIGlobalVariable(name: "true", scope: ![[#]], file: ![[#]], line: 3777, type: ![[#]], isLocal: true, isDefinition: true)

!llvm.module.flags = !{!0, !1}
!llvm.dbg.cu = !{!2}

!0 = !{i32 7, !"Dwarf Version", i32 4}
!1 = !{i32 2, !"Debug Info Version", i32 3}
!2 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !3, producer: "clang", emissionKind: FullDebug, globals: !4)
!3 = !DIFile(filename: "test.cpp", directory: "/path/to")
!4 = !{!5}
!5 = !DIGlobalVariableExpression(var: !6, expr: !DIExpression(DW_OP_constu, 1, DW_OP_stack_value))
!6 = distinct !DIGlobalVariable(name: "true", scope: !2, file: !3, line: 3777, type: !7, isLocal: true, isDefinition: true)
!7 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !8)
!8 = !DIBasicType(name: "bool", size: 8, encoding: DW_ATE_boolean)
