import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_providers.dart';
import '../../messaging/providers/threads_provider.dart';
import '../data/models/internship.dart';
import '../providers/internships_providers.dart';
import '../widgets/tasks_section.dart';
import '../widgets/reports_section.dart';
import '../../evaluations/widgets/evaluations_section.dart';

class InternshipDetailScreen extends ConsumerWidget {
  const InternshipDetailScreen({super.key, required this.internshipId});
  final int internshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(internshipDetailProvider(internshipId));

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              const Text('Could not load internship'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(internshipDetailProvider(internshipId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (dashboard) => _InternshipDetailView(dashboard: dashboard),
    );
  }
}

class _InternshipDetailView extends ConsumerWidget {
  const _InternshipDetailView({required this.dashboard});
  final InternshipDashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final internship = dashboard.internship;
    final user = ref.watch(currentUserProvider);
    final canValidate =
        (user?.role == 'teacher' || user?.role == 'admin') &&
            internship.status == 'pending_academic_validation';

    final tabBar = TabBar(
      tabs: const [
        Tab(icon: Icon(Icons.task_outlined), text: 'Tasks'),
        Tab(icon: Icon(Icons.description_outlined), text: 'Reports'),
        Tab(icon: Icon(Icons.star_outline_rounded), text: 'Evaluations'),
      ],
      labelColor: cs.primary,
      indicatorColor: cs.primary,
      dividerColor: cs.outlineVariant,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          internship.offerTitle,
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          if (internship.status == 'active') _ChatButton(internshipId: internship.id),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatusBadge(status: internship.status),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Parties card
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Participants',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _PartyRow(
                            icon: Icons.person_outline,
                            role: 'Student',
                            name: internship.student.fullName,
                            email: internship.student.email,
                            color: cs.primary,
                          ),
                          const Divider(height: 20),
                          _PartyRow(
                            icon: Icons.business_outlined,
                            role: 'Company',
                            name: internship.company.fullName,
                            email: internship.company.email,
                            color: cs.secondary,
                          ),
                          if (internship.teacher != null) ...[
                            const Divider(height: 20),
                            _PartyRow(
                              icon: Icons.school_outlined,
                              role: 'Supervisor',
                              name: internship.teacher!.fullName,
                              email: internship.teacher!.email,
                              color: cs.tertiary,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dates + progress row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Timeline',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                _DateRow(label: 'Start', iso: internship.startDate),
                                const SizedBox(height: 6),
                                _DateRow(label: 'End', iso: internship.endDate),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Progress',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                _ProgressRow(
                                  label: 'Tasks',
                                  validated: dashboard.progress.tasksValidated,
                                  total: dashboard.progress.tasksTotal,
                                  pct: dashboard.progress.tasksValidatedPct,
                                ),
                                const SizedBox(height: 8),
                                _ProgressRow(
                                  label: 'Reports',
                                  validated: dashboard.progress.reportsValidated,
                                  total: dashboard.progress.reportsTotal,
                                  pct: dashboard.progress.reportsValidatedPct,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Validate action (teacher/admin, pending state)
                    if (canValidate) ...[
                      const SizedBox(height: 12),
                      _ValidateButton(
                        internshipId: internship.id,
                        offerTitle: internship.offerTitle,
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // Sticky tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(tabBar),
            ),
          ],
          body: TabBarView(
            children: [
              TasksSection(internship: internship),
              ReportsSection(internship: internship),
              EvaluationsSection(
                internshipId: internship.id,
                status: internship.status,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Validate button
// ---------------------------------------------------------------------------

class _ValidateButton extends ConsumerWidget {
  const _ValidateButton({
    required this.internshipId,
    required this.offerTitle,
  });
  final int internshipId;
  final String offerTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _confirm(context, ref),
        icon: const Icon(Icons.verified_outlined),
        label: const Text('Validate agreement'),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validate agreement?'),
        content: Text(
          '"$offerTitle" will become active and monitoring will begin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Validate'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(internshipsListProvider.notifier)
            .validate(internshipId);
        ref.invalidate(internshipDetailProvider(internshipId));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  const _PartyRow({
    required this.icon,
    required this.role,
    required this.name,
    required this.email,
    required this.color,
  });
  final IconData icon;
  final String role;
  final String name;
  final String email;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$role · $email',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.iso});
  final String label;
  final String iso;

  static String _fmt(String iso) {
    try {
      return DateFormat('MMMM d, y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
        ),
        Text(
          _fmt(iso),
          style: theme.textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.validated,
    required this.total,
    required this.pct,
  });
  final String label;
  final int validated;
  final int total;
  final int pct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
            Text('$validated/$total',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : pct / 100,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chat icon button — derives thread ID from the loaded threads list.
// ---------------------------------------------------------------------------

class _ChatButton extends ConsumerWidget {
  const _ChatButton({required this.internshipId});
  final int internshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadId = ref.watch(threadIdByInternshipProvider(internshipId));
    return IconButton(
      icon: const Icon(Icons.chat_bubble_outline),
      tooltip: 'Open conversation',
      onPressed: threadId != null
          ? () => context.push('/threads/$threadId')
          : null,
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => tabBar != old.tabBar;
}
