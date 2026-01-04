import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/clipboard_item.dart';

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

  /// Format the timestamp
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

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
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? const Color(0xFF4A4A4C) : const Color(0xFFE8E8ED))
                : (isDark ? const Color(0xFF3A3A3C) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: widget.item.isPinned
                ? Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
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
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content type icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  widget.item.type == ClipboardType.text
                      ? Icons.text_snippet_outlined
                      : Icons.image_outlined,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 12),

              // Content preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content
                    if (widget.item.type == ClipboardType.text)
                      Text(
                        widget.item.textContent ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      )
                    else if (widget.item.imageData != null)
                      ClipRRect(
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
                      ),
                    const SizedBox(height: 6),

                    // Timestamp
                    Text(
                      _formatTime(widget.item.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons (visible on hover)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isHovered ? 1 : 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Copy button
                    IconButton(
                      onPressed: widget.onTap,
                      icon: const Icon(Icons.content_copy, size: 16),
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(28, 28),
                      ),
                      tooltip: 'Copy',
                    ),

                    // Pin button
                    IconButton(
                      onPressed: widget.onPin,
                      icon: Icon(
                        widget.item.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: widget.item.isPinned
                            ? Theme.of(context).colorScheme.primary
                            : (isDark ? Colors.white54 : Colors.black38),
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(28, 28),
                      ),
                      tooltip: widget.item.isPinned ? 'Unpin' : 'Pin',
                    ),

                    // Delete button
                    IconButton(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.close, size: 18),
                      style: IconButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white54
                            : Colors.black38,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(28, 28),
                      ),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              ),

              // Pinned indicator (visible when not hovered)
              if (widget.item.isPinned && !_isHovered)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.push_pin,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
