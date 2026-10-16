import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var prefsStore = PreferencesStore.shared
    @State private var isAccessibilityGranted: Bool = AccessibilityHelper.isAccessibilityGranted
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            PinnedFoldersTab(prefsStore: prefsStore)
                .tabItem {
                    Label("Folders", systemImage: "folder.badge.plus")
                }
                .tag(0)

            TriggerTab(prefsStore: prefsStore)
                .tabItem {
                    Label("Triggers", systemImage: "hand.tap")
                }
                .tag(1)

            ConflictsTab(prefsStore: prefsStore)
                .tabItem {
                    Label("Conflicts", systemImage: "doc.badge.gearshape")
                }
                .tag(2)

            GeneralTab(prefsStore: prefsStore, isAccessibilityGranted: $isAccessibilityGranted)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(3)
        }
        .frame(width: 550, height: 490)
        .onAppear {
            isAccessibilityGranted = AccessibilityHelper.isAccessibilityGranted
        }
    }
}

// MARK: - Tab 1: Pinned Folders
struct PinnedFoldersTab: View {
    @ObservedObject var prefsStore: PreferencesStore
    @State private var selectedFolderID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pinned Root Folders")
                .font(.headline)

            Text("These folders appear at the top level in the QuiFi HUD. Hover over any folder to cascade into its subfolders.")
                .font(.caption)
                .foregroundColor(.secondary)

