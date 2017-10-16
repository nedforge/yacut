#usage: cut_package_find(yaml-cpp)

set(_cut_package_find_name "yaml-cpp")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

hunter_add_package(yaml-cpp)
find_package(yaml-cpp CONFIG REQUIRED)

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime "yaml-cpp::yaml-cpp")
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES
    _CUT_DEFINITIONS
    _CUT_INCLUDES
    _CUT_LIBRARIES "yaml-cpp::yaml-cpp"
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)
