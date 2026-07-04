import OpenPortsCore
import SwiftUI

@MainActor
final class StatusPopoverModel: ObservableObject {
    @Published var descriptor = MenuDescriptor()
    @Published var favoritePorts: Set<Int> = []
    @Published var portCount = 0
    @Published var isLoading = false
    @Published var lastUpdatedAt: Date?
}

struct StatusPopoverView: View {
    @ObservedObject var model: StatusPopoverModel
    @State private var searchText = ""

    let onRefresh: () -> Void
    let onViewLogs: () -> Void
    let onShowPreferences: () -> Void
    let onQuit: () -> Void
    let onTerminate: (Int, Bool) -> Void
    let onToggleFavorite: (Int) -> Void
    let onExport: (ExportFormat) -> Void
    let onSearchChanged: (String) -> Void

    private var entries: [RenderableMenuEntry] {
        let flattenedEntries = model.descriptor.sections.flatMap(\.entries)
        return flattenedEntries.enumerated().map { index, entry in
            RenderableMenuEntry(
                id: stableEntryID(for: entry, index: index),
                entry: entry,
            )
        }
    }

    private var hasVisiblePortRows: Bool {
        entries.contains { item in
            if case .portRow = item.entry {
                return true
            }
            return false
        }
    }

    private var hasWarning: Bool {
        entries.contains { item in
            if case .text(_, style: .warning) = item.entry {
                return true
            }
            return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchField
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 440, height: 600)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            AppIconProvider.swiftUIImage(size: 30)
                .resizable()
                .frame(width: 30, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("OpenPorts")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                TimelineView(.periodic(from: .now, by: 30)) { _ in
                    Text(statusSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onRefresh) {
                Group {
                    if model.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.primary.opacity(0.05)))
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(model.isLoading)
            .keyboardShortcut("r", modifiers: .command)
            .help("Refresh (⌘R)")
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var statusSubtitle: String {
        if model.isLoading {
            return "Scanning…"
        }

        var parts = ["\(model.portCount) \(model.portCount == 1 ? "port" : "ports")"]

        if let date = model.lastUpdatedAt {
            if Date().timeIntervalSince(date) < 5 {
                parts.append("updated just now")
            } else {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                parts.append("updated \(formatter.localizedString(for: date, relativeTo: Date()))")
            }
        }

        return parts.joined(separator: " · ")
    }

    // MARK: Search

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)

            TextField("Search ports, processes, paths…", text: $searchText)
                .font(.system(size: 12))
                .textFieldStyle(.plain)
                .onChange(of: searchText) { _, newValue in
                    onSearchChanged(newValue)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    onSearchChanged("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.05)),
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if model.isLoading, !hasVisiblePortRows {
            stateContainer {
                ProgressView()
                Text("Scanning ports…")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        } else if !hasVisiblePortRows, !hasWarning {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(entries) { item in
                        entryView(item.entry)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
    }

    private var emptyState: some View {
        stateContainer {
            Image(systemName: searchText.isEmpty ? "checkmark.shield" : "magnifyingglass")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.tertiary)
            Text(searchText.isEmpty ? "No open ports" : "No matches")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            Text(searchText.isEmpty ? "Nothing is listening right now." : "Nothing matches “\(searchText)”.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func stateContainer(@ViewBuilder body: () -> some View) -> some View {
        VStack(spacing: 8) {
            body()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                Text(text)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    .padding(.horizontal, 2)
            case .warning:
                warningCard(text)
            default:
                Text(text)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .divider:
            Divider()
                .padding(.vertical, 2)

        case let .portRow(port, category, technology, projectName):
            PopoverPortRow(
                port: port,
                category: category,
                technology: technology,
                projectName: projectName,
                isFavorite: model.favoritePorts.contains(port.port),
                onTerminate: onTerminate,
                onToggleFavorite: { onToggleFavorite(port.port) },
            )

        case .refreshButton, .viewLogsButton, .preferencesButton, .button:
            EmptyView()
        }
    }

    private func warningCard(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.orange)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.orange.opacity(0.10)),
        )
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 2) {
            if hasVisiblePortRows {
                exportMenu
            }

            Spacer()

            FooterButton(title: "Logs", icon: "doc.text", action: onViewLogs)
            FooterButton(title: "Settings", icon: "gearshape", action: onShowPreferences)
            FooterButton(title: "Quit", icon: "power", action: onQuit)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var exportMenu: some View {
        Menu {
            ForEach(ExportFormat.allCases, id: \.self) { format in
                Button(format.displayName) {
                    onExport(format)
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 11, weight: .medium))
                Text("Export")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Export the current port list")
    }
}

private struct FooterButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isHovered ? .primary : .secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.07 : 0)),
            )
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
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
    let isFavorite: Bool
    let onTerminate: (Int, Bool) -> Void
    let onToggleFavorite: () -> Void

    @AppStorage(AppSettingsKey.killWarningLevel) private var killWarningLevel = AppSettings.defaultKillWarningLevel
    @AppStorage(AppSettingsKey.showNewProcessBadges) private var showNewProcessBadges = AppSettings.defaultShowNewProcessBadges

    @State private var isExpanded = false
    @State private var isHovered = false
    @State private var pendingForceKill: Bool?

    private var safetyColor: Color {
        if port.isSystemProcess {
            return .red
        }

        switch port.safety {
        case .critical:
            return .red
        case .important:
            return .orange
        case .userCreated:
            return .blue
        case .optional:
            return .green
        case nil:
            return .gray
        }
    }

    private var safetyLabel: String {
        port.safety?.rawValue ?? (port.isSystemProcess ? "System" : "Unknown")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                collapsedRow
            }
            .buttonStyle(.plain)

            if isExpanded {
                detailView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(backgroundOpacity)),
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var backgroundOpacity: Double {
        if isExpanded {
            return 0.06
        }
        return isHovered ? 0.07 : 0.04
    }

    private var collapsedRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(safetyColor)
                .frame(width: 7, height: 7)
                .help(safetyLabel)

            Text(verbatim: ":\(port.port)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)

            if port.portProtocol == .udp {
                tag("UDP", tint: .purple)
            }

            Text(port.displayName)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            if port.isSystemProcess {
                tag("System", tint: .gray)
            }

            if let category, category == .development, let projectName, shouldShowProjectTag(projectName) {
                tag(projectName, tint: .blue)
            }

            if showNewProcessBadges, port.isNew {
                tag("New", tint: .green)
            }

            Spacer(minLength: 8)

            if let uptime = port.formattedUptime {
                Text(uptime)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .help("Uptime: \(uptime) (\(port.age.rawValue))")
            }

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 11))
                    .foregroundStyle(isFavorite ? Color.yellow : Color.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isFavorite || isHovered ? 1 : 0)
            .help(isFavorite ? "Remove from favorites" : "Add to favorites")

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var detailView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .padding(.horizontal, -10)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 5) {
                detailRow("Process", port.processName)
                detailRow("PID", String(port.pid))
                detailRow("Safety", safetyLabel)
                detailRow("Age", port.age.rawValue)

                if let category {
                    detailRow("Category", category.rawValue)
                }

                if let technology {
                    detailRow("Technology", technology)
                }

                if let projectName {
                    detailRow("Project", projectName)
                }
            }

