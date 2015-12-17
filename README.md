LLVM/SPIR-V Bi-Directional Translator
-------------------------------------

The `khronos/spirv-3.6.1` branch of this repository contains source code for the LLVM/SPIR-V Bi-Directional Translator, a library for translating between LLVM and [SPIR-V](https://www.khronos.org/registry/spir-v/).

The LLVM/SPIR-V Bi-Directional Translator is open source software. You may freely distribute it under the terms of the license agreement found in LICENSE.txt.

Currently it accepts LLVM bitcodes compatible with [SPIR 1.2/2.0 standards](https://www.khronos.org/registry/spir/), and [SPIR-V friendly format](https://github.com/KhronosGroup/SPIRV-LLVM/blob/khronos/spirv-3.6.1/docs/SPIRVRepresentationInLLVM.rst).

It also works together with [Khronos OpenCL C compiler for SPIR-V](https://github.com/KhronosGroup/SPIR/tree/spirv-1.0) to compile OpenCL C source code to SPIR-V.

Directory Structure
-------------------

The files/directories are related to the translator:

* [include/SPIRV.h](https://github.com/KhronosGroup/SPIRV-LLVM/blob/khronos/spirv-3.6.1/include/SPIRV.h) - header file
* [lib/SPIRV](https://github.com/KhronosGroup/SPIRV-LLVM/tree/khronos/spirv-3.6.1/lib/SPIRV) - library for SPIR-V in-memory representation, decoder/encoder and LLVM/SPIR-V translator
* [tools/llvm-spirv](https://github.com/KhronosGroup/SPIRV-LLVM/tree/khronos/spirv-3.6.1/tools/llvm-spirv) - command line utility for translating between LLVM bitcode and SPIR-V binary

Build Instructions
------------------

Follow the build instructions of [Khronos OpenCL C compiler for SPIR-V](https://github.com/KhronosGroup/SPIR/tree/spirv-1.0).

Alternatively,

1.  Clone the `khronos/spirv-3.6.1` branch.
2.  Follow [LLVM build instructions](http://llvm.org/docs/GettingStarted.html).

Run Instructions for `llvm-spirv`
----------------

`llvm-spirv` only accepts SPIR 1.2/2.0 or LLVM bitcode following a [SPIR-V friendly format](https://github.com/KhronosGroup/SPIRV-LLVM/blob/khronos/spirv-3.6.1/docs/SPIRVRepresentationInLLVM.rst).

The [Khronos OpenCL C compiler](https://github.com/KhronosGroup/SPIR) can be used to compile OpenCL 1.2/2.0 C source code to SPIR 1.2/2.0 or SPIR-V. It has three branches: `spir_12`, `spir_20_provisional`, and `spirv-1.0`, corresponding to SPIR 1.2, SPIR 2.0, and SPIR-V, respectively. The `spirv-1.0` branch emits SPIR-V directly. It is recommended to use the `spirv-1.0` branch since SPIR 1.2/2.0 have limitations for representing sampler types and access qualifier of image and pipe types, which may result in incorrect SPIR-V in certain cases.

To translate between SPIR 1.2/2.0 and SPIR-V:

1. Follow the instructions provided by the [Khronos OpenCL C compiler](https://github.com/KhronosGroup/SPIR) website to use clang to compile OpenCL C source code to SPIR 1.2/2.0 binary.

2. Execute the following command to translate `input.bc` to `input.spv`
    ```
    llvm-spirv input.bc
    ```

3. Execute the following command to translate `input.spv` to `input.bc`
    ```
    llvm-spirv -r input.spv
    ```

4. Other options accepted by `llvm-spirv`

    * `-o file_name` - to specify output name
    * `-spirv-debug` - output debugging information
    * `-spirv-text` - read/write SPIR-V in an internal textual format for debugging purpose. The textual format is not defined by SPIR-V spec.
