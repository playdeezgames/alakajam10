#!/usr/bin/env bash
# Native tests of the pure game package, plus a wasm type-check of every package. Usage: tools/test.sh
set -euo pipefail
cd "$(dirname "$0")/.."
odin test src/game -collection:csmos=src -o:speed -define:ODIN_TEST_THREADS=1
odin check src/game -collection:csmos=src -target:js_wasm32 -no-entry-point -vet-shadowing -vet-unused
odin check src/web -collection:csmos=src -target:js_wasm32 -vet-shadowing -vet-unused
echo "ALL TESTS PASSED"
