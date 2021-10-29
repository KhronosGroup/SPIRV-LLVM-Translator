; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv -spirv-ext=+SPV_INTEL_uniform_group_instructions
; RUN: llvm-spirv %t.spv -o %t.spt -to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck < %t.rev.ll %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: TypeInt [[#TypeInt:]] 32
; CHECK-SPIRV: Constant [[#TypeInt]] [[#Scope:]] 2
; CHECK-SPIRV: Constant [[#TypeInt]] [[#Val1:]] 0
; CHECK-SPIRV: TypeFloat [[#TypeFloat:]] 16
; CHECK-SPIRV: Constant [[#TypeFloat]] [[#Val2:]]

; CHECK-SPIRV: GroupBitwiseAndINTEL [[#TypeInt]] [[#]] [[#Scope]] 0 [[#Val1]]
; CHECK-SPIRV: GroupBitwiseOrINTEL [[#TypeInt]] [[#]] [[#Scope]] 0 [[#Val1]]
; CHECK-SPIRV: GroupBitwiseXorINTEL [[#TypeInt]] [[#]] [[#Scope]] 0 [[#Val1]]
; CHECK-SPIRV: GroupLogicalAndINTEL [[#TypeInt]] [[#]] [[#Scope]] 0 [[#Val1]]
; CHECK-SPIRV: GroupLogicalOrINTEL [[#TypeInt]] [[#]] [[#Scope]] 0 [[#Val1]]
; CHECK-SPIRV: GroupLogicalXorINTEL [[#TypeInt]] [[#]] [[#Scope]] 0 [[#Val1]]
; CHECK-SPIRV: GroupIMulINTEL [[#TypeInt]] [[#]] [[#Scope]] 0 [[#Val1]]
; CHECK-SPIRV: GroupFMulINTEL [[#TypeFloat]] [[#]] [[#Scope]] 0 [[#Val2]]

; CHECK-LLVM: %call1 = call spir_func i32 @_Z28__spirv_GroupBitwiseAndINTEL{{.*}}(i32 2, i32 0, i32 0)
; CHECK-LLVM: %call2 = call spir_func i32 @_Z27__spirv_GroupBitwiseOrINTEL{{.*}}(i32 2, i32 0, i32 0)
; CHECK-LLVM: %call3 = call spir_func i32 @_Z28__spirv_GroupBitwiseXorINTEL{{.*}}(i32 2, i32 0, i32 0)
; CHECK-LLVM: %call4 = call spir_func i32 @_Z28__spirv_GroupLogicalAndINTEL{{.*}}(i32 2, i32 0, i32 0)
; CHECK-LLVM: %call5 = call spir_func i32 @_Z27__spirv_GroupLogicalOrINTEL{{.*}}(i32 2, i32 0, i32 0)
; CHECK-LLVM: %call6 = call spir_func i32 @_Z28__spirv_GroupLogicalXorINTEL{{.*}}(i32 2, i32 0, i32 0)
; CHECK-LLVM: %call7 = call spir_func i32 @_Z22__spirv_GroupIMulINTEL{{.*}}(i32 2, i32 0, i32 0)
; CHECK-LLVM: %call8 = call spir_func half @_Z22__spirv_GroupFMulINTEL{{.*}}(i32 2, i32 0, half 0xH0000)

; ModuleID = 'source.edit.bc'
source_filename = "group_operations.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

; Function Attrs: convergent norecurse
define dso_local spir_func void @_Z10test_groupN2cl4sycl5groupILi1EEE() local_unnamed_addr #0 {
entry:
  %call1 = tail call spir_func i32 @_Z28__spirv_GroupBitwiseAndINTELjji(i32 2, i32 0, i32 0) #2
  %call2 = tail call spir_func i32 @_Z27__spirv_GroupBitwiseOrINTELjji(i32 2, i32 0, i32 0) #2
  %call3 = tail call spir_func i32 @_Z28__spirv_GroupBitwiseXorINTELjji(i32 2, i32 0, i32 0) #2
  %call4 = tail call spir_func i32 @_Z28__spirv_GroupLogicalAndINTELjji(i32 2, i32 0, i32 0) #2
  %call5 = tail call spir_func i32 @_Z27__spirv_GroupLogicalOrINTELjji(i32 2, i32 0, i32 0) #2
  %call6 = tail call spir_func i32 @_Z28__spirv_GroupLogicalXorINTELjji(i32 2, i32 0, i32 0) #2
  %call7 = tail call spir_func i32 @_Z22__spirv_GroupIMulINTELjji(i32 2, i32 0, i32 0) #2
  %call8 = tail call fast spir_func half @_Z22__spirv_GroupFMulINTELjjDF16_(i32 2, i32 0, half 0xH0000) #2
  ret void
}

; Function Attrs: convergent
declare dso_local spir_func i32 @_Z28__spirv_GroupBitwiseAndINTELjji(i32, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func i32 @_Z27__spirv_GroupBitwiseOrINTELjji(i32, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func i32 @_Z28__spirv_GroupBitwiseXorINTELjji(i32, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func i32 @_Z28__spirv_GroupLogicalAndINTELjji(i32, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func i32 @_Z27__spirv_GroupLogicalOrINTELjji(i32, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func i32 @_Z28__spirv_GroupLogicalXorINTELjji(i32, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func i32 @_Z22__spirv_GroupIMulINTELjji(i32, i32, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare dso_local spir_func half @_Z22__spirv_GroupFMulINTELjjDF16_(i32, i32, half) local_unnamed_addr #1

attributes #0 = { convergent norecurse "denormal-fp-math"="preserve-sign,preserve-sign" "denormal-fp-math-f32"="ieee,ieee" "frame-pointer"="all" "min-legal-vector-width"="0" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "sycl-module-id"="group_operations.cpp" "unsafe-fp-math"="true" }
attributes #1 = { convergent "denormal-fp-math"="preserve-sign,preserve-sign" "denormal-fp-math-f32"="ieee,ieee" "frame-pointer"="all" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #2 = { convergent }
