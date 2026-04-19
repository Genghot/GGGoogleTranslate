import SwiftUI
import ServiceManagement

/// Menu bar dropdown view with settings for hotkey, launch at login, and quit.
struct SettingsView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // App title
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.accentColor)
                Text("GGGoogleTranslate")
                    .font(.headline)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            Divider()
            
            // Current hotkey display
            HStack {
                Text("Hotkey:")
                    .foregroundColor(.secondary)
                Spacer()
                if appState.isRecordingHotkey {
                    Text("Press new hotkey...")
                        .foregroundColor(.orange)
                        .font(.system(.body, design: .monospaced))
                } else {
                    Text(appState.hotkeyDisplayString)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.15))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            // Change hotkey button
            Button(action: {
                appState.isRecordingHotkey.toggle()
            }) {
                HStack {
                    Image(systemName: appState.isRecordingHotkey ? "xmark.circle" : "keyboard")
                    Text(appState.isRecordingHotkey ? "Cancel" : "Change Hotkey")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            Divider()
            
            // Launch at Login toggle
            Toggle(isOn: $appState.launchAtLogin) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Launch at Login")
                }
            }
            .toggleStyle(.checkbox)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .onChange(of: appState.launchAtLogin) { _, newValue in
                updateLaunchAtLogin(newValue)
            }
            
            Divider()
            
            // Target Language
            HStack {
                Text("Target Language:")
                    .foregroundColor(.secondary)
                Spacer()
                Picker("", selection: $appState.targetLanguage) {
                    Text("English").tag("en")
                    Text("Thai").tag("th")
                    Text("Japanese").tag("ja")
                    Text("Spanish").tag("es")
                    Text("French").tag("fr")
                    Text("German").tag("de")
                    Text("Chinese (Simp)").tag("zh-CN")
                    Text("Korean").tag("ko")
                }
                .frame(width: 120)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            Divider()
            
            // Quit button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit GGGoogleTranslate")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .padding(.bottom, 8)
        }
        .frame(width: 240)
    }
    
    // MARK: - Launch at Login
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
}
