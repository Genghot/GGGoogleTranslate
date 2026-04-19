import Cocoa

/// Checks and manages macOS Accessibility permissions.
/// Required for simulating ⌘C to capture selected text.
final class AccessibilityManager {
    
    /// Check if accessibility permissions are granted.
    /// - Parameter prompt: If true, show the system prompt to grant permission.
    /// - Returns: `true` if accessibility is trusted.
    @discardableResult
    static func checkPermission(prompt: Bool = false) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): prompt]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Show an alert guiding the user to enable accessibility permissions.
    static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        GGGoogleTranslate needs Accessibility permission to capture selected text from other apps.
        
        Please go to:
        System Settings → Privacy & Security → Accessibility
        
        Then enable GGGoogleTranslate in the list.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        alert.icon = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "Permission")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }
    
    /// Open the macOS Accessibility settings pane.
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
