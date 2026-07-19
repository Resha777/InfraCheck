import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            if !state.checks.isEmpty {
                summaryBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            Divider()

            if state.checks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(state.checks) { check in
                            CheckCard(check: check, result: state.results[check.id])
                        }
                    }
                    .padding(14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            Divider()

            footer
        }
        .frame(width: 460, height: 620)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [overallColor.opacity(0.75), overallColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Infrastructure")
                    .font(.system(size: 15, weight: .bold))
                Text(overallTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(overallColor)
            }

            Spacer()

            if state.isRunning {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button {
                    state.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help("Run all checks now")
            }
        }
    }

    // MARK: - Summary

    private var summaryBar: some View {
        HStack(spacing: 8) {
            StatusPill(count: count(.ok), label: "online", color: .green)
            StatusPill(count: count(.warning), label: "warning", color: .yellow)
            StatusPill(count: count(.failed), label: "down", color: .red)
            Spacer()
            if let last = lastChecked {
                Text(last, style: .time)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.tertiary)
                    .help("Last check")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "server.rack")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No checks yet")
                .font(.system(size: 15, weight: .semibold))
            Text("Add your first endpoint to start monitoring.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Button("Add a Check…") {
                openWindow(id: "manage")
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button {
                openWindow(id: "manage")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Manage Checks", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.borderless)

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .font(.system(size: 12, weight: .medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func count(_ status: CheckStatus) -> Int {
        state.checks.filter { $0.enabled && (state.results[$0.id]?.status ?? .unknown) == status }.count
    }

    private var lastChecked: Date? {
        state.results.values.compactMap(\.lastChecked).max()
    }

    private var overallTitle: String {
        switch state.overallStatus {
        case .ok: return "All systems operational"
        case .warning: return "Attention needed"
        case .failed: return "Some checks are failing"
        case .unknown: return "Waiting for first check"
        }
    }

    private var overallColor: Color {
        switch state.overallStatus {
        case .ok: return .green
        case .warning: return .yellow
        case .failed: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Status pill

struct StatusPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text("\(count) \(label)")
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.13)))
        .opacity(count > 0 ? 1 : 0.45)
    }
}

// MARK: - Check card

struct CheckCard: View {
    let check: CheckItem
    let result: CheckResult?
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: typeIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(check.name.isEmpty ? check.target : check.name)
                    .font(.system(size: 13.5, weight: .semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
                if check.enabled, let date = result?.lastChecked {
                    Text(date, style: .time)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(hovering ? 0.09 : 0.045))
        )
        .onHover { hovering = $0 }
        .opacity(check.enabled ? 1 : 0.5)
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private var subtitle: String {
        guard check.enabled else { return "Disabled" }
        return result?.message ?? "Not checked yet"
    }

    private var statusLabel: String {
        guard check.enabled else { return "Off" }
        switch result?.status ?? .unknown {
        case .ok: return "Online"
        case .warning: return "Warning"
        case .failed: return "Down"
        case .unknown: return "Pending"
        }
    }

    private var statusColor: Color {
        guard check.enabled else { return .gray }
        switch result?.status ?? .unknown {
        case .ok: return .green
        case .warning: return .yellow
        case .failed: return .red
        case .unknown: return .gray
        }
    }

    private var typeIcon: String {
        switch check.type {
        case .http: return "globe"
        case .port: return "cable.connector"
        case .ssl: return "lock.shield.fill"
        }
    }
}
