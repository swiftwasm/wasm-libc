set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm32)
set(triple wasm32-unknown-unknown)

set(CMAKE_C_COMPILER "${LLVM_BIN}/clang")
set(CMAKE_CXX_COMPILER "${LLVM_BIN}/clang++")
set(CMAKE_AR "${LLVM_BIN}/llvm-ar" CACHE STRING "LLVM Archiver for wasm32")
set(CMAKE_RANLIB "${LLVM_BIN}/llvm-ranlib" CACHE STRING "LLVM Ranlib for wasm32")
set(CMAKE_C_COMPILER_TARGET ${triple} CACHE STRING "")
set(CMAKE_ASM_COMPILER_TARGET ${triple} CACHE STRING "")

set(CMAKE_C_COMPILER_WORKS ON)
set(CMAKE_CXX_COMPILER_WORKS ON)