            List(selection: $selectedFolderID) {
                ForEach(prefsStore.preferences.pinnedFolders) { folder in
                    HStack(spacing: 10) {
                        Image(systemName: folder.iconName)
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(folder.name)
                                .font(.system(size: 13, weight: .medium))

                            Text(folder.url.path)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()

                        if !folder.exists {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .help("This folder no longer exists.")
                        }
                    }
                    .padding(.vertical, 3)
                    .tag(folder.id)
                }
                .onDelete { offsets in
                    prefsStore.removePinnedFolder(at: offsets)
                }
                .onMove { source, destination in
                    prefsStore.movePinnedFolder(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .frame(maxHeight: .infinity)

            HStack {
                Button(action: addFolder) {
                    Label("Add Folder…", systemImage: "plus")
                }

                Button(action: removeSelectedFolder) {
                    Label("Remove", systemImage: "minus")
                }
                .disabled(selectedFolderID == nil)

                Spacer()

                let count = prefsStore.preferences.pinnedFolders.count
                Text("\(count) \(count == 1 ? "folder" : "folders")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Choose Favorite"

        if panel.runModal() == .OK {
            for url in panel.urls {
                prefsStore.addPinnedFolder(url: url)
            }
        }
    }

    private func removeSelectedFolder() {
        guard let id = selectedFolderID else { return }
        prefsStore.removePinnedFolder(id: id)
        selectedFolderID = nil
    }
}

// MARK: - Tab 2: Trigger Tab
struct TriggerTab: View {
    @ObservedObject var prefsStore: PreferencesStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Shake section
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Shake cursor (Shake-to-Show)", isOn: $prefsStore.preferences.enableShakeTrigger)
                        .font(.system(size: 13, weight: .medium))

                    Text("Grab a file with the cursor and shake it back and forth briefly to reveal QuiFi at your cursor.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if prefsStore.preferences.enableShakeTrigger {
                        HStack {
                            Text("Sensitivity:")
                                .font(.caption)
                            Slider(
                                value: $prefsStore.preferences.shakeSensitivity,
                                in: 15.0...60.0,
                                step: 5.0
                            )
                            Text(sensitivityLabel)
                                .font(.caption)
                                .frame(width: 55, alignment: .trailing)
                        }
                        .padding(.top, 4)
                    }
                }

                Divider()

                // Modifier section
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Hold modifier key while dragging", isOn: $prefsStore.preferences.enableModifierTrigger)
                        .font(.system(size: 13, weight: .medium))

                    Text("Grab a file in Finder and hold the modifier key to instantly reveal the HUD.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if prefsStore.preferences.enableModifierTrigger {
                        Picker("Key:", selection: $prefsStore.preferences.triggerModifier) {
                            ForEach(TriggerModifier.allCases, id: \.self) { modifier in
                                Text(modifier.rawValue).tag(modifier)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 220)
                    }
                }

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var sensitivityLabel: String {
        let val = prefsStore.preferences.shakeSensitivity
        if val <= 25 { return "High" }
        if val <= 40 { return "Medium" }
        return "Gentle"
    }
}

// MARK: - Tab 3: Conflicts Tab
struct ConflictsTab: View {
    @ObservedObject var prefsStore: PreferencesStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Destination File Conflicts")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("If a file with the same name already exists in destination:")
                        .font(.system(size: 12, weight: .medium))

                    Picker("", selection: $prefsStore.preferences.conflictResolution) {
                        ForEach(ConflictResolution.allCases, id: \.self) { res in
                            Text(res.rawValue).tag(res)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Automatic rename pattern:")
                        .font(.system(size: 12, weight: .medium))

                    Picker("Format:", selection: $prefsStore.preferences.renameFormat) {
                        ForEach(RenameFormat.allCases, id: \.self) { fmt in
                            Text(fmt.rawValue).tag(fmt)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 280)

                    Text("Example: 'Invoice.pdf' becomes 'Invoice_1.pdf' or 'Invoice_2026-10-16.pdf'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.accentColor)
                    Text("Tip: The default drop action is Move. Hold the Option (⌥) key while dropping to copy instead.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Tab 4: General Tab
struct GeneralTab: View {
    @ObservedObject var prefsStore: PreferencesStore
    @Binding var isAccessibilityGranted: Bool
    @ObservedObject var updateManager = UpdateManager.shared
    @State private var isFullDiskAccessGranted: Bool = FullDiskAccessHelper.isFullDiskAccessGranted

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Section 1: System Integration
                VStack(alignment: .leading, spacing: 10) {
                    Text("System Integration")
                        .font(.headline)

                    Toggle(
                        "Respect Finder hidden files setting",
                        isOn: $prefsStore.preferences.respectSystemHiddenFiles
                    )

                    HStack {
                        Text("Finder status:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(FolderScanner.shared.isFinderShowingHiddenFiles ? "Hidden files are visible" : "Hidden files are hidden")
                            .font(.caption)
                            .foregroundColor(FolderScanner.shared.isFinderShowingHiddenFiles ? .accentColor : .secondary)
                    }

                    Toggle(
                        "Play haptic feedback on drop",
                        isOn: $prefsStore.preferences.playFeedback
                    )

                    Picker("Menu Bar Icon:", selection: $prefsStore.preferences.menuBarIconStyle) {
                        ForEach(MenuBarIconStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 280)
                    .onChange(of: prefsStore.preferences.menuBarIconStyle) { _ in
                        MenuBarController.shared.updateIcon()
                    }
                }

                Divider()

                // Section 2: Accessibility
                VStack(alignment: .leading, spacing: 6) {
                    Text("Accessibility (Gestures & Shortcuts)")
                        .font(.system(size: 13, weight: .medium))

                    Text("Required to detect global drag gestures and modifier keys (e.g., holding ⌘ Command).")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        if isAccessibilityGranted {
                            Label("Permission granted", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Permission required", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)

                            Button("Open System Settings") {
                                AccessibilityHelper.openSystemAccessibilityPreferences()
                            }
                        }

                        Spacer()

                        Button("Check Status") {
                            isAccessibilityGranted = AccessibilityHelper.isAccessibilityGranted
                            if isAccessibilityGranted {
                                EventTapManager.shared.start()
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                Divider()

                // Section 3: Full Disk Access
                VStack(alignment: .leading, spacing: 6) {
                    Text("File Access (One-time for all folders)")
                        .font(.system(size: 13, weight: .medium))

                    Text("With Full Disk Access, QuiFi can organize files into any folder or subfolder without macOS prompting for permission every time.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        if isFullDiskAccessGranted {
                            Label("Full Disk Access granted (no prompts)", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Limited access (prompts per folder)", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)

                            Button("Open Full Disk Access Settings") {
                                FullDiskAccessHelper.openFullDiskAccessPreferences()
                            }
                        }

                        Spacer()

                        Button("Check Status") {
                            isFullDiskAccessGranted = FullDiskAccessHelper.isFullDiskAccessGranted
                        }
                    }
                    .padding(.top, 4)
                }

                Divider()

                // Section 4: Software Updates
                VStack(alignment: .leading, spacing: 8) {
                    Text("Software Updates")
                        .font(.system(size: 13, weight: .medium))

                    Toggle(
                        "Automatically check for updates daily",
                        isOn: $prefsStore.preferences.autoCheckForUpdates
                    )

                    HStack {
                        Button(action: {
                            Task {
                                await updateManager.checkForUpdates(manual: true)
                            }
                        }) {
                            if updateManager.isChecking {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Check for Updates")
                            }
                        }
                        .disabled(updateManager.isChecking || updateManager.isUpdating)

                        if !updateManager.statusMessage.isEmpty {
                            Text(updateManager.statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if updateManager.updateAvailable, let release = updateManager.latestRelease {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Version \(release.tagName) is available!", systemImage: "sparkles")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.green)

                                Spacer()

                                Button("Update Now") {
                                    Task {
                                        await updateManager.downloadAndInstallUpdate()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(updateManager.isUpdating)
                            }

                            if updateManager.isUpdating {
                                ProgressView(value: updateManager.downloadProgress)
                                    .progressViewStyle(.linear)
                            }
                        }
                        .padding(10)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
