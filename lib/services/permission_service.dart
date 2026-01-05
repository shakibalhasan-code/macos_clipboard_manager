import 'dart:io';
import 'package:flutter/services.dart';

/// Service to manage macOS accessibility permissions
class PermissionService {
  static const _channel = MethodChannel(
    'com.clipboardmanager.macos/permissions',
  );

  /// Check if accessibility permission is granted
  Future<bool> checkAccessibilityPermission() async {
    try {
      final bool? isGranted = await _channel.invokeMethod<bool>(
        'checkAccessibilityPermission',
      );
      return isGranted ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Open System Preferences to Accessibility settings
  Future<void> openAccessibilitySettings() async {
    try {
      await Process.run('open', [
        'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility',
      ]);
    } catch (e) {
      // Just log internally or rethrow if needed
      // debugPrint('Failed to open settings: $e');
    }
  }
}
