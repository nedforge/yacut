#usage: cut_package_find(OptiX [INSTALL] [COMPONENTS prime])

set(_cut_package_find_name "OptiX")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

# Parse cut_find_package() arguments
cmake_parse_arguments(_cut_package_find_arg "INSTALL" "" "COMPONENTS" ${_cut_package_find_registry__CUT_FIND_PACKAGE_PARAMETER})

# OptiX_INSTALL_DIR variable is required to be set.
if(NOT OptiX_INSTALL_DIR)
    message(FATAL_ERROR "Cannot find OptiX. Set OptiX_INSTALL_DIR variable.")
endif()

# Copy and use FindOptiX.cmake included in the OptiX SDK distribution
file(COPY "${OptiX_INSTALL_DIR}/SDK/CMake/FindOptiX.cmake" DESTINATION "${CMAKE_BINARY_DIR}/cmake/")
find_package(OptiX REQUIRED)

# List libraries to link. Internal dependencies (e.g., OpenGL and etc.) are already handled inside FindOptiX.cmake.
set(_cut_package_find_libraries optix optixu)

foreach(_cut_package_find_component ${_cut_package_find_arg_COMPONENTS})
    if(_cut_package_find_component STREQUAL "prime")
        set(_cut_package_find_libraries ${_cut_package_find_libraries} optix_prime)
    else()
        message(FATAL_ERROR "Unknown component \"${_cut_package_find_component}\".")
    endif()
endforeach()

# Copy DLLs if required.
if(WIN32)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8 AND NOT APPLE)
        set(_cut_package_find_bit_dest "64")
    else()
        set(_cut_package_find_bit_dest "")
    endif()
    file(GLOB _cut_package_find_dlls "${OptiX_INSTALL_DIR}/bin${_cut_package_find_bit_dest}/*.dll")
endif(WIN32)

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime ${_cut_package_find_dlls})
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES
    _CUT_DEFINITIONS
    _CUT_INCLUDES ${OptiX_INCLUDE}
    _CUT_LIBRARIES ${_cut_package_find_libraries}
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)
