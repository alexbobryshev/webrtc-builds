#!/bin/sh

WEBRTC_BRANCH=branch-heads/4472
WEBRTC_DIR=webrtc-91

BASEDIR=$(dirname "$0")


if [ -d /usr/local/opt/llvm/bin ]; then
  ARTOOL=llvm-ar
  export PATH=/usr/local/opt/llvm/bin:$PATH
  export LDFLAGS="-L/usr/local/opt/llvm/lib"
  export CPPFLAGS="-I/usr/local/opt/llvm/include"
  echo "INFO: LLVM found, use llvm-ar"
else
  ARTOOL=ar
  echo "WARNING: LLVM not found, use default ar"
fi

CURDIR=$PWD
cd $BASEDIR/..
./build.sh -a $ARTOOL -q -o $WEBRTC_DIR -b $WEBRTC_BRANCH -t mac -c x64 -e 1 -z "use_custom_libcxx_for_host=false rtc_enable_protobuf=false use_custom_libcxx=false"
#-x
rc=$?

cd $CURDIR

exit $rc
