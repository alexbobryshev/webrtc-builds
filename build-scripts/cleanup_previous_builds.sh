#!/bin/sh

BASEDIR=$(dirname "$0")
BASEDIR=`realpath $BASEDIR`
ORIGINDIR=$PWD

cd $BASEDIR

source ./build_common.sh
cd ..

if [ -d ./$WEBRTC_DIR/src/out ]; then
  rm -r ./$WEBRTC_DIR/src/out
fi

rm -r ./$WEBRTC_DIR/webrtc-*

cd $ORIGINDIR
exit 0