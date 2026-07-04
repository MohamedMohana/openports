/// CLI version, surfaced via `openports-cli --version`.
enum CLIVersion {
    /// Keep in sync with `MARKETING_VERSION` in `version.env`.
    /// `CLIVersionTests` fails when the two drift apart.
    static let current = "2.5.1"
}
