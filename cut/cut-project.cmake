if(_cut_project_include_guard)
    return()
endif()
set(_cut_project_include_guard true)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# If src variable has value, set dst variable to it and publish to PARENT_SCOPE.
macro(_cut_project_setup_set_output_variable src dst)
    if(${src})
        set(${dst} ${${dst}} "${${src}}" PARENT_SCOPE)
    endif()
endmacro()

# If src variable has value, append it to dst variable and publish to PARENT_SCOPE.
macro(_cut_project_setup_append_output_variable src dst)
    if(${src})
        set(${dst} ${${dst}} ${${src}} PARENT_SCOPE)
    endif()
endmacro()

macro(_cut_project_setup_set_default_value var value)
    if(NOT ${var})
        set(${var} ${value})
    endif()
endmacro()

# Usage: _cut_project_setup_source_gather_glob(output_var dir1 dir2 ...)
# Retrieves combined globbed results of all files in all specified directories.
function(_cut_project_setup_source_gather_glob output_var)
    if(ARGN)
        set(glob_target "")
        foreach(dir ${ARGN})
            list(APPEND glob_target "${dir}/*")
        endforeach()
        file(GLOB_RECURSE glob_result ${glob_target})
        
        set(${output_var} ${glob_result} PARENT_SCOPE)
    else()
        set(${output_var} "" PARENT_SCOPE)
    endif()
endfunction()

# Gather sources from the parsed arguments and group it if necessary.
macro(_cut_project_setup_source_gather target_name)
    set(CXX_FILES "")
    set(CUDA_OBJ_FILES "")
    set(CUDA_PTX_FILES "")
    set(INCLUDE_PUBLIC_FILES "")
    set(INCLUDE_PRIVATE_FILES "")
    set(RESOURCE_FILES "")

    if(ARG_CXX)
        # Find all files first
        _cut_project_setup_source_gather_glob(glob_result ${ARG_CXX})

        # Now categorize each file based on its extension
        foreach(file ${glob_result})
            if("${file}" MATCHES ".*\.cu")
                list(APPEND CUDA_OBJ_FILES "${file}")
            else()
                list(APPEND CXX_FILES "${file}")
            endif()
        endforeach()
    endif()

    # CUDA PTXs
    _cut_project_setup_source_gather_glob(CUDA_PTX_FILES ${ARG_CUDA_PTX})
    
    # Includes and resources
    _cut_project_setup_source_gather_glob(INCLUDE_PUBLIC_FILES ${ARG_INCLUDE_PUBLIC})
    if(INCLUDE_PUBLIC_FILES) # Make sure that these files are not compiled
        set_source_files_properties(${INCLUDE_PUBLIC_FILES} PROPERTIES HEADER_FILE_ONLY TRUE)
    endif()
    
    _cut_project_setup_source_gather_glob(INCLUDE_PRIVATE_FILES ${ARG_INCLUDE_PRIVATE})
    if(INCLUDE_PRIVATE_FILES) # Make sure that these files are not compiled
        set_source_files_properties(${INCLUDE_PRIVATE_FILES} PROPERTIES HEADER_FILE_ONLY TRUE)
    endif()

    _cut_project_setup_source_gather_glob(RESOURCE_FILES ${ARG_RESOURCE})
    if(RESOURCE_FILES) # Make sure that these files are not compiled
        set_source_files_properties(${RESOURCE_FILES} PROPERTIES HEADER_FILE_ONLY TRUE)
    endif()
    
    # Group by directory if requested
    if(ARG_GROUP_BY)
        cut_project_group_sources_by_directory(
            ${ARG_GROUP_BY}
            ${CXX_FILES}
            ${CUDA_OBJ_FILES}
            ${CUDA_PTX_FILES}
            ${INCLUDE_PUBLIC_FILES}
            ${INCLUDE_PRIVATE_FILES}
            ${RESOURCE_FILES}
            )
    endif()

    # Set output variables
    _cut_project_setup_append_output_variable(CXX_FILES ${target_name}_SOURCE_CXX_FILES)
    _cut_project_setup_append_output_variable(CUDA_OBJ_FILES ${target_name}_SOURCE_CUDA_OBJ_FILES)
    _cut_project_setup_append_output_variable(CUDA_PTX_FILES ${target_name}_SOURCE_CUDA_PTX_FILES)
    _cut_project_setup_append_output_variable(INCLUDE_PUBLIC_FILES ${target_name}_SOURCE_INCLUDE_PUBLIC_FILES)
    _cut_project_setup_append_output_variable(INCLUDE_PRIVATE_FILES ${target_name}_SOURCE_INCLUDE_PRIVATE_FILES)
    _cut_project_setup_append_output_variable(RESOURCE_FILES ${target_name}_SOURCE_RESOURCE_FILES)
