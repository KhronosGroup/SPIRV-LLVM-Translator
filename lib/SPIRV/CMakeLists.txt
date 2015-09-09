include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/libSPIRV
  ${CMAKE_CURRENT_SOURCE_DIR}/Mangler
  ${CMAKE_CURRENT_SOURCE_DIR}/..)

add_llvm_library(LLVMSPIRVLib
  libSPIRV/SPRVBasicBlock.cpp
  libSPIRV/SPRVDebug.cpp
  libSPIRV/SPRVDecorate.cpp
  libSPIRV/SPRVEntry.cpp
  libSPIRV/SPRVFunction.cpp
  libSPIRV/SPRVInstruction.cpp
  libSPIRV/SPRVModule.cpp
  libSPIRV/SPRVStream.cpp
  libSPIRV/SPRVType.cpp
  libSPIRV/SPRVValue.cpp
  Mangler/FunctionDescriptor.cpp
  Mangler/Mangler.cpp
  Mangler/ManglingUtils.cpp
  Mangler/ParameterType.cpp
  OCL20To12.cpp
  OCLUtil.cpp
  SPRVLowerBool.cpp
  SPRVLowerOCLBlocks.cpp
  SPRVReader.cpp
  SPRVRegularizeOCL20.cpp
  SPRVToOCL20.cpp
  SPRVUtil.cpp
  SPRVWriter.cpp
  )

add_dependencies(LLVMSPIRVLib intrinsics_gen)
