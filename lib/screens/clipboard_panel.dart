import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import '../controllers/clipboard_controller.dart';
import '../models/clipboard_item.dart';
import '../widgets/clipboard_item_widget.dart';
import '../widgets/permission_banner.dart';

class ClipboardPanel extends GetView<ClipboardController> {
  const ClipboardPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is already injected
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
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
              _buildHeader(context, isDark),

              // Permission banner (Reactive)
              Obx(
                () => PermissionBanner(
                  hasPermission: controller.hasPermission.value,
                ),
              ),

              // Content (Reactive List)
              Expanded(
                child: Obx(() {
                  final items = controller.items;
                  if (items.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  final pinnedItems = items.where((i) => i.isPinned).toList();
                  final unpinnedItems = items
                      .where((i) => !i.isPinned)
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Pinned section
                      if (pinnedItems.isNotEmpty) ...[
                        _buildSectionHeader(context, 'Pinned', Icons.push_pin),
                        ...pinnedItems.map((item) => _buildItem(item)),
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
                          _buildSectionHeader(context, 'Recent', null, isDark),
                        ...unpinnedItems.map((item) => _buildItem(item)),
                      ],
                    ],
                  );
                }),
              ),

              // Footer
              _buildFooter(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
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
              onChanged: controller.onSearch,
              decoration: InputDecoration(
                hintText: 'Search clipboard history...',
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                suffixIcon: Obx(
                  () => controller.searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: controller.clearSearch,
                          icon: const Icon(Icons.close, size: 18),
                        )
                      : const SizedBox.shrink(),
                ),
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
          Obx(
            () => IconButton(
              onPressed: controller.items.isEmpty
                  ? null
                  : () => _confirmClearHistory(context),
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear history',
              style: IconButton.styleFrom(
                foregroundColor: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => windowManager.hide(),
            icon: const Icon(Icons.close),
            tooltip: 'Close (Esc)',
            style: IconButton.styleFrom(
              foregroundColor: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData? icon, [
    bool isDark = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: icon != null
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(ClipboardItem item) {
    return ClipboardItemWidget(
      item: item,
      onTap: () => controller.copyItem(item),
      onDelete: () => controller.deleteItem(item),
      onPin: () => controller.togglePin(item),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Obx(
            () => Text(
              '${controller.items.length} items',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
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
          Obx(
            () => Text(
              controller.searchQuery.isEmpty
                  ? 'No clipboard history yet'
                  : 'No items match your search',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          Obx(() {
            if (controller.searchQuery.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Copy something to get started',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
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
      controller.clearHistory();
    }
  }
}
