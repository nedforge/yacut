if(_cut_language_include_guard)
    return()
endif()
set(_cut_language_include_guard true)

include(CheckCXXCompilerFlag)

# Usage: cut_language_add_compiler_flags(
#     flag
#     LANGUAGES [CXX] [CUDA|CUDA_Xcompiler|CUDA_Xcudafe]
#     [TEST]
#     [RESULT output_var]
# )
# Try to set flag to the compiler for specific languages.
# If CXX language is enabled, TEST option can be provided to check flags before trying to adding it.
# The optional output variable output_var contains one of following:
# - "SUCCESS": at least one language has been set
# - "ALREADY_ADDED": all languages already have the flag set
# - "FAILED": requested flag failed on testing.
function(cut_language_add_compiler_flags flag)
    cut_utility_parse_arguments(ARG "TEST" "RESULT" "LANGUAGES" ${ARGN})

    # Check arguments
    if(NOT ARG_LANGUAGES)
        message(FATAL_ERROR "Required argument LANGUAGES not provided.")
    endif()
    
    # Check languages to set
    cut_utility_parse_flags(FLAG "CXX;CUDA;CUDA_Xcompiler;CUDA_Xcudafe" ${ARG_LANGUAGES})

    set(lang_CXX OFF) # Either OFF or ON
    set(lang_CUDA OFF) # One of OFF, "NATIVE", "Xcompiler" or "Xcudafe"

    if(FLAG_CXX)
        set(lang_CXX ON)
    endif()
    if(FLAG_CUDA)
        if(lang_CUDA)
            message(FATAL_ERROR "Cannot set multiple CUDA-related flags at once!")
        endif()
        set(lang_CUDA "NATIVE")
    endif()
    if(FLAG_CUDA_Xcompiler)
        if(lang_CUDA)
            message(FATAL_ERROR "Cannot set multiple CUDA-related flags at once!")
        endif()
        set(lang_CUDA "Xcompiler")
    endif()
    if(FLAG_CUDA_Xcudafe)
        if(lang_CUDA)
            message(FATAL_ERROR "Cannot set multiple CUDA-related flags at once!")
        endif()
        set(lang_CUDA "Xcudafe")
    endif()

    if(NOT lang_CXX)
        if(ARG_TEST)
            message(FATAL_ERROR "TEST option is supported only when CXX language is set.")
        endif()
    endif()

    # Arguments to be added
    set(arguments_CXX "")
    set(arguments_CUDA "")
    if(lang_CXX)
        set(arguments_CXX "${flag}")
    endif()
    if(lang_CUDA STREQUAL "NATIVE")
        set(arguments_CUDA "${flag}")
    elseif(lang_CUDA STREQUAL "Xcompiler")
        set(arguments_CUDA "-Xcompiler=\"${flag}\"")
    elseif(lang_CUDA STREQUAL "Xcudafe")
        set(arguments_CUDA "-Xcudafe=\"${flag}\"")
    endif()

    set(output "ALREADY_ADDED")
    
    # Check if already added
    if(lang_CXX)
        string(FIND "${CMAKE_CXX_FLAGS}" "${arguments_CXX}" index)
        if(NOT index EQUAL -1)
            cut_debug_message("Flag ${flag} is already set for C++.")
            set(lang_CXX OFF)
        endif()
    endif()
    if(lang_CUDA)
        string(FIND "${CMAKE_CUDA_FLAGS}" "${arguments_CUDA}" index)
        if(NOT index EQUAL -1)
            cut_debug_message("Flag ${flag} is already set for CUDA.")
            set(lang_CUDA OFF)
        endif()
    endif()

    # Test if required
    if(lang_CXX)
        if(ARG_TEST)
            # The name must be unique per test; check_cxx_compiler_flag() will cache the result internally on that variable.
            string(REGEX REPLACE "[^a-zA-Z0-9_]" "_" test_variable_name "_cut_LACF_test_${arguments_CXX}")
            check_cxx_compiler_flag("${arguments_CXX}" ${test_variable_name})
            if(NOT ${test_variable_name})
                cut_debug_message("Flag ${flag} failed the test.")
                set(output "FAILED")
            endif()
        endif()
    endif()

    if(NOT output STREQUAL "FAILED")
        # Test succeeds. Add flags.
        if(lang_CXX)
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${arguments_CXX}")
            cut_debug_message("Flag ${arguments_CXX} added to C++.")
            set(output "SUCCESS")
        endif()
        if(lang_CUDA)
            set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} ${arguments_CUDA}")
            cut_debug_message("Flag ${arguments_CUDA} added to CUDA.")
            set(output "SUCCESS")
        endif()
    endif()

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" PARENT_SCOPE)
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS}" PARENT_SCOPE)
    if(ARG_RESULT)
        set(${ARG_RESULT} "${output}" PARENT_SCOPE)
    endif()
