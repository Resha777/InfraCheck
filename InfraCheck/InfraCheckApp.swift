import SwiftUI

@main
struct InfraCheckApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(state)
        } label: {
            // Text label makes the item easy to find in a crowded menu bar
            HStack(spacing: 4) {
                Image(systemName: state.menuBarSymbol)
                Text("Infra")
            }
        }
        .menuBarExtraStyle(.window)

        Window("Manage Checks", id: "manage") {
            ManageChecksView()
                .environmentObject(state)
        }
        .defaultSize(width: 620, height: 460)
    }
}
