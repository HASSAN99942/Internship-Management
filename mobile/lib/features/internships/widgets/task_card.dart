import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/models/task.dart';

/// Single task row.
///
/// [onSubmit]     — student submits / resubmits (shown when open or changes_requested)
/// [onValidate]   — supervisor validates (shown when submitted)
/// [onRequestChanges] — supervisor requests changes (shown when submitted)
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onSubmit,
    this.onValidate,
    this.onRequestChanges,
  });

  final Task task;
  final VoidCallback? onSubmit;
  final VoidCallback? onValidate;
  final VoidCallback? onRequestChanges;

  static String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('MMM d, y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSubmitted = task.status == 'submitted';
    final canAct = task.status == 'open' || task.status == 'changes_requested';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: task.status),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13,
                    color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  'Due ${_fmtDate(task.dueDate)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            if (task.status == 'submitted' || task.status == 'changes_requested') ...[
              const SizedBox(height: 6),
              if (task.submissionNote.isNotEmpty)
                Text(
                  'Note: ${task.submissionNote}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (task.submissionFile != null) ...[
                const SizedBox(height: 4),
                _FileChip(url: buildMediaUrl(task.submissionFile!)),
              ],
            ],
            // Actions
            if (canAct && onSubmit != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSubmit,
                  child: Text(task.status == 'changes_requested'
                      ? 'Resubmit'
                      : 'Submit'),
                ),
              ),
            ],
            if (isSubmitted &&
                (onValidate != null || onRequestChanges != null)) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onValidate != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: onValidate,
                        child: const Text('Validate'),
                      ),
                    ),
                  if (onValidate != null && onRequestChanges != null)
                    const SizedBox(width: 8),
                  if (onRequestChanges != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRequestChanges,
                        child: const Text('Request changes'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.attach_file, size: 13,
            color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            url.split('/').last,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
