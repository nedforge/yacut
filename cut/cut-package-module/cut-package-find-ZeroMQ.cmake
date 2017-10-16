#usage: cut_package_find(ZeroMQ)

set(_cut_package_find_name "ZeroMQ")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

hunter_add_package(ZeroMQ)
find_package(ZeroMQ CONFIG REQUIRED)

# Include Winsock if necessary
if(WIN32)
    set(_cut_package_find_wsock "ws2_32")
else()
    set(_cut_package_find_wsock "")
endif()

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime "ZeroMQ::libzmq-static")
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES 
    _CUT_DEFINITIONS
    _CUT_INCLUDES
    _CUT_LIBRARIES "ZeroMQ::libzmq-static" ${_cut_package_find_wsock}
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)
