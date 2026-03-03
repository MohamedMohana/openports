#!/usr/bin/env bash
# OpenPorts App Packaging Script
# Builds and packages OpenPorts.app for distribution

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
CONF="${1:-debug}"
ARCH="${2:-arm64}"

# Map architecture aliases
case "$ARCH" in
  arm64|aarch64)
    ARCH="arm64"
    ARCH_TARGET="arm64-apple-macosx"
    ;;
  intel|x86_64|i386)
    ARCH="x86_64"
    ARCH_TARGET="x86_64-apple-macosx"
    ;;
  *)
    echo -e "${RED}Error: Unknown architecture '$ARCH'. Use 'arm64' or 'intel'${NC}"
    exit 1
    ;;
esac

echo -e "${GREEN}Building OpenPorts for $ARCH ($ARCH_TARGET)...${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Version info
source "$ROOT/version.env"

# App bundle location
APP="$ROOT/OpenPorts.app"

echo "Cleaning previous build..."
rm -rf "$APP"

# Build directory
BUILD_DIR="$ROOT/.build/$ARCH_TARGET/$CONF"
if [[ ! -d "$BUILD_DIR" ]]; then
  BUILD_DIR="$ROOT/.build/$CONF"
fi

# Check if we need to build
if [[ ! -f "$BUILD_DIR/OpenPorts" ]]; then
  echo -e "${YELLOW}Warning: Binary not found at $BUILD_DIR/OpenPorts${NC}"
  echo "Please run: swift build -c $CONF --arch $ARCH"
  exit 1
fi

echo "Creating app bundle structure..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"

# Generate icon
ICON_SOURCE="$ROOT/Icon.iconset"
ICON_TARGET="$ROOT/Icon.icns"

if [[ -d "$ICON_SOURCE" ]]; then
  echo "Generating icon..."
  iconutil --convert icns --output "$ICON_TARGET" "$ICON_SOURCE" 2>/dev/null || \
  sips -s format icns "$ICON_SOURCE/openports-512.png" --out "$ICON_TARGET" >/dev/null 2>&1
fi

# Bundle configuration
BUNDLE_ID="com.mohamedmohana.openports"
FEED_URL=""
AUTO_CHECKS=false

# Configure for release builds
LOWER_CONF=$(printf "%s" "$CONF" | tr '[:upper:]' '[:lower:]')
if [[ "$LOWER_CONF" != "debug" ]]; then
  FEED_URL="https://raw.githubusercontent.com/MohamedMohana/openports/main/appcast.xml"
  AUTO_CHECKS=true
fi

# Ad-hoc signing disables auto-updates
if [[ "${SIGNING_MODE:-}" == "adhoc" ]]; then
  FEED_URL=""
  AUTO_CHECKS=false
fi

# App group for shared preferences
APP_GROUP_ID="group.com.mohamedmohana.openports"
if [[ "$BUNDLE_ID" == *".debug"* ]]; then
  APP_GROUP_ID="group.com.mohamedmohana.openports.debug"
fi

# Create entitlements
ENTITLEMENTS_DIR="$ROOT/.build/entitlements"
APP_ENTITLEMENTS="${ENTITLEMENTS_DIR}/OpenPorts.entitlements"
mkdir -p "$ENTITLEMENTS_DIR"

cat > "$APP_ENTITLEMENTS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>${APP_GROUP_ID}</string>
    </array>
</dict>
</plist>
PLIST

# Build metadata
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Create Info.plist
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>OpenPorts</string>
    <key>CFBundleDisplayName</key><string>OpenPorts</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key><string>OpenPorts</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${MARKETING_VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>CFBundleIconFile</key><string>Icon</string>
    <key>NSHumanReadableCopyright</key><string>© 2025 Mohamed Mohana. MIT License.</string>
    <key>SUFeedURL</key><string>${FEED_URL}</string>
    <key>SUEnableAutomaticChecks</key><${AUTO_CHECKS}/>
    <key>OpenPortsBuildTimestamp</key><string>${BUILD_TIMESTAMP}</string>
    <key>OpenPortsGitCommit</key><string>${GIT_COMMIT}</string>
    <key>OpenPortsArchitecture</key><string>${ARCH}</string>
</dict>
</plist>
PLIST

# Install binary and dependencies
install_binary() {
  local name="$1"
  local arch="$2"
  
  local build_product
  case "$arch" in
    arm64|x86_64)
      build_product=".build/${arch}-apple-macosx/$CONF/${name}"
      ;;
    *)
      build_product=".build/$CONF/${name}"
      ;;
  esac
  
  if [[ ! -f "$build_product" ]]; then
    echo -e "${RED}Error: Missing ${name} build for ${arch}${NC}"
    echo "Expected at: $build_product"
    exit 1
  fi
  
  cp "${build_product}" "$APP/Contents/MacOS/"
}

echo "Installing OpenPorts binary..."
install_binary "OpenPorts" "$ARCH"

# Copy Sparkle if present (for auto-updates)
if [[ -f ".build/${ARCH_TARGET}/$CONF/Sparkle.framework" ]]; then
  echo "Copying Sparkle.framework..."
  cp -R ".build/${ARCH_TARGET}/$CONF/Sparkle.framework" "$APP/Contents/Frameworks/"
fi

# Code signing
CODESIGN_ID=""
CODESIGN_ARGS=()

if [[ "${SIGNING_MODE:-}" == "adhoc" ]]; then
  CODESIGN_ID="-"
  CODESIGN_ARGS=(--force --sign "$CODESIGN_ID")
elif [[ -n "${openportssigningIdIdentity:-}" ]]; then
  CODESIGN_ID="${openportssigningIdIdentity}"
  CODESIGN_ARGS=(--force --timestamp --options runtime --sign "$CODESIGN_ID")
else
  CODESIGN_ID="adhoc"
  CODESIGN_ARGS=(--force --sign -)
fi

# Copy icon if generated
if [[ -f "$ICON_TARGET" ]]; then
  cp "$ICON_TARGET" "$APP/Contents/Resources/Icon.icns"
fi

# Set permissions
chmod -R u+w "$APP"

# Clean up unnecessary files
xattr -cr "$APP"
find "$APP" -name '._*' -delete

# Sign the app
echo "Signing app bundle..."
codesign "${CODESIGN_ARGS[@]}" "$APP"

echo -e "${GREEN}✅ Successfully created $APP${NC}"
echo "   Architecture: $ARCH"
echo "   Configuration: $CONF"
echo "   Version: $MARKETING_VERSION ($BUILD_NUMBER)"
