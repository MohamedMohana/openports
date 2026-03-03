import Foundation

extension AppUpdateService {
    struct GitHubRelease: Decodable {
        let tagName: String
        let htmlURL: URL

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }

        var normalizedVersion: String {
            if tagName.hasPrefix("v") || tagName.hasPrefix("V") {
                return String(tagName.dropFirst())
            }
            return tagName
        }
    }

    enum AppUpdateError: LocalizedError {
        case invalidReleaseURL
        case invalidResponse
        case badStatusCode(Int)
        case brewNotFound
        case brewCommandFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidReleaseURL:
                return "Invalid GitHub release URL."
            case .invalidResponse:
                return "Invalid response from GitHub."
            case let .badStatusCode(statusCode):
                if statusCode == 403 {
                    return "GitHub API rate limit reached. Try again later."
                }
                return "GitHub returned status \(statusCode)."
            case .brewNotFound:
                return "Homebrew was not found. Install Homebrew to use in-app updates."
            case let .brewCommandFailed(output):
                return output
            }
        }
    }
}
