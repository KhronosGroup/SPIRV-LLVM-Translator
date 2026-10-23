; Debug directives produce the same debug instructions as line tables, so the
; two kinds are only told apart by the recorded emission kind.

; RUN: llvm-spirv %s --spirv-debug-info-version=ocl-100 -o %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM

; RUN: llvm-spirv %s --spirv-debug-info-version=nonsemantic-shader-200 -o %t.spv
; RUN: llvm-spirv --to-text %t.spv -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: ModuleProcessed "Debug emission kind: DebugDirectivesOnly"

; CHECK-LLVM: !DICompileUnit({{.*}}emissionKind: DebugDirectivesOnly

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test_kernel(ptr addrspace(1) %out) !dbg !5 {
entry:
  %0 = load float, ptr addrspace(1) %out, align 4, !dbg !7
  %add = fadd float %0, 1.000000e+00, !dbg !7
  store float %add, ptr addrspace(1) %out, align 4, !dbg !7
  ret void, !dbg !8
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3}
!opencl.spir.version = !{!4}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !1, producer: "clang", isOptimized: true, runtimeVersion: 0, emissionKind: DebugDirectivesOnly, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "test.cpp", directory: "/tmp")
!2 = !{i32 7, !"Dwarf Version", i32 4}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, i32 2}
!5 = distinct !DISubprogram(name: "test_kernel", scope: !1, file: !1, line: 1, type: !6, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!6 = !DISubroutineType(types: !9)
!7 = !DILocation(line: 2, column: 3, scope: !5)
!8 = !DILocation(line: 3, column: 3, scope: !5)
!9 = !{}
