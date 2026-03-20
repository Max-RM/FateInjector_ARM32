
cmake_minimum_required(VERSION 3.20)
project(fateInjector VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 17)

# Для совместимости с вложенным wxWidgets CMake под CMake 4.x
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

set(wxBUILD_SHARED OFF CACHE BOOL "OFF for static library!" FORCE) # force wxWidgets to use static library
mark_as_advanced(wxBUILD_SHARED)

add_executable(fateInjector WIN32)
add_subdirectory(src)

if (MSVC)
    # requireAdministrator manifest for MSVC toolchain
    SET_TARGET_PROPERTIES(fateInjector PROPERTIES LINK_FLAGS "/level='requireAdministrator' /uiAccess='false'")
endif ()

# Отключаем встроенный libtiff в wxWidgets: для ARM32 он сейчас конфликтует с типами int64/uint64
set(wxUSE_LIBTIFF OFF CACHE BOOL "Disable built-in libtiff (not needed for this app)" FORCE)

add_subdirectory(wxWidgets-3.2.0)

target_link_libraries(fateInjector wx::net wx::core wx::base)

set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})

