import Foundation

/// Errors that can occur during config discovery
public enum ConfigDiscoveryError: LocalizedError, Equatable {
    case multipleConfigsFound([URL])
    case noConfigFound
    case sharedConfigMissing(URL)
    case targetNotFound(URL)

    public var errorDescription: String? {
        switch self {
        case let .multipleConfigsFound(urls):
            "Multiple config files found: \(urls.map(\.lastPathComponent).joined(separator: ", "))"
        case .noConfigFound:
            "No config file found"
        case let .sharedConfigMissing(url):
            "Shared config file missing: \(url.path)"
        case let .targetNotFound(url):
            "Target not found: \(url.path)"
        }
    }

    public static func == (lhs: ConfigDiscoveryError, rhs: ConfigDiscoveryError) -> Bool {
        switch (lhs, rhs) {
        case let (.multipleConfigsFound(lhsURLs), .multipleConfigsFound(rhsURLs)):
            lhsURLs.map(\.path) == rhsURLs.map(\.path)
        case (.noConfigFound, .noConfigFound):
            true
        case let (.sharedConfigMissing(lhsURL), .sharedConfigMissing(rhsURL)):
            lhsURL.path == rhsURL.path
        case let (.targetNotFound(lhsURL), .targetNotFound(rhsURL)):
            lhsURL.path == rhsURL.path
        default:
            false
        }
    }
}
