llvm_canonicalize_cmake_booleans(SPIRV_SKIP_CLANG_BUILD)
llvm_canonicalize_cmake_booleans(SPIRV_SKIP_DEBUG_INFO_TESTS)
llvm_canonicalize_cmake_booleans(LLVM_BUILD_SHARED_LIBS)
llvm_canonicalize_cmake_booleans(LLVM_SPIRV_BUILD_EXTERNAL)
llvm_canonicalize_cmake_booleans(SPIRV_BACKEND_FOUND)

# required by lit.site.cfg.py.in
get_target_property(LLVM_SPIRV_DIR llvm-spirv BINARY_DIR)
get_target_property(LLVM_SPIRV_LIB_DIR LLVMSPIRVLib BINARY_DIR)
set(LLVM_SPIRV_TEST_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

if(SPIRV_TOOLS_FOUND AND NOT SPIRV-Tools-tools_FOUND)
  # we found SPIRV-Tools via pkgconfig
  find_program(SPIRV_TOOLS_SPIRV_AS NAMES spirv-as PATHS ${SPIRV_TOOLS_PREFIX}/bin)
  if(SPIRV_TOOLS_SPIRV_AS)
    set(SPIRV_TOOLS_SPIRV_AS_FOUND True)
  endif()

  find_program(SPIRV_TOOLS_SPIRV_DIS NAMES spirv-dis PATHS ${SPIRV_TOOLS_PREFIX}/bin)
  if(SPIRV_TOOLS_SPIRV_DIS)
    set(SPIRV_TOOLS_SPIRV_DIS_FOUND True)
  endif()

  find_program(SPIRV_TOOLS_SPIRV_LINK NAMES spirv-link PATHS ${SPIRV_TOOLS_PREFIX}/bin)
  if(SPIRV_TOOLS_SPIRV_LINK)
    set(SPIRV_TOOLS_SPIRV_LINK_FOUND True)
  endif()

  find_program(SPIRV_TOOLS_SPIRV_VAL NAMES spirv-val PATHS ${SPIRV_TOOLS_PREFIX}/bin)
  if(SPIRV_TOOLS_SPIRV_VAL)
    set(SPIRV_TOOLS_SPIRV_VAL_FOUND True)
  endif()

  set(SPIRV_TOOLS_BINDIR "${SPIRV_TOOLS_PREFIX}/bin")
  if (LLVM_SPIRV_ENABLE_LIBSPIRV_DIS)
    set(SPIRV_ENABLE_LIBSPIRV_DIS ON)
  endif()
elseif(SPIRV-Tools-tools_FOUND)
  # we found SPIRV-Tools via cmake targets

  if(TARGET spirv-as)
    set(SPIRV_TOOLS_SPIRV_AS_FOUND True)
  endif()

  if(TARGET spirv-dis)
    set(SPIRV_TOOLS_SPIRV_DIS_FOUND True)
  endif()

  if(TARGET spirv-link)
    set(SPIRV_TOOLS_SPIRV_LINK_FOUND True)
  endif()

  if(TARGET spirv-val)
    set(SPIRV_TOOLS_SPIRV_VAL_FOUND True)
  endif()

  get_target_property(SPIRV_AS_PATH spirv-as IMPORTED_LOCATION_RELEASE)
  if(NOT SPIRV_AS_PATH)
    get_target_property(SPIRV_AS_PATH spirv-as IMPORTED_LOCATION_DEBUG)
  endif()

  if(SPIRV_AS_PATH)
    cmake_path(GET SPIRV_AS_PATH PARENT_PATH SPIRV_AS_PATH)
  endif()

  set(SPIRV_TOOLS_BINDIR "${SPIRV_AS_PATH}")
elseif(LLVM_INCLUDE_SPIRV_TOOLS_TESTS)
  # Fall back to the in-tree SPIRV-Tools build (llvm/tools/spirv-tools),
  # enabled via -DLLVM_INCLUDE_SPIRV_TOOLS_TESTS=ON. Its custom targets
  # copy/symlink binaries into LLVM_RUNTIME_OUTPUT_INTDIR.
  #
  # llvm/CMakeLists.txt calls add_subdirectory(projects) -- which pulls in
  # this project -- before add_subdirectory(tools), where spirv-tools
  # defines the spirv-as/dis/link/val custom targets. So those targets do
  # not exist yet at this point, and if(TARGET ...) would always be false.
  # CMake resolves DEPENDS/add_dependencies target names against the
  # global target table at generate time, so it is safe to just assume
  # the targets will exist and reference them unconditionally.
  set(SPIRV_TOOLS_SPIRV_AS_FOUND True)
  set(SPIRV_TOOLS_SPIRV_DIS_FOUND True)
  set(SPIRV_TOOLS_SPIRV_LINK_FOUND True)
  set(SPIRV_TOOLS_SPIRV_VAL_FOUND True)
  set(SPIRV_TOOLS_BINDIR "${LLVM_RUNTIME_OUTPUT_INTDIR}")
endif()

if(NOT SPIRV_TOOLS_SPIRV_AS_FOUND)
  message(WARNING "spirv-as not found! SPIR-V assembly tests will not be run.")
  set(SPIRV_TOOLS_SPIRV_AS_FOUND False)
endif()

if(NOT SPIRV_TOOLS_SPIRV_DIS_FOUND)
  message(WARNING "spirv-dis not found! SPIR-V disassembly tests will not be run.")
  set(SPIRV_TOOLS_SPIRV_DIS_FOUND False)
endif()

if(NOT SPIRV_TOOLS_SPIRV_LINK_FOUND)
  message(WARNING "spirv-link not found! SPIR-V test involving the linker will not be run.")
  set(SPIRV_TOOLS_SPIRV_LINK_FOUND False)
endif()

if(NOT SPIRV_TOOLS_SPIRV_VAL_FOUND)
  message(WARNING "spirv-val not found! SPIR-V generated for test suite will not be validated.")
  set(SPIRV_TOOLS_SPIRV_VAL_FOUND False)
endif()

configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py
  MAIN_CONFIG
    ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py
)

