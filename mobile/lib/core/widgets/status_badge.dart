import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum _Variant { success, warning, info, neutral, destructive }

_Variant _variantFor(String status) {
  switch (status.toLowerCase()) {
    case 'published':
    case 'active':
    case 'validated':
    case 'accepted':
      return _Variant.success;
    case 'pending':
    case 'pending_academic_validation':
    case 'submitted':
    case 'changes_requested':
      return _Variant.warning;
    case 'in_progress':
    case 'info':
      return _Variant.info;
    case 'closed':
    case 'rejected':
    case 'cancelled':
      return _Variant.destructive;
    // draft, open, withdrawn, and anything else
    default:
      return _Variant.neutral;
  }
}

/// Colored chip that maps a domain status string to a visual variant.
/// Works in both light and dark mode — colours come from theme tokens only.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.label});

  final String status;

  /// Optional override label. Defaults to the raw status string with
  /// underscores replaced by spaces.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final variant = _variantFor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = _colors(variant, isDark);
    final text = label ?? status.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  static (Color bg, Color fg) _colors(_Variant v, bool isDark) {
    final a = isDark ? 0.20 : 0.12;
    switch (v) {
      case _Variant.success:
        return (kSuccess.withValues(alpha: a), kSuccess);
      case _Variant.warning:
        return (kWarning.withValues(alpha: a), kWarning);
      case _Variant.info:
        return (kInfo.withValues(alpha: a), kInfo);
      case _Variant.destructive:
        return (kDestructive.withValues(alpha: a), kDestructive);
      case _Variant.neutral:
        return (kNeutral.withValues(alpha: a), kNeutral);
    }
  }
}