endmacro()

# Usage: Refer to the SOURCE part of cut_project_setup().
macro(_cut_project_setup_source target_name)
    cut_utility_parse_arguments(ARG "" "GROUP_BY" "CXX;CUDA_PTX;INCLUDE;RESOURCE" ${ARGN})
    
    # Set output variables
    _cut_project_setup_append_output_variable(ARG_CXX ${target_name}_SOURCE_CXX)
    _cut_project_setup_append_output_variable(ARG_CUDA_PTX ${target_name}_SOURCE_CUDA_PTX)
    if(ARG_INCLUDE)
        cut_utility_parse_arguments(ARG_INCLUDE "" "" "PUBLIC;PRIVATE" ${ARG_INCLUDE})
        _cut_project_setup_append_output_variable(ARG_INCLUDE_PUBLIC ${target_name}_SOURCE_INCLUDE_PUBLIC)
        _cut_project_setup_append_output_variable(ARG_INCLUDE_PRIVATE ${target_name}_SOURCE_INCLUDE_PRIVATE)
    endif()
    _cut_project_setup_append_output_variable(ARG_RESOURCE ${target_name}_SOURCE_RESOURCE)

    # Gather sources
    _cut_project_setup_source_gather(${target_name})
endmacro()

# Usage: Refer to the BUILD part of cut_project_setup().
macro(_cut_project_setup_build target_name)
    cut_utility_parse_arguments(ARG "" "CUDA_PTX" "" ${ARGN})

    # Set default values
    _cut_project_setup_set_default_value(ARG_CUDA_PTX "${PROJECT_BINARY_DIR}/${target_name}/ptx")

    # Set output variables
    _cut_project_setup_set_output_variable(ARG_CUDA_PTX ${target_name}_BUILD_CUDA_PTX)
endmacro()

# Usage: Refer to the INSTALL part of cut_project_setup().
macro(_cut_project_setup_install target_name)
    cut_utility_parse_arguments(ARG "" "ARCHIVE;LIBRARY;RUNTIME;INCLUDE;CUDA_PTX;RESOURCE" "" ${ARGN})

	# Set default values
    _cut_project_setup_set_default_value(ARG_ARCHIVE "${CMAKE_INSTALL_LIBDIR}")
    _cut_project_setup_set_default_value(ARG_LIBRARY "${CMAKE_INSTALL_LIBDIR}")
    _cut_project_setup_set_default_value(ARG_RUNTIME "${CMAKE_INSTALL_BINDIR}")
    _cut_project_setup_set_default_value(ARG_INCLUDE "${CMAKE_INSTALL_INCLUDEDIR}")
    _cut_project_setup_set_default_value(ARG_CUDA_PTX "${CMAKE_INSTALL_LIBDIR}/${target_name}/ptx")
    _cut_project_setup_set_default_value(ARG_RESOURCE "${CMAKE_INSTALL_DATAROOTDIR}/${target_name}")

    # Setup reverse prefix lookup
    if(IS_ABSOLUTE "${ARG_RUNTIME}")
        # Well in this case it is not that useful...
        file(RELATIVE_PATH irtp "${ARG_RUNTIME}" "${CMAKE_INSTALL_PREFIX}")
    else()
        # Setup reverse lookup
        file(RELATIVE_PATH irtp "${CMAKE_INSTALL_PREFIX}/${ARG_RUNTIME}" "${CMAKE_INSTALL_PREFIX}")
    endif()
    set(${target_name}_INSTALL_RUNTIME_TO_PREFIX "${irtp}" PARENT_SCOPE)
    
    # Set output variables
    _cut_project_setup_set_output_variable(ARG_ARCHIVE ${target_name}_INSTALL_ARCHIVE)
    _cut_project_setup_set_output_variable(ARG_LIBRARY ${target_name}_INSTALL_LIBRARY)
    _cut_project_setup_set_output_variable(ARG_RUNTIME ${target_name}_INSTALL_RUNTIME)
    _cut_project_setup_set_output_variable(ARG_INCLUDE ${target_name}_INSTALL_INCLUDE)
    _cut_project_setup_set_output_variable(ARG_CUDA_PTX ${target_name}_INSTALL_CUDA_PTX)
    _cut_project_setup_set_output_variable(ARG_RESOURCE ${target_name}_INSTALL_RESOURCE)
