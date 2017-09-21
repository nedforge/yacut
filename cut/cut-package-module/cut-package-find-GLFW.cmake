#usage: cut_package_find(GLFW)

set(_cut_package_find_name "GLFW")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

hunter_add_package(glfw)
find_package(glfw3 CONFIG REQUIRED)

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime "glfw")
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES "OpenGL"
    _CUT_DEFINITIONS
    _CUT_INCLUDES
    _CUT_LIBRARIES "glfw"
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)
