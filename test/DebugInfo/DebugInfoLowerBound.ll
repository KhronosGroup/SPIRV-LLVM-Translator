; RUN: llvm-as %s -o %t.bc

; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv %t.bc -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s -check-prefix=CHECK-SPIRV

; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll 
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: TypeInt [[TypeIntId:[0-9]+]] 64 0
; CHECK-SPIRV-DAG: Constant [[TypeIntId]] [[Cound1Id:[0-9]+]] 2 0 
; CHECK-SPIRV-DAG: Constant [[TypeIntId]] [[LowerBoundId:[0-9]+]] 5 0 
; CHECK-SPIRV-DAG: Constant [[TypeIntId]] [[Cound2Id:[0-9]+]] 3 0 
; CHECK-SPIRV-DAG: DebugTypeArray {{[0-9 ]+}} [[Cound1Id]] [[Cound2Id]] [[LowerBoundId]] [[LowerBoundId]] 

; CHECK-LLVM: !DISubrange(count: 2, lowerBound: 5)
; CHECK-LLVM: !DISubrange(count: 3, lowerBound: 5)

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024"
target triple = "spir64-unknown-unknown"

!llvm.module.flags = !{!11, !12}
!llvm.dbg.cu = !{!2}
!opencl.enable.FP_CONTRACT = !{}
!spirv.Source = !{!13}
!opencl.spir.version = !{!14}
!opencl.ocl.version = !{!13}
!opencl.used.extensions = !{!4}
!opencl.used.optional.core.features = !{!4}
!spirv.Generator = !{!15}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "value", scope: !2, file: !3, line: 5, type: !6, isLocal: true, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !3, producer: "spirv", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5)
!3 = !DIFile(filename: "kernel.cpp", directory: "/user/matrix/..")
!4 = !{}
!5 = !{!0}
!6 = !DICompositeType(tag: DW_TAG_array_type, baseType: !7, size: 192, elements: !8)
!7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!8 = !{!9, !10}
!9 = !DISubrange(count: 2, lowerBound: 5)
!10 = !DISubrange(count: 3, lowerBound: 5)
!11 = !{i32 2, !"Dwarf Version", i32 4}
!12 = !{i32 2, !"Debug Info Version", i32 3}
!13 = !{i32 0, i32 0}
!14 = !{i32 1, i32 2}
!15 = !{i16 6, i16 14}
