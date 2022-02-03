; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s --check-prefix=CHECK-LLVM

; Check that vector addrspacecast is properly handled
; at the LLVM regularization stage and further

; CHECK-SPIRV: TypeInt [[int_ty:[0-9]+]] 32
; CHECK-SPIRV: TypePointer [[ptr_gen_ty:[0-9]+]] 8 [[int_ty]]
; CHECK-SPIRV: TypeVector [[vec_gen_ty:[0-9]+]] [[ptr_gen_ty]] 2
; CHECK-SPIRV: TypePointer [[ptr_glob_ty:[0-9]+]] 5 [[int_ty]]
; CHECK-SPIRV: TypeVector [[vec_glob_ty:[0-9]+]] [[ptr_glob_ty]] 2
; CHECK-SPIRV: FunctionParameter [[vec_gen_ty]] [[param:[0-9]+]]
; CHECK-SPIRV: GenericCastToPtr [[vec_glob_ty]] {{[0-9]+}} [[param]]

; CHECK-LLVM: define spir_func void @test(<2 x i32 addrspace(4)*> %arg)
; CHECK-LLVM: addrspacecast <2 x i32 addrspace(4)*> %arg to <2 x i32 addrspace(1)*>

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64"

define spir_func void @test(<2 x i32 addrspace(4)*> %arg) {
  %globalarg = addrspacecast <2 x i32 addrspace(4)*> %arg to <2 x i32 addrspace(1)*>
  %srcptr = extractelement <2 x i32 addrspace(1)*> %globalarg, i32 1
  %val = load i32, i32 addrspace(1)* %srcptr
  %res = add i32 %val, 6
  %dstptr = extractelement <2 x i32 addrspace(1)*> %globalarg, i32 0
  store i32 %res, i32 addrspace(1)* %dstptr
  ret void
}
