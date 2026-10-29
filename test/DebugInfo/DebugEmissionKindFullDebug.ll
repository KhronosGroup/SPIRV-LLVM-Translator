; Check that a full debug information compilation unit is still described as
; such after a round trip.

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

; CHECK-SPIRV: ModuleProcessed "Debug emission kind: FullDebug"

; CHECK-LLVM: !DICompileUnit({{.*}}emissionKind: FullDebug

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test_kernel(ptr addrspace(1) %out) !dbg !5 {
entry:
  %x = alloca float, align 4
    #dbg_declare(ptr %x, !10, !DIExpression(), !11)
  %0 = load float, ptr addrspace(1) %out, align 4, !dbg !11
  store float %0, ptr %x, align 4, !dbg !11
  ret void, !dbg !12
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3}
!opencl.spir.version = !{!4}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !1, producer: "clang", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "test.cpp", directory: "/tmp")
!2 = !{i32 7, !"Dwarf Version", i32 4}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, i32 2}
!5 = distinct !DISubprogram(name: "test_kernel", scope: !1, file: !1, line: 1, type: !6, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
!6 = !DISubroutineType(types: !7)
!7 = !{null, !8}
!8 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!9 = !{}
!10 = !DILocalVariable(name: "x", scope: !5, file: !1, line: 2, type: !8)
!11 = !DILocation(line: 2, column: 9, scope: !5)
!12 = !DILocation(line: 3, column: 3, scope: !5)