endfunction()

# Usage: cut_language_remove_compiler_flags(
#     regex
#     LANGUAGES [CXX] [CUDA]
# )
# Remove compiler flags based on regex.
function(cut_language_remove_compiler_flags regex)
    cut_utility_parse_arguments(ARG "" "" "LANGUAGES" ${ARGN})

    # Check arguments
    if(NOT ARG_LANGUAGES)
        message(FATAL_ERROR "Required argument LANGUAGES not provided.")
    endif()
    cut_utility_parse_flags(lang "CXX;CUDA" ${ARG_LANGUAGES})
    
    if(lang_CXX)
        string(REGEX REPLACE "${regex}" " " CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    endif()
    if(lang_CUDA)
        string(REGEX REPLACE "${regex}" " " CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS}")
    endif()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" PARENT_SCOPE)
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS}" PARENT_SCOPE)
endfunction()

# Usage: cut_language_require([CXX version] [CUDA version] [STRICT])
# Require specific version of language globally. Any targets declared after this will require compiler support.
# For CXX, valid version includes 98|11|14 in CMake 3.9. Refer to CXX_STANDARD property for available values.
# For CUDA, valid version includes 98|11 in CMake 3.9. Refer to CUDA_STANDARD property for available values.
# If "STRICT" argument is given, it will disable compiler extensions and print warnings for standard conformance.
function(cut_language_require)
    cut_utility_parse_arguments(ARG "STRICT" "CXX;CUDA" "" ${ARGN})

    if(ARG_CXX)
        cut_debug_message("CXX version ${ARG_CXX} requested")
        set(CMAKE_CXX_STANDARD ${ARG_CXX} PARENT_SCOPE)
        set(CMAKE_CXX_STANDARD_REQUIRED on PARENT_SCOPE)

		# Workaround for MSVC 2015 Update 3 and later.
		# TODO: Once CMake implements /std:c++14 and /std:c++latest, remove this workaround.
		if(ARG_CXX EQUAL "14")
			if(MSVC_VERSION GREATER_EQUAL "1900")
				cut_language_add_compiler_flags("/std:c++${ARG_CXX}" LANGUAGES CXX TEST)
				set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" PARENT_SCOPE)
			endif()
		endif()
    endif()

    if(ARG_CUDA)
        cut_debug_message("CUDA version ${ARG_CUDA} requested")
        set(CMAKE_CUDA_STANDARD ${ARG_CUDA} PARENT_SCOPE)
        set(CMAKE_CUDA_STANDARD_REQUIRED on PARENT_SCOPE)
    endif()

    if(ARG_STRICT)
        set(cut_LACF_language_requests LANGUAGES)
        set(cut_LRCF_language_requests LANGUAGES)
        
        if(ARG_CXX)
            # Disable compiler extensions, e.g., -std=gnu++xx and such.
            set(CMAKE_CXX_EXTENSIONS OFF)
            set(cut_LACF_language_requests ${cut_LACF_language_requests} CXX)
            set(cut_LRCF_language_requests ${cut_LRCF_language_requests} CXX)
        endif()

        if(ARG_CUDA)
            # Disable compiler extensions, e.g., -std=gnu++xx and such.
            set(CMAKE_CUDA_EXTENSIONS OFF)
            set(cut_LACF_language_requests ${cut_LACF_language_requests} CUDA_Xcompiler)
            set(cut_LRCF_language_requests ${cut_LRCF_language_requests} CUDA)
        endif()

        # Let's face it. /Wall spews out warnings so verbose that even comes from their header files.
        # /W4 should be enough for most of standard conformance problems.
        cut_language_add_compiler_flags("-W4" ${cut_LACF_language_requests} TEST RESULT result)
        if(result STREQUAL "SUCCESS")
            # Remove other warning options
            cut_language_remove_compiler_flags("(^| )[/-][wW][0123]($| )" ${cut_LRCF_language_requests})
            cut_language_remove_compiler_flags("\"[/-][wW][0123]\"" ${cut_LRCF_language_requests})
        endif()
        
        # For non-MSVC
        cut_language_add_compiler_flags("-Wextra" ${cut_LACF_language_requests} TEST)
        cut_language_add_compiler_flags("-pedantic" ${cut_LACF_language_requests} TEST)

        # Set flags globally
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" PARENT_SCOPE)
        set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS}" PARENT_SCOPE)
    endif()
