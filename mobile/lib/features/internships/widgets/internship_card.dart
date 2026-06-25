import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/models/internship.dart';

class InternshipCard extends StatelessWidget {
  const InternshipCard({
    super.key,
    required this.internship,
    this.onTap,
  });

  final Internship internship;
  final VoidCallback? onTap;

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
              // Offer title + badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      internship.offerTitle,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: internship.status),
                ],
              ),
              const SizedBox(height: 6),

              // Parties
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 14,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    internship.student.fullName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.business_outlined,
                      size: 14,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      internship.company.fullName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dates
              Row(
                children: [
                  Icon(Icons.date_range_outlined,
                      size: 12,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    '${fmtDate(internship.startDate)} → ${fmtDate(internship.endDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
