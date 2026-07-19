import Foundation
import Network

enum CheckEngine {

    static func run(_ check: CheckItem) async -> CheckResult {
        switch check.type {
        case .http: return await httpCheck(check)
        case .port: return await portCheck(check)
        case .ssl:  return await sslCheck(check)
        }
    }

    // MARK: - HTTP / HTTPS uptime

    private static func httpCheck(_ check: CheckItem) async -> CheckResult {
        guard let url = normalizedURL(check.target) else {
            return CheckResult(status: .failed, message: "Invalid URL", lastChecked: .now)
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.httpMethod = "GET"
        if check.usesCredentials, let creds = Keychain.load(for: check.id) {
            let token = Data("\(creds.username):\(creds.password)".utf8).base64EncodedString()
            request.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        }
        let start = Date()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            guard let http = response as? HTTPURLResponse else {
                return CheckResult(status: .failed, message: "No HTTP response", lastChecked: .now)
            }
            switch http.statusCode {
            case 200..<400:
                return CheckResult(status: .ok, message: "\(http.statusCode) · \(ms) ms", lastChecked: .now)
            case 401, 403:
                return CheckResult(status: .warning, message: "\(http.statusCode) auth required · \(ms) ms", lastChecked: .now)
            default:
                return CheckResult(status: .failed, message: "HTTP \(http.statusCode)", lastChecked: .now)
            }
        } catch {
            return CheckResult(status: .failed, message: error.localizedDescription, lastChecked: .now)
        }
    }

    // MARK: - TCP port reachability

    private static func portCheck(_ check: CheckItem) async -> CheckResult {
        let host = check.target.trimmingCharacters(in: .whitespaces)
        guard !host.isEmpty, let nwPort = NWEndpoint.Port(rawValue: UInt16(clamping: check.port)) else {
            return CheckResult(status: .failed, message: "Invalid host/port", lastChecked: .now)
        }
        let start = Date()
        let reachable: Bool = await withCheckedContinuation { continuation in
            let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
            let state = CompletionGuard()
            @Sendable func finish(_ result: Bool) {
                guard state.tryFinish() else { return }
                connection.cancel()
                continuation.resume(returning: result)
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready: finish(true)
                case .failed, .cancelled: finish(false)
                default: break
                }
            }
            connection.start(queue: .global())
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) { finish(false) }
        }
        let ms = Int(Date().timeIntervalSince(start) * 1000)
        return reachable
            ? CheckResult(status: .ok, message: "Port \(check.port) open · \(ms) ms", lastChecked: .now)
            : CheckResult(status: .failed, message: "Port \(check.port) unreachable", lastChecked: .now)
    }

    // MARK: - SSL certificate expiry

    private static func sslCheck(_ check: CheckItem) async -> CheckResult {
        guard let url = normalizedURL(check.target), url.scheme == "https" else {
            return CheckResult(status: .failed, message: "Needs an https:// URL", lastChecked: .now)
        }
        let grabber = CertificateGrabber()
        let session = URLSession(configuration: .ephemeral, delegate: grabber, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        do {
            _ = try await session.data(for: request)
        } catch {
            if grabber.notAfter == nil {
                return CheckResult(status: .failed, message: error.localizedDescription, lastChecked: .now)
            }
            // Connection may fail after handshake (e.g. 4xx handled elsewhere); cert info is enough.
        }
        guard let notAfter = grabber.notAfter else {
            return CheckResult(status: .failed, message: "Could not read certificate", lastChecked: .now)
        }
        let days = Int(notAfter.timeIntervalSinceNow / 86_400)
        if days < 0 {
            return CheckResult(status: .failed, message: "Certificate EXPIRED \(-days) days ago", lastChecked: .now)
        } else if days <= 21 {
            return CheckResult(status: .warning, message: "Certificate expires in \(days) days", lastChecked: .now)
        } else {
            return CheckResult(status: .ok, message: "Certificate valid · \(days) days left", lastChecked: .now)
        }
    }

    private static func normalizedURL(_ raw: String) -> URL? {
        var s = raw.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }
        if !s.lowercased().hasPrefix("http://") && !s.lowercased().hasPrefix("https://") {
            s = "https://" + s
        }
        return URL(string: s)
    }
}

/// Thread-safe one-shot completion flag.
private final class CompletionGuard: @unchecked Sendable {
    private let lock = NSLock()
    private var finished = false

    /// Returns true exactly once.
    func tryFinish() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !finished else { return false }
        finished = true
        return true
    }
}

/// Captures the leaf certificate's expiry date during the TLS handshake.
private final class CertificateGrabber: NSObject, URLSessionDelegate {
    var notAfter: Date?

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust,
           let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
           let leaf = chain.first {
            var error: Unmanaged<CFError>?
            if let values = SecCertificateCopyValues(leaf, [kSecOIDX509V1ValidityNotAfter] as CFArray, &error) as? [CFString: Any],
               let entry = values[kSecOIDX509V1ValidityNotAfter] as? [CFString: Any],
               let number = entry[kSecPropertyKeyValue] as? NSNumber {
                notAfter = Date(timeIntervalSinceReferenceDate: number.doubleValue)
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
}
