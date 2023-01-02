set(CMAKE_SYSTEM_NAME Linux)

set(PLATFORM_LIBS rt m pthread dl)
set(ARCH armv8Linux)

set(CPU_ARCH armv8)
set(OPERATING_SYSTEM Linux)

if(DEFINED ENV{NVIDIA_SDK_PATH} AND NOT DEFINED NVIDIA_SDK_PATH)
    set(NVIDIA_SDK_PATH $ENV{NVIDIA_SDK_PATH})
endif()

if(NOT DEFINED NVIDIA_SDK_PATH)
    set(NVIDIA_SDK_PATH $ENV{HOME}/middleware/DATA/SDK_NVIDIA)
endif()

set(NVIDIA_SYSROOT_PATH ${NVIDIA_SDK_PATH}/drive_rootfs)
set(TARGET_COMPILER_PREFIX_PATH ${NVIDIA_SDK_PATH}/toolchains/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu)

set(CMAKE_CXX_COMPILER ${TARGET_COMPILER_PREFIX_PATH}-g++)
set(CMAKE_C_COMPILER ${TARGET_COMPILER_PREFIX_PATH}-gcc)
set(CMAKE_CROSSCOMPILING TRUE)

# root filesystem containing shared libs
set(CMAKE_SYSROOT "${NVIDIA_SYSROOT_PATH}")
set(LINUX_ROOTFS ${NVIDIA_SYSROOT_PATH})
set(CMAKE_FIND_ROOT_PATH ${LINUX_ROOTFS})

if (USE_TENSORRT)
    set(EX_RPATH_LINK "${LINUX_ROOTFS}/opt/nvidia/libs/libtorch_cu102_cudnn75_Full/lib")
    set(EX_LINK_DIRS " -L${LINUX_ROOTFS}/opt/nvidia/libs/libtorch_cu102_cudnn75_Full/lib")
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${LINUX_ROOTFS}/opt/nvidia/libs/libtorch_cu102_cudnn75_Full/lib)
    set(ENV{CUDA_TOOLKIT_ROOT} ${LINUX_ROOTFS}/usr/local/cuda-10.2)
    set(CUDA_NVCC_EXECUTABLE /usr/local/cuda-10.2/bin/nvcc)
    set(CUDNN_INCLUDE_PATH ${LINUX_ROOTFS}/usr/include/aarch64-linux-gnu)
    set(CUDA_HEADERS ${LINUX_ROOTFS}/usr/local/cuda-10.2/include ${LINUX_ROOTFS}/usr/include ${LINUX_ROOTFS}/usr/local/cuda-10.2/targets/aarch64-linux/include)
    set(GLIBCXX_USE_CXX11_ABI 1)
endif()

# linker flags
set (MRPATH_LINK "${LINUX_ROOTFS}/usr/lib:${LINUX_ROOTFS}/lib:${LINUX_ROOTFS}/usr/lib/aarch64-linux-gnu:${LINUX_ROOTFS}/lib/aarch64-linux-gnu:${LINUX_ROOTFS}/usr/lib/aarch64-linux-gnu/tegra")
set (MLINK_DIRS "-L${LINUX_ROOTFS}/usr/lib -L${LINUX_ROOTFS}/lib -L${LINUX_ROOTFS}/usr/lib/aarch64-linux-gnu -L${LINUX_ROOTFS}/lib/aarch64-linux-gnu -L${LINUX_ROOTFS}/usr/lib/aarch64-linux-gnu/tegra")
set (CMAKE_EXE_LINKER_FLAGS "-Wl,-rpath-link,${MRPATH_LINK} ${MLINK_DIRS}" CACHE STRING "EXE LD Flags" FORCE)
set (CMAKE_SHARED_LINKER_FLAGS "-Wl,-rpath-link,${MRPATH_LINK} ${MLINK_DIRS}" CACHE STRING "SHARED LD Flags" FORCE)
set (CMAKE_MODULE_LINKER_FLAGS "-Wl,-rpath-link,${MRPATH_LINK} ${MLINK_DIRS}" CACHE STRING "MODULE LD Flags" FORCE)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)


