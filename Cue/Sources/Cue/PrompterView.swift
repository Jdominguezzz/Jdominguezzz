import SwiftUI

/// Black shape that looks like the notch growing downward: flat top, rounded bottom corners.
struct NotchShape: Shape {
    var radius: CGFloat = 22

    func path(in r: CGRect) -> Path {
        var p = Path()
        let rad = min(radius, r.height / 2, r.width / 2)
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - rad))
        p.addQuadCurve(to: CGPoint(x: r.maxX - rad, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + rad, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - rad), control: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct PrompterView: View {
    @ObservedObject var state = PrompterState.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            NotchShape()
                .fill(Color.black.opacity(state.backgroundOpacity))

            VStack(spacing: 0) {
                // Keep text out from under the physical notch / camera.
                Color.clear.frame(height: state.topInset)

                GeometryReader { geo in
                    Text(state.script.isEmpty ? "Your script is empty — open “Edit Script…” from the menu bar." : state.script)
                        .font(.system(size: state.fontSize, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineSpacing(state.fontSize * 0.25)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            GeometryReader { g in
                                Color.clear.preference(key: ContentHeightKey.self, value: g.size.height)
                            }
                        )
                        .frame(width: geo.size.width, alignment: .top)
                        .padding(.top, 6)
                        .offset(y: -state.offset)
                        .scaleEffect(x: state.mirrored ? -1 : 1, y: 1)
                }
                .clipped()
                .mask(
                    VStack(spacing: 0) {
                        LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 10)
                        Color.black
                        LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: 28)
                    }
                )
                .padding(.horizontal, 22)
                .padding(.bottom, 6)
            }

            if state.isHovering {
                ControlBar(state: state)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if !state.isPlaying {
                Image(systemName: "pause.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.bottom, 6)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: state.isHovering)
        .onPreferenceChange(ContentHeightKey.self) { state.contentHeight = $0 }
    }
}

struct ControlBar: View {
    @ObservedObject var state: PrompterState

    var body: some View {
        HStack(spacing: 14) {
            button("backward.fill", help: "Back (⌃⌥[)") { state.jump(lines: -3) }
            button("tortoise.fill", help: "Slower (⌃⌥-)") { state.slower() }
            button(state.isPlaying ? "pause.fill" : "play.fill", help: "Play / Pause (⌃⌥Space)") { state.togglePlay() }
            button("hare.fill", help: "Faster (⌃⌥=)") { state.faster() }
            button("forward.fill", help: "Forward (⌃⌥])") { state.jump(lines: 3) }
            button("arrow.counterclockwise", help: "Restart (⌃⌥R)") { state.restart() }
            button("square.and.pencil", help: "Edit script") { state.openEditor?() }
            Text("\(Int(state.speed))")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.14)))
    }

    private func button(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
