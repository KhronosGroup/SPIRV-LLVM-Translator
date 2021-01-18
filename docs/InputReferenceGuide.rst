=====================
Input Reference Guide
=====================

.. contents::
   :local:

Introduction
============

Reference guide to the LLVM-SPIRV-Translator input, which is compiler IR
(intermediate representation) based on the `LLVM IR
<https://llvm.org/docs/LangRef.html>`_. We will reference it as SPIR IR to
not confuse it with vanilla LLVM IR.

This document amends `SPIR-V representation in LLVM IR
<https://github.com/KhronosGroup/SPIRV-LLVM-Translator/blob/master/docs/SPIRVRepresentationInLLVM.rst>`_,
which defines most of the rules for encoding SPIR-V instructions and types in
LLVM IR.

**TODO**: should we merge these two documents?

Module level requirements
=========================

Target triple architecture must be ``spir`` (32-bit architecture) or ``spir64``
(64-bit architecture) and ``datalayout`` string must be aligned with OpenCL
environment specification requirements for data type sizes and alignments (e.g.
3-element vector must have 4-element vector alignment). For example:

.. code-block:: llvm
   target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
   target triple = "spir-unknown-unknown"

Target triple architecture is translated to
`addressing model operand <https://www.khronos.org/registry/spir-v/specs/unified1/SPIRV.html#_a_id_addressing_model_a_addressing_model>`_
of
`OpMemoryModel <https://www.khronos.org/registry/spir-v/specs/unified1/SPIRV.html#_a_id_mode_setting_a_mode_setting_instructions>`_
SPIR-V instruction.

- ``spir`` -> Physical32
- ``spir64`` -> Physical64

LLVM metadata
-------------

SPIR-V specification allows multiple module scope instructions, whereas LLVM
named metadata must be unique, so encoding of such instructions has the
following format:

.. code-block:: llvm

  !spirv.<OpCodeName> = !{!<InstructionMetadata1>, !<InstructionMetadata2>, ..}
  !<InstructionMetadata1> = !{<Operand1>, <Operand2>, ..}
  !<InstructionMetadata2> = !{<Operand1>, <Operand2>, ..}

+--------------------+---------------------------------------------------------+
| SPIR-V instruction | LLVM IR                                                 |
+====================+=========================================================+
| OpSource           | .. code-block:: llvm                                    |
|                    |                                                         |
|                    |    !spirv.Source = !{!0}                                |
|                    |    !0 = !{i32 3, i32 102000, !1}                        |
|                    |    ; 3 - OpenCL_C                                       |
|                    |    ; 102000 - OpenCL version 1.2                        |
|                    |    ; !1 - optional file id.                             |
|                    |    !1 = !{!"/tmp/opencl/program.cl"}                    |
+--------------------+---------------------------------------------------------+
| OpSourceExtension  | .. code-block:: llvm                                    |
|                    |                                                         |
|                    |    !spirv.SourceExtension = !{!0, !1}                   |
|                    |    !0 = !{!"cl_khr_fp16"}                               |
|                    |    !1 = !{!"cl_khr_gl_sharing"}                         |
+--------------------+---------------------------------------------------------+
| OpExtension        | .. code-block:: llvm                                    |
|                    |                                                         |
|                    |    !spirv.Extension = !{!0}                             |
|                    |    !0 = !{!"cl_khr_fp16"}                               |
+--------------------+---------------------------------------------------------+
| OpCapability       | .. code-block:: llvm                                    |
|                    |                                                         |
|                    |    !spirv.Capability = !{!0}                            |
|                    |    !0 = !{i32 10} ; Float64 - program uses doubles      |
+--------------------+---------------------------------------------------------+
| OpExecutionMode    | .. code-block:: llvm                                    |
|                    |                                                         |
|                    |    !spirv.ExecutionMode = !{!0}                         |
|                    |    !6 = !{void ()* @worker, i32 30, i32 262149}         |
|                    |    ; Set execution mode with id 30 (VecTypeHint) and    |
|                    |    ; literal `262149` operand.                          |
+--------------------+---------------------------------------------------------+
| OpCapability       | .. code-block:: llvm                                    |
|                    |                                                         |
|                    |    !spirv.Capability = !{!0}                            |
|                    |    !0 = !{i32 10} ; Float64 - program uses doubles      |
+--------------------+---------------------------------------------------------+
| Generator's magic  | .. code-block:: llvm                                    |
| number - word # 2  |                                                         |
| in SPIR-V module   |    !spirv.Generator = !{!0}                             |
|                    |    !0 = !{i16 6, i16 123}                               |
|                    |    ; 6 - Generator Id, 123 - Generator Version          |
+--------------------+---------------------------------------------------------+

**TODO**: Should we document all OpExecutionMode operands supported by the
translator? There is a number of non-standard modes added as Intel extensions.

Function level requirements
===========================

Calling convention
------------------

OpEntryPoint information is represented in SPIR IR in calling convention.
A function with `spir_kernel` calling convention will be translated as an entry
point to SPIR-V module.

Function metadata
-----------------

Some kernel parameter information is stored in SPIR IR as a function level
metadata.

For example:

- !kernel_arg_addr_space !1
- !kernel_arg_access_qual !2
- !kernel_arg_type !3
- !kernel_arg_base_type !4
- !kernel_arg_type_qual !5

**TODO**: Are all these metadata optional? Access qualifiers are translated for
image types, but they should be encoded in LLVM IR type name rather than
function metadata.

Address spaces
==============

Following
`SPIR-V storage classes <https://www.khronos.org/registry/spir-v/specs/unified1/SPIRV.html#Storage_Class>`_
are naturally represented as LLVM IR address spaces with following mapping:

SPIR-V storage class    LLVM IR address space
Function                No address space
CrossWorkgroup          addrspace(1)
UniformConstant         addrspace(2)
Workgroup               addrspace(3)
Generic                 addrspace(4)

Unsupported LLVM IR features
============================

**TODO**: Should these features be listed explicitly?

Debug information extension
===========================

**TBD**