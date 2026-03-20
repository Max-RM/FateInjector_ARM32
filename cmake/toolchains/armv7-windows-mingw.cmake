set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_VERSION 1)

# Путь к установленному llvm-mingw (можно поменять при необходимости)
set(LLVM_MINGW_ROOT "C:/llvm-mingw" CACHE PATH "Path to llvm-mingw root")

set(CMAKE_C_COMPILER   "${LLVM_MINGW_ROOT}/bin/armv7-w64-mingw32-clang.exe")
set(CMAKE_CXX_COMPILER "${LLVM_MINGW_ROOT}/bin/armv7-w64-mingw32-clang++.exe")

set(CMAKE_RC_COMPILER  "${LLVM_MINGW_ROOT}/bin/armv7-w64-mingw32-windres.exe")

set(CMAKE_FIND_ROOT_PATH "${LLVM_MINGW_ROOT}/armv7-w64-mingw32")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
