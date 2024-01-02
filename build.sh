#!/bin/bash

declare -a __OPTS__=() __VARS__=()

function opts() {
  function opt_name() {
    local opt=$1
    local type name
    type=$(opt_type "$opt")
    name=$(echo "${opt/--no-/}" | tr -d '\-=[]')

    if [[ $type == array && ${name: -1} == s ]]; then
      name=${name%?}
    fi
    echo "$name"
  }

  function var_name() {
    local opt=$1
    echo "${opt/--no-/}" | tr -d '\-=[]'
  }

  function short_name() {
    local opt=$1
    local name=${opt/[]//}
    if [[ $name =~ (\[(.)\]) ]]; then
      echo "${BASH_REMATCH[2]}"
    fi
  }

  function opt_type() {
    local opt=$1
    local type=flag
    [[ ! $opt =~ =$   ]] || type=var
    [[ ! $opt =~ \[\] ]] || type=array
    echo $type
  }

  function negated() {
    local opt=$1
    [[ $opt =~ ^--no- ]] && echo true || echo false
  }

  local opts=("$@")

  for opt in "${opts[@]}"; do
    __OPTS__[${#__OPTS__[@]}]="
      opt=$(opt_name "$opt")
      name=$(var_name "$opt")
      type=$(opt_type "$opt")
      short=$(short_name "$opt")
      negated=$(negated "$opt")
    "
  done
}
export -f opts

function opts_eval() {
  function puts() {
    echo "$@" >&2
  }

  function opts_declare() {
    for opt in "${__OPTS__[@]}"; do
      local type= name= short= negated=
      eval "$opt"
      [[ $type != var ]]   || store_var "$name="
      [[ $type != array ]] || store_var "$name=()"
      [[ $type != flag ]]  || store_var "$name=$([[ $negated == true ]] && echo true || echo false)"
    done
  }

  function store_var() {
    __VARS__[${#__VARS__[@]}]="$1"
  }

  function opt_value() {
    local arg=$1 opt=$2 name=$3 short=$4
    [[ $arg =~ --$opt=(.*)$ || $arg =~ -$short=(.*)$ ]] || return 1
    echo "${BASH_REMATCH[1]}"
  }

  function set_var() {
    local name=$3 value=
    value=$(opt_value "$@") && store_var "$name=\"$value\""
  }

  function set_array() {
    local name=$3 value=
    value=$(opt_value "$@") && store_var "$name[\${#""$name""[@]}]=\"$value\""
  }

  function set_flag() {
    local arg=$1 opt=$2 name=$3 short=$4 value=

    if [[ $arg == -$short ]]; then
      value=true
    elif [[ $arg =~ --(no-)?$opt$ ]]; then
      value=$([[ -n ${BASH_REMATCH[1]} ]] && echo false || echo true)
    fi

    [[ -n $value ]] && store_var "$name=$value"
  }

  function opts_parse() {
    local arg=$1

    for opt in "${__OPTS__[@]}"; do
      local type= name= short= negated= value=
      eval "$opt"
      if set_$type "$arg" "$opt" "$name" "$short"; then
        return 0
      fi
    done

    return 1
  }

  function opts_join_assignment() {
    local arg=$1 type= name= short= negated= value=

    for opt in "${__OPTS__[@]}"; do
      eval "$opt"
      if [[ $type != flag && ($arg == --$opt || $arg == -$short) ]]; then #  && (( $# > 0 ))
        return 0
      fi
    done

    return 1
  }

  opts_declare

  local arg var
  args=(0)

  while (( $# > 0 )); do
    if opts_join_assignment "$1"; then
      arg="$1=$2"
      shift || true
    else
      arg=$1
    fi
    shift || true

    if [[ $arg == '--' ]]; then
      args=( ${args[@]} $@ )
      break
    elif opts_parse "$arg"; then
      true
    elif [[ $arg =~ ^- ]]; then
      echo "Unknown option: ${arg}" >&2 && exit 1
    else
      args[${#args[@]}]="$arg"
    fi
  done

  for var in "${__VARS__[@]}"; do
    eval "$var"
  done

  args=(${args[@]:1})
}
export -f opts_eval

function opt() {
  function opt_type() {
    local opt line
    line=$(echo "${__OPTS__[@]}" | grep -A 1 "name=$1" | tail -n 1)
    echo "${line#*=}"
  }

  function opt_var() {
    echo "--$1=\"$(eval "echo \$$1")\""
  }

  function opt_array() {
    local _length
    _length=$(eval "echo \${#$1[@]}")
    (( _length == 0 )) || echo $(
      for ((_i=0; _i < _length ; _i++)); do
        echo "--${1%s}=\"$(eval "echo \${$1[$_i]}")\""
      done
    ) | tr "\n" ' ' | sed 's/ *$//'
  }

  function opt_flag() {
    [[ $(eval "echo \$$1") == false ]] || echo "--$1"
  }

  opt_$(opt_type "$1") "$1"
}
export -f opt

opts --[d]ebug --[a]rch= --[p]ath= --[i]nstall --[o]ptmemonly --[h]elp
opts_eval "$@"
usage(){
  echo "\
  `basename $0` [OPTION...]
  -d, --debug; Enable debug build (default: false)
  -a, --arch; Set target arch: x64Linux, armv8Linux, armv8Qnx, armv8Qcs610, armv8Android (default: x64Linux)
  -p, --path; Cross compile toolchain path (default: ~/middleware/DATA/SDK_NVIDIA (x64Linux, armv8Linux), ~/QCS610_standalone_sdk (armv8Qcs610), ~/middleware/DATA/QNX (armv8Qnx), ~/Android/Sdk/ (armv8Android))
  -n, --ndk_path; Path to the Android NDK (default: ~/Android/Sdk/ndk/23.1.7779620)
  -o, --optmemonly; Only build the optimized memory (default: false)
  -i, --install; Run install step after compiling (default: false)
  -h, --help; Show help content
  " | column -t -s ";"
  exit 1
}

if [[ $help == true ]]; then
  usage;
fi

if [[  "$path" == "" ]]; then
  if [[ "$arch" == "armv8Qcs610" ]]; then
    path=$HOME"/QCS610_standalone_sdk"
  elif [[ "$arch" == "armv8Qnx" ]]; then
    path=$HOME"/middleware/DATA/QNX"
  elif [[ "$arch" == "armv8Android" ]]; then
    path=$HOME"/Android/Sdk"
  else
    path=$HOME"/middleware/DATA/SDK_NVIDIA"
  fi
fi

if [[  "$ndk_path" == "" ]]; then
  if [[ "$arch" == "armv8Android" ]]; then
    ndk_path=${path}"/ndk/23.1.7779620"
  fi
fi

if [[ "$arch" == "" ]]; then
  arch="x64Linux"
fi

echo "-----------------------Configuration--------------------"
echo "Debug: ${debug}"
echo "Arch: $arch"
echo "SDK path: $path"
echo "Build the optimized memory only version: ${optmemonly}"
echo "Install: ${install}"
echo "--------------------------Start-------------------------"

SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=${SCRIPT_DIR}
BUILD_DIR=${SCRIPT_DIR}/build

if [[ $debug == false ]]; then
  BUILD_TYPE="-DCMAKE_BUILD_TYPE=Release"
  INSTALL_PREFIX="-DCMAKE_INSTALL_PREFIX=${SRC_DIR}/install/release"
else
  BUILD_TYPE="-DCMAKE_BUILD_TYPE=Debug"
  INSTALL_PREFIX="-DCMAKE_INSTALL_PREFIX=${SRC_DIR}/install/debug"
fi

if [[ "$path" != "" ]]; then
  if [[ "$arch" == "armv8Qcs610" ]]; then
    export QCS610_SDK_PATH=$path
    TOOLCHAIN_PATH="-DQCS610_SDK_PATH="$path
  else
    if [[ "$arch" == "armv8Qnx" ]]; then
      export QNX_SDK_PATH=$path
      TOOLCHAIN_PATH="-DQNX_SDK_PATH="$path
    else
      if [[ "$arch" == "armv8Android" ]]; then
        export ANDROID_SDK_PATH=$path
        TOOLCHAIN_PATH="-DANDROID_SDK_PATH="$path
      else
        export NVIDIA_SDK_PATH=$path
        TOOLCHAIN_PATH="-DNVIDIA_SDK_PATH="$path
      fi
    fi
  fi
fi

if [[ "$arch" == "armv8Linux" ]]; then
  ARCH="-DARM64_QUALCOMM=OFF -DARM64_LINUX=ON -DX64_LINUX=OFF"
  CMAKE_TOOLCHAIN_FILE=${SRC_DIR}/cmake/toolchain/armv8Linux.cmake
  PLATFORM_BUILD="-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
else
  if [[ "$arch" == "armv8Qcs610" ]]; then
    unset LD_LIBRARY_PATH
    source $QCS610_SDK_PATH/environment-setup-aarch64-oe-linux
    ARCH="-DARM64_QUALCOMM=ON -DARM64_LINUX=OFF -DX64_LINUX=OFF"
    CMAKE_TOOLCHAIN_FILE=${SRC_DIR}/cmake/toolchain/armv8Qcs610.cmake
    PLATFORM_BUILD="-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
  else
    if [[ "$arch" == "armv8Qnx" ]]; then
      echo "QNX_SDK_PATH = ${QNX_SDK_PATH}"
      QNX_START_ENV=${QNX_SDK_PATH}/qnx700/qnxsdp-env.sh
      if test -f "$QNX_START_ENV"; then
          source ${QNX_START_ENV}
      else
          echo "Using default QNX SDP: /opt/qnx700/"
          source /opt/qnx700/qnxsdp-env.sh
      fi
      ARCH="-DARM64_QUALCOMM=OFF -DARM64_LINUX=OFF -DX64_LINUX=OFF -DARM64_QNX=ON"
      CMAKE_TOOLCHAIN_FILE=${SRC_DIR}/cmake/toolchain/armv8Qnx.cmake
      PLATFORM_BUILD="-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
    else
      if [[ "$arch" == "armv8Android" ]]; then
        ADNROID_API_LV="28"
        echo "ANDROID_SDK_PATH = ${ANDROID_SDK_PATH}"
        ARCH="-DARM64_QUALCOMM=OFF -DARM64_LINUX=OFF -DX64_LINUX=OFF -DARM64_QNX=OFF -DARM64_ANDROID=ON"
        CMAKE_TOOLCHAIN_FILE=${ndk_path}/build/cmake/android.toolchain.cmake
        export ANDROID_HOME=${path}
        export ANDROID_NDK_HOME=${ndk_path}
        ANDROID_ABI="-DANDROID_ABI=arm64-v8a"
        ANDROID_PLATFORM="-DANDROID_PLATFORM=${ADNROID_API_LV}"
        ANDROID_TOOLCHAIN="-DANDROID_TOOLCHAIN=clang++"
        ANDROID_NATIVE_API_LEVEL="-DANDROID_NATIVE_API_LEVEL=${ADNROID_API_LV}"
        PLATFORM_BUILD="-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} ${ANDROID_ABI} ${ANDROID_TOOLCHAIN} ${ANDROID_NATIVE_API_LEVEL} ${ANDROID_PLATFORM}"
      else
        if [[ "$arch" == "x64Linux" ]]; then
          ARCH="-DARM64_QUALCOMM=OFF -DARM64_LINUX=OFF -DX64_LINUX=ON -DARM64_QNX=OFF -DARM64_ANDROID=OFF"
        fi
      fi
    fi
  fi
fi

if [[ "$optmemonly" == true ]]; then
  ENABLE_OPTMEMONLY="-DENABLE_OPTMEMONLY=ON -DREQUIRE_SIMD=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DENABLE_SHARED=OFF -DENABLE_STATIC=OFF"
else
  ENABLE_OPTMEMONLY=""
fi

if [[ "$arch" == "x64Linux" ]]; then
  CMAKE_C_COMPILER="-DCMAKE_C_COMPILER=/usr/bin/gcc-11"
  CMAKE_CXX_COMPILER="-DCMAKE_CXX_COMPILER=/usr/bin/g++-11"
fi

BUILD_DIR=${BUILD_DIR}/"$arch"
echo C_COMPILER=${C_COMPILER}
echo CXX_COMPILER=${CXX_COMPILER}
echo "ARCH: ${arch}"
echo "PLATFORM_BUILD: ${PLATFORM_BUILD}"
echo "ENABLE_OPTMEMONLY: ${ENABLE_OPTMEMONLY}"

OPTS="-DCMAKE_CXX_COMPILER_LAUNCHER=ccache -B ${BUILD_DIR} ${CMAKE_C_COMPILER} ${CMAKE_CXX_COMPILER}  ${BUILD_TYPE} ${ARCH} ${PLATFORM_BUILD} ${ENABLE_OPTMEMONLY} ${INSTALL_PREFIX}"
echo cmake ${OPTS} .
cmake ${OPTS} .
cmake --build ${BUILD_DIR} --parallel $(($(nproc)-1)) --verbose
if [[ $install == true ]]; then
  cmake --install ${BUILD_DIR} --verbose
fi
