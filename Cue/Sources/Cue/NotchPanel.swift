import AppKit
import SwiftUI
import Combine

/// Hosting view that handles trackpad scrolling, hover tracking and first-click in a non-key panel.
final class PrompterHostingView: NSHostingView<PrompterView> {
    private var trackingArea: NSTrackingArea?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func scrollWheel(with event: NSEvent) {
        let multiplier: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 12
        PrompterState.shared.nudge(by: -event.scrollingDeltaY * multiplier)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(rect: bounds,
                                  options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                  owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) { PrompterState.shared.isHovering = true }
    override func mouseExited(with event: NSEvent) { PrompterState.shared.isHovering = false }
}

/// Owns the floating panel that sits over the MacBook notch.
final class NotchPanelController {
    let panel: NSPanel
    private let state = PrompterState.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 150),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        // Above the menu bar so it can cover the area around the notch.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false

        let hosting = PrompterHostingView(rootView: PrompterView())
        hosting.sizingOptions = [] // we control the window size ourselves
        panel.contentView = hosting

        // @Published fires on willSet, so hop to the next runloop to read new values.
        state.$panelWidth.map { _ in () }
            .merge(with: state.$panelHeight.map { _ in () })
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.layout() }
            .store(in: &cancellables)

        state.$hideFromScreenShare
            .sink { [weak self] hide in self?.panel.sharingType = hide ? .none : .readOnly }
            .store(in: &cancellables)

        state.$isVisible
            .receive(on: RunLoop.main)
            .sink { [weak self] visible in
                guard let self else { return }
                if visible { self.layout(); self.panel.orderFrontRegardless() } else { self.panel.orderOut(nil) }
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            self?.layout()
        }
    }

    /// Prefer the built-in display with a notch; fall back to the main screen.
    private var targetScreen: NSScreen? {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens.first
    }

    func layout() {
        guard let screen = targetScreen else { return }
        let frame = screen.frame
        let notchHeight = screen.safeAreaInsets.top

        var notchWidth: CGFloat = 0
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            notchWidth = frame.width - left.width - right.width
        }

        let width = max(CGFloat(state.panelWidth), notchWidth + 40)
        let height: CGFloat
        let topY: CGFloat

        if notchHeight > 0 {
            // Grow out of the notch: panel starts at the very top of the screen.
            state.topInset = notchHeight
            state.notchWidth = notchWidth
            height = CGFloat(state.panelHeight) + notchHeight
            topY = frame.maxY
        } else {
            // No notch (external display): hang just below the menu bar.
            state.topInset = 0
            state.notchWidth = 0
            height = CGFloat(state.panelHeight)
            topY = screen.visibleFrame.maxY
        }

        let rect = NSRect(x: frame.midX - width / 2, y: topY - height, width: width, height: height)
        panel.setFrame(rect, display: true)
    }

}
