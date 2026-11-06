import AppKit
import Combine
import QuartzCore

/// Shared, persisted state for the teleprompter.
final class PrompterState: ObservableObject {
    static let shared = PrompterState()

    private let defaults = UserDefaults.standard

    // MARK: Persisted settings
    @Published var script: String { didSet { defaults.set(script, forKey: Keys.script) } }
    /// Scroll speed in points per second.
    @Published var speed: Double { didSet { defaults.set(speed, forKey: Keys.speed) } }
    @Published var fontSize: Double { didSet { defaults.set(fontSize, forKey: Keys.fontSize) } }
    @Published var panelWidth: Double { didSet { defaults.set(panelWidth, forKey: Keys.width) } }
    @Published var panelHeight: Double { didSet { defaults.set(panelHeight, forKey: Keys.height) } }
    @Published var backgroundOpacity: Double { didSet { defaults.set(backgroundOpacity, forKey: Keys.opacity) } }
    @Published var hideFromScreenShare: Bool { didSet { defaults.set(hideFromScreenShare, forKey: Keys.hide) } }
    @Published var mirrored: Bool { didSet { defaults.set(mirrored, forKey: Keys.mirrored) } }

    // MARK: Runtime state
    @Published var isPlaying = false
    @Published var offset: CGFloat = 0
    /// Whether the panel is on screen. Remembered between launches.
    @Published var isVisible: Bool { didSet { defaults.set(isVisible, forKey: Keys.visible) } }
    @Published var isHovering = false
    /// Height reserved at the top of the panel for the physical notch / menu bar.
    @Published var topInset: CGFloat = 0
    /// Width of the physical notch (0 when the screen has none).
    @Published var notchWidth: CGFloat = 0
    var contentHeight: CGFloat = 0

    /// Hook set by the app delegate so the in-panel button can open the editor.
    var openEditor: (() -> Void)?

    static let speedRange: ClosedRange<Double> = 5...300

    private var timer: Timer?
    private var lastTick: CFTimeInterval = 0

    private enum Keys {
        static let script = "script", speed = "speed", fontSize = "fontSize"
        static let width = "panelWidth", height = "panelHeight", opacity = "bgOpacity"
        static let hide = "hideFromScreenShare", mirrored = "mirrored", visible = "visible"
    }

    private init() {
        let d = UserDefaults.standard
        script = d.string(forKey: Keys.script) ?? PrompterState.welcomeText
        speed = d.object(forKey: Keys.speed) as? Double ?? 30
        fontSize = d.object(forKey: Keys.fontSize) as? Double ?? 20
        panelWidth = d.object(forKey: Keys.width) as? Double ?? 460
        panelHeight = d.object(forKey: Keys.height) as? Double ?? 150
        backgroundOpacity = d.object(forKey: Keys.opacity) as? Double ?? 1.0
        hideFromScreenShare = d.object(forKey: Keys.hide) as? Bool ?? true
        mirrored = d.object(forKey: Keys.mirrored) as? Bool ?? false
        isVisible = d.object(forKey: Keys.visible) as? Bool ?? true
    }

    // MARK: Playback

    func togglePlay() { isPlaying ? pause() : play() }

    func play() {
        if offset >= contentHeight, contentHeight > 0 { offset = 0 } // restart if at the end
        isPlaying = true
        lastTick = CACurrentMediaTime()
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func pause() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    func restart() {
        offset = 0
    }

    func hide() {
        pause()
        isVisible = false
    }

    func show() { isVisible = true }

    func toggleVisible() { isVisible ? hide() : show() }

    func faster() { speed = min(speed * 1.15, Self.speedRange.upperBound) }
    func slower() { speed = max(speed / 1.15, Self.speedRange.lowerBound) }

    /// Jump by a few lines (negative = back).
    func jump(lines: Int) {
        nudge(by: CGFloat(lines) * CGFloat(fontSize) * 1.3)
    }

    func nudge(by delta: CGFloat) {
        offset = min(max(offset + delta, 0), max(contentHeight, 0))
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = now - lastTick
        lastTick = now
        guard isPlaying else { return }
        let next = offset + CGFloat(speed * dt)
        if contentHeight > 0, next >= contentHeight {
            offset = contentHeight
            pause()
        } else {
            offset = next
        }
    }

    // MARK: Script loading

    func load(url: URL) throws {
        let text: String
        if ["txt", "md", "markdown", "text"].contains(url.pathExtension.lowercased()) {
            text = try String(contentsOf: url, encoding: .utf8)
        } else {
            // Handles .rtf, .rtfd, .docx, .doc, .html, .odt …
            text = try NSAttributedString(url: url, options: [:], documentAttributes: nil).string
        }
        script = text
        offset = 0
    }

    var wordCount: Int {
        script.split { $0.isWhitespace || $0.isNewline }.count
    }

    static let welcomeText = """
    Welcome to Cue 👋

    Click the menu bar icon and choose “Edit Script…” to paste your transcript, or open a .txt / .docx / .rtf file.

    ⌃⌥Space  play / pause
    ⌃⌥=  faster    ⌃⌥-  slower
    ⌃⌥[  back    ⌃⌥]  forward
    ⌃⌥R  restart    ⌃⌥T  show / hide

    Don't need it right now? Hover and click ✕, press ⌃⌥T, or use the menu bar icon. Open Cue again to bring it back.

    You can also scroll on the prompter with your trackpad. Hover it for controls.

    Keep your eyes up here, near the camera, and you'll look like you're talking straight to the person on the other side. Good luck! 🎤
    """
}
