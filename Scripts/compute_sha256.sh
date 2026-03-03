#!/bin/bash
# Compute SHA256 checksums for OpenPorts releases

set -e

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 v1.1.9"
  exit 1
fi

echo "Computing SHA256 for OpenPorts $VERSION..."
echo ""

# Download files
ARM64_URL="https://github.com/MohamedMohana/openports/releases/download/${VERSION}/OpenPorts-${VERSION}-arm64.zip"
INTEL_URL="https://github.com/MohamedMohana/openports/releases/download/${VERSION}/OpenPorts-${VERSION}-intel.zip"

# Check if release exists
if ! curl --output /dev/null --silent --head --fail "$ARM64_URL"; then
  echo "Error: Release ${VERSION} not found or doesn't have architecture-specific builds"
  echo ""
  echo "For older releases with single zip file:"
  echo "  curl -sL https://github.com/MohamedMohana/openports/releases/download/${VERSION}/OpenPorts-${VERSION}.zip | shasum -a 256"
  exit 1
fi

echo "ARM64:"
curl -sL "$ARM64_URL" | shasum -a 256 | awk '{print "  sha256 \"" $1 "\""}'

echo ""
echo "Intel:"
curl -sL "$INTEL_URL" | shasum -a 256 | awk '{print "  sha256 \"" $1 "\""}'

echo ""
echo "Copy these values to homebrew-tap/Casks/openports.rb"
