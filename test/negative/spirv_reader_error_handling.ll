; readSpirv() is documented to report a rejected module by returning false and
; filling in an error string. It instead reaches std::exit() through
; SPIRVErrorLog::checkError(), because the error handling kind was a global
; defaulting to Exit, so the caller's error handling never ran.
;
; Check that the kind is selectable through TranslatorOpts, and that the non
; fatal kind both keeps the process alive and carries the reason out to the
; caller.
;
; RUN: echo 'not a SPIR-V module' > %t.spv
; RUN: not llvm-spirv -r --spirv-error-handling=ignore %t.spv -o %t.bc 2>&1 | FileCheck %s
;
; The reason has to survive the call, and nothing may be written to stderr
; ahead of the caller's own diagnostic.
; CHECK-NOT: {{.}}
; CHECK: Fails to load SPIR-V as LLVM Module: InvalidModule: Invalid SPIR-V module: invalid magic number
