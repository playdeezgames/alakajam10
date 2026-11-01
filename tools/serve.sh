#!/usr/bin/env bash
# Serves build/web (wasm needs http, not file://). Usage: PORT=8080 tools/serve.sh   (check the port is free first)
exec python3 -m http.server "${PORT:-8080}" -d "$(dirname "$0")/../build/web"
