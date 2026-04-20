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
        
        let handlerErr = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            print("▶️ Carbon event handler triggered!")
            if let event = event, let userData = userData {
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(event,
                                            EventParamName(kEventParamDirectObject),
                                            EventParamType(typeEventHotKeyID),
                                            nil,
                                            MemoryLayout<EventHotKeyID>.size,
                                            nil,
                                            &hotKeyID)
                
                if err == noErr {
                    print("▶️ Caught HotKey (Signature: \(hotKeyID.signature), ID: \(hotKeyID.id))")
                    if hotKeyID.signature == 1195656532 { // 'GGGT' in decimal
                        let mySelf = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                        if !mySelf.appState.isRecordingHotkey {
                            DispatchQueue.main.async { mySelf.onHotkeyPressed?() }
                        }
                    }
                } else {
                    print("▶️ Failed to get hotkey parameter (Error: \(err))")
                }
            }
            return noErr
        }, 1, [eventType], ptr, nil)
        
        print("▶️ Handler Installation Status: \(handlerErr)")
        
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
        
        print("▶️ Registering Carbon Hotkey: KeyCode=\(keyCode), Mods=\(carbonMods)")
        
        // Use 'GGGT' as signature (1195656532)
        let hotKeyID = EventHotKeyID(signature: OSType(1195656532), id: 1)
        let status = RegisterEventHotKey(keyCode, carbonMods, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
            print("▶️ Hotkey successfully registered (Status: \(status))")
        } else {
            print("❌ Failed to register global hotkey (Status: \(status))")
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
