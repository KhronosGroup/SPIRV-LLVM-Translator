; Ensure that vector type's memory size is preserved (with nonsemantic-shader-200) even if
; it does not equal BaseType*ComponentCount.
;
; This test was derived from DebugInfo/X86/sycl-vec-3.ll.

; RUN: llvm-as < %s -o %t.bc

; RUN: llvm-spirv %t.bc -o %t.100.spv -spirv-debug-info-version=nonsemantic-shader-100 -spirv-ext=+SPV_INTEL_vector_compute,+SPV_KHR_non_semantic_info
; RUN: llvm-spirv -r %t.100.spv -o %t.100.bc
; RUN: llvm-dis %t.100.bc -o - | FileCheck %s --check-prefixes=CHECK,CHECK-100

; RUN: llvm-spirv %t.bc -o %t.200.spv -spirv-debug-info-version=nonsemantic-shader-200 -spirv-ext=+SPV_INTEL_vector_compute,+SPV_KHR_non_semantic_info
; RUN: llvm-spirv -r %t.200.spv -o %t.200.bc
; RUN: llvm-dis %t.200.bc -o - | FileCheck %s --check-prefixes=CHECK,CHECK-200

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%"class.cl::sycl::vec" = type { <832 x i32> }
@vector = dso_local addrspace(1) global %"class.cl::sycl::vec" zeroinitializer, align 16, !dbg !0

!llvm.dbg.cu = !{!9}
!llvm.module.flags = !{!10, !11, !12, !13, !14}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "vector", scope: null, file: !2, line: 3, type: !3, isLocal: false, isDefinition: true)
!2 = !DIFile(filename: "sycl-vec-3.cpp", directory: "/tmp")
; nonsemantic-shader-100 does not have 'Memory Size' field.  Memory size is estimated with (element size * number of elements).
; CHECK-100: !DICompositeType(tag: DW_TAG_array_type, baseType: ![[BASE_TY:[0-9]+]],{{.*}} size: 26624, flags: DIFlagVector, elements: ![[ELEMS:[0-9]+]])
; nonsemantic-shader-200 has 'Memory Size' field.  Memory size is accurately preserved.
; CHECK-200: !DICompositeType(tag: DW_TAG_array_type, baseType: ![[BASE_TY:[0-9]+]],{{.*}} size: 32768, flags: DIFlagVector, elements: ![[ELEMS:[0-9]+]])
!3 = distinct !DICompositeType(tag: DW_TAG_array_type, baseType: !6, file: !2, line: 3, size: 32768, flags: DIFlagVector, elements: !4, identifier: "_ZTSN2cl4sycl3vecIiLi3EEE")
; CHECK-DAG: ![[ELEMS]] = !{![[ELEMS_RANGE:[0-9]+]]}
!4 = !{!5}
; CHECK-DAG: ![[ELEMS_RANGE]] = !DISubrange(count: 832{{.*}})
!5 = !DISubrange(count: 832)
; CHECK-DAG: ![[BASE_TY]] = !DIBasicType(name: "int", size: 32,{{.*}} encoding: DW_ATE_signed)
!6 = !DIBasicType(name: "int", size: 32, align: 32, encoding: DW_ATE_signed)
!7 = !{}
!8 = !{!0}
!9 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !2, producer: "clang version 13.0.0 (https://github.com/intel/llvm.git)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !7, retainedTypes: !7, globals: !8, imports: !7)
!10 = !{i32 7, !"Dwarf Version", i32 4}
!11 = !{i32 2, !"Debug Info Version", i32 3}
!12 = !{i32 1, !"wchar_size", i32 4}
!13 = !{i32 7, !"uwtable", i32 1}
!14 = !{i32 7, !"frame-pointer", i32 2}
