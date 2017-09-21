include(hunter_config)
include(hunter_user_error)

hunter_config(glbinding VERSION 2.1.3)

# CUDA 8.0 has a bug in compiling some complex SFINAE constructs so we use older version.
hunter_config(nlohmann_json VERSION 2.1.1-p0)
