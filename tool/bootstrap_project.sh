#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"
./tool/flutterw create . --platforms=android,ios,web
./tool/flutterw pub get
echo "Project Flutter siap. Jalankan ./tool/flutterw run"
