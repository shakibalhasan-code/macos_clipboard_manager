import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'controllers/clipboard_controller.dart';
import 'screens/clipboard_panel.dart';
import 'services/clipboard_service.dart';
import 'services/hotkey_service.dart';
import 'theme/theme.dart';

class ClipboardManagerApp extends StatefulWidget {
  const ClipboardManagerApp({super.key});

  @override
  State<ClipboardManagerApp> createState() => _ClipboardManagerAppState();
}

class _ClipboardManagerAppState extends State<ClipboardManagerApp>
    with WindowListener {
  bool _isHotkeyRegistered = false;
  final hotkeyService = Get.find<HotkeyService>();
  final clipboardController = Get.find<ClipboardController>();

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
      await hotkeyService.register(
        onPressed: () async {
          debugPrint('Hotkey pressed!');
          await hotkeyService.toggleWindow();
        },
      );
      _isHotkeyRegistered = true;
      debugPrint('✓ Hotkey registered successfully (⌘+Shift+V)');
    } catch (e) {
      debugPrint('⚠️ Failed to register hotkey: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('App disposing...');
    windowManager.removeListener(this);
    Get.find<ClipboardService>().dispose();
    hotkeyService.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Prevent window from closing - just hide it instead
    debugPrint('Window close requested, hiding instead');
    await windowManager.hide();
  }

  @override
  void onWindowFocus() {
    clipboardController.onWindowFocus();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Clipboard Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: const ClipboardPanel(),
      ),
    );
  }
}
