import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/clipboard_item.dart';

/// Service for persisting clipboard history using Hive
class StorageService {
  static const String _boxName = 'clipboard_history';
  late Box<ClipboardItem> _box;
  bool _isInitialized = false;

  /// Maximum number of items to store
  static const int maxItems = 50;

  /// Initialize the storage service
  Future<void> init() async {
    if (_isInitialized) return;

    final appDir = await getApplicationSupportDirectory();
    await Hive.initFlutter(appDir.path);

    // Register adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ClipboardItemAdapter());
    }

    _box = await Hive.openBox<ClipboardItem>(_boxName);
    _isInitialized = true;
  }

  /// Get all clipboard items (newest first)
  List<ClipboardItem> getAll() {
    final items = _box.values.toList();
    // Sort by timestamp descending (newest first)
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  /// Get pinned items
  List<ClipboardItem> getPinned() {
    return getAll().where((item) => item.isPinned).toList();
  }

  /// Get unpinned items
  List<ClipboardItem> getUnpinned() {
    return getAll().where((item) => !item.isPinned).toList();
  }

  /// Add a new clipboard item
  Future<void> add(ClipboardItem item) async {
    // Check for duplicates (same content hash)
    final existingItems = getAll();
    final duplicate = existingItems
        .where((existing) => existing.contentHash == item.contentHash)
        .firstOrNull;

    if (duplicate != null) {
      // Remove old duplicate and add new one (updates timestamp)
      await duplicate.delete();
    }

    // Add new item
    await _box.put(item.id, item);

    // Enforce max items limit (keep pinned items)
    await _enforceLimit();
  }

  /// Remove a clipboard item
  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  /// Toggle pin status
  Future<void> togglePin(String id) async {
    final item = _box.get(id);
    if (item != null) {
      item.isPinned = !item.isPinned;
      await item.save();
    }
  }

  /// Clear all items (except pinned)
  Future<void> clearHistory() async {
    final unpinnedItems = getUnpinned();
    for (final item in unpinnedItems) {
      await item.delete();
    }
  }

  /// Clear all items including pinned
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Enforce the maximum items limit
  Future<void> _enforceLimit() async {
    final unpinned = getUnpinned();

    // Only trim unpinned items
    if (unpinned.length > maxItems) {
      // Remove oldest items beyond the limit
      final toRemove = unpinned.skip(maxItems).toList();
      for (final item in toRemove) {
        await item.delete();
      }
    }
  }

  /// Get item by ID
  ClipboardItem? getById(String id) {
    return _box.get(id);
  }

  /// Search items by content
  List<ClipboardItem> search(String query) {
    if (query.isEmpty) return getAll();

    final lowercaseQuery = query.toLowerCase();
    return getAll().where((item) {
      if (item.textContent != null) {
        return item.textContent!.toLowerCase().contains(lowercaseQuery);
      }
      return false;
    }).toList();
  }

  /// Get total item count
  int get count => _box.length;

  /// Stream of changes (for reactive updates)
  Stream<BoxEvent> get changes => _box.watch();
}
