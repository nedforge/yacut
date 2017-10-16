# !!! DO NOT PLACE HEADER GUARDS HERE !!!
# Custom patch.

include(hunter_add_version)
include(hunter_cacheable)
include(hunter_cmake_args)
include(hunter_download)
include(hunter_pick_scheme)

hunter_add_version(
    PACKAGE_NAME glbinding
    VERSION 2.1.3
    URL "https://github.com/cginternals/glbinding/archive/v2.1.3.tar.gz"
    SHA1 6c836f47c0463b3713e831c3325d758dc19531d8
)

hunter_cmake_args(
    glbinding
    CMAKE_ARGS
        OPTION_BUILD_TOOLS=OFF
        OPTION_BUILD_TESTS=OFF
        OPTION_BUILD_GPU_TESTS=OFF
        BUILD_SHARED_LIBS=OFF
)

hunter_pick_scheme(DEFAULT url_sha1_cmake)
hunter_download(PACKAGE_NAME glbinding)
