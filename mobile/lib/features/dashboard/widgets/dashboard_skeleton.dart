import 'package:flutter/material.dart';

/// Placeholder skeleton shown while dashboard data is loading.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Bone(width: 180, height: 26),
        const SizedBox(height: 8),
        const _Bone(width: 240, height: 14),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: const [
            _MetricBone(),
            _MetricBone(),
            _MetricBone(),
            _MetricBone(),
          ],
        ),
        const SizedBox(height: 24),
        const _Bone(width: 140, height: 16),
        const SizedBox(height: 12),
        const _ItemBone(),
        const SizedBox(height: 8),
        const _ItemBone(),
        const SizedBox(height: 8),
        const _ItemBone(),
      ],
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _MetricBone extends StatelessWidget {
  const _MetricBone();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Spacer(),
            Container(
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 72,
              height: 12,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemBone extends StatelessWidget {
  const _ItemBone();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 100,
                    height: 11,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 60,
              height: 22,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
