#usage: cut_package_find(JSON)

set(_cut_package_find_name "nlohmann/json")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

hunter_add_package(nlohmann_json)
find_package(nlohmann_json CONFIG REQUIRED)

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime "nlohmann_json")
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES
    _CUT_DEFINITIONS
    _CUT_INCLUDES
    _CUT_LIBRARIES "nlohmann_json"
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)
