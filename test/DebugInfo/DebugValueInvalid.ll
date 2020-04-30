; Source:
; __kernel void kernel_fn(__global int *res) {}
;
; __kernel void testKernel(__global int *res) {
;   ndrange_t ndrange;
;   void (^kernelBlock)(void) = ^{ kernel_fn(res); };
;   enqueue_kernel(get_default_queue(), CLK_ENQUEUE_FLAGS_NO_WAIT, ndrange, kernelBlock);
; }

; Command:
; clang-7 -cc1 -triple spir -cl-std=cl2.0 -finclude-default-header -disable-llvm-passes /work/tmp/tmp.cl -debug-info-kind=limited -dwarf-column-info -emit-llvm -o - | opt-7 -mem2reg -S -o test/DebugInfo/DebugValueInvalid.ll

; RUN: llvm-as < %s | llvm-spirv -spirv-text -o %t
; RUN: FileCheck < %t %s

; ModuleID = '<stdin>'
source_filename = "/work/tmp/tmp.cl"
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir"

%struct.ndrange_t = type { i32, [3 x i32], [3 x i32], [3 x i32] }
%opencl.queue_t = type opaque

; Function Attrs: convergent nounwind
define spir_kernel void @kernel_fn(i32 addrspace(1)* %res) #0 !dbg !7 !kernel_arg_addr_space !15 !kernel_arg_access_qual !16 !kernel_arg_type !17 !kernel_arg_base_type !17 !kernel_arg_type_qual !18 {
entry:
  call void @llvm.dbg.value(metadata i32 addrspace(1)* %res, metadata !14, metadata !DIExpression()), !dbg !19
  ret void, !dbg !20
}

; Function Attrs: nounwind readnone speculatable
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: convergent nounwind
define spir_kernel void @testKernel(i32 addrspace(1)* %res) #0 !dbg !21 !kernel_arg_addr_space !15 !kernel_arg_access_qual !16 !kernel_arg_type !17 !kernel_arg_base_type !17 !kernel_arg_type_qual !18 {
entry:
  %ndrange = alloca %struct.ndrange_t, align 4
  %block = alloca <{ i32, i32, i32 addrspace(1)* }>, align 4
  %tmp = alloca %struct.ndrange_t, align 4
  call void @llvm.dbg.value(metadata i32 addrspace(1)* %res, metadata !23, metadata !DIExpression()), !dbg !45
  %0 = bitcast %struct.ndrange_t* %ndrange to i8*, !dbg !46
  call void @llvm.lifetime.start.p0i8(i64 40, i8* %0) #5, !dbg !46
  call void @llvm.dbg.declare(metadata %struct.ndrange_t* %ndrange, metadata !24, metadata !DIExpression()), !dbg !47
  %block.size = getelementptr inbounds <{ i32, i32, i32 addrspace(1)* }>, <{ i32, i32, i32 addrspace(1)* }>* %block, i32 0, i32 0, !dbg !48
  store i32 12, i32* %block.size, align 4, !dbg !48
  %block.align = getelementptr inbounds <{ i32, i32, i32 addrspace(1)* }>, <{ i32, i32, i32 addrspace(1)* }>* %block, i32 0, i32 1, !dbg !48
  store i32 4, i32* %block.align, align 4, !dbg !48

  %block.captured = getelementptr inbounds <{ i32, i32, i32 addrspace(1)* }>, <{ i32, i32, i32 addrspace(1)* }>* %block, i32 0, i32 2, !dbg !48
  store i32 addrspace(1)* %res, i32 addrspace(1)** %block.captured, align 4, !dbg !48, !tbaa !49
  %1 = bitcast <{ i32, i32, i32 addrspace(1)* }>* %block to void ()*, !dbg !48
  %2 = addrspacecast void ()* %1 to void () addrspace(4)*, !dbg !48
  call void @llvm.dbg.value(metadata void () addrspace(4)* %2, metadata !38, metadata !DIExpression()), !dbg !53
  %call = call spir_func %opencl.queue_t* @_Z17get_default_queuev() #6, !dbg !54
; CHECK: InBoundsPtrAccessChain
; CHECK: Store
; CHECK: GetDefaultQueue

  %3 = bitcast %struct.ndrange_t* %tmp to i8*, !dbg !55
  %4 = bitcast %struct.ndrange_t* %ndrange to i8*, !dbg !55
  call void @llvm.memcpy.p0i8.p0i8.i32(i8* align 4 %3, i8* align 4 %4, i32 40, i1 false), !dbg !55, !tbaa.struct !56
  %5 = addrspacecast void ()* %1 to i8 addrspace(4)*, !dbg !60
  %6 = call i32 @__enqueue_kernel_basic(%opencl.queue_t* %call, i32 0, %struct.ndrange_t* byval %tmp, i8 addrspace(4)* addrspacecast (i8* bitcast (void (i8 addrspace(4)*)* @__testKernel_block_invoke_kernel to i8*) to i8 addrspace(4)*), i8 addrspace(4)* %5), !dbg !60
  %7 = bitcast %struct.ndrange_t* %ndrange to i8*, !dbg !61
  call void @llvm.lifetime.end.p0i8(i64 40, i8* %7) #5, !dbg !61
  ret void, !dbg !61
}

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.start.p0i8(i64, i8* nocapture) #2

