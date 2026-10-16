; Late declarations from globals and debug info must precede definitions.
; RUN: llvm-spirv %s -spirv-ext=+SPV_INTEL_function_pointers -spirv-text -o - | FileCheck %s
; RUN: llvm-spirv %s -spirv-ext=+SPV_INTEL_function_pointers -o %t.spv
; RUN: spirv-val %t.spv

; CHECK-DAG: Name [[F:[0-9]+]] "f"
; CHECK-DAG: Name [[G:[0-9]+]] "g"
; CHECK-DAG: Name [[ADD:[0-9]+]] "_Z12__spirv_IAddii"
; CHECK-DAG: Function {{[0-9]+}} [[G]]
; CHECK-DAG: Function {{[0-9]+}} [[ADD]]
; CHECK: Function {{[0-9]+}} [[F]]

target datalayout = "e-i64:64-n8:16:32:64-G1"
target triple = "spirv64-unknown-unknown"

@t = addrspace(1) constant [2 x ptr] [ptr @f, ptr @g]

declare spir_func void @g()
declare spir_func i32 @_Z12__spirv_IAddii(i32, i32)

define spir_func i32 @f(i32 %x) !dbg !3 {
  call void @llvm.dbg.value(metadata ptr @_Z12__spirv_IAddii, metadata !5, metadata !DIExpression()), !dbg !6
  %r = call spir_func i32 @_Z12__spirv_IAddii(i32 %x, i32 1)
  ret i32 %r
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, emissionKind: FullDebug)
!1 = !DIFile(filename: "t.cpp", directory: "/")
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = distinct !DISubprogram(name: "f", scope: !1, file: !1, type: !4, spFlags: DISPFlagDefinition, unit: !0)
!4 = !DISubroutineType(types: !{})
!5 = !DILocalVariable(name: "p", scope: !3, file: !1, type: !7)
!6 = !DILocation(line: 1, scope: !3)
!7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
