import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/internships/data/models/internship.dart';
import '../../../features/internships/providers/internships_providers.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/metric_card.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final internshipsAsync = ref.watch(internshipsListProvider);
    final pendingAsync = ref.watch(pendingValidationsProvider);

    if (internshipsAsync.isLoading) {
      return const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: DashboardSkeleton(),
        ),
      );
    }

    if (internshipsAsync.hasError) {
      return Scaffold(
        body: _ErrorView(
          onRetry: () => ref.read(internshipsListProvider.notifier).load(),
        ),
      );
    }

    final internships = internshipsAsync.valueOrNull ?? [];
    final pending = pendingAsync.valueOrNull ?? [];
    final active = internships.where((i) => i.status == 'active').toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(internshipsListProvider.notifier).load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingHeader(
                name: user?.firstName,
                subtitle: "Here's your students overview.",
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  MetricCard(
                    label: 'Students',
                    value: '${internships.length}',
                    icon: Icons.people_outlined,
                    onTap: () => context.go('/teacher/students'),
                  ),
                  MetricCard(
                    label: 'To validate',
                    value: '${pending.length}',
                    icon: Icons.check_circle_outline,
                    color: pending.isNotEmpty ? kWarning : null,
                    onTap: () => context.go('/teacher/agreements'),
                  ),
                  MetricCard(
                    label: 'Active',
                    value: '${active.length}',
                    icon: Icons.school_outlined,
                    color: kSuccess,
                    onTap: () => context.go('/teacher/students'),
                  ),
                  MetricCard(
                    label: 'Total',
                    value: '${internships.length}',
                    icon: Icons.bar_chart_outlined,
                    onTap: () => context.go('/teacher/students'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DashboardSection(
                title: 'Agreements to validate',
                emptyMessage: 'No pending agreements — all up to date.',
                onViewAll: pending.isNotEmpty
                    ? () => context.go('/teacher/agreements')
                    : null,
                children: pending
                    .take(3)
                    .map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _InternshipTile(
                          internship: i,
                          onTap: () =>
                              context.push('/internships/${i.id}'),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (active.isNotEmpty) ...[
                const SizedBox(height: 16),
                DashboardSection(
                  title: 'Active internships',
                  emptyMessage: 'No active internships.',
                  onViewAll: () => context.go('/teacher/students'),
                  children: active
                      .take(3)
                      .map(
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _InternshipTile(
                            internship: i,
                            onTap: () =>
                                context.push('/internships/${i.id}'),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/teacher/agreements'),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Agreements'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/teacher/students'),
                      icon: const Icon(Icons.people_outlined, size: 18),
                      label: const Text('Students'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _InternshipTile extends StatelessWidget {
  const _InternshipTile({
    required this.internship,
    required this.onTap,
  });
  final Internship internship;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      internship.offerTitle,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      internship.student.fullName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: internship.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({this.name, required this.subtitle});
  final String? name;
  final String subtitle;

  static String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName =
        (name != null && name!.isNotEmpty) ? name! : 'there';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_timeGreeting()}, $displayName!',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            const Text('Could not load dashboard'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
