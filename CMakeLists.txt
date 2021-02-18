cmake_minimum_required(VERSION 3.17)
project(wasm-libc)
enable_language(C)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

include(FetchContent)

FetchContent_Declare(
  wasi-libc
  GIT_REPOSITORY https://github.com/WebAssembly/wasi-libc.git
  GIT_TAG        f2e779e5f1ba4a539937cedeeaa762c1e0c162df)

FetchContent_MakeAvailable(wasi-libc)

include(ExternalProject)

find_program(MAKE_EXE NAMES gmake nmake make)

set(wasi-libc_MAKE_ENVS
  WASM_CC=${CMAKE_C_COMPILER} INSTALL_DIR=${wasi-libc_BINARY_DIR})

ExternalProject_Add(wasi-libc
  SOURCE_DIR            ${wasi-libc_SOURCE_DIR}
  CONFIGURE_COMMAND     ""
  INSTALL_COMMAND
    ${CMAKE_COMMAND} -E env ${wasi-libc_MAKE_ENVS} ${MAKE_EXE} install
  BUILD_COMMAND
    ${CMAKE_COMMAND} -E env ${wasi-libc_MAKE_ENVS} ${MAKE_EXE} finish
  BUILD_IN_SOURCE       ON)

install(DIRECTORY
  ${wasi-libc_BINARY_DIR}/
  DESTINATION ${CMAKE_INSTALL_PREFIX}/wasi-libc)

# WebAssembly floating-point match doesn't trap.
# TODO: Add -fno-signaling-nans when the compiler supports it.
add_compile_options(-fno-trapping-math)

# Add all warnings, but disable a few which occur in third-party code.
add_compile_options(
  -Wall -Wextra -Werror
  -Wno-null-pointer-arithmetic
  -Wno-unused-parameter
  -Wno-sign-compare
  -Wno-unused-variable
  -Wno-unused-function
  -Wno-ignored-attributes
  -Wno-missing-braces
  -Wno-ignored-pragmas)

set(wasm_sysroot ${CMAKE_BINARY_DIR}/sysroot)
add_custom_target(setup-wasm-sysroot
  COMMAND
    ${CMAKE_COMMAND} -E make_directory ${wasi-libc_SOURCE_DIR}/build
  COMMAND
    ${CMAKE_COMMAND} -E env SYSROOT=${wasm_sysroot} ${MAKE_EXE} include_dirs
  WORKING_DIRECTORY
    ${wasi-libc_SOURCE_DIR}
)

add_compile_options(
  --sysroot ${wasm_sysroot}
  -DWASI)

add_library(dlmalloc OBJECT
  "${wasi-libc_SOURCE_DIR}/dlmalloc/src/dlmalloc.c")
add_dependencies(dlmalloc setup-wasm-sysroot)
target_compile_options(dlmalloc
  PRIVATE -DLACKS_ERRNO_H -DMALLOC_FAILURE_ACTION)
target_include_directories(dlmalloc
  PUBLIC "${wasi-libc_SOURCE_DIR}/dlmalloc/include")

set(libc_bottom_half_src "${wasi-libc_SOURCE_DIR}/libc-bottom-half")
add_library(libc-bottom-half OBJECT
  "${libc_bottom_half_src}/sources/abort.c"
  "${libc_bottom_half_src}/sources/math/math-builtins.c"
  "${libc_bottom_half_src}/sources/math/fmin-fmax.c")
add_dependencies(libc-bottom-half dlmalloc)

add_library(wasm-libc STATIC
  $<TARGET_OBJECTS:dlmalloc>
  $<TARGET_OBJECTS:libc-bottom-half>)

set_target_properties(wasm-libc
  PROPERTIES
    OUTPUT_NAME   "c")

install(TARGETS wasm-libc
  DESTINATION wasm-libc/lib/wasm32-unknown)
install(DIRECTORY
  ${wasm_sysroot}/include/
  DESTINATION ${CMAKE_INSTALL_PREFIX}/wasm-libc/include)

foreach(name IN ITEMS m rt pthread crypt util xnet resolv dl)
  set(target_name wasm-${name})
  add_library(${target_name} STATIC
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/dummy.c)
  set_target_properties(${target_name}
    PROPERTIES
      OUTPUT_NAME   ${name})
  install(TARGETS ${target_name}
    DESTINATION wasm-libc/lib/wasm32-unknown)
endforeach()
