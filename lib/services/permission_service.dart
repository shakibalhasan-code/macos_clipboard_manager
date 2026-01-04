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
    // This is handled by the permission banner widget using Process.run
  }
}
