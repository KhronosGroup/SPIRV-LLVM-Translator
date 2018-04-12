LLVM/SPIR-V Bi-Directional Translator
-------------------------------------
[![Build Status](https://travis-ci.org/KhronosGroup/SPIRV-LLVM-Translator.svg?branch=master)](https://travis-ci.org/KhronosGroup/SPIRV-LLVM-Translator)

This repository contains source code for the LLVM/SPIR-V Bi-Directional Translator, a library and tool for translation between LLVM IR and [SPIR-V](https://www.khronos.org/registry/spir-v/).

The LLVM/SPIR-V Bi-Directional Translator is open source software. You may freely distribute it under the terms of the license agreement found in LICENSE.txt.


Directory Structure
-------------------

The files/directories related to the translator:

* [include/SPIRV.h](include/SPIRV.h) - header file
* [lib/SPIRV](lib/SPIRV) - library for SPIR-V in-memory representation, decoder/encoder and LLVM/SPIR-V translator
* [tools/llvm-spirv](tools/llvm-spirv) - command line utility for translating between LLVM bitcode and SPIR-V binary

Build Instructions
------------------

TBD

Test instructions
-----------------

All tests related to the translator are placed in the [test](test) directory.

Execute the following command to run translator tests:
```
llvm-lit test
```

Run Instructions for `llvm-spirv`
----------------

To translate between LLVM IR and SPIR-V:

1. Execute the following command to translate `input.bc` to `input.spv`
    ```
    llvm-spirv input.bc
    ```

2. Execute the following command to translate `input.spv` to `input.bc`
    ```
    llvm-spirv -r input.spv
    ```

3. Other options accepted by `llvm-spirv`

    * `-o file_name` - to specify output name
    * `-spirv-debug` - output debugging information
    * `-spirv-text` - read/write SPIR-V in an internal textual format for debugging purpose. The textual format is not defined by SPIR-V spec.
    * `-help` - to see full list of options
