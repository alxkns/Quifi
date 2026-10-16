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
                    Label("Ordner", systemImage: "folder.badge.plus")
                }
                .tag(0)

            TriggerTab(prefsStore: prefsStore)
                .tabItem {
                    Label("Trigger", systemImage: "hand.tap")
                }
                .tag(1)

            ConflictsTab(prefsStore: prefsStore)
                .tabItem {
                    Label("Konflikte", systemImage: "doc.badge.gearshape")
                }
                .tag(2)

            GeneralTab(prefsStore: prefsStore, isAccessibilityGranted: $isAccessibilityGranted)
                .tabItem {
                    Label("Allgemein", systemImage: "gearshape")
                }
                .tag(3)
        }
        .frame(width: 520, height: 420)
        .padding()
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
            Text("Gepinnte Hauptordner")
                .font(.headline)

            Text("Diese Ordner erscheinen als oberste Ebene im QuiFi-HUD. Beim Hovern werden ihre Unterordner kaskadierend eingeblendet.")
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
                                .help("Dieser Ordner existiert nicht mehr.")
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
                    Label("Ordner hinzufügen…", systemImage: "plus")
                }

                Button(action: removeSelectedFolder) {
                    Label("Entfernen", systemImage: "minus")
                }
                .disabled(selectedFolderID == nil)

                Spacer()

                Text("\(prefsStore.preferences.pinnedFolders.count) Ordner")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Als Favorit wählen"

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
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Maus rütteln (Shake-to-Show)", isOn: $prefsStore.preferences.enableShakeTrigger)
                        .font(.system(size: 13, weight: .medium))

                    Text("Datei mit der Maus greifen und kurz hin- und her-schütteln, damit sich QuiFi am Cursor öffnet.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if prefsStore.preferences.enableShakeTrigger {
                        HStack {
                            Text("Empfindlichkeit:")
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
                .padding(.vertical, 6)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Modifier-Taste beim Ziehen halten", isOn: $prefsStore.preferences.enableModifierTrigger)
                        .font(.system(size: 13, weight: .medium))

                    Text("Datei im Finder greifen und die Taste gedrückt halten, um das HUD einzublenden.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if prefsStore.preferences.enableModifierTrigger {
                        Picker("Taste:", selection: $prefsStore.preferences.triggerModifier) {
                            ForEach(TriggerModifier.allCases, id: \.self) { modifier in
                                Text(modifier.rawValue).tag(modifier)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 220)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding()
    }

    private var sensitivityLabel: String {
        let val = prefsStore.preferences.shakeSensitivity
        if val <= 25 { return "Hoch" }
        if val <= 40 { return "Mittel" }
        return "Sanft"
    }
}

// MARK: - Tab 3: Conflicts Tab
struct ConflictsTab: View {
    @ObservedObject var prefsStore: PreferencesStore

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dateikonflikte am Zielort")
                        .font(.headline)

                    Picker("Wenn die Datei bereits existiert:", selection: $prefsStore.preferences.conflictResolution) {
                        ForEach(ConflictResolution.allCases, id: \.self) { res in
                            Text(res.rawValue).tag(res)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Muster für automatisches Umbenennen:")
                            .font(.system(size: 12, weight: .medium))

                        Picker("Format:", selection: $prefsStore.preferences.renameFormat) {
                            ForEach(RenameFormat.allCases, id: \.self) { fmt in
                                Text(fmt.rawValue).tag(fmt)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 280)

                        Text("Beispiel: Aus 'Rechnung.pdf' wird 'Rechnung_1.pdf' oder 'Rechnung_2026-10-16.pdf'")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentColor)
                        Text("Tipp: Die Standard-Aktion ist immer 'Verschieben'. Hältst du beim Ablegen die Option-Taste (⌥) gedrückt, wird die Datei kopiert.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Tab 4: General Tab
struct GeneralTab: View {
    @ObservedObject var prefsStore: PreferencesStore
    @Binding var isAccessibilityGranted: Bool

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("System-Integration")
                        .font(.headline)

                    Toggle(
                        "Finder-Einstellung für versteckte Ordner übernehmen",
                        isOn: $prefsStore.preferences.respectSystemHiddenFiles
                    )

                    HStack {
                        Text("Status im Finder:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(FolderScanner.shared.isFinderShowingHiddenFiles ? "Versteckte Dateien sind sichtbar" : "Versteckte Dateien sind ausgeblendet")
                            .font(.caption)
                            .foregroundColor(FolderScanner.shared.isFinderShowingHiddenFiles ? .accentColor : .secondary)
                    }

                    Toggle(
                        "Haptisches Feedback beim Ablegen abspielen",
                        isOn: $prefsStore.preferences.playFeedback
                    )

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bedienungshilfen-Berechtigung (Accessibility)")
                            .font(.system(size: 13, weight: .medium))

                        Text("QuiFi benötigt diese Berechtigung, um globale Drag- und Modifier-Events im Hintergrund zu erkennen.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            if isAccessibilityGranted {
                                Label("Berechtigung erteilt", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Label("Berechtigung fehlt", systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red)

                                Button("Systemeinstellungen öffnen") {
                                    AccessibilityHelper.openSystemAccessibilityPreferences()
                                }
                            }

                            Spacer()

                            Button("Status prüfen") {
                                isAccessibilityGranted = AccessibilityHelper.isAccessibilityGranted
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
    }
}
