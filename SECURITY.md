# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.1.6   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in OpenPorts, please report it responsibly.

### How to Report

1. **Do not** create a public GitHub issue for security vulnerabilities
2. Send an email to: security@openports.app
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Impact assessment
   - Suggested fix (if any)

### What to Expect

- We will acknowledge receipt of your report within 48 hours
- We will provide a detailed response within 7 days
- We will work with you to understand and fix the issue
- We will coordinate disclosure with you

### Security Best Practices

OpenPorts follows these security practices:

- **Code Signing**: Apps are signed to verify authenticity
- **Ad-hoc Signing**: Currently uses ad-hoc signing (open-source project)
- **Notarization**: Not currently notarized (requires Apple Developer account)
- **Minimal Permissions**: App requests only necessary macOS permissions
- **Privilege Separation**: Admin elevation only when terminating non-owned processes

### Process Termination Security

When terminating processes:
- System processes show clear warning indicators
- Kill confirmation can be configured (None, High Risk Only, All Ports)
- Requires admin password for non-owned processes
- Protected by macOS System Integrity Protection (SIP)

## Known Security Considerations

1. **Gatekeeper Warning**: Users may see Gatekeeper warning on first launch
   - This is expected for open-source projects without paid Apple Developer credentials
   - See README for detailed explanation

2. **Process Termination**: App can terminate any process (with admin privileges)
   - Users should verify process identity before termination
   - Critical ports are clearly marked with red indicators
   - Safety ratings help users make informed decisions

3. **Data Storage**: Preferences stored in `~/Library/Containers/com.mohamedmohana.openports/`
   - Only app-specific preferences are stored
   - No sensitive data or passwords are stored
   - Uses standard macOS UserDefaults

## Contributing Security Improvements

We welcome security-related contributions:

1. Follow the standard [CONTRIBUTING.md](CONTRIBUTING.md) guidelines
2. Mark security-related PRs with `[security]` tag
3. Include security rationale in PR description
4. Ensure tests cover security scenarios

## Security Badge Opportunities

Help improve OpenPorts security and earn GitHub achievements:

- **Security Bug Bounty Hunter**: Find and responsibly disclose vulnerabilities
- **Security Advisory Credit**: Submit security advisories to GitHub Advisory Database

See [GitHub Security Lab](https://github.com/security) for more information on security contributions.
