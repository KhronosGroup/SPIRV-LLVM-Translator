set(LLVM_LINK_COMPONENTS Core IRReader Support TargetParser)

add_llvm_executable(spirv-test-target-layout
  target-layout.cpp
  NO_INSTALL_RPATH
)

target_include_directories(spirv-test-target-layout PRIVATE ${LLVM_INCLUDE_DIRS})
