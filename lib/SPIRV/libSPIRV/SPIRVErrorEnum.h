/* The error code name should be meaningful since it is part of error message */
_SPIRV_OP(Success, "Success")
_SPIRV_OP(InvalidTargetTriple,
          "Expects spir-unknown-unknown or spir64-unknown-unknown.")
_SPIRV_OP(InvalidSubArch, "Expecting v1.0-v1.6.")
_SPIRV_OP(TripleMaxVersionIncompatible,
          "Triple version and maximum version are incompatible.")
_SPIRV_OP(InvalidAddressingModel, "Expects 0-2.")
_SPIRV_OP(InvalidMemoryModel, "Expects 0-3.")
_SPIRV_OP(InvalidFunctionControlMask, "")
_SPIRV_OP(InvalidBuiltinSetName, "Expects OpenCL.std.")
_SPIRV_OP(InvalidFunctionCall, "Unexpected llvm intrinsic:\n")
_SPIRV_OP(InvalidBitWidth, "Invalid bit width in input:")
_SPIRV_OP(InvalidModule, "Invalid SPIR-V module:")
_SPIRV_OP(InvalidLlvmModule, "Invalid LLVM module:")
_SPIRV_OP(UnimplementedOpCode, "Unimplemented opcode")
_SPIRV_OP(FunctionPointers, "Can't translate function pointer:\n")
_SPIRV_OP(InvalidInstruction, "Can't translate llvm instruction:\n")
_SPIRV_OP(InvalidWordCount,
          "Can't encode instruction with word count greater than 65535:\n")
_SPIRV_OP(Requires1_1, "Feature requires SPIR-V 1.1 or greater:")
_SPIRV_OP(RequiresVersion, "Cannot fulfill SPIR-V version restriction:\n")
_SPIRV_OP(RequiresExtension,
          "Feature requires the following SPIR-V extension:\n")
_SPIRV_OP(InvalidMagicNumber, "Invalid Magic Number.")
_SPIRV_OP(InvalidVersionNumber, "Invalid Version Number.")
_SPIRV_OP(UnspecifiedMemoryModel, "Unspecified Memory Model.")
_SPIRV_OP(RepeatedMemoryModel, "Expects a single OpMemoryModel instruction.")
_SPIRV_OP(UnsupportedVarArgFunction,
          "Variadic functions other than 'printf' are not supported in SPIR-V.")
_SPIRV_OP(DeprecatedExtension,
          "Feature requires the following deprecated SPIR-V extension:\n")
_SPIRV_OP(InvalidNumberOfOperands,
          "Number of operands does not match the expected count.")

/* This is the last error code to have a maximum valid value to compare to */
_SPIRV_OP(InternalMaxErrorCode, "Unknown error code")
