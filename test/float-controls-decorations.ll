; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv %t.spv -o %t.spt --to-text
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.spv -o %t.bc -r 
; RUN: llvm-dis %t.bc -o %t.ll
; RUN: FileCheck < %t.ll %s --check-prefix=CHECK-LLVM
target triple = "spir64"


define dso_local <4 x i32> @foo(<4 x i32> %a, <4 x i32> %b) #0 {
entry:
  ret <4 x i32> %a
}

define dso_local <4 x i32> @bar(<4 x i32> %a, <4 x i32> %b) #1 {
entry:
  ret <4 x i32> %b
}


; CHECK-LLVM: "VCFloatControl"="0"
; CHECK-LLVM: "VCFloatControl"="48"
; CHECK-SPIRV: 3 Name [[FOO_ID:[0-9]+]] "foo"
; CHECK-SPIRV: 3 Name [[BAR_ID:[0-9]+]] "bar"
; CHECK-SPIRV: 5 Decorate [[DEC_DENORM_GROUP_ID:[0-9]+]] FunctionDenormModeINTEL 16 1
; CHECK-SPIRV: 5 Decorate [[DEC_DENORM_GROUP_ID_1:[0-9]+]] FunctionDenormModeINTEL 32 1
; CHECK-SPIRV: 5 Decorate [[DEC_DENORM_GROUP_ID_2:[0-9]+]] FunctionDenormModeINTEL 64 1
; CHECK-SPIRV: 5 Decorate [[DEC_FLT_GROUP_ID:[0-9]+]] FunctionFloatingPointModeINTEL 16 0
; CHECK-SPIRV: 5 Decorate [[DEC_FLT_GROUP_ID_1:[0-9]+]] FunctionFloatingPointModeINTEL 32 0
; CHECK-SPIRV: 5 Decorate [[DEC_FLT_GROUP_ID_2:[0-9]+]] FunctionFloatingPointModeINTEL 64 0
; CHECK-SPIRV: 5 Decorate [[FOO_ID]] FunctionRoundingModeINTEL 16 0
; CHECK-SPIRV-NEXT: 5 Decorate [[BAR_ID]] FunctionRoundingModeINTEL 16 1
; CHECK-SPIRV-NEXT: 5 Decorate [[FOO_ID]] FunctionRoundingModeINTEL 32 0
; CHECK-SPIRV-NEXT: 5 Decorate [[BAR_ID]] FunctionRoundingModeINTEL 32 1
; CHECK-SPIRV-NEXT: 5 Decorate [[FOO_ID]] FunctionRoundingModeINTEL 64 0
; CHECK-SPIRV-NEXT: 5 Decorate [[BAR_ID]] FunctionRoundingModeINTEL 64 1
; CHECK-SPIRV: 4 GroupDecorate [[DEC_DENORM_GROUP_ID]] [[FOO_ID]] [[BAR_ID]]
; CHECK-SPIRV-NEXT: 4 GroupDecorate [[DEC_DENORM_GROUP_ID_1]] [[FOO_ID]] [[BAR_ID]]
; CHECK-SPIRV-NEXT: 4 GroupDecorate [[DEC_DENORM_GROUP_ID_2]] [[FOO_ID]] [[BAR_ID]]
; CHECK-SPIRV-NEXT: 4 GroupDecorate [[DEC_FLT_GROUP_ID]] [[FOO_ID]] [[BAR_ID]]
; CHECK-SPIRV-NEXT: 4 GroupDecorate [[DEC_FLT_GROUP_ID_1]] [[FOO_ID]] [[BAR_ID]]
; CHECK-SPIRV-NEXT: 4 GroupDecorate [[DEC_FLT_GROUP_ID_2]] [[FOO_ID]] [[BAR_ID]]

attributes #0 = { "VCFloatControl"="0" "VCFunction"  }
attributes #1 = { "VCFloatControl"="48" "VCFunction" }


