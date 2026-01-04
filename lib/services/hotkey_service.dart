import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Service for managing global hotkey registration
class HotkeyService {
  HotKey? _mainHotKey;
  bool _isRegistered = false;

  /// Callback when hotkey is pressed
  VoidCallback? onHotkeyPressed;

  /// The default hotkey: Command + Shift + V
  static final HotKey defaultHotKey = HotKey(
    key: PhysicalKeyboardKey.keyV,
    modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
    scope: HotKeyScope.system,
  );

  /// Initialize and register the hotkey
  Future<void> register({
    HotKey? customHotKey,
    required VoidCallback onPressed,
  }) async {
    if (_isRegistered) {
      await unregister();
    }

    _mainHotKey = customHotKey ?? defaultHotKey;
    onHotkeyPressed = onPressed;

    await hotKeyManager.register(
      _mainHotKey!,
      keyDownHandler: (_) => _handleHotKey(),
    );

    _isRegistered = true;
  }

  /// Handle hotkey press
  void _handleHotKey() {
    if (onHotkeyPressed != null) {
      onHotkeyPressed!();
    }
  }

  /// Unregister the hotkey
  Future<void> unregister() async {
    if (_mainHotKey != null && _isRegistered) {
      await hotKeyManager.unregister(_mainHotKey!);
      _isRegistered = false;
    }
  }

  /// Toggle window visibility
  Future<void> toggleWindow() async {
    final isVisible = await windowManager.isVisible();
    final isFocused = await windowManager.isFocused();

    if (isVisible && isFocused) {
      await hideWindow();
    } else {
      await showWindow();
    }
  }

  /// Show the window
  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// Hide the window
  Future<void> hideWindow() async {
    await windowManager.hide();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await unregister();
  }
}
