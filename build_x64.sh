#!/bin/bash

# BUILD_TYPE="-DCMAKE_BUILD_TYPE=Debug"
BUILD_TYPE="-DCMAKE_BUILD_TYPE=Release"
cmake -B build ${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=./install -DWITH_TURBOJPEG=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .
cmake --build build --parallel $(($(nproc)-1)) --verbose
cmake --install build