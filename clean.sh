#!/bin/bash
set -eo pipefail
set -x

# This cleans up all the builds in the output directory

# win req: rmdir, rm
# lin req: rm
# osx req: rm

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/environment.sh

if [ $UNAME = 'Windows_NT' ]; then
  pushd $OUT_DIR
  # windows rmdir
  cmd //c "for /D %f in (*) do rmdir /s /q %f" || true
  # and again, for any stragglers
  rm -rf *
  popd
else
  rm -rf $OUT_DIR/*
fi
