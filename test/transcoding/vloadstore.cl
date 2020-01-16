// RUN: %clang_cc1 -triple spir-unknown-unknown -O1 -cl-std=CL2.0 -finclude-default-header -emit-llvm-bc %s -o %t.bc
// RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
// RUN: llvm-spirv %t.bc -o %t.spv
// RUN: spirv-val %t.spv
// RUN: llvm-spirv -r %t.spv -o %t.rev.bc
// RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

#pragma OPENCL EXTENSION cl_khr_fp16 : enable
__kernel void test_vloadstore( __global half *src, __global half *dst )
{
   vload( 0, src );
   vload2(0 , src);
   vload3(0 , src);
   vload4(0 , src);
   vload8(0 , src);
   vload16(0 , src);

   vstore(0, 0, dst);
   vstore2(0, 0, dst);
   vstore3(0, 0, dst);
   vstore4(0, 0, dst);
   vstore8(0, 0, dst);
   vstore16(0, 0, dst);

   vload_half(0, src);
   vload_half2(0, src);
   vload_half3(0, src);
   vload_half4(0, src);
   vload_half8(0, src);
   vload_half16(0, src);
   
   vstore_half(0.0f, 0, dst);
   vstore_half2((float2)(0.0f, 0.0f), 0, dst);
   vstore_half3((float3)(0.0f, 0.0f, 0.0f), 0, dst);
   vstore_half4((float4)(0.0f, 0.0f, 0.0f, 0.0f), 0, dst);
   vstore_half8((float8)(0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f), 0,
                dst);
   vstore_half16((float16)(0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
                           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f),
                 0,
                 dst);
}

// CHECK-SPIRV: TypeVoid [[void_t:[0-9]+]]
// CHECK-SPIRV: TypeFloat [[half_t:[0-9]+]] 16
// CHECK-SPIRV: TypeVector [[half2_t:[0-9]+]] [[half_t]] 2
// CHECK-SPIRV: TypeVector [[half3_t:[0-9]+]] [[half_t]] 3
// CHECK-SPIRV: TypeVector [[half4_t:[0-9]+]] [[half_t]] 4
// CHECK-SPIRV: TypeVector [[half8_t:[0-9]+]] [[half_t]] 8
// CHECK-SPIRV: TypeVector [[half16_t:[0-9]+]] [[half_t]] 16

// CHECK-SPIRV: TypeFloat [[float_t:[0-9]+]] 32
// CHECK-SPIRV: TypeVector [[float2_t:[0-9]+]] [[float_t]] 2
// CHECK-SPIRV: TypeVector [[float3_t:[0-9]+]] [[float_t]] 3
// CHECK-SPIRV: TypeVector [[float4_t:[0-9]+]] [[float_t]] 4
// CHECK-SPIRV: TypeVector [[float8_t:[0-9]+]] [[float_t]] 8
// CHECK-SPIRV: TypeVector [[float16_t:[0-9]+]] [[float_t]] 16

// CHECK-SPIRV: Constant [[half_t]] [[half_c:[0-9]+]] 0
// CHECK-SPIRV: ConstantNull [[half2_t]] [[half2_c:[0-9]+]]
// CHECK-SPIRV: ConstantNull [[half3_t]] [[half3_c:[0-9]+]]
// CHECK-SPIRV: ConstantNull [[half4_t]] [[half4_c:[0-9]+]]
// CHECK-SPIRV: ConstantNull [[half8_t]] [[half8_c:[0-9]+]]
// CHECK-SPIRV: ConstantNull [[half16_t]] [[half16_c:[0-9]+]]

// CHECK-SPIRV: Constant [[float_t]] [[float_c:[0-9]+]] 0
// CHECK-SPIRV: ConstantNull [[float2_t]] [[float2_c:[0-9]+]]
// CHECK-SPIRV: ConstantNull [[float3_t]] [[float3_c:[0-9]+]]
// CHECK-SPIRV: ConstantNull [[float4_t]] [[float4_c:[0-9]+]]
// CHECK-SPIRV: ConstantNull [[float8_t]] [[float8_c:[0-9]+]]
// CHECK-SPIRV: ConstantNull [[float16_t]] [[float16_c:[0-9]+]]

// CHECK-SPIRV: ExtInst [[half_t]] {{[0-9]+}} {{[0-9]+}} vloadn {{[0-9]+}} {{[0-9]+}} 1
// CHECK-SPIRV: ExtInst [[half2_t]] {{[0-9]+}} {{[0-9]+}} vloadn {{[0-9]+}} {{[0-9]+}} 2
// CHECK-SPIRV: ExtInst [[half3_t]] {{[0-9]+}} {{[0-9]+}} vloadn {{[0-9]+}} {{[0-9]+}} 3
// CHECK-SPIRV: ExtInst [[half4_t]] {{[0-9]+}} {{[0-9]+}} vloadn {{[0-9]+}} {{[0-9]+}} 4
// CHECK-SPIRV: ExtInst [[half8_t]] {{[0-9]+}} {{[0-9]+}} vloadn {{[0-9]+}} {{[0-9]+}} 8
// CHECK-SPIRV: ExtInst [[half16_t]] {{[0-9]+}} {{[0-9]+}} vloadn {{[0-9]+}} {{[0-9]+}} 16

// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstoren [[half_c]]
// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstoren [[half2_c]]
// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstoren [[half3_c]]
// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstoren [[half4_c]]
// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstoren [[half8_c]]
// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstoren [[half16_c]]

