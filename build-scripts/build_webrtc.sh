#!/bin/bash

#########################################

function usage() {
  echo "USAGE: build_webrtc.sh <os> <arch> [nofetch]"
  echo "       <os>   - win, linux, ios, android"
  echo "       <arch> - x64, x86, arm, arm64"
  echo "       nofetch - build downloaded code without internet (otherwise update code from internet)"
}

function do_build() {
  BUILD_OS=$1
  BUILD_ARCH=$2
  ARG=$3

  cd $BASEDIR/..

  NOFETCH_X=
  NOFETCH_I=

  if [ "$ARG" == "nofetch" ]; then
    NOFETCH_X=-x
    NOFETCH_I=-w
  fi

  if [ "$ARG" != "nofetch" ] && [ "$ARG" != "" ]; then
    echo "ERROR: Unrecognized argument '$ARG'. Argument may be 'nofetch' for prevent update sources from internet"
    exit 255
  fi

  CUSTOM_ARGS="use_custom_libcxx_for_host=false rtc_enable_protobuf=false use_custom_libcxx=false"
  if [ "$BUILD_OS" == "ios" ]; then
    CUSTOM_ARGS="$CUSTOM_ARGS ios_enable_code_signing=false"
  fi

  ./build.sh -a $ARTOOL -q -o $WEBRTC_DIR -b $WEBRTC_BRANCH -t $BUILD_OS -c $BUILD_ARCH -e 1 \
             -z "$CUSTOM_ARGS" \
             "$NOFETCH_X" "$NOFETCH_I"
  rc=$?

  if [ "$rc" != "0" ]; then
    echo "ERROR: Build $BUILD_OS $BUILD_ARCH process returned error $rc"
  else
    echo "BUILD $BUILD_OS $BUILD_ARCH Success!"
  fi

  return $rc
}

#######################################

BUILD_OS=$1
BUILD_ARCH=$2
ARG=$3

if [ "$BUILD_OS" == "" ] || [ "$BUILD_ARCH" == "" ]; then
  usage
  exit 1
fi

BASEDIR=$(dirname "$0")
BASEDIR=`realpath $BASEDIR`
ORIGINDIR=$PWD

cd $BASEDIR

source ./build_vars.sh

# Fix 'ar' tool for macos/ios: use llvm-ar instead default ar tool
if [ -d /usr/local/opt/llvm/bin ]; then
  export ARTOOL=llvm-ar
  export PATH=/usr/local/opt/llvm/bin:$PATH
  export LDFLAGS="-L/usr/local/opt/llvm/lib"
  export CPPFLAGS="-I/usr/local/opt/llvm/include"
  echo "INFO: LLVM found, use llvm-ar"
else
  export ARTOOL=ar
fi

do_build $BUILD_OS $BUILD_ARCH $ARG
rc=$?

cd $ORIGINDIR
exit $rc
