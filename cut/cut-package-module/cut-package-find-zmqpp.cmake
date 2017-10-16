#usage: cut_package_find(zmqpp)

set(_cut_package_find_name "zmqpp")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

hunter_cmake_args(
    ZMQPP
    CMAKE_ARGS
    CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
)
hunter_add_package(ZMQPP)
find_package(ZMQPP CONFIG REQUIRED)

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime "ZMQPP::zmqpp-static")
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES "ZeroMQ"
    _CUT_DEFINITIONS
    _CUT_INCLUDES
    _CUT_LIBRARIES "ZMQPP::zmqpp-static"
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)
