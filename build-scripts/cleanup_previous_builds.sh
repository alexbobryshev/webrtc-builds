#!/bin/bash

BASEDIR=$(dirname "$0")
BASEDIR=`realpath $BASEDIR`
ORIGINDIR=$PWD

cd $BASEDIR

source ./build_vars.sh
cd ..

echo "Cleaning previous builds..."

if [ -d ./$WEBRTC_DIR/src/out ]; then
  rm -r ./$WEBRTC_DIR/src/out
fi

rm -r ./$WEBRTC_DIR/webrtc-* 1>/dev/null 2>/dev/null

echo "Cleanup finished!"
cd $ORIGINDIR
exit 0