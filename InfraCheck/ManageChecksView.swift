import SwiftUI
import ServiceManagement

struct ManageChecksView: View {
    @EnvironmentObject private var state: AppState
    @State private var editing: CheckItem?
    @State private var showingEditor = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)

            Divider()

            if state.checks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(state.checks) { check in
                            ManageRow(
                                check: check,
                                onToggle: { enabled in
                                    var updated = check
                                    updated.enabled = enabled
                                    state.upsert(updated)
                                },
                                onEdit: {
                                    editing = check
                                    showingEditor = true
                                },
                                onDelete: {
                                    state.delete(check)
                                }
                            )
                        }
                    }
                    .padding(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            Divider()

            footer
        }
        .frame(minWidth: 660, minHeight: 480)
        .sheet(isPresented: $showingEditor) {
            CheckEditorView(original: editing)
                .environmentObject(state)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Manage Checks")
                    .font(.system(size: 17, weight: .bold))
                Text(headerSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                editing = nil
                showingEditor = true
            } label: {
                Label("Add Check", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var headerSubtitle: String {
        let enabled = state.checks.filter(\.enabled).count
        return "\(state.checks.count) configured · \(enabled) enabled · runs every \(state.intervalMinutes) min"
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "server.rack")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No checks yet")
                .font(.system(size: 15, weight: .semibold))
            Text("Add an endpoint, host, or certificate to monitor.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Button("Add a Check…") {
                editing = nil
                showingEditor = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 16) {
            HStack(spacing: 7) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                Text("Check every")
                Picker("", selection: $state.intervalMinutes) {
                    ForEach([1, 2, 5, 10, 15, 30, 60], id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .labelsHidden()
                .frame(width: 88)
            }

            Divider()
                .frame(height: 16)

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }

            Spacer()

            Button {
                state.refresh()
            } label: {
                Label("Run All Now", systemImage: "arrow.clockwise")
            }
            .disabled(state.isRunning)
        }
        .font(.system(size: 12))
        .controlSize(.small)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Row

struct ManageRow: View {
    let check: CheckItem
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: typeIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(check.name.isEmpty ? check.target : check.name)
                        .font(.system(size: 13.5, weight: .semibold))
                        .lineLimit(1)
                    if check.usesCredentials {
                        Image(systemName: "key.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .help("Uses credentials stored in Keychain")
                    }
                }
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help("Edit")
            .opacity(hovering ? 1 : 0.35)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .help("Delete")
            .opacity(hovering ? 1 : 0.35)

            Toggle("", isOn: Binding(get: { check.enabled }, set: onToggle))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .padding(.leading, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(hovering ? 0.09 : 0.045))
        )
        .onHover { hovering = $0 }
        .opacity(check.enabled ? 1 : 0.55)
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private var subtitle: String {
        switch check.type {
        case .port: return "\(check.type.rawValue) · \(check.target):\(check.port)"
        default: return "\(check.type.rawValue) · \(check.target)"
        }
    }

    private var typeIcon: String {
        switch check.type {
        case .http: return "globe"
        case .port: return "cable.connector"
        case .ssl: return "lock.shield.fill"
        }
    }

    private var accent: Color {
        switch check.type {
        case .http: return .blue
        case .port: return .purple
        case .ssl: return .teal
        }
    }
}

// MARK: - Editor

struct CheckEditorView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    let original: CheckItem?

    @State private var draft = CheckItem()
    @State private var username = ""
    @State private var password = ""
    @State private var useCredentials = false

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: original == nil ? "plus" : "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                Text(original == nil ? "New Check" : "Edit Check")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            Form {
                Section("What to monitor") {
                    Picker("Type", selection: $draft.type) {
                        ForEach(CheckType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    TextField("Name", text: $draft.name, prompt: Text("e.g. Production API"))
                    TextField(targetLabel, text: $draft.target, prompt: Text(targetPrompt))
                    if draft.type == .port {
                        TextField("Port", value: $draft.port, format: .number.grouping(.never))
                    }
                }

                if draft.type == .http {
                    Section("Authentication") {
                        Toggle("Use basic-auth credentials", isOn: $useCredentials)
                        if useCredentials {
                            TextField("Username", text: $username)
                            SecureField("Password", text: $password)
                            Label("Stored securely in your Mac's Keychain.", systemImage: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(original == nil ? "Add Check" : "Save Changes") { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.target.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(14)
        }
        .frame(width: 440)
        .onAppear {
            if let original {
                draft = original
                useCredentials = original.usesCredentials
                if let creds = Keychain.load(for: original.id) {
                    username = creds.username
                    password = creds.password
                }
            }
        }
    }

    private var targetLabel: String {
        draft.type == .port ? "Host" : "URL"
    }

    private var targetPrompt: String {
        switch draft.type {
        case .http: return "https://api.example.com/health"
        case .port: return "db.example.com"
        case .ssl:  return "https://example.com"
        }
    }

    private func save() {
        draft.usesCredentials = draft.type == .http && useCredentials
        if draft.usesCredentials {
            Keychain.save(.init(username: username, password: password), for: draft.id)
        } else {
            Keychain.delete(for: draft.id)
        }
        state.upsert(draft)
        dismiss()
    }
}
