# CUT: CMake Utility Toolkit

if(_cut_include_guard)
    return()
endif()
set(_cut_include_guard true)

get_filename_component(CUT_ROOT "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
list(APPEND CMAKE_MODULE_PATH
    "${CUT_ROOT}"               # this directory
    "${CMAKE_BINARY_DIR}/cmake" # some of the dynamically created/downloaded CMake files are located here.
    )

include(cut-utility)
include(cut-language)
include(cut-project)
include(cut-package)
