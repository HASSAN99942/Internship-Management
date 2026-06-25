import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/models/offer.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.onTap,
    this.showStatus = false,
  });

  final Offer offer;
  final VoidCallback onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row + optional badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      offer.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showStatus) ...[
                    const SizedBox(width: 8),
                    StatusBadge(status: offer.status),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Company name
              Text(
                offer.company.companyName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              // Meta chips row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MetaChip(
                    icon: Icons.location_on_outlined,
                    label: offer.location,
                  ),
                  _MetaChip(
                    icon: Icons.schedule_outlined,
                    label: '${offer.durationWeeks}w',
                  ),
                  _MetaChip(
                    icon: Icons.people_outline,
                    label: '${offer.positions} position${offer.positions == 1 ? '' : 's'}',
                  ),
                  _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: _formatDate(offer.startDate),
                  ),
                ],
              ),
              if (offer.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  offer.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('MMM d, y').format(dt);
    } catch (_) {
      return isoDate;
    }
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
