# MacClip - The Modern macOS Clipboard Manager 📋

[![Platform](https://img.shields.io/badge/Platform-macOS-black?style=flat-square&logo=apple)](https://apple.com/macos)
[![Built With](https://img.shields.io/badge/Built%20With-Flutter-blue?style=flat-square&logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

**MacClip** is a lightweight, blazing-fast, and beautiful clipboard manager for macOS, designed to boost your productivity. It runs silently in the background, remembering everything you copy so you never lose a link, text snippet, or image again.

![MacClip Demo](https://via.placeholder.com/800x450.png?text=MacClip+Preview)
*(Replace with actual screenshot)*

## ✨ Features

- **🚀 Infinite History**: Automatically saves text and images copied to your clipboard.
- **⚡️ Global Hotkey**: Press `⌘ + Shift + V` anywhere to open your history instantly.
- **🔍 Smart Search**: Find that lost link or snippet in milliseconds.
- **📌 Pin Favorites**: Keep important items at the top of your list.
- **🖼 Image Support**: Preview copied images directly in the history.
- **🌙 Dark Mode**: Native macOS look and feel, supporting both Light and Dark themes.
- **🔄 Persistent**: Runs in the background and launches automatically at login.

## 📥 Installation

### Option 1: Download DMG
1. Download the latest `ClipboardManager.dmg` from the [Releases](#) page.
2. Drag **Clipboard Manager** to your **Applications** folder.
3. Open the app.
4. Grant **Accessibility Permissions** when prompted (Required to detect the hotkey).

### Option 2: Build from Source
```bash
git clone https://github.com/yourusername/mac-clipboard-manager.git
cd mac-clipboard-manager
flutter pub get
flutter build macos --release
```

## 🛠 Usage settings

1. **Open History**: `Cmd + Shift + V`
2. **Paste Item**: Click any item to copy it back to your clipboard.
3. **Pin Item**: Click the pin icon to save it permanently.
4. **Delete Item**: Click the trash icon to remove it.

## 🔐 Privacy & Permissions

**MacClip** values your privacy.
- **Offline First**: All clipboard history is stored locally on your machine.
- **No Tracking**: No data is sent to the cloud.
- **Accessibility Permission**: Required solely to detect the global hotkey (`⌘+Shift+V`) even when the app is in the background.

## 🤝 Contributing

Contributions are welcome! If you have ideas for new features or bug fixes, feel free to open an issue or submit a pull request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
*Keywords: macOS clipboard manager, clipboard history, productivity tool, flutter macos app, copy paste tool, clipboard extender, mac utility*
