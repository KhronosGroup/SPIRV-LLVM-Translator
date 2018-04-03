configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py
  MAIN_CONFIG
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py
  )

list(APPEND LLVM_SPIRV_TEST_DEPS
  FileCheck count not
  llvm-as
  llvm-dis
  llvm-spirv
)

add_lit_testsuite(check-llvm-spirv "Running the LLVM-SPIRV regression tests"
  ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${LLVM_SPIRV_TEST_DEPS}
  )