; Function Attrs: convergent nounwind
define internal spir_func void @__testKernel_block_invoke(i8 addrspace(4)* %.block_descriptor) #3 !dbg !62 {
entry:
  call void @llvm.dbg.value(metadata i8 addrspace(4)* %.block_descriptor, metadata !67, metadata !DIExpression()), !dbg !74
  %block = bitcast i8 addrspace(4)* %.block_descriptor to <{ i32, i32, i32 addrspace(1)* }> addrspace(4)*, !dbg !75
  call void @llvm.dbg.declare(metadata <{ i32, i32, i32 addrspace(1)* }> addrspace(4)* %block, metadata !76, metadata !DIExpression(DW_OP_deref, DW_OP_plus_uconst, 8)), !dbg !77
  %block.capture.addr = getelementptr inbounds <{ i32, i32, i32 addrspace(1)* }>, <{ i32, i32, i32 addrspace(1)* }> addrspace(4)* %block, i32 0, i32 2, !dbg !78
  %0 = load i32 addrspace(1)*, i32 addrspace(1)* addrspace(4)* %block.capture.addr, align 4, !dbg !78, !tbaa !49
  call spir_kernel void @kernel_fn(i32 addrspace(1)* %0) #7, !dbg !80
  ret void, !dbg !81
}

; Function Attrs: convergent
declare spir_func %opencl.queue_t* @_Z17get_default_queuev() #4

; Function Attrs: argmemonly nounwind
declare void @llvm.memcpy.p0i8.p0i8.i32(i8* nocapture writeonly, i8* nocapture readonly, i32, i1) #2

; Function Attrs: nounwind
define internal spir_kernel void @__testKernel_block_invoke_kernel(i8 addrspace(4)*) #5 {
entry:
  call void @__testKernel_block_invoke(i8 addrspace(4)* %0), !dbg !60
  ret void, !dbg !60
}

declare i32 @__enqueue_kernel_basic(%opencl.queue_t*, i32, %struct.ndrange_t*, i8 addrspace(4)*, i8 addrspace(4)*)

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.end.p0i8(i64, i8* nocapture) #2

; Function Attrs: nounwind readnone speculatable
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

