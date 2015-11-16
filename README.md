LLVM/SPIR-V Bi-Directional Translator
-------------------------------------

The khronos/spirv-3.6.1 branch of this repository contains source code for the LLVM/SPIR-V Bi-Directional Translator, a library for translating between LLVM and [SPIR-V](https://www.khronos.org/registry/spir-v/).

The LLVM/SPIR-V Bi-Directional Translator is open source software. You may freely distribute it under the terms of the license agreement found in LICENSE.txt.

Currently it accepts LLVM bitcodes compatible with [SPIR 1.2/2.0 standards](https://www.khronos.org/registry/spir/), and [SPIR-V friendly format](https://github.com/KhronosGroup/SPIRV-LLVM/blob/khronos/spirv-3.6.1/docs/SPIRVRepresentationInLLVM.rst).

Directory Structure
-------------------

The files/directories are related to the translator:

* [include/SPIRV.h](https://github.com/KhronosGroup/SPIRV-LLVM/blob/khronos/spirv-3.6.1/include/SPIRV.h) - header file
* [lib/SPIRV](https://github.com/KhronosGroup/SPIRV-LLVM/tree/khronos/spirv-3.6.1/lib/SPIRV) - library for SPIR-V in-memory representation, decoder/encoder and LLVM/SPIR-V translator
* [tools/llvm-spirv](https://github.com/KhronosGroup/SPIRV-LLVM/tree/khronos/spirv-3.6.1/tools/llvm-spirv) - command line utility for translating between LLVM bitcode and SPIR-V binary

Build Instructions
------------------

* Clone the khronos/spirv-3.6.1 branch.
* Follow [LLVM build instructions](http://llvm.org/docs/GettingStarted.html).

Run Instructions for llvm-spirv
----------------

llvm-spirv only accepts SPIR 1.2/2.0 or LLVM bitcode following a [SPIR-V friendly format](https://github.com/KhronosGroup/SPIRV-LLVM/blob/khronos/spirv-3.6.1/docs/SPIRVRepresentationInLLVM.rst).

The [Open Source SPIR producer](https://github.com/KhronosGroup/SPIR) can be used to compile OpenCL 1.2/2.0 C source code to SPIR 1.2/2.0.

To translate between SPIR 1.2/2.0 and SPIR-V:

1. Follow the instructions provided by the open source SPIR producer website to use clang to compile OpenCL C source code to SPIR 1.2/2.0 binary.

2. Execute the following command to translate input.bc to input.spv

    llvm-spirv input.bc

3. Execute the following command to translate input.spv to input.bc

    llvm-spirv -r input.spv

4. Other options accepted by llvm-spirv

* -o file_name - to specify output name
* -spirv-debug - output debugging information
* -spirv-text - read/write SPIR-V in an internal textual format for debugging purpose. The textual format is not defined by SPIR-V spec.