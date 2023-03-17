#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/util.sh

usage ()
{
cat << EOF

Usage:
   $0 [OPTIONS]

WebRTC automated build script.

OPTIONS:
   -o OUTDIR      Output directory. Default is 'out'
   -b BRANCH      Latest revision on git branch. Overrides -r. Common branch names are 'branch-heads/nn', where 'nn' is the release number.
   -r REVISION    Git SHA revision. Default is latest revision.
   -t TARGET OS   The target os for cross-compilation. Default is the host OS such as 'linux', 'mac', 'win'. Other values can be 'android', 'ios'.
   -c TARGET CPU  The target cpu for cross-compilation. Default is 'x64'. Other values can be 'x86', 'arm64', 'arm'.
   -l BLACKLIST   List *.o objects to exclude from the static library.
   -e ENABLE_RTTI Compile WebRTC with RTII enabled. Default is '1'.
   -n CONFIGS     Build configurations, space-separated. Default is 'Debug Release'. Other values can be 'Debug', 'Release'.
   -z CUSTOMARGS  Custom build arts in double quotes.
   -a ARTOOL      Set custom ar tool. Used ar by default.
   -q             Use CLANG. By default clang is NOT used.
   -x             Express build mode. Skip repo sync and dependency checks, just build, compile and package.
   -w             Skip all internet activities
   -D             [Linux] Generate a debian package
   -d             Debug mode. Print all executed commands.
   -h             Show this message
EOF
}

#ARTOOL=
#CUSTOM_BUILD_ARGS_VALUE=
#NOINTERNET=

while getopts :a:o:b:r:t:c:l:e:n:z:xDdqw OPTION; do
  case $OPTION in
  a) ARTOOL=$OPTARG ;;
  o) OUTDIR=$OPTARG ;;
  b) BRANCH=$OPTARG ;;
  r) REVISION=$OPTARG ;;
  t) TARGET_OS=$OPTARG ;;
  c) TARGET_CPU=$OPTARG ;;
  l) BLACKLIST=$OPTARG ;;
  e) ENABLE_RTTI=$OPTARG ;;
  n) CONFIGS=$OPTARG ;;
  z) CUSTOM_BUILD_ARGS_VALUE=$OPTARG ;;
  x) BUILD_ONLY=1 ;;
  D) PACKAGE_AS_DEBIAN=1 ;;
  d) DEBUG=1 ;;
  q) ENABLE_CLANG=1 ;;
  w) NOINTERNET=1 ;;
  ?) usage; exit 1 ;;
  esac
done

NOINTERNET=${NOINTERNET:-0}
OUTDIR=${OUTDIR:-out}
BRANCH=${BRANCH:-}
BLACKLIST=${BLACKLIST:-}
ENABLE_RTTI=${ENABLE_RTTI:-1}
ENABLE_ITERATOR_DEBUGGING=0
ENABLE_CLANG=${ENABLE_CLANG:-0}
ENABLE_STATIC_LIBS=1
BUILD_ONLY=${BUILD_ONLY:-0}
DEBUG=${DEBUG:-0}
CONFIGS=${CONFIGS:-Debug Release}
COMBINE_LIBRARIES=${COMBINE_LIBRARIES:-1}
PACKAGE_AS_DEBIAN=${PACKAGE_AS_DEBIAN:-0}
PACKAGE_FILENAME_PATTERN=${PACKAGE_FILENAME_PATTERN:-"webrtc-%sr%-%to%-%tc%"}
PACKAGE_NAME_PATTERN=${PACKAGE_NAME_PATTERN:-"webrtc"}
PACKAGE_VERSION_PATTERN=${PACKAGE_VERSION_PATTERN:-"%rn%"}
REPO_URL="https://chromium.googlesource.com/external/webrtc"
DEPOT_TOOLS_URL="https://chromium.googlesource.com/chromium/tools/depot_tools.git"
DEPOT_TOOLS_DIR=$DIR/depot_tools
TOOLS_DIR=$DIR/tools
PATH=$DEPOT_TOOLS_DIR:$DEPOT_TOOLS_DIR/python276_bin:$PATH

[ "$CUSTOM_BUILD_ARGS_VALUE" != "" ] && CUSTOM_BUILD_ARGS=1
[ "$DEBUG" = 1 ] && set -x
[ "$ARTOOL" == "" ] && ARTOOL=ar

