; REQUIRES: spirv-dis
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: spirv-dis %t.spv | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spv -o %t.rev.bc -r --spirv-target-env=SPV-IR
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck --input-file=%t.rev.ll %s --check-prefix=CHECK-LLVM

; Branch weight metadata (as produced by __builtin_expect, [[likely]]/
; [[unlikely]], or PGO) is translated to and from the optional Branch
; Weights operands of OpBranchConditional.

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir64-unknown-unknown"

; CHECK-SPIRV: %weighted_branch = OpFunction
; CHECK-SPIRV: OpBranchConditional %cmp %if_then %if_else 2000 1
define spir_func i32 @weighted_branch(i32 %x) {
entry:
  %cmp = icmp sgt i32 %x, 10
  br i1 %cmp, label %if.then, label %if.else, !prof !0

if.then:
  ret i32 %x

if.else:
  ret i32 %x
}

; CHECK-SPIRV: %unweighted_branch = OpFunction
; CHECK-SPIRV: OpBranchConditional %cmp_0 %if_then_0 %if_else_0{{$}}
define spir_func i32 @unweighted_branch(i32 %x) {
entry:
  %cmp = icmp sgt i32 %x, 10
  br i1 %cmp, label %if.then, label %if.else

if.then:
  ret i32 %x

if.else:
  ret i32 %x
}

; Sum overflows 32 bits, so weights are scaled down.
; CHECK-SPIRV: %large_weights_branch = OpFunction
; CHECK-SPIRV: OpBranchConditional %cmp_1 %if_then_1 %if_else_1 1500000000 1500000000
define spir_func i32 @large_weights_branch(i32 %x) {
entry:
  %cmp = icmp sgt i32 %x, 10
  br i1 %cmp, label %if.then, label %if.else, !prof !1

if.then:
  ret i32 %x

if.else:
  ret i32 %x
}

; Downscaling preserves the ratio between the two weights: 3000000000:1500000000
; is 2:1, same as the scaled-down 1500000000:750000000.
; CHECK-SPIRV: %large_weights_ratio_branch = OpFunction
; CHECK-SPIRV: OpBranchConditional %cmp_2 %if_then_2 %if_else_2 1500000000 750000000
define spir_func i32 @large_weights_ratio_branch(i32 %x) {
entry:
  %cmp = icmp sgt i32 %x, 10
  br i1 %cmp, label %if.then, label %if.else, !prof !4

if.then:
  ret i32 %x

if.else:
  ret i32 %x
}

; NOTE: this sum is exactly UINT32_MAX, so it already fits in 32 bits, but
; llvm::calculateCountScale (ProfDataUtils.h) currently downscales it anyway
; because it checks "< UINT32_MAX" rather than "<= UINT32_MAX". Once that
; off-by-one is fixed upstream, the expected weights below will change from
; 2147483647/0 to 4294967294/1.
; CHECK-SPIRV: %uint32_max_sum_branch = OpFunction
; CHECK-SPIRV: OpBranchConditional %cmp_3 %if_then_3 %if_else_3 2147483647 0
define spir_func i32 @uint32_max_sum_branch(i32 %x) {
entry:
  %cmp = icmp sgt i32 %x, 10
  br i1 %cmp, label %if.then, label %if.else, !prof !5

if.then:
  ret i32 %x

if.else:
  ret i32 %x
}

; A single zero weight is valid and preserved as-is.
; CHECK-SPIRV: %one_zero_weight_branch = OpFunction
; CHECK-SPIRV: OpBranchConditional %cmp_4 %if_then_4 %if_else_4 0 5
define spir_func i32 @one_zero_weight_branch(i32 %x) {
entry:
  %cmp = icmp sgt i32 %x, 10
  br i1 %cmp, label %if.then, label %if.else, !prof !2

if.then:
  ret i32 %x

if.else:
  ret i32 %x
}

; All-zero weights are dropped instead of emitting OpBranchConditional 0 0.
; CHECK-SPIRV: %zero_weights_branch = OpFunction
; CHECK-SPIRV: OpBranchConditional %cmp_5 %if_then_5 %if_else_5{{$}}
define spir_func i32 @zero_weights_branch(i32 %x) {
entry:
  %cmp = icmp sgt i32 %x, 10
  br i1 %cmp, label %if.then, label %if.else, !prof !3

if.then:
  ret i32 %x

if.else:
  ret i32 %x
}

; CHECK-LLVM-LABEL: define spir_func i32 @weighted_branch
; CHECK-LLVM: br i1 %{{.*}}, label %{{.*}}, label %{{.*}}, !prof ![[#PROF:]]

; CHECK-LLVM-LABEL: define spir_func i32 @unweighted_branch
; CHECK-LLVM-NOT: !prof

; CHECK-LLVM-LABEL: define spir_func i32 @large_weights_branch
; CHECK-LLVM: br i1 %{{.*}}, label %{{.*}}, label %{{.*}}, !prof ![[#PROF2:]]

; CHECK-LLVM-LABEL: define spir_func i32 @large_weights_ratio_branch
; CHECK-LLVM: br i1 %{{.*}}, label %{{.*}}, label %{{.*}}, !prof ![[#PROF4:]]

; CHECK-LLVM-LABEL: define spir_func i32 @uint32_max_sum_branch
; CHECK-LLVM: br i1 %{{.*}}, label %{{.*}}, label %{{.*}}, !prof ![[#PROF5:]]

; CHECK-LLVM-LABEL: define spir_func i32 @one_zero_weight_branch
; CHECK-LLVM: br i1 %{{.*}}, label %{{.*}}, label %{{.*}}, !prof ![[#PROF3:]]

; CHECK-LLVM-LABEL: define spir_func i32 @zero_weights_branch
; CHECK-LLVM-NOT: !prof

; CHECK-LLVM: ![[#PROF]] = !{!"branch_weights", i32 2000, i32 1}
; CHECK-LLVM: ![[#PROF2]] = !{!"branch_weights", i32 1500000000, i32 1500000000}
; CHECK-LLVM: ![[#PROF4]] = !{!"branch_weights", i32 1500000000, i32 750000000}
; CHECK-LLVM: ![[#PROF5]] = !{!"branch_weights", i32 2147483647, i32 0}
; CHECK-LLVM: ![[#PROF3]] = !{!"branch_weights", i32 0, i32 5}

!0 = !{!"branch_weights", i32 2000, i32 1}
!1 = !{!"branch_weights", i32 3000000000, i32 3000000000}
!2 = !{!"branch_weights", i32 0, i32 5}
!3 = !{!"branch_weights", i32 0, i32 0}
!4 = !{!"branch_weights", i32 3000000000, i32 1500000000}
!5 = !{!"branch_weights", i32 4294967294, i32 1}
