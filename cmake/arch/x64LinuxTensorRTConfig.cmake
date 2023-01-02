set(ARCH_TARGET x64Linux)
set(ARCH x64Linux)
set(CPU_ARCH x64)
set(OPERATING_SYSTEM Linux)

########## Check TensorRT Libraries ##################

# set(CMAKE_CUDA_COMPILER /usr/local/cuda-10.2/bin/nvcc)
# enable_language(CUDA)

# Cuda and TensorRT lib
set(CUDA_VERSION 10.2)

set(CUDA_TOOLKIT_ROOT_DIR ${LINUX_ROOTFS}/usr/local/cuda-10.2)

find_package(CUDA ${CUDA_VERSION} REQUIRED)

find_library(CUDART_LIB cudart HINTS ${CUDA_TOOLKIT_ROOT_DIR} PATH_SUFFIXES lib lib64)

list(APPEND INFERENCE_ENGINE_HEADER_DIRS
    ${CUDA_INCLUDE_DIRS}
    ${NVIDIA_SYSROOT_PATH}/usr/local/cuda-10.2/targets/aarch64-linux/include
    )

message(STATUS "Target root path ${NVIDIA_SYSROOT_PATH}")
message(STATUS "CUDA_INCLUDE_DIR is ${CUDA_INCLUDE_DIRS}")
message(STATUS "CUDART LIB here is ${CUDART_LIB}")


################################### End of TensoRT ####################################
list(APPEND DMSAPI_LIBRARY_STATIC_LINK stdc++fs backtrace)

set(OpenCV_DIR "${CMAKE_SOURCE_DIR}/ThirdParty/opencv/lib/x64Linux/cmake/opencv4")
find_package(OpenCV REQUIRED)