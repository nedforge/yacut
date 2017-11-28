include(hunter_config)
include(hunter_user_error)

hunter_config(glbinding VERSION 2.1.3)
# Force build on 1.65.1 since CUDA 9 requires it
hunter_config(Boost VERSION 1.65.1)
