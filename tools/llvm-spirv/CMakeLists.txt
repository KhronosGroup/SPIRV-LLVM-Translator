set(LLVM_LINK_COMPONENTS
  Analysis
  BitReader
  BitWriter
  IPO
  SPIRVLib
  Core
  Support
  )

add_llvm_tool(llvm-spirv
  llvm-spirv.cpp
  )
