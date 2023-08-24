; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv -opaque-pointers=0 %t.bc -o %t.spt -spirv-ext=+SPV_INTEL_function_pointers,+SPV_INTEL_task_sequence --spirv-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spt -o %t.spv -to-binary
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis -opaque-pointers=0 %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: TypeStruct [[#Struct:]]
; CHECK-SPIRV: TaskSequenceGetINTEL [[#Struct]] [[#Get:]] [[#]] [[#]] [[#]] [[#]]
; CHECK-SPIRV: Store [[#]] [[#Get]]

; CHECK-LLVM: call spir_func void @"_Z28__spirv_TaskSequenceGetINTEL{{.*}}"(%struct.FunctionPacket addrspace(4)* sret(%struct.FunctionPacket) %{{.*}}, %"class.sycl::_V1::ext::intel::experimental::task_sequence.17" addrspace(4)* %{{.*}}, void (%struct.FunctionPacket addrspace(4)*, i1)* @_Z15function2Structb, i64 %{{.*}}, i32 12)

; ModuleID = 'before.bc'
source_filename = "test.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

%struct.FunctionPacket = type <{ float, i8, [3 x i8] }>
%"class.sycl::_V1::ext::intel::experimental::task_sequence.17" = type { i32, i64 }

$_ZTS16TaskSequenceTest = comdat any

; Function Attrs: convergent norecurse
define weak_odr dso_local spir_kernel void @_ZTS16TaskSequenceTest(%"class.sycl::_V1::ext::intel::experimental::task_sequence.17" addrspace(4)* noundef %var1, i64 noundef %var2) {
entry:
  %var = alloca %struct.FunctionPacket, align 4
  %retvar = addrspacecast %struct.FunctionPacket* %var to %struct.FunctionPacket addrspace(4)*
  call spir_func void @_Z28__spirv_TaskSequenceGetINTELIN4sycl3_V13ext5intel12experimental13task_sequenceIL_Z15function2StructbELj12ELj12EEE14FunctionPacketJbEET0_PT_PFS8_DpT1_Emj(%struct.FunctionPacket addrspace(4)* sret(%struct.FunctionPacket) align 4 %retvar, %"class.sycl::_V1::ext::intel::experimental::task_sequence.17" addrspace(4)* noundef %var1, void (%struct.FunctionPacket addrspace(4)*, i1)* noundef nonnull @_Z15function2Structb, i64 noundef %var2, i32 noundef 12)
  call spir_func void @stub(%struct.FunctionPacket addrspace(4)* align 4 %retvar)
  ret void
}

; Function Attrs: convergent nounwind
declare dso_local spir_func void @_Z28__spirv_TaskSequenceGetINTELIN4sycl3_V13ext5intel12experimental13task_sequenceIL_Z15function2StructbELj12ELj12EEE14FunctionPacketJbEET0_PT_PFS8_DpT1_Emj(%struct.FunctionPacket addrspace(4)* sret(%struct.FunctionPacket) align 4, %"class.sycl::_V1::ext::intel::experimental::task_sequence.17" addrspace(4)* noundef, void (%struct.FunctionPacket addrspace(4)*, i1)* noundef, i64 noundef, i32 noundef) local_unnamed_addr

declare spir_func void @stub(%struct.FunctionPacket addrspace(4)* align 4)

declare dso_local spir_func void @_Z15function2Structb(%struct.FunctionPacket addrspace(4)* noalias nocapture writeonly sret(%struct.FunctionPacket) align 4, i1)
