import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/clipboard_item.dart';
import '../utils/date_time_utils.dart';

/// Widget to display a single clipboard item
class ClipboardItemWidget extends StatefulWidget {
  final ClipboardItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  const ClipboardItemWidget({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onPin,
  });

  @override
  State<ClipboardItemWidget> createState() => _ClipboardItemWidgetState();
}

class _ClipboardItemWidgetState extends State<ClipboardItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: _buildDecoration(context, isDark),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeIcon(context, isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContent(context, isDark),
                    const SizedBox(height: 6),
                    _buildTimestamp(isDark),
                  ],
                ),
              ),
              _buildActionButtons(context, isDark),
              if (widget.item.isPinned && !_isHovered)
                _buildPinnedIndicator(context),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(BuildContext context, bool isDark) {
    return BoxDecoration(
      color: _isHovered
          ? (isDark ? const Color(0xFF4A4A4C) : const Color(0xFFE8E8ED))
          : (isDark ? const Color(0xFF3A3A3C) : Colors.white),
      borderRadius: BorderRadius.circular(10),
      border: widget.item.isPinned
          ? Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildTypeIcon(BuildContext context, bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        widget.item.type == ClipboardType.text
            ? Icons.text_snippet_outlined
            : Icons.image_outlined,
        size: 18,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    if (widget.item.type == ClipboardType.text) {
      return Text(
        widget.item.textContent ?? '',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.4,
        ),
      );
    } else if (widget.item.imageData != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          widget.item.imageData!,
          height: 60,
          width: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 60,
            width: 80,
            color: Colors.grey.shade800,
            child: const Icon(Icons.broken_image, size: 24),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTimestamp(bool isDark) {
    return Text(
      DateTimeUtils.formatTime(widget.item.timestamp),
      style: TextStyle(
        fontSize: 11,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: _isHovered ? 1 : 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconButton(
            context,
            icon: Icons.content_copy,
            onPressed: widget.onTap,
            tooltip: 'Copy',
            color: Theme.of(context).colorScheme.primary,
          ),
          _buildIconButton(
            context,
            icon: widget.item.isPinned
                ? Icons.push_pin
                : Icons.push_pin_outlined,
            onPressed: widget.onPin,
            tooltip: widget.item.isPinned ? 'Unpin' : 'Pin',
            color: widget.item.isPinned
                ? Theme.of(context).colorScheme.primary
                : (isDark ? Colors.white54 : Colors.black38),
          ),
          _buildIconButton(
            context,
            icon: Icons.close,
            onPressed: widget.onDelete,
            tooltip: 'Remove',
            color: isDark ? Colors.white54 : Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      style: IconButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.all(6),
        minimumSize: const Size(28, 28),
      ),
      tooltip: tooltip,
    );
  }

  Widget _buildPinnedIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Icon(
        Icons.push_pin,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
