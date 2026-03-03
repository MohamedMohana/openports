import AppKit
import SwiftUI

struct DebugLogsView: View {
    @ObservedObject var logger: AppLogger
    @State private var autoScrollToLatest = true

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider().overlay(Color.white.opacity(0.15))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(logger.logs.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundStyle(colorForLogLine(line))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                    }
                    .padding(12)
                }
                .background(Color.black.opacity(0.20))
                .onAppear {
                    scrollToBottom(proxy)
                }
                .onChange(of: logger.logs.count) { _, _ in
                    guard autoScrollToLatest else {
                        return
                    }
                    scrollToBottom(proxy)
                }
            }

            Divider().overlay(Color.white.opacity(0.15))

            footer
        }
        .frame(minWidth: 620, minHeight: 420)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.18),
                    Color(red: 0.07, green: 0.09, blue: 0.14),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            ),
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconProvider.swiftUIImage(size: 58)
                .resizable()
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("OpenPorts Debug Logs")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Live application logs")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            Spacer(minLength: 10)

            Button("Clear") {
                logger.clear()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Toggle("Auto-scroll to latest", isOn: $autoScrollToLatest)
                .toggleStyle(.switch)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.8))

            Spacer()

            Button("Copy to Clipboard") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(logger.getLogsText(), forType: .string)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func colorForLogLine(_ line: String) -> Color {
        if line.contains("[ERROR]") {
            return .red.opacity(0.95)
        }

        if line.contains("[WARN]") {
            return .orange.opacity(0.95)
        }

        if line.contains("[DEBUG]") {
            return .blue.opacity(0.95)
        }

        return Color.white.opacity(0.88)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let lastIndex = logger.logs.indices.last else {
            return
        }

        DispatchQueue.main.async {
            proxy.scrollTo(lastIndex, anchor: .bottom)
        }
    }
}
