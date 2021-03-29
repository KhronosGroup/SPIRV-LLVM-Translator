; RUN: llvm-as %s -o %t.bc
; Translation shouldn't crash:
; RUN: llvm-spirv %t.bc -spirv-text
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc

source_filename = "llvm-link"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64"

!llvm.module.flags = !{!5, !6, !7, !8}
!llvm.dbg.cu = !{!9}

!0 = !{}
!5 = !{i32 1, !"wchar_size", i32 4}
!6 = !{i32 7, !"PIC Level", i32 2}
!7 = !{i32 2, !"Debug Info Version", i32 3}
!8 = !{i32 2, !"Dwarf Version", i32 4}
!9 = distinct !DICompileUnit(language: DW_LANG_Fortran95, file: !10, producer: " F90 Flang -Beating Intel(R) Fortran 21.0-2297", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !0, globals: !11, imports: !22, splitDebugInlining: false, nameTableKind: None)
!10 = !DIFile(filename: "declare_target_subroutine.F90", directory: "/test")
!11 = !{!12, !20}
!12 = !DIGlobalVariableExpression(var: !13, expr: !DIExpression())
!13 = distinct !DIGlobalVariable(name: "ompvv_sharedenv", linkageName: "ompvv_lib_mp_ompvv_sharedenv_", scope: !14, file: !15, line: 105, type: !16, isLocal: false, isDefinition: true)
!14 = !DIModule(scope: null, name: "ompvv_lib", file: !15, line: 99)
!15 = !DIFile(filename: "./ompvv.F90", directory: "/test")
!16 = !DIBasicType(name: "LOGICAL*4", size: 32, encoding: DW_ATE_boolean)
!18 = distinct !DIGlobalVariable(name: "ompvv_errors", linkageName: "ompvv_lib_mp_ompvv_errors_", scope: !14, file: !15, line: 104, type: !19, isLocal: false, isDefinition: true)
!19 = !DIBasicType(name: "INTEGER*4", size: 32, encoding: DW_ATE_signed)
!20 = !DIGlobalVariableExpression(var: !21, expr: !DIExpression())
!21 = distinct !DIGlobalVariable(name: "ompvv_ishost", linkageName: "ompvv_lib_mp_ompvv_ishost_", scope: !14, file: !15, line: 103, type: !16, isLocal: false, isDefinition: true)
!22 = !{!23}
!23 = !DIImportedEntity(tag: DW_TAG_imported_module, scope: !24, entity: !34, file: !10, line: 24)
!24 = distinct !DISubprogram(name: "declare_target_subroutine", linkageName: "MAIN__", scope: !10, file: !10, line: 23, type: !25, scopeLine: 23, spFlags: DISPFlagDefinition | DISPFlagMainSubprogram, unit: !9, retainedNodes: !27)
!25 = !DISubroutineType(types: !26)
!26 = !{null}
!27 = !{!28, !29}
!28 = !DILocalVariable(name: "sum", scope: !24, file: !10, line: 29, type: !19)
!29 = !DILocalVariable(name: "x", scope: !24, file: !10, line: 29, type: !19)
!31 = !DICompositeType(tag: DW_TAG_array_type, baseType: !19, elements: !32, dataLocation: !DIExpression(DW_OP_push_object_address, DW_OP_deref), associated: !DIExpression(DW_OP_push_object_address, DW_OP_deref, DW_OP_constu, 0, DW_OP_or))
!32 = !{!33}
!33 = !DISubrange(lowerBound: !DIExpression(DW_OP_push_object_address, DW_OP_plus_uconst, 64, DW_OP_deref), upperBound: !DIExpression(DW_OP_push_object_address, DW_OP_plus_uconst, 64, DW_OP_deref, DW_OP_push_object_address, DW_OP_plus_uconst, 48, DW_OP_deref, DW_OP_plus, DW_OP_constu, 1, DW_OP_minus), stride: !DIExpression(DW_OP_push_object_address, DW_OP_plus_uconst, 56, DW_OP_deref))
!34 = !DIModule(scope: !24, name: "iso_fortran_env", isDecl: true)