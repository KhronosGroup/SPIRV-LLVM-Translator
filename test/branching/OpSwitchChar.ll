;; __kernel void test_switch(__global int* res, uchar val)
;; {
;;   switch(val)
;;   {
;;   case 0:
;;     *res = 1;
;;     break;
;;   case 1:
;;     *res = 2;
;;     break;
;;   case 2:
;;     *res = 3;
;;     break;
;;   }
;; }

; RUN: llvm-as < %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o - | FileCheck %s

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; CHECK: Switch [[#]] [[#]] 0 [[#]] 1 [[#]] 2 [[#]]

define spir_kernel void @test_switch(i32 addrspace(1)* %res, i8 zeroext %val) {
entry:
  %res.addr = alloca i32 addrspace(1)*, align 4
  %val.addr = alloca i8, align 1
  store i32 addrspace(1)* %res, i32 addrspace(1)** %res.addr, align 4
  store i8 %val, i8* %val.addr, align 1
  %0 = load i8, i8* %val.addr, align 1
  switch i8 %0, label %sw.epilog [
    i8 0, label %sw.bb
    i8 1, label %sw.bb1
    i8 2, label %sw.bb2
  ]

sw.bb:                                            ; preds = %entry
  %1 = load i32 addrspace(1)*, i32 addrspace(1)** %res.addr, align 4
  store i32 1, i32 addrspace(1)* %1, align 4
  br label %sw.epilog

sw.bb1:                                           ; preds = %entry
  %2 = load i32 addrspace(1)*, i32 addrspace(1)** %res.addr, align 4
  store i32 2, i32 addrspace(1)* %2, align 4
  br label %sw.epilog

sw.bb2:                                           ; preds = %entry
  %3 = load i32 addrspace(1)*, i32 addrspace(1)** %res.addr, align 4
  store i32 3, i32 addrspace(1)* %3, align 4
  br label %sw.epilog

sw.epilog:                                        ; preds = %entry, %sw.bb2, %sw.bb1, %sw.bb
  ret void
}
