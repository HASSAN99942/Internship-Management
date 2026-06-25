import 'package:flutter/material.dart';

/// Shimmer-style skeleton card shown while offer lists load.
class OfferSkeleton extends StatefulWidget {
  const OfferSkeleton({super.key});

  @override
  State<OfferSkeleton> createState() => _OfferSkeletonState();
}

class _OfferSkeletonState extends State<OfferSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final base = cs.surfaceContainerHighest;
        final highlight = cs.surfaceContainerHighest.withValues(alpha: 0.4);
        final color = Color.lerp(base, highlight, _anim.value)!;
        return _SkeletonCard(shimmerColor: color);
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.shimmerColor});
  final Color shimmerColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Bar(width: double.infinity, height: 18, color: shimmerColor),
            const SizedBox(height: 8),
            _Bar(width: 140, height: 13, color: shimmerColor),
            const SizedBox(height: 14),
            Row(
              children: [
                _Bar(width: 80, height: 22, color: shimmerColor),
                const SizedBox(width: 8),
                _Bar(width: 50, height: 22, color: shimmerColor),
                const SizedBox(width: 8),
                _Bar(width: 70, height: 22, color: shimmerColor),
              ],
            ),
            const SizedBox(height: 12),
            _Bar(width: double.infinity, height: 12, color: shimmerColor),
            const SizedBox(height: 6),
            _Bar(width: 200, height: 12, color: shimmerColor),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color});
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

/// A list of [count] skeleton cards.
class OfferSkeletonList extends StatelessWidget {
  const OfferSkeletonList({super.key, this.count = 5});
  final int count;

  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => const OfferSkeleton(),
      );
}
