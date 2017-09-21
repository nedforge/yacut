# Usage: cut_package_find(Boost [COMPONENTS filesystem system ...])

set(_cut_package_find_name "Boost")
_cut_package_get_identifier(_cut_package_find_id "${_cut_package_find_name}")
_cut_package_parse_registry(_cut_package_find_registry "${_cut_package_find_name}")

# Parse cut_find_package() arguments
cmake_parse_arguments(_cut_package_find_arg "" "" "COMPONENTS" ${_cut_package_find_registry__CUT_FIND_PACKAGE_PARAMETER})

# Before we fetch Boost and then find_package() it, make sure that we do NOT use FindBoost.cmake distributed with hunter but the default one instead.
# The reason behind this is that FindBoost.cmake shipped with hunter is outdated.
# It has an issue in fetching some dependency components (e.g., Boost::log_setup for Boost::log).
# Fortunately the build by hunter_add_package() builds them; it's just a find_package() issue and nothing else.
# Recent version support fetching appropriate dependencies so we use it instead.
set(_cut_package_find_old_module_path ${CMAKE_MODULE_PATH})
set(CMAKE_MODULE_PATH "")
foreach(_cut_package_find_module_dir ${_cut_package_find_old_module_path})
    # Remove hunter find modules from module path
    string(FIND "${_cut_package_find_module_dir}" "/cmake/find" _cut_package_find_string_index)
	if(_cut_package_find_string_index EQUAL -1)
		list(APPEND CMAKE_MODULE_PATH ${_cut_package_find_module_dir})
	endif()
endforeach()

# Fetch the package
set(Boost_USE_STATIC_LIBS ON)
if(_cut_package_find_arg_COMPONENTS)
    hunter_add_package(Boost COMPONENTS ${_cut_package_find_arg_COMPONENTS})
	find_package(Boost MODULE REQUIRED COMPONENTS ${_cut_package_find_arg_COMPONENTS})
else()
    hunter_add_package(Boost)
    find_package(Boost MODULE REQUIRED)
endif()

# Restore CMake module path that was disabled for FindBoost.cmake
set(CMAKE_MODULE_PATH ${_cut_package_find_old_module_path})

# Disable #pragma comment(lib, ~~) feature in MSVC
if(MSVC)
  set(_cut_package_find_definitions -DBOOST_ALL_NO_LIB=1)
endif()

# Report
_cut_package_obtain_runtime(_cut_package_find_runtime) # We're using static libraries anyway
_cut_package_report(${_cut_package_find_name}
    _CUT_DEPENDENCIES
    _CUT_DEFINITIONS ${_cut_package_find_definitions}
    _CUT_INCLUDES ${Boost_INCLUDE_DIRS}
    _CUT_LIBRARIES ${Boost_LIBRARIES}
    _CUT_RUNTIMES ${_cut_package_find_runtime}
)