endmacro()

# Usage: cut_project_setup(
#     target_name
#     SOURCE
#         [CXX srcdir1 srcdir2 ...]
#         [CUDA_PTX cudaptxdir1 cudaptxdir2 ...]
#         [INCLUDE
#             [PUBLIC publicincludedir1 publicincludedir2 ...]
#             [PRIVATE privateincludedir1 privateincludedir2 ...]
#         ]
#         [RESOURCE resourcedir1 resourcedir2 ...]
#         [GROUP_BY relative_to]
#     [BUILD]
#         [CUDA_PTX cudaptxdir]
#     [INSTALL]
#         [ARCHIVE archivedir]
#         [LIBRARY librarydir]
#         [RUNTIME runtimedir]
#         [INCLUDE includedir]
#         [CUDA_PTX cudaptxdir]
#         [RESOURCE resourcedir]
# )
#
# Glob sources and set variables for C++/CUDA project as a target.
# Note: Any multiple calls will result in either appending the directory (for multi-valued entries) or overwriting one (for single-valued ones).
#
# SOURCE indicates the source element.
#     CXX specifies source directory for C++/CUDA fatbin sources.
#     CUDA_PTX specifies source directory for CUDA PTX sources.
#     INCLUDE specifies include directories. PUBLIC/PRIVATE specifies the visibility on linking.
#     RESOURCE specifies the resource directory. If INSTALL is specified, the content is installed into resource installation directory.
#     If GROUP_BY is specified, all the globbed files are grouped in relative to specified root directory.
#
#     Related outputs:
#         ${target_name}_SOURCE_CXX_FILES:             Anything in source dirs except *.cu
#         ${target_name}_SOURCE_CUDA_OBJ_FILES:        *.cu in source dirs
#         ${target_name}_SOURCE_CUDA_PTX_FILES:        Anything in CUDA ptx dirs.
#         ${target_name}_SOURCE_INCLUDE_PUBLIC_FILES:  Anything in public include dirs.
#         ${target_name}_SOURCE_INCLUDE_PRIVATE_FILES: Anything in private include dirs.
#         ${target_name}_SOURCE_RESOURCE_FILES:        Anything in resource dirs
#
#         ${target_name}_SOURCE_CXX:             Copy of CXX argument.
#         ${target_name}_SOURCE_CUDA_PTX:        Copy of CUDA_PTX argument.
#         ${target_name}_SOURCE_INCLUDE_PUBLIC:  Copy of INCLUDE (PUBLIC) argument.
#         ${target_name}_SOURCE_INCLUDE_PRIVATE: Copy of INCLUDE (PRIVATE) argument.
#         ${target_name}_SOURCE_RESOURCE:        Copy of RESOURCE argument.
# If provided, BUILD sets the directory specific to build artifacts.
# Note: if BUILD is not provided at all, the created project will have its PTX files built into somewhere CMake sets.
#       The files are still installable, yet may not be available at debugging time for some IDEs such as Visual Studio.
#     CUDA_PTX specifies where CUDA PTX are built into. Default value is "${PROJECT_BINARY_DIR}/${target_name}/ptx".
#
#     Related outputs:
#         ${target_name}_BUILD_CUDA_PTX: Copy of CUDA_PTX argument.
# If provided, INSTALL sets the install destination.
# Note: if INSTALL is not provided at all, the created project will not have an installation entry.
# Note: it is recommended to use relative path from the installation prefix. Otherwise there's high chance that your project is not relocatable.
#     ARCHIVE, LIBRARY and RUNTIME determines the installation location of target. Refer install() for meaning of each type. Default value is following:
#         ARCHIVE: "${CMAKE_INSTALL_LIBDIR}"
#         LIBRARY: "${CMAKE_INSTALL_LIBDIR}"
#         RUNTIME: "${CMAKE_INSTALL_BINDIR}"
#     INCLUDE determines the installation location of include files. Default value is "${CMAKE_INSTALL_INCLUDEDIR}".
#     CUDA_PTX determines the installation location of CUDA PTX files. Default value is "${CMAKE_INSTALL_LIBDIR}/${target_name}/ptx".
#     RESOURCE determines the installation location of resource files. Default value is "${CMAKE_INSTALL_DATAROOTDIR}/${target_name}".
#
#     Related outputs:
#         ${target_name}_INSTALL_RUNTIME_TO_PREFIX: Reversed relative path from runtime location to the prefix.
#                                                   For example, if ${target_name}_INSTALL_RUNTIME is "bin/abcd",
#                                                   then this becomes "../..".
#         ${target_name}_INSTALL_ARCHIVE:           Copy of ARCHIVE argument.
#         ${target_name}_INSTALL_LIBRARY:           Copy of LIBRARY argument.
#         ${target_name}_INSTALL_RUNTIME:           Copy of RUNTIME argument. *Note: DLL goes here in WIN32.
#         ${target_name}_INSTALL_INCLUDE:           Copy of INCLUDE argument.
#         ${target_name}_INSTALL_CUDA_PTX:          Copy of CUDA_PTX argument.
#         ${target_name}_INSTALL_RESOURCE:          Copy of RESOURCE argument.
function(cut_project_setup target_name)
    cut_utility_parse_arguments(ARG "" "" "SOURCE;BUILD;INSTALL" ${ARGN})

    list(FIND ARGN SOURCE find_result)
    if(NOT "${find_result}" EQUAL "-1")
        _cut_project_setup_source(${target_name} ${ARG_SOURCE})
    endif()

    list(FIND ARGN BUILD find_result)
    if(NOT "${find_result}" EQUAL "-1")
        _cut_project_setup_build(${target_name} ${ARG_BUILD})
    endif()

    list(FIND ARGN INSTALL find_result)
    if(NOT "${find_result}" EQUAL "-1")
        _cut_project_setup_install(${target_name} ${ARG_INSTALL})
    endif()
