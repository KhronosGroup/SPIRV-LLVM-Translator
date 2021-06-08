; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o %t.txt
; RUN: FileCheck < %t.txt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV-NOT: llvm.memmove

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "spir64-unknown-unknown"

declare void @llvm.memmove.p1i8.p1i8.i64(i8 addrspace(1)* nocapture, i8 addrspace(1)* nocapture readonly, i64, i1)

define spir_func void @memmove_caller(i8 addrspace(1)* %dst, i8 addrspace(1)* %src, i64 %n) {
entry:
  call void @llvm.memmove.p1i8.p1i8.i64(i8 addrspace(1)* %dst, i8 addrspace(1)* %src, i64 %n, i1 false)
  ret void

; CHECK-LLVM: @memmove_caller(i8 addrspace(1)* [[DST:%.*]], i8 addrspace(1)* [[SRC:%.*]], i64 [[N:%.*]])
; CHECK-LLVM:  [[SRC_CMP:%.*]] = ptrtoint i8 addrspace(1)* %src to i64
; CHECK-LLVM:  [[DST_CMP:%.*]] = ptrtoint i8 addrspace(1)* %dst to i64
; CHECK-LLVM: [[COMPARE_SRC_DST:%.*]] = icmp ult i64 [[SRC_CMP]], [[DST_CMP]]
; CHECK-LLVM-NEXT: [[COMPARE_N_TO_0:%.*]] = icmp eq i64 [[N]], 0
; CHECK-LLVM-NEXT: br i1 [[COMPARE_SRC_DST]], label [[COPY_BACKWARDS:%.*]], label [[COPY_FORWARD:%.*]]
; CHECK-LLVM: copy_backwards:
; CHECK-LLVM-NEXT: br i1 [[COMPARE_N_TO_0]], label [[MEMMOVE_DONE:%.*]], label [[COPY_BACKWARDS_LOOP:%.*]]
; CHECK-LLVM: copy_backwards_loop:
; CHECK-LLVM-NEXT: [[TMP1:%.*]] = phi i64 [ [[INDEX_PTR:%.*]], [[COPY_BACKWARDS_LOOP]] ], [ [[N]], [[COPY_BACKWARDS]] ]
; CHECK-LLVM-NEXT: [[INDEX_PTR]] = sub i64 [[TMP1]], 1
; CHECK-LLVM-NEXT: [[TMP2:%.*]] = getelementptr inbounds i8, i8 addrspace(1)* [[SRC]], i64 [[INDEX_PTR]]
; CHECK-LLVM-NEXT: [[ELEMENT:%.*]] = load i8, i8 addrspace(1)* [[TMP2]], align 1
; CHECK-LLVM-NEXT: [[TMP3:%.*]] = getelementptr inbounds i8, i8 addrspace(1)* [[DST]], i64 [[INDEX_PTR]]
; CHECK-LLVM-NEXT: store i8 [[ELEMENT]], i8 addrspace(1)* [[TMP3]], align 1
; CHECK-LLVM-NEXT: [[TMP4:%.*]] = icmp eq i64 [[INDEX_PTR]], 0
; CHECK-LLVM-NEXT: br i1 [[TMP4]], label [[MEMMOVE_DONE]], label [[COPY_BACKWARDS_LOOP]]
; CHECK-LLVM: copy_forward:
; CHECK-LLVM-NEXT: br i1 [[COMPARE_N_TO_0]], label [[MEMMOVE_DONE]], label [[COPY_FORWARD_LOOP:%.*]]
; CHECK-LLVM: copy_forward_loop:
; CHECK-LLVM-NEXT: [[INDEX_PTR1:%.*]] = phi i64 [ [[INDEX_INCREMENT:%.*]], [[COPY_FORWARD_LOOP]] ], [ 0, [[COPY_FORWARD]] ]
; CHECK-LLVM-NEXT: [[TMP5:%.*]] = getelementptr inbounds i8, i8 addrspace(1)* [[SRC]], i64 [[INDEX_PTR1]]
; CHECK-LLVM-NEXT: [[ELEMENT2:%.*]] = load i8, i8 addrspace(1)* [[TMP5]], align 1
; CHECK-LLVM-NEXT: [[TMP6:%.*]] = getelementptr inbounds i8, i8 addrspace(1)* [[DST]], i64 [[INDEX_PTR1]]
; CHECK-LLVM-NEXT: store i8 [[ELEMENT2]], i8 addrspace(1)* [[TMP6]], align 1
; CHECK-LLVM-NEXT: [[INDEX_INCREMENT]] = add i64 [[INDEX_PTR1]], 1
; CHECK-LLVM-NEXT: [[TMP7:%.*]] = icmp eq i64 [[INDEX_INCREMENT]], [[N]]
; CHECK-LLVM-NEXT: br i1 [[TMP7]], label [[MEMMOVE_DONE]], label [[COPY_FORWARD_LOOP]]
; CHECK-LLVM: memmove_done:
; CHECK-LLVM-NEXT: ret void

}
