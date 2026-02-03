#!/usr/bin/env bash
set -euo pipefail

CONF=${1:-release}
SIGNING_MODE=${OPENPORTS_SIGNING:-}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

source "$ROOT/version.env"

ARCH_LIST=( ${ARCHES:-} )
if [[ ${#ARCH_LIST[@]} -eq 0 ]]; then
  HOST_ARCH=$(uname -m)
  case "$HOST_ARCH" in
    arm64) ARCH_LIST=(arm64) ;;
    x86_64) ARCH_LIST=(x86_64) ;;
    *) ARCH_LIST=("$HOST_ARCH") ;;
  esac
fi

APP="$ROOT/OpenPorts.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"

ICON_SOURCE="$ROOT/Icon.iconset"
ICON_TARGET="$ROOT/Icon.icns"
if [[ -d "$ICON_SOURCE" ]]; then
  iconutil --convert icns --output "$ICON_TARGET" "$ICON_SOURCE" 2>/dev/null || \
  sips -s format icns "$ICON_SOURCE/openports-512.png" --out "$ICON_TARGET" >/dev/null 2>&1
fi

BUNDLE_ID="com.mohamedmohana.openports"
FEED_URL=""
AUTO_CHECKS=false
LOWER_CONF=$(printf "%s" "$CONF" | tr '[:upper:]' '[:lower:]')
if [[ "$LOWER_CONF" != "debug" ]]; then
  FEED_URL="https://raw.githubusercontent.com/MohamedMohana/openports/main/appcast.xml"
  AUTO_CHECKS=true
fi
if [[ "$SIGNING_MODE" == "adhoc" ]]; then
  FEED_URL=""
  AUTO_CHECKS=false
fi
APP_GROUP_ID="group.com.mohamedmohana.openports"
if [[ "$BUNDLE_ID" == *".debug"* ]]; then
  APP_GROUP_ID="group.com.mohamedmohana.openports.debug"
fi

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

BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

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
</dict>
</plist>
PLIST

build_product_path() {
  local name="$1"
  local arch="$2"
  case "$arch" in
    arm64|x86_64) echo ".build/${arch}-apple-macosx/$CONF/$name" ;;
    *) echo ".build/$CONF/$name" ;;
  esac
}

verify_binary_arches() {
  local binary="$1"
  shift
  local expected=("$@")
  local actual
  actual=$(lipo -archs "$binary")
  local actual_count expected_count
  actual_count=$(wc -w <<<"$actual" | tr -d ' ')
  expected_count=${#expected[@]}
  if [[ "$actual_count" -ne "$expected_count" ]]; then
    echo "ERROR: $binary arch mismatch (expected: ${expected[*]}, actual: ${actual})" >&2
    exit 1
  fi
  for arch in "${expected[@]}"; do
    if [[ "$actual" != *"$arch"* ]]; then
      echo "ERROR: $binary missing arch $arch (have: ${actual})" >&2
      exit 1
    fi
  done
}

install_binary() {
  local name="$1"
  local dest="$2"
  local binaries=()
  for arch in "${ARCH_LIST[@]}"; do
    local src
    src=$(build_product_path "$name" "$arch")
    if [[ ! -f "$src" ]]; then
      echo "ERROR: Missing ${name} build for ${arch} at ${src}" >&2
      exit 1
    fi
    binaries+=("$src")
  done
  if [[ ${#ARCH_LIST[@]} -gt 1 ]]; then
    lipo -create "${binaries[@]}" -output "$dest"
  else
    cp "${binaries[0]}" "$dest"
  fi
  chmod +x "$dest"
  verify_binary_arches "$dest" "${ARCH_LIST[@]}"
}

install_binary "OpenPorts" "$APP/Contents/MacOS/OpenPorts"

if [[ "$SIGNING_MODE" == "adhoc" ]]; then
  CODESIGN_ID="-"
  CODESIGN_ARGS=(--force --sign "$CODESIGN_ID")
elif [[ "${OPENPORTS_SIGNING_IDENTITY:-}" ]]; then
  CODESIGN_ID="${OPENPORTS_SIGNING_IDENTITY}"
  CODESIGN_ARGS=(--force --timestamp --options runtime --sign "$CODESIGN_ID")
else
  CODESIGN_ID="adhoc"
  CODESIGN_ARGS=(--force --sign -)
fi

function resign() {
  codesign "${CODESIGN_ARGS[@]}" "$1"
}

if [[ -f "$ICON_TARGET" ]]; then
  cp "$ICON_TARGET" "$APP/Contents/Resources/Icon.icns"
fi

chmod -R u+w "$APP"

xattr -cr "$APP"
find "$APP" -name '._*' -delete

resign "$APP"

echo "Created $APP"
