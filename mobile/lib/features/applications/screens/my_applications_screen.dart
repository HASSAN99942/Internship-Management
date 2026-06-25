import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/application.dart';
import '../providers/applications_providers.dart';
import '../widgets/application_card.dart';
import '../widgets/application_skeleton.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myApplicationsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(myApplicationsProvider.notifier).load(),
        child: async.when(
          loading: () => const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: ApplicationSkeletonList(count: 5),
          ),
          error: (e, _) => _ErrorView(
            onRetry: () => ref.read(myApplicationsProvider.notifier).load(),
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
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: applications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final app = applications[i];
        return _ApplicationRow(application: app);
      },
    );
  }
}

class _ApplicationRow extends ConsumerWidget {
  const _ApplicationRow({required this.application});
  final Application application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ApplicationCard(
      application: application,
      onTap: () => context.push('/applications/${application.id}'),
      showStudent: false,
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error states
// ---------------------------------------------------------------------------

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
              Icons.description_outlined,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('No applications yet',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Browse open offers and apply to get started.',
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
          const Text('Could not load your applications'),
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
