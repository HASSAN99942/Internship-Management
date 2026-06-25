import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/models/report.dart';

/// Single report row.
///
/// [onValidate]       — supervisor validates (shown when submitted)
/// [onRequestChanges] — supervisor requests changes (shown when submitted)
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.onValidate,
    this.onRequestChanges,
  });

  final Report report;
  final VoidCallback? onValidate;
  final VoidCallback? onRequestChanges;

  static String _fmtDate(String iso) {
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
    final isSubmitted = report.status == 'submitted';

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Period: ${report.period}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 13,
                    color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  _fmtDate(report.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            if (report.file != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_file,
                      size: 13, color: cs.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      buildMediaUrl(report.file!).split('/').last,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (report.feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.comment_outlined,
                        size: 14,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report.feedback,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
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
