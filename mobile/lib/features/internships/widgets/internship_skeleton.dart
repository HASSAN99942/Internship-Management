import 'package:flutter/material.dart';

class InternshipSkeleton extends StatefulWidget {
  const InternshipSkeleton({super.key});

  @override
  State<InternshipSkeleton> createState() => _InternshipSkeletonState();
}

class _InternshipSkeletonState extends State<InternshipSkeleton>
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
        final color = Color.lerp(
          cs.surfaceContainerLow,
          cs.surfaceContainerHigh,
          _anim.value,
        )!;
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
                _box(width: 80, height: 22, radius: 12),
              ],
            ),
            const SizedBox(height: 10),
            _box(width: 200),
            const SizedBox(height: 10),
            _box(width: 160, height: 12),
          ],
        ),
      ),
    );
  }
}

class InternshipSkeletonList extends StatelessWidget {
  const InternshipSkeletonList({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < count - 1 ? 8 : 0),
          child: const InternshipSkeleton(),
        ),
      ),
    );
  }
}
