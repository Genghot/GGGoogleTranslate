import Cocoa
import WebKit

/// A floating panel that displays Google Translate in a WebView.
/// Appears above all windows, is resizable, and dismisses on ESC.
final class TranslatePanel: NSPanel, WKNavigationDelegate {
    
    private let webView: WKWebView
    private let appState: AppState
    
    /// Default window size
    static let defaultWidth: CGFloat = 700
    static let defaultHeight: CGFloat = 500
    
    init(appState: AppState) {
        self.appState = appState
        
        // Configure WKWebView
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = false
        
        self.webView = WKWebView(frame: .zero, configuration: config)
        
        // Create panel with floating style
        super.init(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Self.defaultWidth,
                height: Self.defaultHeight
            ),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupPanel()
        setupWebView()
    }
    
    // MARK: - Setup
    
    private func setupPanel() {
        self.title = "GGG Translate"
        self.level = .floating
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.animationBehavior = .utilityWindow
        
        // Set minimum size
        self.minSize = NSSize(width: 400, height: 300)
        
        // Set background color for title bar area
        self.backgroundColor = NSColor.windowBackgroundColor
        self.titlebarAppearsTransparent = false
    }
    
    private func setupWebView() {
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set a desktop Safari user agent to get the full Google Translate experience
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        guard let contentView = self.contentView else { return }
        contentView.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: contentView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    // MARK: - Public Methods
    
    /// Show the panel with the given text loaded in Google Translate.
    /// - Parameter text: The text to translate.
    func showTranslation(for text: String) {
        let targetLang = appState.targetLanguage
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let urlString = "https://translate.google.com/?sl=auto&tl=\(targetLang)&text=\(encodedText)&op=translate"
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        centerOnScreen()
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Center the panel on the main screen.
    private func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelFrame = self.frame
        
        let x = screenFrame.midX - panelFrame.width / 2
        let y = screenFrame.midY - panelFrame.height / 2
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    // MARK: - ESC to Dismiss
    
    override func cancelOperation(_ sender: Any?) {
        saveTargetLanguageFromURL()
        orderOut(nil)
    }
    
    override func close() {
        saveTargetLanguageFromURL()
        orderOut(nil)
    }
    
    // MARK: - Language Persistence
    
    /// Extract the `tl` parameter from the current WebView URL and save it.
    private func saveTargetLanguageFromURL() {
        guard let url = webView.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let tlParam = components.queryItems?.first(where: { $0.name == "tl" })?.value
        else { return }
        
        if !tlParam.isEmpty && tlParam != appState.targetLanguage {
            appState.targetLanguage = tlParam
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Update language from URL after page loads (user may have changed it)
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Allow all navigations within Google Translate
        decisionHandler(.allow)
    }
}
