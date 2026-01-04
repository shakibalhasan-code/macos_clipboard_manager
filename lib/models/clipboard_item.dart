import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'clipboard_item.g.dart';

/// Types of clipboard content
enum ClipboardType { text, image }

/// Represents a single clipboard history item
@HiveType(typeId: 0)
class ClipboardItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? textContent;

  @HiveField(2)
  final Uint8List? imageData;

  @HiveField(3)
  final int typeIndex; // Store enum as int for Hive

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? appSource;

  @HiveField(6)
  bool isPinned;

  ClipboardItem({
    required this.id,
    this.textContent,
    this.imageData,
    required this.typeIndex,
    required this.timestamp,
    this.appSource,
    this.isPinned = false,
  });

  /// Get the clipboard type
  ClipboardType get type => ClipboardType.values[typeIndex];

  /// Create a text clipboard item
  factory ClipboardItem.text({
    required String id,
    required String content,
    String? appSource,
  }) {
    return ClipboardItem(
      id: id,
      textContent: content,
      typeIndex: ClipboardType.text.index,
      timestamp: DateTime.now(),
      appSource: appSource,
    );
  }

  /// Create an image clipboard item
  factory ClipboardItem.image({
    required String id,
    required Uint8List imageData,
    String? appSource,
  }) {
    return ClipboardItem(
      id: id,
      imageData: imageData,
      typeIndex: ClipboardType.image.index,
      timestamp: DateTime.now(),
      appSource: appSource,
    );
  }

  /// Get a preview of the content (first 100 chars for text)
  String get preview {
    if (type == ClipboardType.text && textContent != null) {
      if (textContent!.length > 100) {
        return '${textContent!.substring(0, 100)}...';
      }
      return textContent!;
    }
    return '[Image]';
  }

  /// Generate a content hash for duplicate detection
  String get contentHash {
    if (type == ClipboardType.text && textContent != null) {
      return textContent.hashCode.toString();
    } else if (imageData != null) {
      // Use first 1000 bytes for image hash (performance optimization)
      final bytesToHash = imageData!.length > 1000
          ? imageData!.sublist(0, 1000)
          : imageData!;
      return bytesToHash.fold(0, (prev, byte) => prev ^ byte).toString();
    }
    return '';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClipboardItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
