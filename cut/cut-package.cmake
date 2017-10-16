if(_cut_package_include_guard)
    return()
endif()
set(_cut_package_include_guard true)

# Add cut-package-module to module path
set(_cut_package_module_path "${CUT_ROOT}/cut-package-module")
list(APPEND CMAKE_MODULE_PATH "${_cut_package_module_path}")

# Install hunter, our backend to package managing & retrieving
set(HUNTER_ROOT "${CMAKE_BINARY_DIR}/.hunter")
if(EXISTS "${CMAKE_BINARY_DIR}/cmake/HunterGate.cmake")
else()
    file(
        DOWNLOAD
        "https://raw.githubusercontent.com/hunter-packages/gate/master/cmake/HunterGate.cmake"
        "${CMAKE_BINARY_DIR}/cmake/HunterGate.cmake"
    )
endif()
include(HunterGate)
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.19.108.tar.gz"
    SHA1 "56cf9f1d52296373dbcc0d0c9c2b5526a0815019"
    FILEPATH "${_cut_package_module_path}/cut-package-hunter-config.cmake"
)
# Patch hunter for additional packages.
execute_process(
    COMMAND
        ${CMAKE_COMMAND} -E copy_directory
            "${CUT_ROOT}/cut-package-hunter-projects"
            "${HUNTER_SELF}/cmake/projects"
)

# Usage: _cut_package_parse_registry(some_prefix package_name)
# All found packages are registered in _cut_package_registry_${id} where id is obtained via cut_package_get_identifier().
# The data is stored in a shallow dictionary as argument format. Use this macro to get info from package registry via package name.
macro(_cut_package_parse_registry prefix name)
    _cut_package_get_identifier(_cut_package_parse_registry_id "${name}")
    cmake_parse_arguments(
        ${prefix}
        ""
        ""
        "_CUT_FIND_PACKAGE_PARAMETER;_CUT_DEPENDENCIES;_CUT_DEFINITIONS;_CUT_INCLUDES;_CUT_LIBRARIES;_CUT_RUNTIMES"
        ${_cut_package_registry_${_cut_package_parse_registry_id}}
    )
endmacro()

# Usage: cut_package_get_identifier(nlohmann-json) -> nlohmann_json
# Make all characters except alphanumeric into underscore, making it to be used in variable names.
function(_cut_package_get_identifier outputvar name)
    string(REGEX REPLACE "[^a-zA-Z0-9_]" "_" id "${name}")
    set(${outputvar} ${id} PARENT_SCOPE)
endfunction()

# Usage: cut_package_find(name [options...])
# Warning: DO NOT CALL cut_package_find() WITHIN THE RECIPES.
macro(cut_package_find name)
    # Before resolving our package modules, manually finalize hunter configuration phase, i.e. SHA1 computation and etc.
    # The default behavior is to lazily run it at first hunter_add_package() call.
    # 1) However, some of the cut package initializers do hunter_add_version() calls which must be done after the finalization.
    #    So it must be done BEFORE we include package modules.
    # 2) And we can't do it right after the HunterGate() call either, because some of the logics depend on variables on project properties.
    #    For example, MSVC env. var. is set AFTER root project has been established. So we should call it AFTER the project() call.
    # Thus, probably this location is the best to call it.
    if(NOT HUNTER_FINALIZED)
        hunter_finalize()
        set(HUNTER_FINALIZED TRUE)
    endif()
    
    _cut_package_get_identifier(_cut_package_find_id "${name}")
    
    # Check if we have already found it before.
    if(NOT DEFINED _cut_package_registry_${_cut_package_find_id})
        if(EXISTS "${_cut_package_module_path}/cut-package-find-${_cut_package_find_id}.cmake") # Recipe found
            message(STATUS "Finding package ${name}")
            set(_cut_package_registry_${_cut_package_find_id} _CUT_FIND_PACKAGE_PARAMETER ${ARGN}) # Pass arguments via registry
            include(cut-package-find-${_cut_package_find_id})
            message(STATUS "Finding package ${name} - done")
        else() # Recipe not found
            message(FATAL_ERROR "Cannot find package ${name} to resolve.")
        endif()
    endif()
endmacro()

