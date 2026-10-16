# QuiFi — Lightning-Fast Drag & Drop File Organizer for macOS

<p align="center">
  <img src="docs/images/AppIcon.png" width="128" height="128" alt="QuiFi Icon"><br>
  <a href="README.de.md">🇩🇪 Deutsche Version</a>
</p>

<p align="center">
  <b>Instant drag & drop file organization with cascading folder columns for macOS.</b><br>
  <i>Stop digging through nested Finder windows. Grab a file, shake your mouse or hold Command, and drop it straight into any subfolder in seconds.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-blue?logo=apple" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-6.0%2B-orange?logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%26%20Intel-purple" alt="Universal">
  <img src="https://img.shields.io/badge/Privacy-100%25%20Offline-brightgreen" alt="100% Offline">
</p>

---

## 💡 What is QuiFi?

Inspired by modern macOS productivity tools like *Dropover*, *Yoink*, and *Filee*, **QuiFi** solves the everyday friction of moving files into deeply nested directories:

1. **Grab** a file in Finder (e.g. from your **Downloads** folder or Desktop).
2. **Shake** your mouse briefly **or** hold down `⌘ Command`.
3. A sleek floating HUD opens directly at your cursor showing your **pinned favorite folders**.
4. Hovering over any folder instantly cascades into its subfolders using clean **Miller columns** (*Projects* → *2026* → *Q1*).
5. **Release** the mouse button — your file is instantly moved or copied!

```
[Cursor dragging file]
          │
          ▼  (Shake mouse or hold ⌘)
┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
│ Favorites         │ │ Projects          │ │ 2026              │
├───────────────────┤ ├───────────────────┤ ├───────────────────┤
│ 📁 Downloads      │ │ 📁 Archives       │ │ 📁 Q1             │
│ 📁 Projects    ───┼─► 📁 2025           │ │ 📁 Q2       ◄─────┼─ [DROP!]
│ 📁 Documents      │ │ 📁 2026        ───┼─► 📁 Q3             │
│ 📁 Desktop        │ │ 📁 Templates      │ │ 📁 Q4             │
└───────────────────┘ └───────────────────┘ └───────────────────┘
```

---

## ✨ Features

* **⚡ Instant HUD at Cursor:** 
  * **Shake-to-Show:** A natural shake of the mouse while dragging summons the HUD immediately.
  * **Modifier Key:** Alternatively hold `⌘ Command`, `⌥ Option`, or `⌃ Control` during any drag operation.
  * Fully customizable sensitivity and trigger behavior in Settings.
* **🗂️ Cascading Miller Columns:**
  * Hover over any folder to reveal its subfolders in a smooth, snappily cascading column.
  * Browse to arbitrary depths without cluttering your screen with Finder windows.
* **🔄 Move or Copy:**
  * **Move** by default (perfect for keeping your Downloads and Desktop clean).
  * Hold `⌥ Option` while dropping to switch dynamically to **Copy** mode (complete with a visual `+` badge).
* **🛡️ Smart Conflict Resolution:**
  * If a file already exists at the destination, QuiFi gives you quick control: **Replace**, **Auto-Rename**, or **Cancel**.
  * Flexible auto-renaming patterns:
    * Counter: `Filename_1.pdf` or `Filename (1).pdf`
    * Date: `Filename_2026-10-16.pdf`
    * Timestamp: `Filename_20261016_114000.pdf`
* **👁️ Respects Finder Visibility:**
  * Seamlessly reads your system Finder settings (`AppleShowAllFiles`) to hide or show dotfiles and hidden folders.
* **🪶 100% Native & Privacy-First:**
  * Built purely with **Swift** and **SwiftUI**.
  * Discreet menu bar utility (`LSUIElement`), no unnecessary Dock icon.
  * Runs entirely offline with zero network calls, zero telemetry, and 100% privacy.

---

## 🛠️ Download & Installation

### Option 1: Download Pre-built Release
1. Download the latest **`QuiFi.dmg`** or **`QuiFi-macOS.zip`** from [Releases](https://github.com/alxkns/Quifi/releases).
2. Open the DMG and drag **QuiFi.app** to your `/Applications` folder.
3. Launch QuiFi. Because QuiFi listens for global mouse drags and modifier keys, macOS will prompt you once to grant **Accessibility permissions** under *System Settings > Privacy & Security > Accessibility*.

### Option 2: Build from Source
QuiFi uses the standard Swift Package Manager:

```bash
git clone https://github.com/alxkns/Quifi.git
cd Quifi

# Run unit tests
swift test -Xswiftc -plugin-path -Xswiftc /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins

# Build .app and .dmg
./Scripts/build_dmg.sh
```

The completed build is generated at `build/QuiFi.app` and `build/QuiFi.dmg`.

---

## ⚙️ Settings & Configuration

Click the menu bar icon (`folder.badge.gearshape`) to open preferences:

* **Folders:** Add, reorder, or remove any number of root favorite folders from your disk.
* **Triggers:** Enable/disable mouse shake (with slider for sensitivity) and modifier key triggers.
* **Conflicts:** Configure default behavior for name collisions and choose your preferred rename template.
* **General:** Toggle haptic feedback on drop and verify Accessibility status.

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are very welcome!
Feel free to open an issue or submit a pull request:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for more information.
