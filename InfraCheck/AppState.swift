import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var checks: [CheckItem] = [] { didSet { persist() } }
    @Published var results: [UUID: CheckResult] = [:]
    @Published var isRunning = false
    @Published var intervalMinutes: Int {
        didSet {
            UserDefaults.standard.set(intervalMinutes, forKey: Self.intervalKey)
            restartTimer()
        }
    }

    private var timer: Timer?
    private static let checksKey = "InfraCheck.checks"
    private static let intervalKey = "InfraCheck.intervalMinutes"

    init() {
        intervalMinutes = max(1, UserDefaults.standard.object(forKey: Self.intervalKey) as? Int ?? 5)
        if let data = UserDefaults.standard.data(forKey: Self.checksKey),
           let saved = try? JSONDecoder().decode([CheckItem].self, from: data) {
            checks = saved
        }
        restartTimer()
        Task { await runAll() }
    }

    // MARK: - Status rollup

    var overallStatus: CheckStatus {
        let active = checks.filter(\.enabled)
        guard !active.isEmpty else { return .unknown }
        let statuses = active.map { results[$0.id]?.status ?? .unknown }
        if statuses.contains(.failed) { return .failed }
        if statuses.contains(.warning) { return .warning }
        if statuses.allSatisfy({ $0 == .ok }) { return .ok }
        return .unknown
    }

    var menuBarSymbol: String {
        switch overallStatus {
        case .ok: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.octagon.fill"
        case .unknown: return "circle.dashed"
        }
    }

    // MARK: - Running checks

    func runAll() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        await withTaskGroup(of: (UUID, CheckResult).self) { group in
            for check in checks where check.enabled {
                group.addTask { (check.id, await CheckEngine.run(check)) }
            }
            for await (id, result) in group {
                results[id] = result
            }
        }
    }

    func refresh() {
        Task { await runAll() }
    }

    // MARK: - CRUD

    func upsert(_ check: CheckItem) {
        if let index = checks.firstIndex(where: { $0.id == check.id }) {
            checks[index] = check
        } else {
            checks.append(check)
        }
        Task { results[check.id] = await CheckEngine.run(check) }
    }

    func delete(_ check: CheckItem) {
        checks.removeAll { $0.id == check.id }
        results[check.id] = nil
        Keychain.delete(for: check.id)
    }

    // MARK: - Private

    private func persist() {
        if let data = try? JSONEncoder().encode(checks) {
            UserDefaults.standard.set(data, forKey: Self.checksKey)
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Double(intervalMinutes) * 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.runAll() }
        }
    }
}
