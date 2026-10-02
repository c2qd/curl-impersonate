#!/bin/sh
set -eu

ACTION="${1:-build}"

case "$ACTION" in
  all|configure|build|target|checkbuild|install|install-strip|clean|distclean) ;;
  *)
    echo "Usage: $0 {all|configure|build|target|checkbuild|install|install-strip|clean|distclean}" >&2
    exit 1 ;;
esac

MINGW_ROOT="${MINGW_ROOT:-}"
if [ -n "$MINGW_ROOT" ]; then
  export PATH="$MINGW_ROOT/bin:$PATH"
fi

case "$TOOLCHAIN" in
  clang)
    _CC="clang"
    _CXX="clang++"
    case "$ARCH" in
      x86_64|i686|aarch64|armv7) ;;
      *)
        echo "Unsupported architecture: $ARCH" >&2
        exit 1 ;;
    esac
    ;;
  gcc)
    _CC="gcc"
    _CXX="g++"
    case "$ARCH" in
      x86_64|i686|aarch64) ;;
      *)
        echo "Unsupported architecture: $ARCH" >&2
        exit 1 ;;
    esac ;;
  *)
    echo "Unsupported toolchain: $TOOLCHAIN" >&2
    exit 1 ;;
esac

CC="${MINGW_CC:-${ARCH}-w64-mingw32-${_CC}}"
CXX="${MINGW_CXX:-${ARCH}-w64-mingw32-${_CXX}}"

MAKE=${MAKE:-make}

USE_WINE="${USE_WINE:-0}"
CURL_RUNNER="${CURL_RUNNER:-}"
if [ "$USE_WINE" = "1" ] && [ -z "${CURL_RUNNER}" ]; then
  CURL_RUNNER="wine"
fi

BUILD_DIR=${BUILD_DIR:-build}

CMAKE_CONFIGURE_ARGS="${CMAKE_CONFIGURE_ARGS:-}"
CMAKE_CONFIGURE_ARGS="$CMAKE_CONFIGURE_ARGS -G Ninja -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR=$ARCH"
CMAKE_CONFIGURE_ARGS="$CMAKE_CONFIGURE_ARGS -DUSE_LIBIDN2=OFF"
CMAKE_CONFIGURE_ARGS="$CMAKE_CONFIGURE_ARGS -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX"
CMAKE_BUILD_ARGS="${CMAKE_BUILD_ARGS:-}"
CMAKE_INSTALL_ARGS="${CMAKE_INSTALL_ARGS:-}"

$MAKE $ACTION BUILD_DIR="$BUILD_DIR" CMAKE="${CMAKE:-cmake}" TARGET="${TARGET:-curl-impersonate}" \
    CMAKE_CONFIGURE_ARGS="$CMAKE_CONFIGURE_ARGS" \
    CMAKE_BUILD_ARGS="${CMAKE_BUILD_ARGS:-}" CMAKE_INSTALL_ARGS="${CMAKE_INSTALL_ARGS:-}" JOBS="${JOBS:-}" \
    CURL_RUNNER="${CURL_RUNNER:-}" CURL_BIN="$BUILD_DIR/deps/build/curl/src/curl-impersonate.exe"
