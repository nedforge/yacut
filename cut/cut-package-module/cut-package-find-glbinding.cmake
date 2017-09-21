#usage: cut_package_find(glbinding)

set(_cut_package_find_name "glbinding")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

hunter_add_package(glbinding)
find_package(glbinding CONFIG REQUIRED)

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime "glbinding::glbinding")
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES "OpenGL"
    _CUT_DEFINITIONS
    _CUT_INCLUDES
    _CUT_LIBRARIES "glbinding::glbinding"
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)