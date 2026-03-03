import OpenPortsCore
import SwiftUI

@MainActor
final class StatusPopoverModel: ObservableObject {
    @Published var descriptor = MenuDescriptor()
}

struct StatusPopoverView: View {
    @ObservedObject var model: StatusPopoverModel

    let onRefresh: () -> Void
    let onViewLogs: () -> Void
    let onShowPreferences: () -> Void
    let onQuit: () -> Void
    let onTerminate: (Int, Bool) -> Void

    private var entries: [RenderableMenuEntry] {
        let flattenedEntries = model.descriptor.sections.flatMap(\.entries)
        return flattenedEntries.enumerated().map { index, entry in
            RenderableMenuEntry(
                id: stableEntryID(for: entry, index: index),
                entry: entry,
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.15))

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(entries) { item in
                        entryView(item.entry)
                    }
                }
                .padding(12)
            }

            Divider().overlay(Color.white.opacity(0.15))
            footer
        }
        .frame(width: 480, height: 620)
        .background(background)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.12, blue: 0.18),
                Color(red: 0.07, green: 0.09, blue: 0.14),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconProvider.swiftUIImage(size: 34)
                .resizable()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("OpenPorts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Custom Control Center")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            Spacer()

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Refresh")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func stableEntryID(for entry: MenuEntry, index: Int) -> String {
        switch entry {
        case let .portRow(port, _, _, _):
            "port-\(port.pid)-\(port.port)-\(port.portProtocol.rawValue.lowercased())"
        case let .text(text, style):
            "text-\(style.id)-\(text)-\(index)"
        case .divider:
            "divider-\(index)"
        case let .button(title, _):
            "button-\(title)-\(index)"
        case .refreshButton:
            "refresh"
        case .viewLogsButton:
            "view-logs"
        case .preferencesButton:
            "preferences"
        }
    }

    @ViewBuilder
    private func entryView(_ entry: MenuEntry) -> some View {
        switch entry {
        case let .text(text, style):
            switch style {
            case .header:
                Text(text.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
            case .warning:
                Text(text)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.orange.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .secondary:
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .frame(maxWidth: .infinity, alignment: .leading)
            default:
                Text(text)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .divider:
            Divider().overlay(Color.white.opacity(0.12))

        case let .portRow(port, category, technology, projectName):
            PopoverPortRow(
                port: port,
                category: category,
                technology: technology,
                projectName: projectName,
                onTerminate: onTerminate,
            )

        case .refreshButton, .viewLogsButton, .preferencesButton:
            EmptyView()

        case .button:
            EmptyView()
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            footerButton("Logs", icon: "text.append", action: onViewLogs)
            footerButton("Prefs", icon: "slider.horizontal.3", action: onShowPreferences)
            footerButton("Quit", icon: "power", action: onQuit)
        }
        .padding(12)
    }

    private func footerButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct RenderableMenuEntry: Identifiable {
    let id: String
    let entry: MenuEntry
}

private extension MenuEntryStyle {
    var id: String {
        switch self {
        case .header:
            "header"
        case .primary:
            "primary"
        case .secondary:
            "secondary"
        case .warning:
            "warning"
        case .system:
            "system"
        }
    }
}

private struct PopoverPortRow: View {
    let port: PortInfo
    let category: PortCategory?
    let technology: String?
    let projectName: String?
    let onTerminate: (Int, Bool) -> Void

    @State private var isExpanded = false

    private var safetyIcon: String {
        port.safety?.icon ?? (port.isSystemProcess ? "🔴" : "⚪")
    }

    private var riskColor: Color {
        if port.isSystemProcess {
            return Color.red.opacity(0.65)
        }

        switch port.safety {
        case .critical:
            return Color.red.opacity(0.65)
        case .important:
            return Color.orange.opacity(0.65)
        case .userCreated:
            return Color.blue.opacity(0.60)
        default:
            return Color.white.opacity(0.12)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(safetyIcon)
                        .font(.system(size: 13))

                    Text(":\(port.port)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)

                    Text(port.portProtocol.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.12), in: Capsule())

                    Text(port.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if port.isSystemProcess {
                        Text("System")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.red.opacity(0.95))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.14), in: Capsule())
                    }

                    if let category, category == .development, let projectName, shouldShowProjectTag(projectName) {
                        Text(projectName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.blue.opacity(0.95))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.16), in: Capsule())
                    }

                    Spacer(minLength: 4)

                    Text(port.age.icon)
                        .font(.system(size: 12))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    metadataLine("Safety", value: port.safety?.rawValue ?? "Unknown")
                    metadataLine("Age", value: port.age.rawValue)

                    if let uptime = port.formattedUptime {
                        metadataLine("Uptime", value: uptime)
                    }

                    if let category {
                        metadataLine("Category", value: category.rawValue)
                    }

                    if let technology {
                        metadataLine("Technology", value: technology)
                    }

                    if let projectName {
                        metadataLine("Project", value: projectName)
                    }

                    metadataLine("Process", value: port.processName)
                    metadataLine("PID", value: String(port.pid))

                    if let path = port.executablePath {
                        Text(path)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }

                    HStack(spacing: 8) {
                        Button(port.isSystemProcess ? "⚠️ Terminate (SIGTERM)" : "Terminate (SIGTERM)") {
                            onTerminate(port.pid, false)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(port.isSystemProcess ? .orange : .gray)

                        Button(port.isSystemProcess ? "⚠️ Force Kill (SIGKILL)" : "Force Kill (SIGKILL)") {
                            onTerminate(port.pid, true)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.red)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(riskColor, lineWidth: 1),
                ),
        )
    }

    private func metadataLine(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(label):")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.65))
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private func shouldShowProjectTag(_ projectName: String) -> Bool {
        let normalizedProject = projectName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedDisplay = port.displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !normalizedProject.isEmpty && normalizedProject != normalizedDisplay
    }
}
