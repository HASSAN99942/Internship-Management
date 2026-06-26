import 'package:flutter/material.dart';

/// Section header + item list. Shows [emptyMessage] when [children] is empty.
class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    required this.children,
    this.emptyMessage = 'Nothing here yet.',
    this.onViewAll,
    this.viewAllLabel = 'View all',
  });

  final String title;
  final List<Widget> children;
  final String emptyMessage;
  final VoidCallback? onViewAll;
  final String viewAllLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(viewAllLabel),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              emptyMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          )
        else
          ...children,
      ],
    );
  }
}
