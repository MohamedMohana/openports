import Foundation

/// Lightweight semantic version parser/comparator (e.g. "2.0.1" or "v2.0.1").
public struct SemanticVersion: Comparable, Equatable, CustomStringConvertible {
    public let rawValue: String
    public let components: [Int]

    public init?(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let withoutPrefix: String
        if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") {
            withoutPrefix = String(trimmed.dropFirst())
        } else {
            withoutPrefix = trimmed
        }

        let coreVersion = withoutPrefix.split(separator: "-", maxSplits: 1).first.map(String.init) ?? ""
        guard !coreVersion.isEmpty else {
            return nil
        }

        let segments = coreVersion.split(separator: ".")
        guard !segments.isEmpty else {
            return nil
        }

        var parsed: [Int] = []
        for segment in segments {
            guard !segment.isEmpty, segment.allSatisfy(\.isNumber), let value = Int(segment) else {
                return nil
            }
            parsed.append(value)
        }

        self.rawValue = rawValue
        components = parsed
    }

    public var description: String {
        components.map(String.init).joined(separator: ".")
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let maxCount = max(lhs.components.count, rhs.components.count)
        for index in 0 ..< maxCount {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left == right {
                continue
            }
            return left < right
        }
        return false
    }

    public static func isNewer(_ candidate: String, than current: String) -> Bool {
        guard let candidateVersion = SemanticVersion(candidate), let currentVersion = SemanticVersion(current) else {
            return false
        }
        return candidateVersion > currentVersion
    }
}