endfunction()

# Usage: cut_project_group_sources_by_directory(relative_to filepath1 filepath2 ...)
# Group files by directory if the generator supports it (e.g., MSVC)
# The group is set based on relative path from where relative_to sets.
function(cut_project_group_sources_by_directory relative_to)
    foreach(file ${ARGN})
        get_filename_component(path_absolute "${file}" ABSOLUTE)
        get_filename_component(path_parent "${path_absolute}" DIRECTORY)
        file(RELATIVE_PATH path_relative "${relative_to}" "${path_parent}")
        string(REPLACE "/" "\\" groupname "${path_relative}")
        source_group(${groupname} FILES "${file}")
    endforeach() 
endfunction()

# Usage: cut_project_add_cut_as_source(target_name)
# Add CUT files to the target's source tree.
function(cut_project_add_cut_as_source target_name)
    file(GLOB_RECURSE cut_cmake_files_list "${CUT_ROOT}/*")
    get_filename_component(cut_parent "${CUT_ROOT}" DIRECTORY)
    cut_project_group_sources_by_directory(${cut_parent} ${cut_cmake_files_list})
    set_source_files_properties(${cut_cmake_files_list} PROPERTIES HEADER_FILE_ONLY TRUE)
    target_sources(${target_name} PRIVATE ${cut_cmake_files_list})
endfunction()

# Usage: _cut_PCT_setup_target_includes(target_name target_prefix)
# Setup proper target_include_directories() for target. Target setup variables are found via ${target_prefix}_blahblah.
function(_cut_PCT_setup_target_includes target_name target_prefix)
    set(public_include_dirs "")
    foreach(public_include_dir ${${target_prefix}_SOURCE_INCLUDE_PUBLIC})
        set(public_include_dirs ${public_include_dirs} "$<BUILD_INTERFACE:${public_include_dir}>")
    endforeach()
    set(public_include_dirs ${public_include_dirs} "$<INSTALL_INTERFACE:${${target_prefix}_INSTALL_INCLUDE}>")
    cut_debug_message("Include setup for target ${target_name} (PUBLIC): ${public_include_dirs}")
    cut_debug_message("Include setup for target ${target_name} (PRIVATE): ${${target_prefix}_INSTALL_INCLUDE}")
    target_include_directories(
        ${target_name}
        PUBLIC
        ${public_include_dirs}
        PRIVATE
        ${${target_prefix}_SOURCE_INCLUDE_PRIVATE}
    )
