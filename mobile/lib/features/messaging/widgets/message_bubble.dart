import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.showSenderName = false,
  });

  final Message message;
  final bool isOwn;

  /// Show the sender's name above the bubble (first bubble in a group run).
  final bool showSenderName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = isOwn ? cs.primary : cs.surfaceContainerHigh;
    final fg = isOwn ? cs.onPrimary : cs.onSurface;

    // Own message: tail at bottom-right (small radius). Others: bottom-left.
    final bubbleShape = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isOwn ? 14 : 4),
      bottomRight: Radius.circular(isOwn ? 4 : 14),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: showSenderName ? 8 : 2,
        bottom: 2,
        left: 12,
        right: 12,
      ),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isOwn && showSenderName)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(
                    message.sender.fullName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: bubbleShape,
                ),
                child: Text(
                  message.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fg,
                    height: 1.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontSize: 10,
                      ),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 3),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 13,
                        color: message.isRead
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      return DateFormat.Hm().format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return '';
    }
  }
}
