#usage: cut_package_find(cereal)

set(_cut_package_find_name "cereal")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

hunter_add_package(cereal)
find_package(cereal CONFIG REQUIRED)

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime "cereal::cereal")
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES 
    _CUT_DEFINITIONS
    _CUT_INCLUDES
    _CUT_LIBRARIES "cereal::cereal"
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)
