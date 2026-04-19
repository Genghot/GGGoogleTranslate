import SwiftUI
import Cocoa

/// GGGoogleTranslate — a macOS menu bar app for instant Google Translate access.
/// Highlight text anywhere, press ⌘+Shift+T, and get a floating translate popup.
@main
struct GGGTranslateApp: App {
    @State private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Menu bar presence
        MenuBarExtra {
            SettingsView(appState: appState)
                .onChange(of: appState.isRecordingHotkey) { _, isRecording in
                    if isRecording {
                        appDelegate.startHotkeyRecording()
                    } else {
                        appDelegate.stopHotkeyRecording()
                    }
                }
                .onAppear {
                    appDelegate.appState = appState
                }
        } label: {
            Image(systemName: "globe")
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState? {
        didSet {
            if translatePanel == nil, let state = appState {
                setup(with: state)
            }
        }
    }
    
    private var hotkeyManager: HotkeyManager?
    private var textCaptureService = TextCaptureService()
    private var translatePanel: TranslatePanel?
    private var hotkeyRecorderMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let isTrusted = AccessibilityManager.checkPermission(prompt: false)
        print("▶️ Accessibility Trusted: \(isTrusted)")
        // Accessibility check
        if !isTrusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                AccessibilityManager.showPermissionAlert()
            }
        }
        
        // Setup happens when appState is injected by the view
        // If appState is somehow injected early:
        if let state = appState, translatePanel == nil {
            setup(with: state)
        }
    }
    
    private func setup(with state: AppState) {
        let panel = TranslatePanel(appState: state)
        self.translatePanel = panel
        
        let manager = HotkeyManager(appState: state)
        manager.startListening { [weak self] in
            self?.handleHotkeyPressed()
        }
        self.hotkeyManager = manager
    }
    
    // MARK: - Translate Flow
    
    private func handleHotkeyPressed() {
        print("▶️ HOTKEY TRIGGERED!")
        textCaptureService.captureSelectedText { [weak self] text in
            print("▶️ CAPTURED TEXT: \(String(describing: text))")
            guard let text = text, !text.isEmpty else {
                print("▶️ No text captured, beeping.")
                NSSound.beep()
                return
            }
            print("▶️ Showing translation panel for text...")
            self?.translatePanel?.showTranslation(for: text)
        }
    }
    
    // MARK: - Hotkey Recorder
    
    func startHotkeyRecording() {
        guard let state = appState else { return }
        
        hotkeyRecorderMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
            
            guard !flags.isEmpty else {
                if event.keyCode == 53 {
                    state.isRecordingHotkey = false
                }
                return nil
            }
            
            state.hotkeyKeyCode = event.keyCode
            state.hotkeyModifiers = flags.rawValue
            state.isRecordingHotkey = false
            self.hotkeyManager?.updateListening()
            return nil
        }
    }
    
    func stopHotkeyRecording() {
        if let monitor = hotkeyRecorderMonitor {
            NSEvent.removeMonitor(monitor)
            hotkeyRecorderMonitor = nil
        }
    }
}
