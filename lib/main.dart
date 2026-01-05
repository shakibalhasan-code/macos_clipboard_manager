import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'services/clipboard_service.dart';
import 'services/hotkey_service.dart';
import 'services/storage_service.dart';
import 'controllers/clipboard_controller.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Starting Clipboard Manager...');

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Enable launch at startup safely
  try {
    final packageInfo = await PackageInfo.fromPlatform();

    // Get the .app bundle path from the executable path
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

  // Initialize services with GetX for Dependency Injection
  debugPrint('Initializing services...');

  // Storage Service
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService);
  debugPrint('✓ Storage service initialized');

  // Clipboard Service
  final clipboardService = ClipboardService(storageService);
  clipboardService.startMonitoring();
  Get.put(clipboardService);
  debugPrint('✓ Clipboard monitoring started');

  // Hotkey Service
  final hotkeyService = HotkeyService();
  Get.put(hotkeyService);

  // Initialize Controller
  Get.put(ClipboardController());

  runApp(const ClipboardManagerApp());
}
