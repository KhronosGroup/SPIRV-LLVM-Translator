; One emission kind is recorded per compilation unit, but the kind applies to
; the whole module, so compilation units that disagree all become FullDebug.
; The line-table-only unit comes first, so the fallback has to overwrite it.

; RUN: llvm-spirv %s --spirv-debug-info-version=ocl-100 -o %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: llvm-spirv %s --spirv-ext=+SPV_KHR_non_semantic_info \
; RUN:   --spirv-debug-info-version=nonsemantic-shader-100 -o %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: llvm-spirv %s --spirv-debug-info-version=nonsemantic-shader-200 -o %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: ModuleProcessed "Debug emission kind: LineTablesOnly"
; CHECK-SPIRV-DAG: ModuleProcessed "Debug emission kind: FullDebug"

; CHECK-LLVM-COUNT-2: !DICompileUnit({{.*}}emissionKind: FullDebug
; CHECK-LLVM-NOT: emissionKind: LineTablesOnly

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spir64-unknown-unknown"

define spir_kernel void @line_tables_kernel(ptr addrspace(1) %out) !dbg !7 {
entry:
  %0 = load float, ptr addrspace(1) %out, align 4, !dbg !10
  store float %0, ptr addrspace(1) %out, align 4, !dbg !10
  ret void, !dbg !10
}

define spir_kernel void @full_kernel(ptr addrspace(1) %out) !dbg !11 {
entry:
  %x = alloca float, align 4
    #dbg_declare(ptr %x, !15, !DIExpression(), !16)
  %0 = load float, ptr addrspace(1) %out, align 4, !dbg !16
  store float %0, ptr %x, align 4, !dbg !16
  ret void, !dbg !16
}

!llvm.dbg.cu = !{!0, !5}
!llvm.module.flags = !{!2, !3}
!opencl.spir.version = !{!4}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !1, producer: "clang", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "lines.cpp", directory: "/tmp")
!2 = !{i32 7, !"Dwarf Version", i32 4}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, i32 2}
!5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !6, producer: "clang", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!6 = !DIFile(filename: "full.cpp", directory: "/tmp")
!7 = distinct !DISubprogram(name: "line_tables_kernel", scope: !1, file: !1, line: 1, type: !8, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!8 = !DISubroutineType(types: !9)
!9 = !{}
!10 = !DILocation(line: 1, column: 1, scope: !7)
!11 = distinct !DISubprogram(name: "full_kernel", scope: !6, file: !6, line: 1, type: !12, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !9)
!12 = !DISubroutineType(types: !13)
!13 = !{null, !14}
!14 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!15 = !DILocalVariable(name: "x", scope: !11, file: !6, line: 2, type: !14)
!16 = !DILocation(line: 2, column: 9, scope: !11)
