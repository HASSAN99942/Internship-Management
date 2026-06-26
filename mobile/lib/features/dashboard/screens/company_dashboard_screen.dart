import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../features/applications/providers/applications_providers.dart';
import '../../../features/applications/widgets/application_card.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/internships/data/models/internship.dart';
import '../../../features/internships/providers/internships_providers.dart';
import '../../../features/offers/providers/offers_providers.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/metric_card.dart';

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final offersAsync = ref.watch(myOffersProvider);
    final appsAsync = ref.watch(receivedApplicationsProvider);
    final internshipsAsync = ref.watch(internshipsListProvider);

    final isLoading = offersAsync.isLoading ||
        appsAsync.isLoading ||
        internshipsAsync.isLoading;
    final hasError = !isLoading &&
        (offersAsync.hasError ||
            appsAsync.hasError ||
            internshipsAsync.hasError);

    if (isLoading) {
      return const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: DashboardSkeleton(),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        body: _ErrorView(onRetry: () {
          ref.read(myOffersProvider.notifier).load();
          ref.read(receivedApplicationsProvider.notifier).load();
          ref.read(internshipsListProvider.notifier).load();
        }),
      );
    }

    final offers = offersAsync.valueOrNull ?? [];
    final apps = appsAsync.valueOrNull ?? [];
    final internships = internshipsAsync.valueOrNull ?? [];

    final activeOffers =
        offers.where((o) => o.status == 'published').length;
    final activeInterns =
        internships.where((i) => i.status == 'active').length;
    final pendingApps =
        apps.where((a) => a.status == 'pending').toList();

    final displayName = user?.companyProfile?.companyName?.isNotEmpty == true
        ? user!.companyProfile!.companyName!
        : user?.firstName;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.read(myOffersProvider.notifier).load(),
          ref.read(receivedApplicationsProvider.notifier).load(),
          ref.read(internshipsListProvider.notifier).load(),
        ]),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingHeader(
                name: displayName,
                subtitle: "Here's your company overview.",
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
                    label: 'Active offers',
                    value: '$activeOffers',
                    icon: Icons.work_outline,
                    onTap: () => context.go('/company/offers/manage'),
                  ),
                  MetricCard(
                    label: 'Applications',
                    value: '${apps.length}',
                    icon: Icons.inbox_outlined,
                    onTap: () => context.go('/company/applications'),
                  ),
                  MetricCard(
                    label: 'Active interns',
                    value: '$activeInterns',
                    icon: Icons.people_outlined,
                    onTap: () => context.go('/company/internships'),
                  ),
                  MetricCard(
                    label: 'Pending reviews',
                    value: '${pendingApps.length}',
                    icon: Icons.rate_review_outlined,
                    onTap: () => context.go('/company/applications'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DashboardSection(
                title: 'New applications',
                emptyMessage: 'No pending applications.',
                onViewAll: apps.isNotEmpty
                    ? () => context.go('/company/applications')
                    : null,
                children: pendingApps
                    .take(3)
                    .map(
                      (app) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ApplicationCard(
                          application: app,
                          onTap: () =>
                              context.push('/applications/${app.id}'),
                          showStudent: true,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _InternshipsSection(internships: internships),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/company/offers/manage'),
                      icon: const Icon(Icons.work_outline, size: 18),
                      label: const Text('My offers'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/company/applications'),
                      icon: const Icon(Icons.inbox_outlined, size: 18),
                      label: const Text('Applications'),
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

class _InternshipsSection extends StatelessWidget {
  const _InternshipsSection({required this.internships});
  final List<Internship> internships;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final recent = internships
        .where((i) =>
            i.status == 'active' ||
            i.status == 'pending_academic_validation')
        .take(3)
        .toList();

    return DashboardSection(
      title: 'Recent internships',
      emptyMessage: 'No active internships yet.',
      onViewAll: internships.isNotEmpty
          ? () => GoRouter.of(context).go('/company/internships')
          : null,
      children: recent
          .map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () =>
                      GoRouter.of(context).push('/internships/${i.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i.offerTitle,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                i.student.fullName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: i.status),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
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
