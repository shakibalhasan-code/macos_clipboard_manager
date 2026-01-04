import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'screens/clipboard_panel.dart';
import 'services/clipboard_service.dart';
import 'services/hotkey_service.dart';
import 'services/storage_service.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Starting Clipboard Manager...');

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Enable launch at startup safely
  try {
    final packageInfo = await PackageInfo.fromPlatform();

    // Get the .app bundle path from the executable path
    // executable: /path/to/App.app/Contents/MacOS/App
    // desired: /path/to/App.app
    String appPath = Platform.resolvedExecutable;
    if (appPath.contains('.app/Contents/MacOS')) {
      appPath = appPath.substring(0, appPath.indexOf('.app') + 4);
    }

    LaunchAtStartup.instance.setup(
      appName: packageInfo.appName,
      appPath: appPath,
    );

    await LaunchAtStartup.instance.enable();
    debugPrint('✓ Launch at startup enabled');
  } catch (e) {
    debugPrint('⚠️ Failed to enable launch at startup: $e');
  }

  // Configure window options
  const windowOptions = WindowOptions(
    size: Size(420, 550),
    minimumSize: Size(350, 400),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    debugPrint('✓ Window ready, configuring...');
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(true);
    await windowManager.setBackgroundColor(Colors.transparent);
    // Don't show here - wait for UI to be ready
  });

  // Initialize services
  debugPrint('Initializing services...');
  final storageService = StorageService();
  await storageService.init();
  debugPrint('✓ Storage service initialized');

  final clipboardService = ClipboardService(storageService);
  clipboardService.startMonitoring();
  debugPrint('✓ Clipboard monitoring started');

  final hotkeyService = HotkeyService();

  runApp(
    ClipboardManagerApp(
      storageService: storageService,
      clipboardService: clipboardService,
      hotkeyService: hotkeyService,
    ),
  );
}

class ClipboardManagerApp extends StatefulWidget {
  final StorageService storageService;
  final ClipboardService clipboardService;
  final HotkeyService hotkeyService;

  const ClipboardManagerApp({
    super.key,
    required this.storageService,
    required this.clipboardService,
    required this.hotkeyService,
  });

  @override
  State<ClipboardManagerApp> createState() => _ClipboardManagerAppState();
}

class _ClipboardManagerAppState extends State<ClipboardManagerApp>
    with WindowListener {
  bool _isHotkeyRegistered = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    debugPrint('App state initialized');

    // Delay hotkey registration and window showing to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _registerHotkey();

      // Show window only after UI is ready to avoid black screen
      debugPrint('UI ready, showing window...');
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Future<void> _registerHotkey() async {
    if (_isHotkeyRegistered) return;

    try {
      debugPrint('Registering hotkey...');
      await widget.hotkeyService.register(
        onPressed: () async {
          debugPrint('Hotkey pressed!');
          await widget.hotkeyService.toggleWindow();
        },
      );
      _isHotkeyRegistered = true;
      debugPrint('✓ Hotkey registered successfully (⌘+Shift+V)');
    } catch (e) {
      debugPrint('⚠️ Failed to register hotkey: $e');
      // Don't crash the app, just log the error
    }
  }

  @override
  void dispose() {
    debugPrint('App disposing...');
    windowManager.removeListener(this);
    widget.clipboardService.dispose();
    widget.hotkeyService.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Prevent window from closing - just hide it instead
    debugPrint('Window close requested, hiding instead');
    await windowManager.hide();
  }

  @override
  void onWindowEvent(String eventName) {
    debugPrint('Window event: $eventName');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clipboard Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: ClipboardPanel(
          storageService: widget.storageService,
          clipboardService: widget.clipboardService,
        ),
      ),
    );
  }
}