            if let path = port.executablePath {
                Text(path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }

            if port.isSystemProcess || port.safety == .critical {
                Label("Stopping this process may affect system stability.", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 8) {
                Button("Stop") {
                    requestTerminate(forceKill: false)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Send SIGTERM to PID \(port.pid)")

                Button("Force Kill") {
                    requestTerminate(forceKill: true)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
                .foregroundStyle(.red)
                .help("Send SIGKILL to PID \(port.pid)")

                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
        .padding(.bottom, 10)
        .confirmationDialog(
            confirmationTitle,
            isPresented: confirmationShown,
            titleVisibility: .visible,
        ) {
            Button(pendingForceKill == true ? "Force Kill" : "Stop", role: .destructive) {
                if let forceKill = pendingForceKill {
                    onTerminate(port.pid, forceKill)
                }
                pendingForceKill = nil
            }
            Button("Cancel", role: .cancel) {
                pendingForceKill = nil
            }
        } message: {
            Text(confirmationMessage)
        }
    }

    private var confirmationShown: Binding<Bool> {
        Binding(
            get: { pendingForceKill != nil },
            set: { isShown in
                if !isShown {
                    pendingForceKill = nil
                }
            },
        )
    }

    private var confirmationTitle: String {
        "\(pendingForceKill == true ? "Force kill" : "Stop") \(port.displayName)?"
    }

    private var confirmationMessage: String {
        let signal = pendingForceKill == true ? "SIGKILL" : "SIGTERM"
        let base = "PID \(port.pid) on port \(port.port) will receive \(signal)."
        if let warning = port.safety?.warningMessage {
            return "\(warning)\n\n\(base)"
        }
        return base
    }

    private var requiresConfirmation: Bool {
        switch killWarningLevel {
        case .none:
            false
        case .all:
            true
        case .highRiskOnly:
            port.isSystemProcess || port.safety == .critical || port.safety == .important
        }
    }

    private func requestTerminate(forceKill: Bool) {
        if requiresConfirmation {
            pendingForceKill = forceKill
        } else {
            onTerminate(port.pid, forceKill)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func tag(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(Capsule().fill(tint.opacity(0.14)))
    }

    private func shouldShowProjectTag(_ projectName: String) -> Bool {
        let normalizedProject = projectName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedDisplay = port.displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !normalizedProject.isEmpty && normalizedProject != normalizedDisplay
    }
}
