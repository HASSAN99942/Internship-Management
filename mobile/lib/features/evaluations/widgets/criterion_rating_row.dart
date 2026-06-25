import 'package:flutter/material.dart';
import '../data/models/evaluation.dart';

class CriterionRatingRow extends StatelessWidget {
  const CriterionRatingRow({
    super.key,
    required this.criterion,
    required this.value,
    this.onChanged,
  });

  final Criterion criterion;
  final int? value;
  final ValueChanged<int>? onChanged;

  bool get _readOnly => onChanged == null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasValue = value != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                criterion.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface
                      .withValues(alpha: _readOnly ? 0.55 : 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                hasValue
                    ? '$value / ${criterion.max}'
                    : '— / ${criterion.max}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: hasValue
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
          if (!_readOnly) ...[
            const SizedBox(height: 2),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: (value ?? criterion.min).toDouble(),
                min: criterion.min.toDouble(),
                max: criterion.max.toDouble(),
                divisions: criterion.max - criterion.min,
                label: '${value ?? criterion.min}',
                onChanged: (v) => onChanged!(v.round()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
