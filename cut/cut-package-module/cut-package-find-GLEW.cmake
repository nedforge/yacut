#usage: cut_package_find(GLEW)

set(_cut_package_find_name "GLEW")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

hunter_add_package(GLEW)
find_package(GLEW CONFIG REQUIRED)

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime "glew::glew")
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES "OpenGL"
    _CUT_DEFINITIONS
    _CUT_INCLUDES
    _CUT_LIBRARIES "glew::glew"
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)