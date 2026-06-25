import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/application.dart';
import '../providers/applications_providers.dart';
import '../widgets/application_card.dart';
import '../widgets/application_skeleton.dart';

class ReceivedApplicationsScreen extends ConsumerWidget {
  const ReceivedApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(receivedApplicationsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(receivedApplicationsProvider.notifier).load(),
        child: async.when(
          loading: () => const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: ApplicationSkeletonList(count: 5),
          ),
          error: (e, _) => _ErrorView(
            onRetry: () =>
                ref.read(receivedApplicationsProvider.notifier).load(),
          ),
          data: (apps) => apps.isEmpty
              ? const _EmptyView()
              : _ApplicationList(applications: apps),
        ),
      ),
    );
  }
}

class _ApplicationList extends StatelessWidget {
  const _ApplicationList({required this.applications});
  final List<Application> applications;

  @override
  Widget build(BuildContext context) {
    // Group by status: pending first, then accepted, then rejected/withdrawn.
    final pending =
        applications.where((a) => a.status == 'pending').toList();
    final decided =
        applications.where((a) => a.status != 'pending').toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (pending.isNotEmpty) ...[
          _SectionHeader(
              title: 'Pending review (${pending.length})'),
          const SizedBox(height: 8),
          ...pending.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ApplicationCard(
                  application: a,
                  showStudent: true,
                  onTap: () => context.push('/applications/${a.id}'),
                ),
              )),
          const SizedBox(height: 8),
        ],
        if (decided.isNotEmpty) ...[
          _SectionHeader(title: 'Decided (${decided.length})'),
          const SizedBox(height: 8),
          ...decided.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ApplicationCard(
                  application: a,
                  showStudent: true,
                  onTap: () => context.push('/applications/${a.id}'),
                ),
              )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('No applications received',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Applications to your published offers will appear here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          const Text('Could not load applications'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
