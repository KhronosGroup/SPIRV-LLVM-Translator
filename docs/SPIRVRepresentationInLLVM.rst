Overview
========
.. contents::

As one of the goals of SPIR-V is to "map easily to other IRs, including LLVM IR"[1_], most of SPIR-V entities (global variables, constants, types, functions, basic blocks, instructions) have straightforward counterparts in LLVM. Therefore the focus of this document is those entities in SPIR-V which do not map to LLVM in an obvious way. These include:

 * SPIR-V instructions mapped to LLVM function calls
 * SPIR-V extended instructions mapped to LLVM function calls
 * SPIR-V Builtins Variables Mapped to LLVM Global Variables
 * SPIR-V instructions mapped to LLVM metadata
 * SPIR-V types mapped to LLVM opaque types
 * SPIR-V decorations mapped to LLVM metadata or named attributes

SPIR-V Instructions Mapped to LLVM Function Calls
=================================================

Some SPIR-V instructions which can be included in basic blocks do not have corresponding LLVM instructions or intrinsics. These SPIR-V instructions are represented by function calls in LLVM. The function corresponding to a SPIR-V instruction is termed SPIR-V builtin function and its name is IA64 mangled[2] with extensions for SPIR-V specific types. The unmangled name of a SPIR-V builtin function follows the convention

__spirv_{OpCodeName}{_OptionalPostfixes}

where {OpCodeName} is the op code name of the SPIR-V instructions without the "Op" prefix, e.g. EnqueueKernel. {OptionalPostfixes} are optional postfixes to specify decorations for the SPIR-V instruction. The SPIR-V op code name and each postfix does not contain "_".

The literal operands of extended instruction are mapped to function call arguments with type i32.

SPIR-V Builtin Functions with Casted Arguments
----------------------------------------------

SPIR-V builtin functions accepts all argument types accepted by the corresponding SPIR-V instructions, with exceptions of the following instructions:

 * Pipe instructions: where the pipe type is casted to i8* and mangled as such
 * EnqueueKernel instruction: where the invoke function argument is casted to (void*)(void) and mangled as such

This is to simplify the mangling of pipe and function types. For these functions the information carried by the argument type can be obtained otherwise therefore it can be omitted in the mangled names by casting the arguments to simpler types.

Optional Postfixes for SPIR-V Builtin Function Names
----------------------------------------------------

SPIR-V builtin functions corresponding to the following SPIR-V instructions are postfixed following the order specified as below:

 * Instructions having identical argument types but different return types are postfixed with "_R{ReturnType}" where
    - {ReturnType} = {ScalarType}|{VectorType}
    - {ScalarType} = char|uchar|short|ushort|int|uint|long|ulong
    - {VectorType} = {ScalarType}{2|3|4|8|16}
 * Instructions with saturation decoration are postfixed with "_sat"
 * Instructions with floating point rounding mode decoration are postfixed with "_rtp|_rtn|_rtz|_rte"

SPIR-V Builtin Conversion Function Names
----------------------------------------

The unmangled names of SPIR-V builtin conversion functions follow the convention:

__spirv_{ConversionOpCodeName}_R{ReturnType}{_sat}{_rtp|_rtn|_rtz|_rte}

where

 * {ConversionOpCodeName} = ConvertFToU|ConvertFToS|ConvertUToF|ConvertUToS|UConvert|SConvert|FConvert|SatConvertSToU|SatConvertUToS

SPIR-V Extended Instructions Mapped to LLVM Function Calls
==========================================================

SPIR-V extended instructions are mapped to LLVM function calls. The function name is IA64 mangled and the unmangled name has the format

__spirv_{ExtendedInstructionSetName}_{ExtendedInstrutionName}

where {ExtendedInstructionSetName} for OpenCL is "ocl".

The literal operands of extended instruction are mapped to function call arguments with type i32.

SPIR-V Builtins Variables Mapped to LLVM Global Variables
=========================================================

SPIR-V builtin variables are mapped to LLVM global variables with unmangled name __spirv_BuiltIn{Name}.

SPIR-V instructions mapped to LLVM metadata
===========================================

SPIR-V specification allows multiple instructions with the same id, whereas LLVM named metadata must be unique, so encoding of such instructions has the following format:

.. code-block:: llvm

  !spirv.<OpCodeName> = !{!<InstructionMetadata1>, <InstructionMetadata2>, ..}
  !<InstructionMetadata1> = !{<Operand1>, <Operand2>, ..}
  !<InstructionMetadata2> = !{<Operand1>, <Operand2>, ..}
 

For example:

.. code-block:: llvm


   !spirv.Source = !{!0}
   !spirv.SourceExtensions = !{!2, !3}
   !spirv.Capability = !{!4}
   !spirv.MemoryModel = !{!5}
   !spirv.EntryPoint = !{!6 ,!7}
   !spirv.ExecutionMode = !{!8, !9}

   ; 3 - OpenCL, 120 - OpenCL version 1.2, !0 - optional file id.
   !0 = !{i32 3, i32 120, !1}
   !1 = !{!"/tmp/opencl/program.cl"}
   !2 = !{!"cl_khr_fp16"}
   !3 = !{!"cl_khr_gl_sharing"}
   !4 = !{i32 10}                ; Float64 - program uses doubles
   !5 = !{i32 1, i32 2}     ; 1 - 32-bit addressing model, 2 - OpenCL memory model
   !6 = !{i32 6, TBD, !"kernel1", TBD}
   !7 = !{i32 6, TBD, !"kernel2", TBD}
   !8 = !{!6, i32 18, i32 16, i32 1, i32 1}     ; local size hint <16, 1, 1> for 'kernel1'
   !9 = !{!7, i32 32}     ; independent forward progress is required for 'kernel2'
   
References
==========

.. _1: https://cvs.khronos.org/svn/repos/SPIRV/trunk/specs/SPIRV.html#_goals
    https://mentorembedded.github.io/cxx-abi/abi.html#mangling
