import Foundation

enum CheckType: String, Codable, CaseIterable, Identifiable {
    case http = "HTTP/HTTPS"
    case port = "TCP Port"
    case ssl  = "SSL Certificate"

    var id: String { rawValue }
}

struct CheckItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String = ""
    var type: CheckType = .http
    /// URL for HTTP/SSL checks (e.g. https://api.example.com/health),
    /// hostname or IP for port checks (e.g. db.example.com)
    var target: String = ""
    /// Used by TCP port checks only
    var port: Int = 443
    var enabled: Bool = true
    /// Set to true when basic-auth credentials are stored in the Keychain
    var usesCredentials: Bool = false
}

enum CheckStatus: Int {
    case ok, warning, failed, unknown
}

struct CheckResult {
    var status: CheckStatus = .unknown
    var message: String = "Not checked yet"
    var lastChecked: Date? = nil
}
