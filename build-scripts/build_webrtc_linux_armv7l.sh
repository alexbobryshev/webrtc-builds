#!/bin/sh

BASEDIR=$(dirname "$0")
BASEDIR=`realpath $BASEDIR`
ORIGINDIR=$PWD
ARG=$1

cd $BASEDIR

source ./build_common.sh
cd ..

NOFETCH=

if [ "$ARG" == "nofetch" ]; then
  NOFETCH=-x
fi

if [ "$ARG" != "nofetch" ] && [ "$ARG" != "" ]; then
  echo "ERROR: Unrecognized argument '$ARG'. Argument may be 'nofetch' for prevent update sources from internet"
  exit 255
fi

./build.sh -a $ARTOOL -q -o $WEBRTC_DIR -b $WEBRTC_BRANCH -t linux -c arm -e 1 -z "use_custom_libcxx_for_host=false rtc_enable_protobuf=false use_custom_libcxx=false" $NOFETCH

rc=$?

if [ "$rc" != "0" ]; then
  echo "ERROR: Build process returned error $rc"
else
  echo "BUILD Success!"
fi

cd $ORIGINDIR
exit $rc
