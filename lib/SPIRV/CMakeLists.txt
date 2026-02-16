# Copy headers into build directory.
set(LLVM_SPIRV_HEADER_OUTPUT_DIR "${CMAKE_BINARY_DIR}/include/LLVMSPIRVLib")
file(MAKE_DIRECTORY ${LLVM_SPIRV_HEADER_OUTPUT_DIR})
foreach(HEADER ${LLVM_SPIRV_HEADERS})
  cmake_path(GET HEADER FILENAME HEADER_FILENAME)
  cmake_path(APPEND COPIED_HEADER ${LLVM_SPIRV_HEADER_OUTPUT_DIR} ${HEADER_FILENAME})
  add_custom_command(OUTPUT ${COPIED_HEADER}
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${HEADER} ${COPIED_HEADER}
    DEPENDS ${HEADER}
    COMMENT "Copying SPIRV-LLVM-Translator header: ${HEADER}"
  )
  list(APPEND COPIED_HEADERS ${COPIED_HEADER})
endforeach()
add_custom_target(CopyLLVMSPIRVHeaders DEPENDS ${COPIED_HEADERS})

set(SRC_LIST
  LLVMSPIRVOpts.cpp
  LLVMToSPIRVDbgTran.cpp
  Mangler/FunctionDescriptor.cpp
  Mangler/Mangler.cpp
  Mangler/ManglingUtils.cpp
  Mangler/ParameterType.cpp
  OCLToSPIRV.cpp
  OCLTypeToSPIRV.cpp
  OCLUtil.cpp
  VectorComputeUtil.cpp
  SPIRVBuiltinHelper.cpp
  SPIRVLowerBitCastToNonStandardType.cpp
  SPIRVLowerBool.cpp
  SPIRVLowerConstExpr.cpp
  SPIRVLowerMemmove.cpp
  SPIRVLowerOCLBlocks.cpp
  SPIRVLowerLLVMIntrinsic.cpp
  SPIRVReader.cpp
  SPIRVRegularizeLLVM.cpp
  SPIRVToLLVMDbgTran.cpp
  SPIRVToOCL.cpp
  SPIRVToOCL12.cpp
  SPIRVToOCL20.cpp
  SPIRVTypeScavenger.cpp
  SPIRVUtil.cpp
  SPIRVWriter.cpp
  SPIRVWriterPass.cpp
  PassPlugin.cpp
  PreprocessMetadata.cpp
  libSPIRV/SPIRVBasicBlock.cpp
  libSPIRV/SPIRVDebug.cpp
  libSPIRV/SPIRVDecorate.cpp
  libSPIRV/SPIRVEntry.cpp
  libSPIRV/SPIRVFunction.cpp
  libSPIRV/SPIRVInstruction.cpp
  libSPIRV/SPIRVModule.cpp
  libSPIRV/SPIRVStream.cpp
  libSPIRV/SPIRVType.cpp
  libSPIRV/SPIRVValue.cpp
  libSPIRV/SPIRVError.cpp
  libSPIRV/SPIRVFnVar.cpp
  )

set(SPIRVLIB_LINK_COMPONENTS
    Analysis
    BitWriter
    CodeGen
    Core
    Demangle
    IRReader
    Linker
    Passes
    Support
    TargetParser
    TransformUtils
    )

if(SPIRV_BACKEND_FOUND)
  list(APPEND SPIRVLIB_LINK_COMPONENTS "SPIRVCodeGen")
endif()

add_llvm_library(LLVMSPIRVLib
  ${SRC_LIST}
  LINK_COMPONENTS
    ${SPIRVLIB_LINK_COMPONENTS}
  DEPENDS
    intrinsics_gen
  )

add_dependencies(LLVMSPIRVLib CopyLLVMSPIRVHeaders)

target_include_directories(LLVMSPIRVLib
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include>
  PRIVATE
    ${LLVM_INCLUDE_DIRS}
    # TODO: Consider using SPIRV-Headers' as a header-only INTERFACE
    # instead. Right now this runs into exporting issues with
    # the LLVM in-tree builds.
    ${LLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/libSPIRV
    ${CMAKE_CURRENT_SOURCE_DIR}/Mangler
)
