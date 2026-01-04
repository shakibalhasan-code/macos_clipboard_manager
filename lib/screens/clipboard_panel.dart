import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../models/clipboard_item.dart';
import '../services/clipboard_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../widgets/clipboard_item_widget.dart';
import '../widgets/permission_banner.dart';

/// Main clipboard panel screen
class ClipboardPanel extends StatefulWidget {
  final StorageService storageService;
  final ClipboardService clipboardService;

  const ClipboardPanel({
    super.key,
    required this.storageService,
    required this.clipboardService,
  });

  @override
  State<ClipboardPanel> createState() => _ClipboardPanelState();
}

class _ClipboardPanelState extends State<ClipboardPanel>
    with WindowListener, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final PermissionService _permissionService = PermissionService();
  List<ClipboardItem> _items = [];
  String _searchQuery = '';
  bool _hasPermission = false; // Start false to force check
  Timer? _permissionCheckTimer;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    _loadItems();
    _checkPermission();

    // Listen for new clipboard items
    widget.clipboardService.onNewItem.listen((_) {
      _loadItems();
    });

    // Listen for storage changes
    widget.storageService.changes.listen((_) {
      _loadItems();
    });

    // Periodically check permission while window is open
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkPermission();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed, checking permission...');
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _permissionService
        .checkAccessibilityPermission();
    debugPrint('Permission check result: $hasPermission');
    if (mounted && hasPermission != _hasPermission) {
      setState(() {
        _hasPermission = hasPermission;
      });
    }
  }

  @override
  void onWindowFocus() {
    _checkPermission();
  }

  void _loadItems() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _items = widget.storageService.getAll();
      } else {
        _items = widget.storageService.search(_searchQuery);
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _loadItems();
    });
  }

  Future<void> _onItemTap(ClipboardItem item) async {
    try {
      // Copy to clipboard
      await widget.clipboardService.copyToClipboard(item);

      // Show feedback without hiding window
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.type == ClipboardType.text
                  ? 'Copied to clipboard'
                  : 'Image copied',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            width: 200,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying item: $e');
    }
  }

  Future<void> _onItemDelete(ClipboardItem item) async {
    await widget.storageService.remove(item.id);
    _loadItems();
  }

  Future<void> _onItemPin(ClipboardItem item) async {
    await widget.storageService.togglePin(item.id);
    _loadItems();
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Remove all unpinned items from clipboard history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.clearHistory();
      _loadItems();
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    _permissionCheckTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinnedItems = _items.where((i) => i.isPinned).toList();
    final unpinnedItems = _items.where((i) => !i.isPinned).toList();

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        // Hide on Escape key
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          windowManager.hide();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2D2D2D).withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header with search
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Search field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'Search clipboard history...',
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearch('');
                                  },
                                  icon: const Icon(Icons.close, size: 18),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Clear history button
                    IconButton(
                      onPressed: _items.isEmpty ? null : _clearHistory,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Clear history',
                      style: IconButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white54
                            : Colors.black45,
                      ),
                    ),

                    // Settings/close button
                    IconButton(
                      onPressed: () => windowManager.hide(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close (Esc)',
                      style: IconButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white54
                            : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),

              // Permission banner
              PermissionBanner(hasPermission: _hasPermission),

              // Content
              Expanded(
                child: _items.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          // Pinned section
                          if (pinnedItems.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.push_pin,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pinned',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...pinnedItems.map(
                              (item) => ClipboardItemWidget(
                                item: item,
                                onTap: () => _onItemTap(item),
                                onDelete: () => _onItemDelete(item),
                                onPin: () => _onItemPin(item),
                              ),
                            ),
                            if (unpinnedItems.isNotEmpty)
                              Divider(
                                height: 24,
                                indent: 16,
                                endIndent: 16,
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1),
                              ),
                          ],

                          // Recent section
                          if (unpinnedItems.isNotEmpty) ...[
                            if (pinnedItems.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  4,
                                ),
                                child: Text(
                                  'Recent',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ),
                              ),
                            ...unpinnedItems.map(
                              (item) => ClipboardItemWidget(
                                item: item,
                                onTap: () => _onItemTap(item),
                                onDelete: () => _onItemDelete(item),
                                onPin: () => _onItemPin(item),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_items.length} items',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.keyboard_outlined,
                          size: 14,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '⌘⇧V to toggle',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.content_paste_off_outlined,
            size: 48,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No clipboard history yet'
                : 'No items match your search',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Copy something to get started',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
