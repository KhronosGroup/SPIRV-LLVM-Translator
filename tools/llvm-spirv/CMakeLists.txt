set(LLVM_LINK_COMPONENTS analysis bitreader bitwriter ipo spirv)

add_llvm_tool(llvm-spirv
  llvm-spirv.cpp
  )
