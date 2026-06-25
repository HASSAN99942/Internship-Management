import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/internship.dart';
import '../providers/internships_providers.dart';
import '../widgets/internship_card.dart';
import '../widgets/internship_skeleton.dart';

/// Role-scoped internships list.
/// Used by: student (/student/internship), company (/company/internships),
/// and teacher (/teacher/students).
class InternshipsListScreen extends ConsumerWidget {
  const InternshipsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(internshipsListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(internshipsListProvider.notifier).load(),
        child: async.when(
          loading: () => const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: InternshipSkeletonList(count: 4),
          ),
          error: (e, _) => _ErrorView(
            onRetry: () =>
                ref.read(internshipsListProvider.notifier).load(),
          ),
          data: (internships) => internships.isEmpty
              ? const _EmptyView()
              : _InternshipList(internships: internships),
        ),
      ),
    );
  }
}

class _InternshipList extends StatelessWidget {
  const _InternshipList({required this.internships});
  final List<Internship> internships;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: internships.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final internship = internships[i];
        return InternshipCard(
          internship: internship,
          onTap: () => context.push('/internships/${internship.id}'),
        );
      },
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
              Icons.school_outlined,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('No internships yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Accepted applications create internship agreements here.',
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
          const Text('Could not load internships'),
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
