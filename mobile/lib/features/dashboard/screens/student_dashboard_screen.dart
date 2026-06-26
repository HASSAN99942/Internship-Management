import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../features/applications/providers/applications_providers.dart';
import '../../../features/applications/widgets/application_card.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/internships/data/models/task.dart';
import '../../../features/internships/providers/internships_providers.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/metric_card.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final appsAsync = ref.watch(myApplicationsProvider);
    final internshipsAsync = ref.watch(internshipsListProvider);

    if (appsAsync.isLoading || internshipsAsync.isLoading) {
      return const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: DashboardSkeleton(),
        ),
      );
    }

    if (appsAsync.hasError || internshipsAsync.hasError) {
      return Scaffold(
        body: _ErrorView(onRetry: () {
          ref.read(myApplicationsProvider.notifier).load();
          ref.read(internshipsListProvider.notifier).load();
        }),
      );
    }

    final apps = appsAsync.valueOrNull ?? [];
    final internships = internshipsAsync.valueOrNull ?? [];
    final activeList = internships.where((i) => i.status == 'active').toList();
    final activeInternship = activeList.isNotEmpty ? activeList.first : null;

    final detailAsync = activeInternship != null
        ? ref.watch(internshipDetailProvider(activeInternship.id))
        : null;

    final tasks = detailAsync?.valueOrNull?.tasks ?? [];
    final reports = detailAsync?.valueOrNull?.reports ?? [];
    final openTasks = tasks.where((t) => t.status == 'open').toList();
    final submittedReports =
        reports.where((r) => r.status == 'submitted').length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(myApplicationsProvider.notifier).load(),
            ref.read(internshipsListProvider.notifier).load(),
          ]);
          if (activeInternship != null) {
            ref.invalidate(internshipDetailProvider(activeInternship.id));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingHeader(
                name: user?.firstName,
                subtitle: "Here's your internship overview.",
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
                    label: 'Applications',
                    value:
                        '${apps.where((a) => a.status == 'pending').length}',
                    icon: Icons.description_outlined,
                    onTap: () => context.go('/student/applications'),
                  ),
                  MetricCard(
                    label: 'Internship',
                    value: activeInternship != null ? 'Active' : '—',
                    icon: Icons.school_outlined,
                    color: activeInternship != null ? kSuccess : null,
                    onTap: () => context.go('/student/internship'),
                  ),
                  MetricCard(
                    label: 'Open tasks',
                    value: '${openTasks.length}',
                    icon: Icons.task_alt_outlined,
                    onTap: activeInternship != null
                        ? () => context
                            .push('/internships/${activeInternship.id}')
                        : null,
                  ),
                  MetricCard(
                    label: 'Reports',
                    value: '$submittedReports',
                    icon: Icons.article_outlined,
                    onTap: activeInternship != null
                        ? () => context
                            .push('/internships/${activeInternship.id}')
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DashboardSection(
                title: 'Recent applications',
                emptyMessage:
                    'No applications yet — browse offers to get started.',
                onViewAll: apps.isNotEmpty
                    ? () => context.go('/student/applications')
                    : null,
                children: apps
                    .take(3)
                    .map(
                      (app) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ApplicationCard(
                          application: app,
                          onTap: () =>
                              context.push('/applications/${app.id}'),
                          showStudent: false,
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (activeInternship != null && openTasks.isNotEmpty) ...[
                const SizedBox(height: 16),
                DashboardSection(
                  title: 'Open tasks',
                  emptyMessage: 'All caught up — no open tasks.',
                  onViewAll: () =>
                      context.push('/internships/${activeInternship.id}'),
                  children: openTasks
                      .take(3)
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TaskTile(
                            task: t,
                            onTap: () => context
                                .push('/internships/${activeInternship.id}'),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/student/offers'),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Browse offers'),
                ),
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onTap});
  final Task task;
  final VoidCallback onTap;

  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String? dueDateLabel;
    if (task.dueDate != null) {
      try {
        dueDateLabel = _dateFmt.format(DateTime.parse(task.dueDate!));
      } catch (_) {}
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dueDateLabel != null)
                      Text(
                        'Due $dueDateLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: task.status),
            ],
          ),
        ),
      ),
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
