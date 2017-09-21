#usage: cut_package_find(spdlog)

set(_cut_package_find_name "spdlog")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

hunter_add_package(spdlog)
find_package(spdlog CONFIG REQUIRED)

# By default spdlog does NOT require fmtlib as it bundles everything.
# However we will stick to use external fmtlib (i.e. SPDLOG_FMT_EXTERNAL) to manage dependency easily.

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime "spdlog::spdlog")
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES "fmt"
    _CUT_DEFINITIONS "-DSPDLOG_FMT_EXTERNAL"
    _CUT_INCLUDES
    _CUT_LIBRARIES "spdlog::spdlog"
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)
