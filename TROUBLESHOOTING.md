# Troubleshooting

## "App cannot be opened because the developer cannot be verified"

![Gatekeeper Warning](https://docs.flutter.dev/assets/images/docs/get-started/macos/gatekeeper.png)

### The Issue
You see a warning saying:
> "Clipboard Manager" cannot be opened because the developer cannot be verified.
> macOS cannot verify that this app is free from malware.

This happens because the app is **open-source** and has not been signed with a paid Apple Developer ID (which costs $99/year).

### The Solution

1. Click **Done** or **Cancel** on the warning dialog.
2. Go to your **Applications** folder.
3. **Right-click** (or Control-click) on `Clipboard Manager.app`.
4. Select **Open** from the menu.
5. You will see a new dialog box asking if you're sure you want to open it.
6. Click **Open**.

> **Note**: You only need to do this **once**. After the first time, you can open the app normally by double-clicking.

### Alternative Method (System Settings)
1. Open **System Settings**.
2. Go to **Privacy & Security**.
3. Scroll down to the "Security" section.
4. You should see a message about "Clipboard Manager". Click **Open Anyway**.
