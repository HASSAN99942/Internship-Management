import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/message_thread.dart';

class ThreadListTile extends ConsumerWidget {
  const ThreadListTile({
    super.key,
    required this.thread,
    required this.onTap,
  });

  final MessageThreadRow thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentUser = ref.watch(currentUserProvider);

    final others = thread.participants
        .where((p) => p.id != currentUser?.id)
        .toList();
    final names =
        others.map((p) => p.fullName).join(', ');
    final initials = others.isEmpty
        ? '?'
        : others
            .map((p) => p.firstName.isNotEmpty ? p.firstName[0] : '?')
            .join('');

    final hasUnread = thread.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        child: Text(initials.toUpperCase()),
      ),
      title: Text(
        names.isNotEmpty ? names : thread.offerTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        thread.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: hasUnread
              ? cs.onSurface
              : cs.onSurface.withValues(alpha: 0.6),
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(thread.lastActivity),
            style: theme.textTheme.labelSmall?.copyWith(
              color: hasUnread
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.55),
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                thread.unreadCount > 99 ? '99+' : '${thread.unreadCount}',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dt.year, dt.month, dt.day);
      final diffDays = today.difference(msgDay).inDays;
      if (diffDays == 0) return DateFormat.Hm().format(dt);
      if (diffDays < 7) return DateFormat('EEE').format(dt);
      return DateFormat('dd/MM').format(dt);
    } catch (_) {
      return '';
    }
  }
}
