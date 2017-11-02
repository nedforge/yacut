#usage: cut_package_find(Catch)

set(_cut_package_find_name "Catch")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

hunter_add_package(Catch)
find_package(Catch CONFIG REQUIRED)

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime "Catch::Catch")
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES
    _CUT_DEFINITIONS
    _CUT_INCLUDES
    _CUT_LIBRARIES "Catch::Catch"
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)
