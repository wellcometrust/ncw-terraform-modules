#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
(cd frontend && npm ci && npm run build)
rm -rf build && mkdir -p build/scanner_deps
pip install -r scanner/requirements.txt -t build/scanner_deps --quiet
echo "Build complete."
