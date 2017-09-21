#usage: cut_package_find(OpenGL)

set(_cut_package_find_name "OpenGL")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

find_package(OpenGL REQUIRED)

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime)
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES
    _CUT_DEFINITIONS
    _CUT_INCLUDES ${OPENGL_INCLUDE_DIR}
    _CUT_LIBRARIES ${OPENGL_LIBRARIES}
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)