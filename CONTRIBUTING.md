# Contributing to OpenPorts

Thank you for your interest in contributing to OpenPorts! This document provides guidelines and information for contributors.

## Quick Start

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/openports.git
cd openports

# Build
swift build

# Run tests
swift test

# Package app
./Scripts/package_app.sh debug
```

## Code Style

- Run linting before committing: `./Scripts/lint.sh`
- Follow existing code style (SwiftFormat and SwiftLint rules)
- Keep functions small and focused
- Add tests for new functionality

## Testing

- Run tests before committing: `swift test`
- Add tests for new features
- Test on different macOS versions if possible
- Test both Apple Silicon and Intel if you have access to both

## 🎯 Code Signing & Notarization (How to Help)

### The Problem

OpenPorts currently shows a Gatekeeper security warning on first launch because:
- No Apple Developer account for proper code signing
- No notarization by Apple
- Uses ad-hoc signing (local-only)

This causes users to see: **"Apple could not verify 'OpenPorts' is free of malware"**

### How You Can Help

If you have an **Apple Developer account** (costs $99/year), you can help eliminate this warning for all users by:

#### Option 1: Full Code Signing + Notarization

Set up your Apple Developer credentials and run:

```bash
export APP_STORE_CONNECT_API_KEY_P8="<your-private-key-file>"
export APP_STORE_CONNECT_KEY_ID="<your-key-id>"
export APP_STORE_CONNECT_ISSUER_ID="<your-issuer-id>"
export OPENPORTS_SIGNING_IDENTITY="<your-certificate-name>"

./Scripts/sign-and-notarize.sh
```

This will:
1. Sign the app with your Apple Developer certificate
2. Submit to Apple for notarization
3. Staple the notarization ticket to the app
4. Generate a verified .app bundle that passes Gatekeeper

#### Option 2: Create a Signed Release PR

1. Follow the steps above to create a signed/notarized build
2. Create a PR with the signed `OpenPorts.app` in a zip file
3. We can update the GitHub release with the signed version

### Files Involved

- `Scripts/sign-and-notarize.sh` - Handles code signing and notarization
- `Scripts/package_app.sh` - Creates the .app bundle
- Package configuration in `Package.swift`

### Apple Developer Documentation

- [Code Signing](https://developer.apple.com/support/code-signing/)
- [Notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution/)
- [App Store Connect API Keys](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)

## Adding Features

When adding new features:

1. Update this README with feature documentation
2. Add tests for new functionality
3. Update relevant documentation files
4. Consider backwards compatibility

## Reporting Issues

When reporting bugs:

1. Search existing issues first
2. Include macOS version
3. Include architecture (Apple Silicon or Intel)
4. Include reproduction steps
5. Include error messages or screenshots if applicable

## Feature Requests

For feature requests:

1. Search existing feature requests
2. Use the appropriate issue template
3. Explain the use case clearly
4. Consider if it fits the project's scope

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
