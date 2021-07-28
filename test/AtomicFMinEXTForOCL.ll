; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_EXT_shader_atomic_float_min_max -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv --spirv-target-env=CL2.0 -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefixes=CHECK-LLVM-CL,CHECK-LLVM-CL20

; RUN: llvm-spirv --spirv-target-env=SPV-IR -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefixes=CHECK-LLVM-SPV

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-SPIRV: Capability AtomicFloat32MinMaxEXT
; CHECK-SPIRV: Capability AtomicFloat64MinMaxEXT
; CHECK-SPIRV: Extension "SPV_EXT_shader_atomic_float_min_max"
; CHECK-SPIRV: TypeFloat [[TYPE_FLOAT_32:[0-9]+]] 32
; CHECK-SPIRV: TypeFloat [[TYPE_FLOAT_64:[0-9]+]] 64

; Function Attrs: convergent nounwind
define spir_func void @test_float(float addrspace(1)* %a) local_unnamed_addr #0 {
entry:
  ; CHECK-SPIRV: 7 AtomicFMinEXT [[TYPE_FLOAT_32]]
  %call = tail call spir_func float @_Z25atomic_fetch_min_explicitPU3AS1VU7_Atomicff12memory_order(float addrspace(1)* %a, float 0.000000e+00, i32 0) #2
  ; CHECK-SPIRV: 7 AtomicFMinEXT [[TYPE_FLOAT_32]]
  ; CHECK-LLVM-CL20: call spir_func float @[[FLOAT_FUNC_NAME:_Z25atomic_fetch_min_explicit[[:alnum:]]+_Atomicff[a-zA-Z0-9_]+]]({{.*}})
  ; CHECK-LLVM-SPV: call spir_func float @[[FLOAT_FUNC_NAME:_Z21__spirv_AtomicFMinEXT[[:alnum:]]+fiif]]({{.*}})
  %call1 = tail call spir_func float @_Z25atomic_fetch_min_explicitPU3AS1VU7_Atomicff12memory_order(float addrspace(1)* %a, float 0.000000e+00, i32 0) #2
  ; CHECK-SPIRV: 7 AtomicFMinEXT [[TYPE_FLOAT_32]]
  %call2 = tail call spir_func float @_Z25atomic_fetch_min_explicitPU3AS1VU7_Atomicff12memory_order12memory_scope(float addrspace(1)* %a, float 0.000000e+00, i32 0, i32 1) #2
  ret void
}

; Function Attrs: convergent
declare spir_func float @_Z25atomic_fetch_min_explicitPU3AS1VU7_Atomicff12memory_order(float addrspace(1)*, float, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func float @_Z25atomic_fetch_min_explicitPU3AS1VU7_Atomicff12memory_order12memory_scope(float addrspace(1)*, float, i32, i32) local_unnamed_addr #1
; CHECK-LLVM-SPV: declare {{.*}}spir_func float @[[FLOAT_FUNC_NAME]](float

; Function Attrs: convergent nounwind
define spir_func void @test_double(double addrspace(1)* %a) local_unnamed_addr #0 {
entry:
  ; CHECK-SPIRV: 7 AtomicFMinEXT [[TYPE_FLOAT_64]]
  %call = tail call spir_func double @_Z16atomic_fetch_minPU3AS1VU7_Atomicdd(double addrspace(1)* %a, double 0.000000e+00) #2
  ; CHECK-SPIRV: 7 AtomicFMinEXT [[TYPE_FLOAT_64]]
  ; CHECK-LLVM-CL20: call spir_func double @[[DOUBLE_FUNC_NAME:_Z25atomic_fetch_min_explicit[[:alnum:]]+_Atomicdd[a-zA-Z0-9_]+]]({{.*}})
  ; CHECK-LLVM-SPV: call spir_func double @[[DOUBLE_FUNC_NAME:_Z21__spirv_AtomicFMinEXT[[:alnum:]]+diid]]({{.*}})
  %call1 = tail call spir_func double @_Z25atomic_fetch_min_explicitPU3AS1VU7_Atomicdd12memory_order(double addrspace(1)* %a, double 0.000000e+00, i32 0) #2
  ; CHECK-SPIRV: 7 AtomicFMinEXT [[TYPE_FLOAT_64]]
  %call2 = tail call spir_func double @_Z25atomic_fetch_min_explicitPU3AS1VU7_Atomicdd12memory_order12memory_scope(double addrspace(1)* %a, double 0.000000e+00, i32 0, i32 1) #2
  ret void
}

; Function Attrs: convergent
declare spir_func double @_Z16atomic_fetch_minPU3AS1VU7_Atomicdd(double addrspace(1)*, double) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func double @_Z25atomic_fetch_min_explicitPU3AS1VU7_Atomicdd12memory_order(double addrspace(1)*, double, i32) local_unnamed_addr #1
; CHECK-LLVM-SPV: declare {{.*}}spir_func double @[[DOUBLE_FUNC_NAME]](double

; Function Attrs: convergent
declare spir_func double @_Z25atomic_fetch_min_explicitPU3AS1VU7_Atomicdd12memory_order12memory_scope(double addrspace(1)*, double, i32, i32) local_unnamed_addr #1

; CHECK-LLVM-CL: declare {{.*}}spir_func float @[[FLOAT_FUNC_NAME]](float
; CHECK-LLVM-CL: declare {{.*}}spir_func double @[[DOUBLE_FUNC_NAME]](double

attributes #0 = { convergent nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { convergent "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { convergent nounwind }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 2, i32 0}
!2 = !{!"clang version 9.0.1 (7e3651de4027cff2d6afda804a914e56dc529487)"}
