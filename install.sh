#!/bin/bash
set -euo pipefail
clear

REPO="thelastligma/SolaraM"
TAG="Releases"

# The new name for the application
APP_NAME="Zen Ware"
APP_BUNDLE="${APP_NAME}.app"

echo "🚀 ${APP_NAME} Installer"
echo "===================="

OS_VERSION=$(sw_vers -productVersion | cut -d. -f1,2)
ARCH=$(uname -m)

# Catalina detection (10.15)
if [[ "$OS_VERSION" == "10.15" ]]; then
  ASSET_NAME="Solara-catliona.zip"
  echo "Detected: macOS Catalina ($OS_VERSION)"
else
  case "$ARCH" in
    arm64|aarch64)
      ASSET_NAME="Solara-arm64.zip"
      echo "Detected: Apple Silicon ($ARCH)"
      ;;
    x86_64|amd64)
      ASSET_NAME="Solara-x86_64.zip"
      echo "Detected: Intel ($ARCH)"
      ;;
    *)
      echo "❌ Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac
fi

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ASSET_NAME"

TMP_ZIP="/tmp/$ASSET_NAME"
TMP_DIR=$(mktemp -d)

echo "🔗 Downloading: $DOWNLOAD_URL"
curl -fL "$DOWNLOAD_URL" -o "$TMP_ZIP" || {
  echo "❌ Download failed."
  exit 1
}

echo "📦 Extracting ZIP..."
unzip -q "$TMP_ZIP" -d "$TMP_DIR"

# Find the original .app regardless of its name in the ZIP
ORIGINAL_APP=$(find "$TMP_DIR" -maxdepth 2 -name "*.app" -type d | head -n 1)

if [ -z "$ORIGINAL_APP" ]; then
  echo "❌ Application bundle not found in ZIP"
  exit 1
fi

# Rename the source folder to Zen Ware before moving it
mv "$ORIGINAL_APP" "$TMP_DIR/$APP_BUNDLE"
APP_SRC="$TMP_DIR/$APP_BUNDLE"

if [ -d "/Applications/$APP_BUNDLE" ]; then
  echo "♻️ Removing existing installation..."
  rm -rf "/Applications/$APP_BUNDLE"
fi

echo "💾 Installing as $APP_NAME..."
if [ -w /Applications ]; then
  cp -R "$APP_SRC" "/Applications/"
else
  sudo cp -R "$APP_SRC" "/Applications/"
fi

echo "🛡️ Removing quarantine flags..."
xattr -rd com.apple.quarantine "/Applications/$APP_BUNDLE" 2>/dev/null || true

echo "🧹 Cleaning up..."
rm -rf "$TMP_DIR" "$TMP_ZIP"

echo ""
echo "✅ $APP_NAME installed successfully!"
open -a "/Applications/$APP_BUNDLE"
