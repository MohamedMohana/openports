#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Formatting code..."
swiftformat Sources Tests

echo "Linting code..."
swiftlint --strict

echo "Done!"
