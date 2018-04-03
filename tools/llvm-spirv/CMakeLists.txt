set(LLVM_LINK_COMPONENTS
  Analysis
  BitReader
  BitWriter
  Core
  SPIRVLib
  Support
  TransformUtils
  )

include_directories(${LLVM_SPIRV_INCLUDE_DIRS})

add_llvm_tool(llvm-spirv
  llvm-spirv.cpp
  )
