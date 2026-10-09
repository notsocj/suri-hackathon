#!/bin/bash
set -euo pipefail
SURI_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SURI_PLATFORM="${1:-simulator}"
SURI_VERSION=b11527
SURI_SOURCE="$SURI_ROOT/.build/LlamaSource"
if [[ ! -f "$SURI_SOURCE/.suri-version" ]] || [[ "$(cat "$SURI_SOURCE/.suri-version")" != "$SURI_VERSION" ]]; then
  mkdir -p "$SURI_SOURCE"
  curl -L --fail --retry 2 "https://github.com/ggml-org/llama.cpp/archive/refs/tags/$SURI_VERSION.tar.gz" -o "$SURI_ROOT/.build/llama-source.tar.gz"
  tar -xzf "$SURI_ROOT/.build/llama-source.tar.gz" --strip-components=1 -C "$SURI_SOURCE"
  printf '%s' "$SURI_VERSION" > "$SURI_SOURCE/.suri-version"
fi
if [[ "$SURI_PLATFORM" == simulator ]]; then
  SURI_SDK=iphonesimulator
  SURI_TARGET=arm64-apple-ios18.0-simulator
  SURI_BUILD="$SURI_ROOT/.build/LlamaSimulatorCPU"
elif [[ "$SURI_PLATFORM" == device ]]; then
  SURI_SDK=iphoneos
  SURI_TARGET=arm64-apple-ios18.0
  SURI_BUILD="$SURI_ROOT/.build/LlamaDeviceCPU"
else
  echo 'Usage: scripts/prepare_runtime.sh [simulator|device]' >&2
  exit 2
fi
cmake -S "$SURI_SOURCE" -B "$SURI_BUILD" -G 'Unix Makefiles' \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$(xcrun --sdk "$SURI_SDK" --show-sdk-path)" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=18.0 \
  -DCMAKE_C_COMPILER="$(xcrun --find clang)" -DCMAKE_CXX_COMPILER="$(xcrun --find clang++)" \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_C_FLAGS="-target $SURI_TARGET" -DCMAKE_CXX_FLAGS="-target $SURI_TARGET" \
  -DCMAKE_BUILD_TYPE=Release -DGGML_METAL=OFF -DGGML_ACCELERATE=ON -DGGML_NATIVE=OFF \
  -DBUILD_SHARED_LIBS=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_TOOLS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF
cmake --build "$SURI_BUILD" --target llama -j 4
