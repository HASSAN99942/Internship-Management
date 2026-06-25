import 'package:flutter/material.dart';
import '../data/models/evaluation.dart';

class EvaluationSummaryCard extends StatelessWidget {
  const EvaluationSummaryCard({super.key, required this.summary});

  final EvaluationSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final chips = <_SummaryChipData>[];
    if (summary.company != null) {
      chips.add(_SummaryChipData(
          'Company', summary.company!.totalScore, cs.secondary));
    }
    if (summary.teacher != null) {
      chips.add(_SummaryChipData(
          'Academic', summary.teacher!.totalScore, cs.tertiary));
    }
    if (summary.combined != null) {
      chips.add(
          _SummaryChipData('Combined', summary.combined!, cs.primary));
    }

    return Card(
      color: cs.primaryContainer.withValues(alpha: 0.35),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evaluation summary',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map((d) => _SummaryChip(data: d))
                  .toList(),
            ),
            if (summary.student != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star_rounded,
                      size: 18,
                      color: cs.primary.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'Student rating: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                  Text(
                    summary.student!.totalScore.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  Text(
                    ' / 5',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5)),
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

class _SummaryChipData {
  const _SummaryChipData(this.label, this.score, this.color);
  final String label;
  final double score;
  final Color color;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.data});
  final _SummaryChipData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: data.color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            data.score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: data.color,
            ),
          ),
          Text(
            '/5',
            style: TextStyle(
              fontSize: 11,
              color: data.color.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
