import 'package:flutter/material.dart';
import '../data/models/app_notification.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final unread = !notification.isRead;

    return Material(
      color: unread
          ? cs.surfaceContainerLow
          : cs.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(notification.type),
                  size: 20,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              // Message + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.payload.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            unread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (unread)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String type) => switch (type) {
        'application_received' => Icons.inbox_outlined,
        'application_accepted' => Icons.check_circle_outline,
        'application_rejected' => Icons.cancel_outlined,
        'agreement_to_validate' => Icons.verified_outlined,
        'internship_activated' => Icons.school_outlined,
        'task_assigned' => Icons.assignment_outlined,
        'task_submitted' => Icons.assignment_turned_in_outlined,
        'task_validated' => Icons.task_alt_outlined,
        'task_changes_requested' => Icons.edit_note_outlined,
        'report_submitted' => Icons.description_outlined,
        'report_validated' => Icons.fact_check_outlined,
        'report_changes_requested' => Icons.rate_review_outlined,
        'new_message' => Icons.chat_bubble_outline,
        'evaluation_submitted' => Icons.star_outline_rounded,
        _ => Icons.notifications_outlined,
      };

  static String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }
}
