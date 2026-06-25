import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/models/application.dart';

class ApplicationCard extends StatelessWidget {
  const ApplicationCard({
    super.key,
    required this.application,
    this.onTap,
    this.showStudent = false,
  });

  final Application application;
  final VoidCallback? onTap;

  /// When true, shows the student name (used in the company received view).
  /// When false, shows the offer title (used in the student own-applications view).
  final bool showStudent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String fmtDate(String iso) {
      try {
        return DateFormat('MMM d, y').format(DateTime.parse(iso));
      } catch (_) {
        return iso;
      }
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      showStudent
                          ? application.student.fullName
                          : application.offer.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: application.status),
                ],
              ),
              const SizedBox(height: 4),
              if (showStudent)
                Text(
                  application.offer.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  application.student.fullName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Applied ${fmtDate(application.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  if (application.cvFile != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.attach_file,
                      size: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'CV attached',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
