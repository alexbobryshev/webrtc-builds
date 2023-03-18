#!/bin/bash

BASEDIR=$(dirname "$0")
BASEDIR=`realpath $BASEDIR`
ORIGINDIR=$PWD
ARG=$1

cd $BASEDIR

source $BASEDIR/build_vars.sh

bash $BASEDIR/cleanup_previous_builds.sh

OSNAME=Windows
OSPARAM=win

echo "***** BUILDING $OSNAME x64 *****"
bash $BASEDIR/build_webrtc.sh $OSPARAM x64 $ARG
rc=$?

if [ "$rc" != "0" ]; then
  echo "ERROR: Build $OSNAME x64 error!!!"
  read -p a
  exit 255
fi

echo "***** BUILDING $OSNAME x86 *****"
bash $BASEDIR/build_webrtc.sh $OSPARAM x86 $ARG
rc=$?

if [ "$rc" != "0" ]; then
  echo "ERROR: Build $OSNAME x86 error!!!"
  read -p a
  exit 255
fi

echo "***** BUILDING $OSNAME arm64 *****"
bash $BASEDIR/build_webrtc.sh $OSPARAM arm64 $ARG
rc=$?

if [ "$rc" != "0" ]; then
  echo "ERROR: Build $OSNAME arm64 error!!!"
  read -p a
  exit 255
fi

echo "ALL BUILDS FINISHED SUCCESSFULLY FOR $OSNAME!"
exit 0