endfunction()


# Usage: cut_project_create_target(target_name [EXECUTABLE|LIBRARY] [EXPORT])
# Create target based on setup informations from previous cut_project_setup() call.
#
# If EXPORT is given, its CMake export can be installed later via cut_project_install_export().
function(cut_project_create_target target_name)
    cut_utility_parse_arguments(ARG "EXECUTABLE;LIBRARY;EXPORT" "" "" ${ARGN})

    # Check arguments
    if(ARG_EXECUTABLE)
        if(ARG_LIBRARY)
            message(FATAL_ERROR "Both EXECUTABLE and LIBRARY are specified.")
        endif()
    else()
        if(NOT ARG_LIBRARY)
            message(FATAL_ERROR "Neither EXECUTABLE nor LIBRARY is specified.")
        endif()
    endif()

    ### Create target ###
    cut_debug_message("Adding target ${target_name}...")
    if(ARG_EXECUTABLE)
        add_executable(
            ${target_name}
            ${${target_name}_SOURCE_CXX_FILES}
            ${${target_name}_SOURCE_CUDA_OBJ_FILES}
            ${${target_name}_SOURCE_INCLUDE_PUBLIC_FILES}
            ${${target_name}_SOURCE_INCLUDE_PRIVATE_FILES}
            ${${target_name}_SOURCE_RESOURCE_FILES}
        )
    else()
        add_library(
            ${target_name}
            ${${target_name}_SOURCE_CXX_FILES}
            ${${target_name}_SOURCE_CUDA_OBJ_FILES}
            ${${target_name}_SOURCE_INCLUDE_PUBLIC_FILES}
            ${${target_name}_SOURCE_INCLUDE_PRIVATE_FILES}
            ${${target_name}_SOURCE_RESOURCE_FILES}
        )
    endif()
    
    # Setup includes
    _cut_PCT_setup_target_includes(${target_name} ${target_name})

    # Setup CUDA compilation options
    set_target_properties(${target_name} PROPERTIES POSITION_INDEPENDENT_CODE ON)

    # Create PTX object library
    if(${target_name}_SOURCE_CUDA_PTX_FILES)
        add_library(
            ${target_name}-PTX
            OBJECT
            ${${target_name}_SOURCE_CUDA_PTX_FILES}
        )
        set_property(TARGET ${target_name}-PTX PROPERTY CUDA_PTX_COMPILATION ON)
        
        # Setup includes
        _cut_PCT_setup_target_includes(${target_name}-PTX ${target_name})
        
        add_dependencies(${target_name} ${target_name}-PTX)

        # Setup post-build event for PTX
        if(${target_name}_BUILD_CUDA_PTX)
            add_custom_command(
                TARGET ${target_name}
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory "${${target_name}_BUILD_CUDA_PTX}"
                COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_OBJECTS:${target_name}-PTX> "${${target_name}_BUILD_CUDA_PTX}/"
                COMMAND_EXPAND_LISTS
                COMMENT "Copying PTX files to build directory..."
            )
        endif()
    endif()

    ### Install ###
    if(NOT ${target_name}_INSTALL_RUNTIME_TO_PREFIX)
        return()
    endif()
    # Set parameter for associating an export if requested
    if(ARG_EXPORT)
        cut_debug_message("Export of ${target_name} requested with name ${PROJECT_NAME}Target")
        set(export_option EXPORT "${PROJECT_NAME}Target")
    else()
        set(export_option "")
    endif()

    # Install binary
    install(TARGETS ${target_name} ${export_option}
        ARCHIVE DESTINATION "${${target_name}_INSTALL_ARCHIVE}"
        LIBRARY DESTINATION "${${target_name}_INSTALL_LIBRARY}"
        RUNTIME DESTINATION "${${target_name}_INSTALL_RUNTIME}"
    )

    # Install includes
    foreach(includedir ${${target_name}_SOURCE_INCLUDE_PUBLIC})
        install(DIRECTORY "${includedir}/" DESTINATION "${${target_name}_INSTALL_INCLUDE}")
    endforeach()

    # Install PTXs
    if(${target_name}_SOURCE_CUDA_PTX_FILES)
        install(FILES $<TARGET_OBJECTS:${target_name}-PTX> DESTINATION "${${target_name}_INSTALL_CUDA_PTX}")
    endif()

    # Install resources
    foreach(resourcedir ${${target_name}_SOURCE_RESOURCE})
        install(DIRECTORY "${resourcedir}/" DESTINATION "${${target_name}_INSTALL_RESOURCE}")
    endforeach()