if(NOT LLVM_SPIRV_BUILD_EXTERNAL)
  set(LLVM_SPIRV_TEST_DEPS
    FileCheck
    count
    llvm-as
    llvm-config
    llvm-dis
    not
  )
  if(NOT SPIRV_SKIP_CLANG_BUILD)
    list(APPEND LLVM_SPIRV_TEST_DEPS
      clang
    )
  endif(NOT SPIRV_SKIP_CLANG_BUILD)
  if(NOT SPIRV_SKIP_DEBUG_INFO_TESTS)
    list(APPEND LLVM_SPIRV_TEST_DEPS
      llc
      llvm-dwarfdump
      llvm-objdump
      llvm-readelf
      llvm-readobj
    )
  endif(NOT SPIRV_SKIP_DEBUG_INFO_TESTS)
  if(SPIRV_BACKEND_FOUND AND SPIRV_SKIP_DEBUG_INFO_TESTS)
    list(APPEND LLVM_SPIRV_TEST_DEPS
      llc
    )
  endif()
  if(LLVM_BUILD_SHARED_LIBS)
    list(APPEND LLVM_SPIRV_TEST_DEPS
      opt
    )
  endif()
endif(NOT LLVM_SPIRV_BUILD_EXTERNAL)


if(LLVM_INCLUDE_SPIRV_TOOLS_TESTS AND NOT SPIRV_TOOLS_FOUND AND NOT SPIRV-Tools-tools_FOUND)
  # These targets are defined later, by llvm/tools/spirv-tools (processed
  # after this project's add_subdirectory(projects) call), so if(TARGET)
  # would always be false here. CMake still resolves DEPENDS against them
  # correctly at generate time.
  list(APPEND LLVM_SPIRV_TEST_DEPS spirv-as spirv-dis spirv-link spirv-val)
endif()

add_lit_testsuite(check-llvm-spirv "Running the LLVM-SPIRV regression tests"
  ${CMAKE_CURRENT_BINARY_DIR}
  ARGS
    --verbose
  DEPENDS
    ${LLVM_SPIRV_TEST_DEPS}
    llvm-spirv
)

# to enable a custom test target on cmake below 3.11
# starting with 3.11 "test" is only reserved if ENABLE_TESTING(ON)
if(LLVM_SPIRV_BUILD_EXTERNAL)
  cmake_policy(PUSH)
  if(POLICY CMP0037 AND ${CMAKE_VERSION} VERSION_LESS "3.11.0")
    cmake_policy(SET CMP0037 OLD)
  endif(POLICY CMP0037 AND ${CMAKE_VERSION} VERSION_LESS "3.11.0")
  add_custom_target(test
    DEPENDS
      check-llvm-spirv
  )
  cmake_policy(POP)
endif(LLVM_SPIRV_BUILD_EXTERNAL)
