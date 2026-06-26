import 'package:flutter/material.dart';

/// Compact stat card used in the 2-column metric grid on dashboard screens.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;

  /// Accent color for the icon chip. Defaults to `cs.primary`.
  final Color? color;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = color ?? cs.primary;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