endfunction()

# Usage: cut_project_install_export()
# Install an export for current project. All previously registered export targets are exported.
# Note: All the previous targets in the project must have been bound with current project.
#       Refer to the EXPORT keyword for cut_project_create_target().
function(cut_project_install_export)
    install(EXPORT "${PROJECT_NAME}Target" DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake")

    string(TOUPPER "${PROJECT_NAME}" cut_config_var_varprefix)
    set(cut_config_var_target_include "${PROJECT_NAME}Target.cmake")
    configure_package_config_file(
        "${CUT_ROOT}/cut-project-template/CutProjectConfig.cmake.in"
        "${PROJECT_BINARY_DIR}/cmake/${PROJECT_NAME}Config.cmake"
        INSTALL_DESTINATION  "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake"
    )
    install(FILES "${PROJECT_BINARY_DIR}/cmake/${PROJECT_NAME}Config.cmake" DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}/cmake")
endfunction()

# Usage: cut_project_create_config(
#    target_name
#    PATH path
#    [PROPAGATE_DIR_PATHS [SOURCE] [BUILD] [INSTALL]]
#    [PROPAGATE var1 var2 ...]
# )
# Create a configuration header at path. Propagate variables specified by PROPAGATE.
# Call this funciton after setups and before target creation (cut_project_create_target()).
# If PROPAGATE_DIR_PATHS is given, it propagates respective directory settings from cut_project_setup().
function(cut_project_create_config target_name)
    cut_utility_parse_arguments(ARG "" "PATH" "PROPAGATE;PROPAGATE_DIR_PATHS" ${ARGN})

    if(NOT ARG_PATH)
        message(FATAL_ERROR "Configuration path needed.")
    endif()

    # List variables to propagate
    set(var_to_propagate ${ARG_PROPAGATE})
    cut_utility_parse_flags(FLAG "SOURCE;BUILD;INSTALL" ${ARG_PROPAGATE_DIR_PATHS})
    if(FLAG_SOURCE)
        list(APPEND var_to_propagate ${target_name}_SOURCE_CXX)
        list(APPEND var_to_propagate ${target_name}_SOURCE_CUDA_PTX)
        list(APPEND var_to_propagate ${target_name}_SOURCE_INCLUDE_PUBLIC)
        list(APPEND var_to_propagate ${target_name}_SOURCE_INCLUDE_PRIVATE)
        list(APPEND var_to_propagate ${target_name}_SOURCE_RESOURCE)
    endif()
    if(FLAG_BUILD)
        list(APPEND var_to_propagate ${target_name}_BUILD_CUDA_PTX)
    endif()
    if(FLAG_INSTALL)
        list(APPEND var_to_propagate ${target_name}_INSTALL_RUNTIME_TO_PREFIX)
        list(APPEND var_to_propagate ${target_name}_INSTALL_ARCHIVE)
        list(APPEND var_to_propagate ${target_name}_INSTALL_LIBRARY)
        list(APPEND var_to_propagate ${target_name}_INSTALL_RUNTIME)
        list(APPEND var_to_propagate ${target_name}_INSTALL_INCLUDE)
        list(APPEND var_to_propagate ${target_name}_INSTALL_CUDA_PTX)
        list(APPEND var_to_propagate ${target_name}_INSTALL_RESOURCE)
    endif()
    list(REMOVE_DUPLICATES var_to_propagate)

    # Construct content
    cut_utility_make_identifier_upper(id_target_name "${target_name}")
    string(CONCAT content
        "#ifndef _CUT_${id_target_name}_CONFIGURE_HEADER_\n"
        "#define _CUT_${id_target_name}_CONFIGURE_HEADER_\n"
        "\n"
    )

    foreach(var ${var_to_propagate})
        cut_utility_make_identifier_upper(id_var "${var}")
        string(CONCAT content "${content}"
            "#define ${id_var} \"${${var}}\"\n"
        )
    endforeach()

    string(CONCAT content "${content}"
        "\n"
        "#endif\n"
    )

    # Write file
    file(WRITE "${ARG_PATH}" "${content}")
endfunction()