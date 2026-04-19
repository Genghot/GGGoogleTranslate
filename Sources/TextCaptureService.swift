import Cocoa
import Carbon

/// Captures the currently selected text from any application
/// using clipboard simulation (save clipboard → ⌘C → read → restore).
final class TextCaptureService {
    
    /// Capture the currently selected text from the frontmost application.
    /// - Parameter completion: Called with the captured text, or nil if nothing was selected.
    func captureSelectedText(completion: @escaping (String?) -> Void) {
        let pasteboard = NSPasteboard.general
        let initialChangeCount = pasteboard.changeCount
        
        // 1. Save current clipboard contents
        let savedItems = savePasteboard(pasteboard)
        
        // 2. Clear the clipboard
        pasteboard.clearContents()
        
        // 3. Simulate ⌘C
        print("▶️ Simulating ⌘C...")
        simulateCopyKeypress()
        
        // 4. Robust wait: Check for change count increment (max 0.5s)
        var attempts = 0
        func checkClipboard() {
            if pasteboard.changeCount > initialChangeCount {
                let capturedText = pasteboard.string(forType: .string)
                print("▶️ captured text changed! Result: \(capturedText?.prefix(20) ?? "nil")")
                finalizeCapture(capturedText)
            } else if attempts < 10 {
                attempts += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: checkClipboard)
            } else {
                print("▶️ Timeout waiting for clipboard update.")
                finalizeCapture(nil)
            }
        }
        
        func finalizeCapture(_ text: String?) {
            // 5. Restore original clipboard contents
            self.restorePasteboard(pasteboard, items: savedItems)
            completion(text)
        }
        
        checkClipboard()
    }
    
    // MARK: - Private Methods
    
    /// Simulate pressing ⌘C to copy selected text.
    private func simulateCopyKeypress() {
        // Use a source that ignores hardware state to avoid modifier contamination
        guard let source = CGEventSource(stateID: .privateState) else { return }
        
        // Key code 8 = "C"
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        
        // EXPLICITLY set flags to ONLY Command, removing Option/Control/Shift hardware interference
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        // Post events to the HID tap for system-wide effect
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    /// Save all items from the pasteboard for later restoration.
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
    
    /// Restore previously saved pasteboard items.
    private func restorePasteboard(_ pasteboard: NSPasteboard, items: [(NSPasteboard.PasteboardType, Data)]) {
        guard !items.isEmpty else { return }
        
        pasteboard.clearContents()
        
        for (type, data) in items {
            pasteboard.setData(data, forType: type)
        }
    }
}
