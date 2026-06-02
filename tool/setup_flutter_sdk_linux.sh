#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:-3.41.6}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SDK_DIR="$ROOT_DIR/.flutter_sdk"
ARCHIVE_NAME="flutter_linux_${VERSION}-stable.tar.xz"
ARCHIVE_PATH="$SDK_DIR/$ARCHIVE_NAME"
URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${ARCHIVE_NAME}"
mkdir -p "$SDK_DIR"
echo "Downloading Flutter SDK ${VERSION} from official storage..."
curl -L "$URL" -o "$ARCHIVE_PATH"
tar -xf "$ARCHIVE_PATH" -C "$SDK_DIR"
rm -f "$ARCHIVE_PATH"
"$SDK_DIR/flutter/bin/flutter" --version
