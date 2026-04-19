import Foundation
import Combine
import AppKit

/// Shared application state persisted to UserDefaults.
/// Holds hotkey configuration, target language, and launch-at-login preference.
@Observable
final class AppState {
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let targetLanguage = "targetLanguage"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let launchAtLogin = "launchAtLogin"
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }
    
    // MARK: - Properties
    
    /// Google Translate target language code (e.g., "th", "ja", "en")
    var targetLanguage: String {
        didSet { UserDefaults.standard.set(targetLanguage, forKey: Keys.targetLanguage) }
    }
    
    /// Virtual key code for the global hotkey (default: 17 = "T")
    var hotkeyKeyCode: UInt16 {
        didSet { UserDefaults.standard.set(Int(hotkeyKeyCode), forKey: Keys.hotkeyKeyCode) }
    }
    
    /// Modifier flags for the global hotkey (default: ⌘+⇧)
    var hotkeyModifiers: UInt {
        didSet { UserDefaults.standard.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers) }
    }
    
    /// Whether to launch the app at login
    var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }
    
    /// Whether the hotkey recorder is currently listening for a new hotkey
    var isRecordingHotkey: Bool = false
    
    // MARK: - Computed Properties
    
    /// Human-readable representation of the current hotkey
    var hotkeyDisplayString: String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: hotkeyModifiers)
        
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        
        let keyName = Self.keyCodeToString(hotkeyKeyCode)
        parts.append(keyName)
        
        return parts.joined()
    }
    
    // MARK: - Initialization
    
    init() {
        let defaults = UserDefaults.standard
        let isFirstLaunch = !defaults.bool(forKey: Keys.hasLaunchedBefore)
        
        if isFirstLaunch {
            // Detect target language from OS locale
            let osLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            self.targetLanguage = osLanguage
            
            // Default hotkey: ⌘+Option+G
            self.hotkeyKeyCode = 5 // "G"
            self.hotkeyModifiers = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue
            self.launchAtLogin = false
            
            // Persist defaults
            defaults.set(self.targetLanguage, forKey: Keys.targetLanguage)
            defaults.set(Int(self.hotkeyKeyCode), forKey: Keys.hotkeyKeyCode)
            defaults.set(self.hotkeyModifiers, forKey: Keys.hotkeyModifiers)
            defaults.set(self.launchAtLogin, forKey: Keys.launchAtLogin)
            defaults.set(true, forKey: Keys.hasLaunchedBefore)
        } else {
            self.targetLanguage = defaults.string(forKey: Keys.targetLanguage) ?? "en"
            self.hotkeyKeyCode = UInt16(defaults.integer(forKey: Keys.hotkeyKeyCode))
            self.hotkeyModifiers = UInt(defaults.integer(forKey: Keys.hotkeyModifiers))
            self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
            
            // Fallback if keyCode is 0 (not set)
            if self.hotkeyKeyCode == 0 {
                self.hotkeyKeyCode = 5
                self.hotkeyModifiers = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue
            }
        }
    }
    
    // MARK: - Key Code Mapping
    
    static func keyCodeToString(_ keyCode: UInt16) -> String {
        let mapping: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space", 50: "`",
            51: "Delete", 53: "Esc", 96: "F5", 97: "F6", 98: "F7", 99: "F3",
            100: "F8", 101: "F9", 103: "F11", 105: "F13", 107: "F14",
            109: "F10", 111: "F12", 113: "F15", 118: "F4", 119: "F2",
            120: "F1", 122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return mapping[keyCode] ?? "Key\(keyCode)"
    }
}
