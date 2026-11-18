#!/usr/bin/env bash
# Builds libconversion.so for every supported ABI into
# ../src/SharedLib/libconversion/<abi>/ (these prebuilt libraries are what the
# plugin's CMakeLists.txt links against).
#
# Usage:  ./buildAndroid.sh
# Env:    ANDROID_SDK_ROOT / ANDROID_HOME  (default: $HOME/Android/Sdk)
#         ANDROID_NDK                      (default: newest complete NDK in the SDK)
#         ANDROID_CMAKE_DIR                (default: newest cmake in the SDK)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
if [ -z "${ANDROID_NDK:-}" ]; then
  # newest NDK that is actually installed (has a toolchain file)
  for d in $(ls -d "$SDK"/ndk/*/ | sort -V -r); do
    if [ -f "${d}build/cmake/android.toolchain.cmake" ]; then ANDROID_NDK="$d"; break; fi
  done
fi
NDK="${ANDROID_NDK%/}"
CMAKE_DIR="${ANDROID_CMAKE_DIR:-$(ls -d "$SDK"/cmake/*/ | sort -V | tail -n1)}"
CMAKE_DIR="${CMAKE_DIR%/}"
OUT_ROOT="$SCRIPT_DIR/../src/SharedLib/libconversion"

# x86 (32-bit) is not built: it is not supported by modern NDKs/devices.
for ABI in arm64-v8a armeabi-v7a x86_64; do
  BUILD_DIR="$SCRIPT_DIR/build/$ABI"
  "$CMAKE_DIR/bin/cmake" \
    -DCMAKE_SYSTEM_NAME=Android \
    -DCMAKE_SYSTEM_VERSION=24 \
    -DANDROID_PLATFORM=android-24 \
    -DANDROID_ABI="$ABI" \
    -DCMAKE_ANDROID_ARCH_ABI="$ABI" \
    -DANDROID_NDK="$NDK" \
    -DCMAKE_ANDROID_NDK="$NDK" \
    -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
    -DCMAKE_MAKE_PROGRAM="$CMAKE_DIR/bin/ninja" \
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="$OUT_ROOT/$ABI" \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY="$OUT_ROOT/$ABI" \
    -DCMAKE_BUILD_TYPE=Release \
    -S "$SCRIPT_DIR" -B "$BUILD_DIR" -GNinja
  "$CMAKE_DIR/bin/cmake" --build "$BUILD_DIR"
done