attributes #0 = { convergent nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable }
attributes #2 = { argmemonly nounwind }
attributes #3 = { convergent nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { convergent "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { nounwind }
attributes #6 = { convergent }
attributes #7 = { convergent "uniform-work-group-size"="false" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4}
!opencl.ocl.version = !{!5}
!opencl.spir.version = !{!5}
!llvm.ident = !{!6}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 7.0.1-svn348686-1~exp1~20181221231927.53 (branches/release_70)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2)
!1 = !DIFile(filename: "/work/tmp/<stdin>", directory: "/work/SPIRV-LLVM-Translator/build")
!2 = !{}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 2, i32 0}
!6 = !{!"clang version 7.0.1-svn348686-1~exp1~20181221231927.53 (branches/release_70)"}
!7 = distinct !DISubprogram(name: "kernel_fn", scope: !8, file: !8, line: 17, type: !9, isLocal: false, isDefinition: true, scopeLine: 17, flags: DIFlagPrototyped, isOptimized: true, unit: !0, retainedNodes: !13)
!8 = !DIFile(filename: "/work/tmp/tmp.cl", directory: "/work/SPIRV-LLVM-Translator/build")
!9 = !DISubroutineType(cc: DW_CC_LLVM_OpenCLKernel, types: !10)
!10 = !{null, !11}
!11 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !12, size: 32)
!12 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!13 = !{!14}
!14 = !DILocalVariable(name: "res", arg: 1, scope: !7, file: !8, line: 17, type: !11)
!15 = !{i32 1}
!16 = !{!"none"}
!17 = !{!"int*"}
!18 = !{!""}
!19 = !DILocation(line: 17, column: 39, scope: !7)
!20 = !DILocation(line: 17, column: 45, scope: !7)
!21 = distinct !DISubprogram(name: "testKernel", scope: !8, file: !8, line: 19, type: !9, isLocal: false, isDefinition: true, scopeLine: 19, flags: DIFlagPrototyped, isOptimized: true, unit: !0, retainedNodes: !22)
!22 = !{!23, !24, !38}
!23 = !DILocalVariable(name: "res", arg: 1, scope: !21, file: !8, line: 19, type: !11)
!24 = !DILocalVariable(name: "ndrange", scope: !21, file: !8, line: 20, type: !25)
!25 = !DIDerivedType(tag: DW_TAG_typedef, name: "ndrange_t", file: !26, line: 15755, baseType: !27)
!26 = !DIFile(filename: "/usr/lib/llvm-7/bin/../lib/clang/7.0.1/include/opencl-c.h", directory: "/work/SPIRV-LLVM-Translator/build")
!27 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !26, line: 15750, size: 320, elements: !28)
!28 = !{!29, !31, !36, !37}
!29 = !DIDerivedType(tag: DW_TAG_member, name: "workDimension", scope: !27, file: !26, line: 15751, baseType: !30, size: 32)
!30 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!31 = !DIDerivedType(tag: DW_TAG_member, name: "globalWorkOffset", scope: !27, file: !26, line: 15752, baseType: !32, size: 96, offset: 32)
!32 = !DICompositeType(tag: DW_TAG_array_type, baseType: !33, size: 96, elements: !34)
!33 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !26, line: 60, baseType: !30)
!34 = !{!35}
!35 = !DISubrange(count: 3)
!36 = !DIDerivedType(tag: DW_TAG_member, name: "globalWorkSize", scope: !27, file: !26, line: 15753, baseType: !32, size: 96, offset: 128)
!37 = !DIDerivedType(tag: DW_TAG_member, name: "localWorkSize", scope: !27, file: !26, line: 15754, baseType: !32, size: 96, offset: 224)
!38 = !DILocalVariable(name: "kernelBlock", scope: !21, file: !8, line: 21, type: !39)
!39 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !40)
!40 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !41, size: 32)
!41 = !DICompositeType(tag: DW_TAG_structure_type, scope: !8, size: 64, flags: DIFlagAppleBlock, elements: !42)
!42 = !{!43, !44}
!43 = !DIDerivedType(tag: DW_TAG_member, name: "__size", scope: !8, file: !8, baseType: !12, size: 32)
!44 = !DIDerivedType(tag: DW_TAG_member, name: "__align", scope: !8, file: !8, baseType: !12, size: 32, offset: 32)
!45 = !DILocation(line: 19, column: 40, scope: !21)
!46 = !DILocation(line: 20, column: 3, scope: !21)
!47 = !DILocation(line: 20, column: 13, scope: !21)
!48 = !DILocation(line: 21, column: 31, scope: !21)
!49 = !{!50, !50, i64 0}
!50 = !{!"any pointer", !51, i64 0}
!51 = !{!"omnipotent char", !52, i64 0}
!52 = !{!"Simple C/C++ TBAA"}
!53 = !DILocation(line: 21, column: 10, scope: !21)
!54 = !DILocation(line: 22, column: 18, scope: !21)
!55 = !DILocation(line: 22, column: 66, scope: !21)
!56 = !{i64 0, i64 4, !57, i64 4, i64 12, !59, i64 16, i64 12, !59, i64 28, i64 12, !59}
!57 = !{!58, !58, i64 0}
!58 = !{!"int", !51, i64 0}
!59 = !{!51, !51, i64 0}
!60 = !DILocation(line: 22, column: 3, scope: !21)
!61 = !DILocation(line: 23, column: 1, scope: !21)
!62 = distinct !DISubprogram(name: "__testKernel_block_invoke", scope: !8, file: !8, line: 21, type: !63, isLocal: true, isDefinition: true, scopeLine: 21, flags: DIFlagPrototyped, isOptimized: true, unit: !0, retainedNodes: !66)
!63 = !DISubroutineType(types: !64)
!64 = !{null, !65}
!65 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 32)
!66 = !{!67}
!67 = !DILocalVariable(name: ".block_descriptor", arg: 1, scope: !62, file: !8, line: 21, type: !68, flags: DIFlagArtificial)
!68 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !69, size: 32)
!69 = !DICompositeType(tag: DW_TAG_structure_type, name: "__block_literal_1", scope: !8, file: !8, line: 21, size: 96, elements: !70)
!70 = !{!71, !72, !73}
!71 = !DIDerivedType(tag: DW_TAG_member, name: "__size", scope: !8, file: !8, line: 21, baseType: !12, size: 32, flags: DIFlagPublic)
!72 = !DIDerivedType(tag: DW_TAG_member, name: "__align", scope: !8, file: !8, line: 21, baseType: !12, size: 32, offset: 32, flags: DIFlagPublic)
!73 = !DIDerivedType(tag: DW_TAG_member, name: "res", scope: !8, file: !8, line: 21, baseType: !11, size: 32, offset: 64, flags: DIFlagPublic)
!74 = !DILocation(line: 21, column: 31, scope: !62)
!75 = !DILocation(line: 21, column: 32, scope: !62)
!76 = !DILocalVariable(name: "res", scope: !62, file: !8, line: 19, type: !11)
!77 = !DILocation(line: 19, column: 40, scope: !62)
!78 = !DILocation(line: 21, column: 44, scope: !79)
!79 = distinct !DILexicalBlock(scope: !62, file: !8, line: 21, column: 32)
!80 = !DILocation(line: 21, column: 34, scope: !79)
!81 = !DILocation(line: 21, column: 50, scope: !62)
