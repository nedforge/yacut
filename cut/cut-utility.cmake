if(_cut_utility_include_guard)
    return()
endif()
set(_cut_utility_include_guard true)

# Usage: same as cmake_parse_arguments().
# This will pop error if there's any unparsed argument.
macro(cut_utility_parse_arguments arg_prefix a b c)
    cmake_parse_arguments("${arg_prefix}" "${a}" "${b}" "${c}" ${ARGN})
    if(${arg_prefix}_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown argument: ${${arg_prefix}_UNPARSED_ARGUMENTS}.")
    endif()
endmacro()

# Usage: cut_utility_parse_flags(arg_prefix "FLAG1;FLAG2;FLAG3" FLAG1 FLAG3).
# -> ${arg_prefix}_FLAG1 = ON
# -> ${arg_prefix}_FLAG2 = OFF
# -> ${arg_prefix}_FLAG3 = ON
# Will pop error if there are duplicates or undefined.
function(cut_utility_parse_flags arg_prefix defined_flags)
    # initialize local variables
    foreach(flag ${defined_flags})
        set(${arg_prefix}_${flag} OFF)
    endforeach()

    # parse
    foreach(entry ${ARGN})
        list(FIND defined_flags "${entry}" find_result)

        if(find_result EQUAL -1)
            message(FATAL_ERROR "Unknown flag: ${entry}")
        elseif(${arg_prefix}_${entry} EQUAL ON)
            message(FATAL_ERROR "flag already set: ${entry}")
        else()
            set(${arg_prefix}_${entry} ON)
        endif()
    endforeach()

    # return results
    foreach(flag ${defined_flags})
        set(${arg_prefix}_${flag} ${${arg_prefix}_${flag}} PARENT_SCOPE)
    endforeach()
endfunction()

# Usage: cut_utility_make_identifier(a/c var) -> var = "a_c"
function(cut_utility_make_identifier outputvar name)
    string(REGEX REPLACE "[^a-zA-Z0-9_]" "_" id "${name}")
    set(${outputvar} ${id} PARENT_SCOPE)
endfunction()

# Usage: cut_utility_make_identifier_upper(a/c var) -> var = "A_C"
function(cut_utility_make_identifier_upper outputvar name)
    string(REGEX REPLACE "[^a-zA-Z0-9_]" "_" id "${name}")
    string(TOUPPER "${id}" id)
    set(${outputvar} ${id} PARENT_SCOPE)
endfunction()

macro(cut_debug_message msg)
    if(CUT_DEBUG_MESSAGE)
        message(STATUS "** CUT debug: ${msg}")
    endif()
endmacro()

macro(cut_debug_dumpvar var)
    message(STATUS "** CUT debug: ${var}: ${${var}}")
endmacro()
