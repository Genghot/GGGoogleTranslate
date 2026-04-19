import Cocoa
import Carbon

/// Manages global keyboard shortcut registration and detection using Carbon HIToolbox.
final class HotkeyManager {
    
    private var hotKeyRef: EventHotKeyRef?
    private let appState: AppState
    private var onHotkeyPressed: (() -> Void)?
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    /// Start listening for the configured global hotkey.
    func startListening(handler: @escaping () -> Void) {
        self.onHotkeyPressed = handler
        
        // Setup Carbon event handler
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let ptr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            if let event = event, let userData = userData {
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(event,
                                            EventParamName(kEventParamDirectObject),
                                            EventParamType(typeEventHotKeyID),
                                            nil,
                                            MemoryLayout<EventHotKeyID>.size,
                                            nil,
                                            &hotKeyID)
                
                if err == noErr, hotKeyID.id == 1 {
                    let mySelf = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                    // Check if recording – if so ignore hotkey trigger
                    print("▶️ Carbon detected hotkey press! Recording: \(mySelf.appState.isRecordingHotkey)")
                    if !mySelf.appState.isRecordingHotkey {
                        DispatchQueue.main.async { mySelf.onHotkeyPressed?() }
                    }
                }
            }
            return noErr
        }, 1, [eventType], ptr, nil)
        
        // Register the initial hotkey
        registerCarbonHotkey()
    }
    
    private func registerCarbonHotkey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        
        let keyCode = UInt32(appState.hotkeyKeyCode)
        let flags = NSEvent.ModifierFlags(rawValue: appState.hotkeyModifiers)
        
        var carbonMods: UInt32 = 0
        if flags.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if flags.contains(.option) { carbonMods |= UInt32(optionKey) }
        if flags.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        if flags.contains(.control) { carbonMods |= UInt32(controlKey) }
        
        let hotKeyID = EventHotKeyID(signature: OSType(1001), id: 1)
        let status = RegisterEventHotKey(keyCode, carbonMods, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status != noErr {
            print("Failed to register global hotkey (Status: \(status))")
        }
    }
    
    /// Update listening if hotkey changed
    func updateListening() {
        registerCarbonHotkey()
    }
    
    /// Stop listening for hotkey events.
    func stopListening() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    deinit {
        stopListening()
    }
}
