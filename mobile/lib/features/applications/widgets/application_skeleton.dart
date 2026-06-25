import 'package:flutter/material.dart';

class ApplicationSkeleton extends StatefulWidget {
  const ApplicationSkeleton({super.key});

  @override
  State<ApplicationSkeleton> createState() => _ApplicationSkeletonState();
}

class _ApplicationSkeletonState extends State<ApplicationSkeleton>
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
      builder: (_, _) {
        final base = cs.surfaceContainerLow;
        final highlight = cs.surfaceContainerHigh;
        final color = Color.lerp(base, highlight, _anim.value)!;
        return _SkeletonCard(color: color);
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.color});
  final Color color;

  Widget _box({double? width, double height = 14, double radius = 6}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _box(height: 16)),
                const SizedBox(width: 12),
                _box(width: 72, height: 22, radius: 12),
              ],
            ),
            const SizedBox(height: 8),
            _box(width: 140),
            const SizedBox(height: 12),
            _box(width: 180, height: 12),
          ],
        ),
      ),
    );
  }
}

class ApplicationSkeletonList extends StatelessWidget {
  const ApplicationSkeletonList({super.key, this.count = 5});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < count - 1 ? 8 : 0),
          child: const ApplicationSkeleton(),
        ),
      ),
    );
  }
}
