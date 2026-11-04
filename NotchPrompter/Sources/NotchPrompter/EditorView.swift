import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct EditorView: View {
    @ObservedObject var state = PrompterState.shared
    @State private var loadError: String?

    private var readingTime: String {
        // ~140 words per minute is a natural speaking pace.
        let minutes = Double(state.wordCount) / 140
        let m = Int(minutes), s = Int((minutes - Double(m)) * 60)
        return "\(state.wordCount) words · ~\(m)m \(s)s spoken"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { openFile() } label: { Label("Open File…", systemImage: "doc") }
                Button { pasteClipboard() } label: { Label("Paste", systemImage: "doc.on.clipboard") }
                Button(role: .destructive) { state.script = ""; state.restart() } label: { Label("Clear", systemImage: "trash") }
                Spacer()
                Text(readingTime).font(.caption).foregroundColor(.secondary)
            }

            TextEditor(text: $state.script)
                .font(.system(size: 14))
                .frame(minHeight: 200)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))

            GroupBox("Playback") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(state.isPlaying ? "Pause" : "Play") { state.togglePlay() }
                        Button("Restart") { state.restart() }
                        Spacer()
                    }
                    slider("Speed", value: $state.speed, range: PrompterState.speedRange, format: "%.0f pt/s")
                }
                .padding(4)
            }

            GroupBox("Appearance") {
                VStack(alignment: .leading, spacing: 8) {
                    slider("Text size", value: $state.fontSize, range: 12...44, format: "%.0f pt")
                    slider("Width", value: $state.panelWidth, range: 260...1000, format: "%.0f pt")
                    slider("Height", value: $state.panelHeight, range: 60...420, format: "%.0f pt")
                    slider("Background", value: $state.backgroundOpacity, range: 0.3...1, format: "%.0f%%", scale: 100)
                    Toggle("Hide from screen sharing & recordings", isOn: $state.hideFromScreenShare)
                    Toggle("Mirror text (for beam-splitter glass)", isOn: $state.mirrored)
                }
                .padding(4)
            }

            Text("Shortcuts (work everywhere, even while Zoom is focused):  ⌃⌥Space play/pause · ⌃⌥= faster · ⌃⌥- slower · ⌃⌥[ back · ⌃⌥] forward · ⌃⌥R restart · ⌃⌥T show/hide")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let loadError {
                Text(loadError).font(.caption).foregroundColor(.red)
            }
        }
        .padding(16)
        .frame(minWidth: 520, minHeight: 600)
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        format: String, scale: Double = 1) -> some View {
        HStack {
            Text(title).frame(width: 80, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: format, value.wrappedValue * scale))
                .font(.system(.caption, design: .monospaced))
                .frame(width: 70, alignment: .trailing)
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        var types: [UTType] = [.plainText, .text, .rtf, .rtfd, .html]
        if let docx = UTType(filenameExtension: "docx") { types.append(docx) }
        if let md = UTType(filenameExtension: "md") { types.append(md) }
        panel.allowedContentTypes = types
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try state.load(url: url)
                loadError = nil
            } catch {
                loadError = "Couldn't open \(url.lastPathComponent): \(error.localizedDescription)"
            }
        }
    }

    private func pasteClipboard() {
        if let text = NSPasteboard.general.string(forType: .string) {
            state.script = text
            state.restart()
        }
    }
}
