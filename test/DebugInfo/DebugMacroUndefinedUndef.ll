; This test exercises the cases where there is a DW_MACINFO_undef without a matching DW_MACINFO_def

; Test round-trip translation of debug macro information:
; LLVM IR -> SPIR-V -> LLVM IR

; RUN: llvm-spirv --spirv-debug-info-version=nonsemantic-shader-100 %s -o %t.spv
; RUN: spirv-val %t.spv

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc 
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck %s --input-file %t.rev.ll --check-prefix CHECK

; CHECK-DAG: ![[#r1:]] = !DIFile(filename: "def.c", directory: ".")
; CHECK-DAG: ![[#r2:]] = !DIMacroFile(file: ![[#r1]], nodes: ![[#r3:]])
; CHECK-DAG: ![[#r3]] = !{![[#r5:]]}
; CHECK-DAG: ![[#r5]] = !DIMacro(type: DW_MACINFO_undef, line: 1, name: "<UNAVAILABLE_MACRO_NAME>")

target triple = "spir64-unknown-unknown"

; Function Attrs: nounwind
define spir_func i32 @main() #0 {
entry:
  ret i32 0
}

attributes #0 = { nounwind }

!llvm.module.flags = !{!0, !1, !12}
!llvm.dbg.cu = !{!4}
!spirv.MemoryModel = !{!13}
!opencl.enable.FP_CONTRACT = !{}
!spirv.Source = !{!14}
!opencl.spir.version = !{!15}
!opencl.used.extensions = !{!16}
!opencl.used.optional.core.features = !{!16}
!spirv.Generator = !{!17}

!0 = !{i32 7, !"Dwarf Version", i32 0}
!1 = !{i32 2, !"Source Lang Literal", !2}
!2 = !{!3}
!3 = !{!4, i32 12}
!4 = distinct !DICompileUnit(language: DW_LANG_OpenCL, file: !5, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, macros: !6)
!5 = !DIFile(filename: "def.c", directory: "/tmp")
!6 = !{!7}
!7 = !DIMacroFile(file: !8, nodes: !9)
!8 = !DIFile(filename: "def.c", directory: ".")
!9 = !{!11}
!11 = !DIMacro(type: DW_MACINFO_undef, line: 1, name: "SIZE")
!12 = !{i32 2, !"Debug Info Version", i32 3}
!13 = !{i32 2, i32 2}
!14 = !{i32 4, i32 100000}
!15 = !{i32 1, i32 2}
!16 = !{}
!17 = !{i16 7, i16 0}

