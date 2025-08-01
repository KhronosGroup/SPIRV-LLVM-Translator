==========================================================
SPIR-V representation in LLVM IR for FP8 datatypes
==========================================================
.. contents::
   :local:

Overview
========

Open Compute and other projects are adding various new data-types and SPIR-V
(starting from SPV_EXT_float8) is now adopting them. None of these data-types
have appropriate LLVM IR counterparts. This document describes the proposed
LLVM IR input format for *FP8* types, the translation flow, and the
expected LLVM IR output from the consumer.

SPIR-V FP8 Types Mapped to LLVM Types
=============================================

All formats of *FP8* will be represented in LLVM IR with *i8* type.
Until 'type resolution' instruction appears in the module (see below) the *i8* value will
remain to be integer, when 'type resolution' instruction is being processed - integer value will be bitcasted
to floating-point value with width and encoding depending on the instruction. If the instruction's
result is *FP8* or a composite containing them, then it is also being bitcasted to *i8* or
the appropriate composite. It is safe to do as the extension doesn't add support
for arithmetic instructions and builtins (unless it's *OpCooperativeMatrixMulAddKHR*, but this
case will be handled separately).

The 'type resolution' instruction can be either a conversion instruction or *OpCooperativeMatrixMulAddKHR*.

SPIR-V conversion instructions
==============================

There is limited number of conversions that will be supported now. Most of them will be represented by *OpFConvert* instruction
in SPIR-V, which itself doesn't carry information about floating-point value's width and encoding, so there is nothing to expose
in SPIR-V friendly LLVM IR call. This document adds a new set of external function calls
each of which has a name that is formed from encoding a specific conversion that it performs.
This name has a *__builtin_spirv_* prefix and *EXT* postfix (from SPV_EXT_float8). These calls will
be translated to SPIR-V conversion instruction operating over the appropriate types. These functions are expected to
be mangled following Itanium C++ ABI. SPIR-V consumer will apply Itanium mangling during
translation to LLVM IR as well.

SPIR-V generator will support *scalar*, *vector* and *packed* for the conversion builtin functions as LLVM IR input;
*packed* format is translated to a *vector*. Meanwhile SPIR-V consumer
will never pack a *vector* back to *packed* format.

Following list of function calls will be handled by the translator:
Translated to *OpFConvert*

.. code-block:: C

  __builtin_spirv_ConvertFP16ToE4M3EXT, __builtin_spirv_ConvertBF16ToE4M3EXT,
  __builtin_spirv_ConvertFP16ToE5M2EXT, __builtin_spirv_ConvertBF16ToE5M2EXT,
  __builtin_spirv_ConvertE4M3ToFP16EXT, __builtin_spirv_ConvertE5M2ToFP16EXT,
  __builtin_spirv_ConvertE4M3ToBF16EXT, __builtin_spirv_ConvertE5M2ToBF16EXT

Translated to *OpConvertSToF*

.. code-block:: C

  __builtin_spirv_ConvertInt4ToE4M3EXT, __builtin_spirv_ConvertInt4ToE5M2EXT,
  __builtin_spirv_ConvertInt4ToFP16EXT, __builtin_spirv_ConvertInt4ToBF16EXT


Translated to *OpConvertFToS*

.. code-block:: C

  __builtin_spirv_ConvertFP16ToInt4EXT, __builtin_spirv_ConvertBF16ToInt4EXT

Translated to *OpConvertUToF*

.. code-block:: C

  __builtin_spirv_ConvertUInt4ToE4M3EXT, __builtin_spirv_ConvertUInt4ToE5M2EXT,
  __builtin_spirv_ConvertUInt4ToFP16EXT, __builtin_spirv_ConvertUInt4ToBF16EXT


Translated to *OpConvertFToU*

.. code-block:: C

  __builtin_spirv_ConvertFP16ToUInt4EXT, __builtin_spirv_ConvertBF16ToUInt4EXT


Example LLVM IR to SPIR-V translation:
Input LLVM IR

.. code-block:: C

   %alloc = alloca half
   %FP16_val = call half __builtin_spirv_ConvertE4M3ToFP16EXT(i8 1)
   store half %FP16_val, ptr %alloc

Output SPIR-V

.. code-block:: C

   %half_ty = OpTypeFloat 16 0
   %ptr_ty = OpTypePointer %half_ty Private
   %int8_ty = OpTypeInt 8 0
   %fp8_ty = OpTypeFloat 8 1
   %const = OpConstant %int8_ty 1
   /*...*/
   %alloc = OpVariable %half_ty Private
   %fp8_val = OpBitCast %fp8_ty %const
   %fp16_val = OpFConvert %half_ty %fp8_val
   OpStore %fp16_val %alloc

Output LLVM IR

.. code-block:: C

   %alloc = alloca half
   %fp16_val = call half __builtin_spirv_ConvertE4M3ToFP16EXT(i8 1)
   store half %fp16_val, ptr %alloc

SPIR-V cooperative matrix instructions
======================================

TBD
