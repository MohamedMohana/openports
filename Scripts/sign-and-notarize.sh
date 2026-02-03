#!/usr/bin/env bash
set -euo pipefail

APP_NAME="OpenPorts"
APP_IDENTITY="${OPENPORTS_SIGNING_IDENTITY:-}"
APP_BUNDLE="OpenPorts.app"
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/version.env"
ZIP_NAME="${APP_NAME}-${MARKETING_VERSION}.zip"
DSYM_ZIP="${APP_NAME}-${MARKETING_VERSION}.dSYM.zip"

if [[ -z "${APP_STORE_CONNECT_API_KEY_P8:-}" || -z "${APP_STORE_CONNECT_KEY_ID:-}" || -z "${APP_STORE_CONNECT_ISSUER_ID:-}" ]]; then
  if [[ "$OPENPORTS_SIGNING" == "production" ]]; then
    echo "Missing APP_STORE_CONNECT_* env vars for production signing." >&2
    exit 1
  fi
  echo "Skipping notarization (development build)."
  exit 0
fi

if [[ -z "${APP_IDENTITY}" ]]; then
  echo "APP_IDENTITY is required for production signing." >&2
  exit 1
fi

echo "$APP_STORE_CONNECT_API_KEY_P8" | sed 's/\\n/\n/g' > /tmp/openports-api-key.p8
trap 'rm -f /tmp/openports-api-key.p8 /tmp/${APP_NAME}Notarize.zip' EXIT

ARCHES_VALUE=${ARCHES:-"arm64 x86_64"}
ARCH_LIST=( ${ARCHES_VALUE} )
for ARCH in "${ARCH_LIST[@]}"; do
  swift build -c release --arch "$ARCH"
done
ARCHES="${ARCHES_VALUE}" ./Scripts/package_app.sh release

ENTITLEMENTS_DIR="$ROOT/.build/entitlements"
APP_ENTITLEMENTS="${ENTITLEMENTS_DIR}/OpenPorts.entitlements"

echo "Signing with $APP_IDENTITY"

codesign --force --timestamp --options runtime --sign "$APP_IDENTITY" \
  --entitlements "$APP_ENTITLEMENTS" \
  "$APP_BUNDLE"

DITTO_BIN=${DITTO_BIN:-/usr/bin/ditto}
"$DITTO_BIN" --norsrc -c -k --keepParent "$APP_BUNDLE" "/tmp/${APP_NAME}Notarize.zip"

echo "Submitting for notarization"
xcrun notarytool submit "/tmp/${APP_NAME}Notarize.zip" \
  --key /tmp/openports-api-key.p8 \
  --key-id "$APP_STORE_CONNECT_KEY_ID" \
  --issuer "$APP_STORE_CONNECT_ISSUER_ID" \
  --wait

echo "Stapling ticket"
xcrun stapler staple "$APP_BUNDLE"

xattr -cr "$APP_BUNDLE"
find "$APP_BUNDLE" -name '._*' -delete

"$DITTO_BIN" --norsrc -c -k --keepParent "$APP_BUNDLE" "$ZIP_NAME"

spctl -a -t exec -vv "$APP_BUNDLE"
stapler validate "$APP_BUNDLE"

echo "Done: $ZIP_NAME"
