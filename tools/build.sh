#!/usr/bin/env bash
# Builds the web game into build/web (git-ignored). Usage: tools/build.sh [--size]   (--size for shipping)
set -euo pipefail
cd "$(dirname "$0")/.."
flags="-o:speed"
[ "${1:-}" = "--size" ] && flags="-o:size"
mkdir -p build/web
odin build src/web -collection:csmos=src -target:js_wasm32 -out:build/web/game.wasm -vet-shadowing -vet-unused $flags
cp "$(odin root)/core/sys/wasm/js/odin.js" build/web/
cp web/index.html build/web/
echo "web build: build/web (serve with tools/serve.sh)"
