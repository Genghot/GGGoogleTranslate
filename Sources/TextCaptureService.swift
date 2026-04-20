import Cocoa
import Carbon

/// Captures the currently selected text from any application
/// using multiple strategies: AppleScript (primary) and CGEvent fallback.
final class TextCaptureService {
    
    private var isCapturing = false
    
    /// Capture the currently selected text from the frontmost application.
    /// - Parameter completion: Called with the captured text, or nil if nothing was selected.
    func captureSelectedText(completion: @escaping (String?) -> Void) {
        guard !isCapturing else {
            print("▶️ Already capturing, ignoring duplicate.")
            return
        }
        isCapturing = true
        
        let pasteboard = NSPasteboard.general
        
        // 1. Save current clipboard
        let savedItems = savePasteboard(pasteboard)
        
        // 2. Clear clipboard
        pasteboard.clearContents()
        let targetChangeCount = pasteboard.changeCount
        
        // 3. Wait briefly for the user's physical modifier keys to release,
        //    then fire the copy command
        print("▶️ Scheduling copy command...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // Try AppleScript first (most reliable across all apps)
            self.simulateCopyViaAppleScript()
            
            // Also fire CGEvent as backup
            self.simulateCopyViaEvent()
            
            // 4. Poll for clipboard update (max ~1.5s)
            var attempts = 0
            func checkClipboard() {
                if pasteboard.changeCount > targetChangeCount {
                    let capturedText = pasteboard.string(forType: .string)
                    print("▶️ ✅ Clipboard updated! Text: \(capturedText?.prefix(40) ?? "nil")")
                    self.finalize(pasteboard: pasteboard, savedItems: savedItems, text: capturedText, completion: completion)
                } else if attempts < 30 {
                    attempts += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: checkClipboard)
                } else {
                    print("▶️ ⏱️ Timeout waiting for clipboard.")
                    self.finalize(pasteboard: pasteboard, savedItems: savedItems, text: nil, completion: completion)
                }
            }
            checkClipboard()
        }
    }
    
    // MARK: - Copy Strategies
    
    /// Strategy 1: AppleScript — tell System Events to keystroke "c" with command down.
    /// This bypasses CGEvent modifier contamination entirely.
    private func simulateCopyViaAppleScript() {
        print("▶️ Trying AppleScript copy...")
        let script = NSAppleScript(source: """
            tell application "System Events"
                keystroke "c" using command down
            end tell
        """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        if let error = error {
            print("▶️ AppleScript error: \(error)")
        } else {
            print("▶️ AppleScript copy sent.")
        }
    }
    
    /// Strategy 2: CGEvent — direct HID simulation as fallback.
    private func simulateCopyViaEvent() {
        print("▶️ Trying CGEvent copy...")
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            print("▶️ Could not create CGEventSource.")
            return
        }
        
        // Key code 8 = "C"
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        
        // Set ONLY Command flag — clear any hardware modifier contamination
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
        print("▶️ CGEvent copy posted.")
    }
    
    // MARK: - Finalize
    
    private func finalize(pasteboard: NSPasteboard, savedItems: [(NSPasteboard.PasteboardType, Data)], text: String?, completion: @escaping (String?) -> Void) {
        restorePasteboard(pasteboard, items: savedItems)
        isCapturing = false
        completion(text)
    }
    
    // MARK: - Pasteboard Save/Restore
    
    private func savePasteboard(_ pasteboard: NSPasteboard) -> [(NSPasteboard.PasteboardType, Data)] {
        var savedItems: [(NSPasteboard.PasteboardType, Data)] = []
        guard let types = pasteboard.types else { return savedItems }
        for type in types {
            if let data = pasteboard.data(forType: type) {
                savedItems.append((type, data))
            }
        }
        return savedItems
    }
    
    private func restorePasteboard(_ pasteboard: NSPasteboard, items: [(NSPasteboard.PasteboardType, Data)]) {
        guard !items.isEmpty else { return }
        pasteboard.clearContents()
        for (type, data) in items {
            pasteboard.setData(data, forType: type)
        }
    }
}
