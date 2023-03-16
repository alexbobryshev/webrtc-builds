export WEBRTC_BRANCH=branch-heads/4472
export WEBRTC_DIR=webrtc-91

##############

if [ -d /usr/local/opt/llvm/bin ]; then
  export ARTOOL=llvm-ar
  export PATH=/usr/local/opt/llvm/bin:$PATH
  export LDFLAGS="-L/usr/local/opt/llvm/lib"
  export CPPFLAGS="-I/usr/local/opt/llvm/include"
  echo "INFO: LLVM found, use llvm-ar"
else
  export ARTOOL=ar
  echo "WARNING: LLVM not found, use default ar"
fi