// CHECK-SPIRV: ExtInst [[float_t]] {{[0-9]+}} {{[0-9]+}} vload_half {{[0-9]+}} {{[0-9]+}}
// CHECK-SPIRV: ExtInst [[float2_t]] {{[0-9]+}} {{[0-9]+}} vload_halfn {{[0-9]+}} {{[0-9]+}} 2
// CHECK-SPIRV: ExtInst [[float3_t]] {{[0-9]+}} {{[0-9]+}} vload_halfn {{[0-9]+}} {{[0-9]+}} 3
// CHECK-SPIRV: ExtInst [[float4_t]] {{[0-9]+}} {{[0-9]+}} vload_halfn {{[0-9]+}} {{[0-9]+}} 4
// CHECK-SPIRV: ExtInst [[float8_t]] {{[0-9]+}} {{[0-9]+}} vload_halfn {{[0-9]+}} {{[0-9]+}} 8
// CHECK-SPIRV: ExtInst [[float16_t]] {{[0-9]+}} {{[0-9]+}} vload_halfn {{[0-9]+}} {{[0-9]+}} 16

// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstore_half [[float_c]]
// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstore_halfn [[float2_c]]
// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstore_halfn [[float3_c]]
// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstore_halfn [[float4_c]]
// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstore_halfn [[float8_c]]
// CHECK-SPIRV: ExtInst [[void_t]] {{[0-9]+}} {{[0-9]+}} vstore_halfn [[float16_c]]

// CHECK-LLVM: call spir_func half @_Z5vloadjPU3AS4KDh(i32 0, half addrspace(4)* %0)
// CHECK-LLVM: call spir_func <2 x half> @_Z6vload2jPU3AS4KDh(i32 0, half addrspace(4)* %0)
// CHECK-LLVM: call spir_func <3 x half> @_Z6vload3jPU3AS4KDh(i32 0, half addrspace(4)* %0)
// CHECK-LLVM: call spir_func <4 x half> @_Z6vload4jPU3AS4KDh(i32 0, half addrspace(4)* %0)
// CHECK-LLVM: call spir_func <8 x half> @_Z6vload8jPU3AS4KDh(i32 0, half addrspace(4)* %0)
// CHECK-LLVM: call spir_func <16 x half> @_Z7vload16jPU3AS4KDh(i32 0, half addrspace(4)* %0)

// CHECK-LLVM: call spir_func void @_Z6vstoreDhjPU3AS4Dh(half 0xH0000, i32 0, half addrspace(4)* %1)
// CHECK-LLVM: call spir_func void @_Z7vstore2Dv2_DhjPU3AS4Dh(<2 x half> zeroinitializer, i32 0, half addrspace(4)* %1)
// CHECK-LLVM: call spir_func void @_Z7vstore3Dv3_DhjPU3AS4Dh(<3 x half> zeroinitializer, i32 0, half addrspace(4)* %1)
// CHECK-LLVM: call spir_func void @_Z7vstore4Dv4_DhjPU3AS4Dh(<4 x half> zeroinitializer, i32 0, half addrspace(4)* %1)
// CHECK-LLVM: call spir_func void @_Z7vstore8Dv8_DhjPU3AS4Dh(<8 x half> zeroinitializer, i32 0, half addrspace(4)* %1)
// CHECK-LLVM: call spir_func void @_Z8vstore16Dv16_DhjPU3AS4Dh(<16 x half> zeroinitializer, i32 0, half addrspace(4)* %1)

// CHECK-LLVM: call spir_func float @_Z10vload_halfjPU3AS4KDh(i32 0, half addrspace(4)* %0)
// CHECK-LLVM: call spir_func <2 x float> @_Z11vload_half2jPU3AS4KDh(i32 0, half addrspace(4)* %0)
// CHECK-LLVM: call spir_func <3 x float> @_Z11vload_half3jPU3AS4KDh(i32 0, half addrspace(4)* %0)
// CHECK-LLVM: call spir_func <4 x float> @_Z11vload_half4jPU3AS4KDh(i32 0, half addrspace(4)* %0)
// CHECK-LLVM: call spir_func <8 x float> @_Z11vload_half8jPU3AS4KDh(i32 0, half addrspace(4)* %0)
// CHECK-LLVM: call spir_func <16 x float> @_Z12vload_half16jPU3AS4KDh(i32 0, half addrspace(4)* %0)

// CHECK-LLVM: call spir_func void @_Z11vstore_halffjPU3AS4Dh(float 0.000000e+00, i32 0, half addrspace(4)* %1)
// CHECK-LLVM: call spir_func void @_Z12vstore_half2Dv2_fjPU3AS4Dh(<2 x float> zeroinitializer, i32 0, half addrspace(4)* %1)
// CHECK-LLVM: call spir_func void @_Z12vstore_half3Dv3_fjPU3AS4Dh(<3 x float> zeroinitializer, i32 0, half addrspace(4)* %1)
// CHECK-LLVM: call spir_func void @_Z12vstore_half4Dv4_fjPU3AS4Dh(<4 x float> zeroinitializer, i32 0, half addrspace(4)* %1)
// CHECK-LLVM: call spir_func void @_Z12vstore_half8Dv8_fjPU3AS4Dh(<8 x float> zeroinitializer, i32 0, half addrspace(4)* %1)
// CHECK-LLVM: call spir_func void @_Z13vstore_half16Dv16_fjPU3AS4Dh(<16 x float> zeroinitializer, i32 0, half addrspace(4)* %1)