# Check dependencies and return the list.
function(_cut_package_solve_dependencies outputvar name)
    # Check if the target is already resolved before.
    list(FIND ${outputvar} "${name}" index)
    if(index EQUAL -1)
        # Add children first
        _cut_package_parse_registry(REGISTRY "${name}")
        foreach(dep ${REGISTRY__CUT_DEPENDENCIES})
            _cut_package_solve_dependencies(${outputvar} ${dep})
        endforeach()
        # Add and return the package itself.
        set(${outputvar} ${${outputvar}} "${name}" PARENT_SCOPE)
    endif()
endfunction()

# Usage: cut_package_configure(target PACKAGE package1 package2... [RUNTIME [build] [install]])
# Setup packages to be linked for a target.
# If RUNTIME arguments are given, the runtime shared libraries will be copied to build/install directory.
# This is especially useful for Win32 VS configuration.
function(cut_package_configure target)
    cmake_parse_arguments(ARG "" "" "PACKAGE;RUNTIME" ${ARGN})

    # Solve dependencies first
    set(package_install_list "")
    foreach(name ${ARG_PACKAGE})
        _cut_package_solve_dependencies(package_install_list "${name}")
    endforeach()
    list(REMOVE_DUPLICATES package_install_list)

    # Now install everything
    foreach(name ${package_install_list})
        # Acquire an identifier
        _cut_package_get_identifier(id "${name}")

        # Check if it's found
        if(NOT DEFINED _cut_package_registry_${id})
            message(FATAL_ERROR "Package ${name} requested for target ${target} not found.")
        endif()
        
        # Add the package to the project
        _cut_package_parse_registry(REGISTRY "${name}")
        target_compile_definitions(${target} PUBLIC ${REGISTRY__CUT_DEFINITIONS})
		# Just globally include_directories() and not target_include_directories(),
		# since we're not going to install all the hunter-generated packages into the installation prefix.
		include_directories(SYSTEM ${REGISTRY__CUT_INCLUDES})
        target_link_libraries(${target} PUBLIC ${REGISTRY__CUT_LIBRARIES})
        
        # Setup post-build copy and installation of runtime shared libraries (DLLs).
        foreach(runtime ${ARG_RUNTIME})
            foreach(file ${REGISTRY__CUT_RUNTIMES})
                if(${runtime} STREQUAL "build")
                    add_custom_command(
                        TARGET ${target}
                        POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                            "${file}"
                            "$<TARGET_FILE_DIR:${target}>/"
                        COMMENT "Copying runtime..."
                    )
                elseif(${runtime} STREQUAL "install")
                    install(
                        FILES "${file}"
                        DESTINATION "${CMAKE_INSTALL_BINDIR}"
                    )
                else()
                    message(FATAL_ERROR "Unknown runtime copy setup ${runtime}.")
                endif()
            endforeach()
        endforeach()
    endforeach()
endfunction()

# Usage: _cut_package_obtain_runtime(outputvar target1 target2 ...)
# Used by package recipes to extract names for runtime files.
# If targetN is a CMake target, its runtime file will be added only if it is a shared library.
# Otherwise, the target will be treated just as a file.
function(_cut_package_obtain_runtime outputvar)
    set(${outputvar} "")
    foreach(target ${ARGN})
        if(TARGET "${target}")
            get_target_property(type ${target} TYPE)
            if(type EQUAL "SHARED_LIBRARY")
                list(APPEND ${outputvar} "$<TARGET_FILE:${target}>")
            else()
                # Let's skip this case since we don't exactly know every target being shared or not.
            endif()
        else()
            # Just a file. Make it absolute path.
            get_filename_component(path_absolute "${target}" ABSOLUTE)
            list(APPEND ${outputvar} "${path_absolute}")
        endif()
    endforeach()
    set(${outputvar} ${${outputvar}} PARENT_SCOPE)
endfunction()

# Usage: _cut_package_report(package_name [package info])
# Used by package recipes to register the found data.
macro(_cut_package_report name)
    _cut_package_get_identifier(_cut_package_report_id "${name}")
    list(APPEND _cut_package_registry_${_cut_package_report_id} ${ARGN})
endmacro()