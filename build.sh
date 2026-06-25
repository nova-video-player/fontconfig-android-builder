#!/bin/bash

source ../../AVP/android-setup-light.sh

LOCAL_PATH=$($READLINK -f .)
mkdir -p ../prebuilt/fontconfig
PREBUILT_DIR=$($READLINK -f ../prebuilt/fontconfig)

if [ -f "${PREBUILT_DIR}/lib/armeabi-v7a/libfontconfig.a" ] && \
   [ -f "${PREBUILT_DIR}/lib/arm64-v8a/libfontconfig.a" ] && \
   [ -f "${PREBUILT_DIR}/lib/x86/libfontconfig.a" ] && \
   [ -f "${PREBUILT_DIR}/lib/x86_64/libfontconfig.a" ]; then
  echo "All fontconfig prebuilt libs already exist, skipping"
  exit 0
fi

if [ ! -d "fontconfig" ]
then
  git clone https://gitlab.freedesktop.org/fontconfig/fontconfig.git
  cd fontconfig
  git checkout 2.18.1
  cd ..
fi

API_LEVEL=21

for ABI in armeabi-v7a arm64-v8a x86 x86_64
do
  case "${ABI}" in
    'arm64-v8a')
      TARGET=aarch64-linux-android
      CPU_FAMILY=aarch64
      ;;
    'armeabi-v7a')
      TARGET=armv7a-linux-androideabi
      CPU_FAMILY=arm
      ;;
    'x86')
      TARGET=i686-linux-android
      CPU_FAMILY=x86
      ;;
    'x86_64')
      TARGET=x86_64-linux-android
      CPU_FAMILY=x86_64
      ;;
  esac

  PREFIX="${PREBUILT_DIR}"

  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  TOOLCHAIN="${NDK_PATH}/toolchains/llvm/prebuilt/${OS}-x86_64"

  export AR="${TOOLCHAIN}/bin/llvm-ar"
  export AS="${TOOLCHAIN}/bin/llvm-as"
  export RANLIB="${TOOLCHAIN}/bin/llvm-ranlib"
  export STRIP="${TOOLCHAIN}/bin/llvm-strip"
  export CC="${TOOLCHAIN}/bin/${TARGET}${API_LEVEL}-clang"
  export CXX="${TOOLCHAIN}/bin/${TARGET}${API_LEVEL}-clang++"

  # Locate prebuilt dependencies
  FREETYPE_PREBUILT=$($READLINK -f ../prebuilt/freetype)
  LIBXML2_PREBUILT=$($READLINK -f ../prebuilt/libxml2)
  ZLIB_PREBUILT=$($READLINK -f ../prebuilt/zlib)
  LIBPNG_PREBUILT=$($READLINK -f ../prebuilt/libpng)

  export PKG_CONFIG_PATH="${FREETYPE_PREBUILT}/lib/${ABI}/pkgconfig:${LIBXML2_PREBUILT}/lib/${ABI}/pkgconfig:${ZLIB_PREBUILT}/lib/${ABI}/pkgconfig:${LIBPNG_PREBUILT}/lib/${ABI}/pkgconfig"
  export PKG_CONFIG_LIBDIR="${FREETYPE_PREBUILT}/lib/${ABI}/pkgconfig:${LIBXML2_PREBUILT}/lib/${ABI}/pkgconfig:${ZLIB_PREBUILT}/lib/${ABI}/pkgconfig:${LIBPNG_PREBUILT}/lib/${ABI}/pkgconfig"

  export CFLAGS="-fPIC -O3 -I${FREETYPE_PREBUILT}/include -I${FREETYPE_PREBUILT}/include/freetype2 -I${LIBXML2_PREBUILT}/include/libxml2 -I${ZLIB_PREBUILT}/include -Wl,-z,max-page-size=16384"
  export CXXFLAGS="-fPIC -O3 -I${FREETYPE_PREBUILT}/include -I${FREETYPE_PREBUILT}/include/freetype2 -I${LIBXML2_PREBUILT}/include/libxml2 -I${ZLIB_PREBUILT}/include -Wl,-z,max-page-size=16384"
  export LDFLAGS="-L${FREETYPE_PREBUILT}/lib/${ABI} -L${LIBXML2_PREBUILT}/lib/${ABI} -L${ZLIB_PREBUILT}/lib/${ABI} -Wl,-z,max-page-size=16384"

  if [ ! -f "${PREBUILT_DIR}/lib/${ABI}/libfontconfig.a" ]
  then
    echo "Building fontconfig for ${ABI}..."
    cd fontconfig
    ./autogen.sh
    ./configure --host=${TARGET} --prefix="${PREFIX}" --libdir="${PREFIX}/lib/${ABI}" --enable-static --disable-shared --disable-docs --disable-libuuid --with-arch=${CPU_FAMILY} --enable-libxml2 ac_cv_va_copy=C99
    make clean
    make -j${CORES}
    make install
    cd ..
  else
    echo "Fontconfig already built for ${ABI}"
  fi
done