echo "No internet mode: $NOINTERNET"

#if [ "$NOINTERNET" == "1" ]; then
#  if [ -z $REVISION ]; then
#    echo "ERROR: parameter -i (no internet build) requires revision ()"
#  fi
#fi

mkdir -p $OUTDIR
OUTDIR=$(cd $OUTDIR && pwd -P)

detect-platform
TARGET_OS=${TARGET_OS:-$PLATFORM}
TARGET_CPU=${TARGET_CPU:-x64}

echo "Host OS: $PLATFORM"
echo "Target OS: $TARGET_OS"
echo "Target CPU: $TARGET_CPU"

echo Checking build environment dependencies
check::build::env $PLATFORM "$TARGET_CPU"

if [ "$NOINTERNET" != "1" ]; then
  echo Checking depot-tools
  check::depot-tools $PLATFORM $DEPOT_TOOLS_URL $DEPOT_TOOLS_DIR
fi

if [ "$NOINTERNET" == "1" ]; then
  CURDIR=$PWD
  if [ ! -d "$OUTDIR/src" ]; then
    echo "ERROR: -i (no internet) mode selected, but directory with sources does not exist"
    exit 1;
  fi

  cd "$OUTDIR/src"
  REVISION=`git rev-parse HEAD`
  rc=$?
  cd $CURDIR

  if [ "$rc" != "0" ]; then
    echo "ERROR: -i (no internet) mode selected, but source directory does not contain git revision"
    exit 1;
  fi
else
  if [ ! -z $BRANCH ]; then
    REVISION=$(git ls-remote $REPO_URL --heads $BRANCH | head --lines 1 | cut -f 1) || \
      { echo "Cound not get branch revision" && exit 1; }
     echo "Building branch: $BRANCH"
  else
    REVISION=${REVISION:-$(latest-rev $REPO_URL)} || \
      { echo "Could not get latest revision" && exit 1; }
  fi
fi

echo "Building revision: $REVISION"

# REVISION_NUMBER=$(revision-number $REPO_URL $REVISION) || \
#  { echo "Could not get revision number" && exit 1; }
# echo "Associated revision number: $REVISION_NUMBER"

if [ $BUILD_ONLY = 0 ]; then
  echo "Checking out WebRTC revision (this will take a while): $REVISION"
  checkout "$TARGET_OS" $OUTDIR $REVISION

  echo Checking WebRTC dependencies
  check::webrtc::deps $PLATFORM $OUTDIR "$TARGET_OS"

  echo Patching WebRTC source
  patch $PLATFORM $OUTDIR $ENABLE_RTTI
fi

echo Compiling WebRTC
compile $PLATFORM $OUTDIR "$TARGET_OS" "$TARGET_CPU" "$CONFIGS" "$BLACKLIST"

# Default PACKAGE_FILENAME is <projectname>-<rev-number>-<short-rev-sha>-<target-os>-<target-cpu>
PACKAGE_FILENAME=$(interpret-pattern "$PACKAGE_FILENAME_PATTERN" "$PLATFORM" "$OUTDIR" "$TARGET_OS" "$TARGET_CPU" "$BRANCH" "$REVISION")
PACKAGE_NAME=$(interpret-pattern "$PACKAGE_NAME_PATTERN" "$PLATFORM" "$OUTDIR" "$TARGET_OS" "$TARGET_CPU" "$BRANCH" "$REVISION")
PACKAGE_VERSION=$(interpret-pattern "$PACKAGE_VERSION_PATTERN" "$PLATFORM" "$OUTDIR" "$TARGET_OS" "$TARGET_CPU" "$BRANCH" "$REVISION")

echo "Packaging WebRTC: $PACKAGE_FILENAME"
package::prepare $PLATFORM $OUTDIR $PACKAGE_FILENAME $DIR/resource "$CONFIGS" 

if [ "$PACKAGE_AS_DEBIAN" = 1 ]; then
  package::debian $OUTDIR $PACKAGE_FILENAME $PACKAGE_NAME $PACKAGE_VERSION "$(debian-arch $TARGET_CPU)"
else
  package::archive $PLATFORM $OUTDIR $PACKAGE_FILENAME
  package::manifest $PLATFORM $OUTDIR $PACKAGE_FILENAME
fi

echo "$PACKAGE_FILENAME">$OUTDIR/lastbuild.txt

echo Build successful
