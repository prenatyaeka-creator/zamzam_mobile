#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:-3.41.6}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SDK_DIR="$ROOT_DIR/.flutter_sdk"
ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  ARCHIVE_NAME="flutter_macos_arm64_${VERSION}-stable.zip"
else
  ARCHIVE_NAME="flutter_macos_${VERSION}-stable.zip"
fi
ARCHIVE_PATH="$SDK_DIR/$ARCHIVE_NAME"
URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/${ARCHIVE_NAME}"
mkdir -p "$SDK_DIR"
echo "Downloading Flutter SDK ${VERSION} from official storage..."
curl -L "$URL" -o "$ARCHIVE_PATH"
unzip -q "$ARCHIVE_PATH" -d "$SDK_DIR"
rm -f "$ARCHIVE_PATH"
"$SDK_DIR/flutter/bin/flutter" --version
