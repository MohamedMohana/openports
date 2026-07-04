#!/bin/bash
# Render the OpenPorts Homebrew cask for a given release version and checksums.

set -euo pipefail

VERSION_INPUT="${1:-}"
ARM64_SHA="${2:-}"
INTEL_SHA="${3:-}"
OUTPUT_PATH="${4:-}"

if [[ -z "$VERSION_INPUT" || -z "$ARM64_SHA" || -z "$INTEL_SHA" ]]; then
  echo "Usage: $0 <version|tag> <arm64-sha256> <intel-sha256> [output-path]" >&2
  echo "Example: $0 2.1.1 <arm64-sha> <intel-sha> homebrew-tap/Casks/openports.rb" >&2
  exit 1
fi

if [[ "$VERSION_INPUT" == v* ]]; then
  VERSION="${VERSION_INPUT#v}"
else
  VERSION="$VERSION_INPUT"
fi

render_cask() {
  cat <<EOF
cask "openports" do
  version "${VERSION}"

  on_arm do
    url "https://github.com/MohamedMohana/openports/releases/download/v#{version}/OpenPorts-v#{version}-arm64.zip",
        verified: "github.com/MohamedMohana/openports/"
    sha256 "${ARM64_SHA}"
  end

  on_intel do
    url "https://github.com/MohamedMohana/openports/releases/download/v#{version}/OpenPorts-v#{version}-intel.zip",
        verified: "github.com/MohamedMohana/openports/"
    sha256 "${INTEL_SHA}"
  end

  name "OpenPorts"
  desc "Smart port monitoring for Mac developers"
  homepage "https://github.com/MohamedMohana/openports"

  auto_updates false
  depends_on macos: :sonoma

  app "OpenPorts.app"
end
EOF
}

if [[ -n "$OUTPUT_PATH" ]]; then
  mkdir -p "$(dirname "$OUTPUT_PATH")"
  render_cask > "$OUTPUT_PATH"
else
  render_cask
fi
