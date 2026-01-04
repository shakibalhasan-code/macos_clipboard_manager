import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:uuid/uuid.dart';
import '../models/clipboard_item.dart';
import 'storage_service.dart';

/// Service for monitoring clipboard changes
class ClipboardService {
  final StorageService _storageService;
  Timer? _pollTimer;
  String? _lastContentHash;
  bool _isMonitoring = false;

  /// Polling interval in milliseconds
  static const int pollInterval = 500;

  /// Callback when new content is detected
  final StreamController<ClipboardItem> _onNewItemController =
      StreamController<ClipboardItem>.broadcast();

  Stream<ClipboardItem> get onNewItem => _onNewItemController.stream;

  ClipboardService(this._storageService);

  /// Start monitoring the clipboard
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Initial check
    _checkClipboard();

    // Start polling
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: pollInterval),
      (_) => _checkClipboard(),
    );
  }

  /// Stop monitoring the clipboard
  void stopMonitoring() {
    _isMonitoring = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Check clipboard for new content
  Future<void> _checkClipboard() async {
    try {
      // Try to read text first
      final textContent = await Clipboard.getData(Clipboard.kTextPlain);

      if (textContent?.text != null && textContent!.text!.isNotEmpty) {
        final content = textContent.text!;
        final contentHash = content.hashCode.toString();

        if (contentHash != _lastContentHash) {
          _lastContentHash = contentHash;
          await _addTextItem(content);
          return;
        }
      }

      // Try to read image
      final imageBytes = await Pasteboard.image;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        // Simple hash check for images
        final imageHash = _computeImageHash(imageBytes);
        if (imageHash != _lastContentHash) {
          _lastContentHash = imageHash;
          await _addImageItem(imageBytes);
        }
      }
    } catch (e) {
      // Silently handle clipboard access errors
      // This can happen if clipboard is locked by another app
    }
  }

  /// Add a text item to history
  Future<void> _addTextItem(String content) async {
    final item = ClipboardItem.text(id: const Uuid().v4(), content: content);

    await _storageService.add(item);
    _onNewItemController.add(item);
  }

  /// Add an image item to history
  Future<void> _addImageItem(Uint8List imageData) async {
    final item = ClipboardItem.image(
      id: const Uuid().v4(),
      imageData: imageData,
    );

    await _storageService.add(item);
    _onNewItemController.add(item);
  }

  /// Compute a simple hash for image content
  String _computeImageHash(Uint8List bytes) {
    final bytesToHash = bytes.length > 1000 ? bytes.sublist(0, 1000) : bytes;
    return bytesToHash.fold(0, (prev, byte) => prev ^ byte).toString();
  }

  /// Copy a clipboard item's content back to clipboard
  Future<void> copyToClipboard(ClipboardItem item) async {
    if (item.type == ClipboardType.text && item.textContent != null) {
      await Clipboard.setData(ClipboardData(text: item.textContent!));
    } else if (item.type == ClipboardType.image && item.imageData != null) {
      await Pasteboard.writeImage(item.imageData!);
    }

    // Update the last hash to prevent re-adding
    _lastContentHash = item.contentHash;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _onNewItemController.close();
  }
}