endfunction()

# Usage: cut_language_prevent_msvc_codepage_warning([LANGUAGES [CXX] [CUDA]])
# Suppress warning (C4819): The file contains a character that cannot be represented
#                           in the current code page (xxx). Save the file in Unicode
#                           format to prevent data loss.
# If LANGUAGES is not provided, it defaults to CXX.
function(cut_language_prevent_msvc_codepage_warning)
    cut_utility_parse_arguments(ARG "" "" "LANGUAGES" ${ARGN})

    # Check arguments
    if(NOT ARG_LANGUAGES)
        set(ARG_LANGUAGES CXX)
    endif()
    cut_utility_parse_flags(lang "CXX;CUDA" ${ARG_LANGUAGES})

    # Add languages to process
    set(cut_LACF_language_requests LANGUAGES)
    if(lang_CXX)
        set(cut_LACF_language_requests ${cut_LACF_language_requests} CXX)
    endif()
    if(lang_CUDA)
        set(cut_LACF_language_requests ${cut_LACF_language_requests} CUDA_Xcompiler)
    endif()
    
    cut_language_add_compiler_flags("/wd4819" ${cut_LACF_language_requests})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" PARENT_SCOPE)
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS}" PARENT_SCOPE)
endfunction()

# Usage: cut_language_disable_minmax_macros([LANGUAGES [CXX] [CUDA]])
# Kill min() and max() macros. Usually these are defined in Windows headers and frequently clashes with CUDA codes.
# If LANGUAGES is not provided, it defaults to CXX.
function(cut_language_disable_minmax_macros)
    cut_utility_parse_arguments(ARG "" "" "LANGUAGES" ${ARGN})

    # Check arguments
    if(NOT ARG_LANGUAGES)
        set(ARG_LANGUAGES CXX)
    endif()
    cut_utility_parse_flags(lang "CXX;CUDA" ${ARG_LANGUAGES})

    # Add languages to process
    set(cut_LACF_language_requests LANGUAGES)
    if(lang_CXX)
        set(cut_LACF_language_requests ${cut_LACF_language_requests} CXX)
    endif()
    if(lang_CUDA)
        set(cut_LACF_language_requests ${cut_LACF_language_requests} CUDA_Xcompiler)
    endif()

    cut_language_add_compiler_flags("-DNOMINMAX" ${cut_LACF_language_requests})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" PARENT_SCOPE)
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS}" PARENT_SCOPE)
endfunction()


# Usage: cut_language_cuda_enable_fastmath()
# Enable fastmath compiler options: 
function(cut_language_cuda_enable_fastmath)
    cut_language_add_compiler_flags("--use_fast_math" LANGUAGES CUDA)
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS}" PARENT_SCOPE)
endfunction()

# Usage: cut_language_cuda_disable_gpu_deprecation_warning()
# Suppress warning : The 'compute_20', 'sm_20', and 'sm_21' architectures are deprecated, and may be removed in a future release. 
function(cut_language_cuda_disable_gpu_deprecation_warning)
    cut_language_add_compiler_flags("-Wno-deprecated-gpu-targets" LANGUAGES CUDA)
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS}" PARENT_SCOPE)
endfunction()
