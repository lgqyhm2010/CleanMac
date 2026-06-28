import SwiftUI

struct SettingsView: View {
    @AppStorage("aiExecutable") private var aiExecutable = "/usr/bin/env"
    @AppStorage("aiArguments") private var aiArguments = "codex exec"

    var body: some View {
        TabView {
            Form {
                TextField("Executable", text: $aiExecutable)
                TextField("Arguments", text: $aiArguments)
            }
            .padding(20)
            .tabItem {
                Label("AI CLI", systemImage: "sparkles")
            }
        }
        .frame(width: 520, height: 180)
    }
}
