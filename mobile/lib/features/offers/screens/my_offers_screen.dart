import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/models/offer.dart';
import '../providers/offers_providers.dart';
import '../widgets/offer_skeleton.dart';

class MyOffersScreen extends ConsumerWidget {
  const MyOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myOffersProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(myOffersProvider.notifier).load(),
        child: async.when(
          loading: () => const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: OfferSkeletonList(count: 4),
          ),
          error: (e, _) => _ErrorView(
            onRetry: () => ref.read(myOffersProvider.notifier).load(),
          ),
          data: (offers) => offers.isEmpty
              ? _EmptyView(onCreateTap: () => context.push('/company/offers/new'))
              : _OffersList(offers: offers),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/company/offers/new'),
        icon: const Icon(Icons.add),
        label: const Text('New offer'),
      ),
    );
  }
}

class _OffersList extends StatelessWidget {
  const _OffersList({required this.offers});
  final List<Offer> offers;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: offers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final offer = offers[i];
        return _OfferManageCard(offer: offer);
      },
    );
  }
}

class _OfferManageCard extends ConsumerWidget {
  const _OfferManageCard({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    offer.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: offer.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${offer.location} · ${offer.durationWeeks}w · '
              '${offer.positions} position${offer.positions == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),

            // Action row
            Row(
              children: [
                // View
                _ActionChip(
                  icon: Icons.visibility_outlined,
                  label: 'View',
                  onTap: () => context.push('/offers/${offer.id}'),
                ),
                const SizedBox(width: 6),
                // Edit
                _ActionChip(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () =>
                      context.push('/company/offers/${offer.id}/edit'),
                ),
                const SizedBox(width: 6),
                // Publish (draft only)
                if (offer.status == 'draft')
                  _ActionChip(
                    icon: Icons.publish_outlined,
                    label: 'Publish',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => _confirmAction(
                      context,
                      title: 'Publish offer?',
                      message:
                          'The offer will be visible to all students.',
                      confirmLabel: 'Publish',
                      onConfirm: () =>
                          ref.read(myOffersProvider.notifier).publish(offer.id),
                    ),
                  ),
                // Close (published only)
                if (offer.status == 'published')
                  _ActionChip(
                    icon: Icons.lock_outline,
                    label: 'Close',
                    color: Theme.of(context).colorScheme.error,
                    onTap: () => _confirmAction(
                      context,
                      title: 'Close offer?',
                      message:
                          'No new applications will be accepted. This cannot be undone.',
                      confirmLabel: 'Close',
                      destructive: true,
                      onConfirm: () =>
                          ref.read(myOffersProvider.notifier).close(offer.id),
                    ),
                  ),
                const Spacer(),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Delete',
                  onPressed: () => _confirmAction(
                    context,
                    title: 'Delete offer?',
                    message:
                        '"${offer.title}" will be permanently deleted.',
                    confirmLabel: 'Delete',
                    destructive: true,
                    onConfirm: () =>
                        ref.read(myOffersProvider.notifier).delete(offer.id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(ctx).colorScheme.error,
                    foregroundColor:
                        Theme.of(ctx).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await onConfirm();
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? cs.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style:
                  Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreateTap});
  final VoidCallback onCreateTap;

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
              Icons.work_off_outlined,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('No offers yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Create your first internship offer to get started.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add),
              label: const Text('Create offer'),
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
          const Text('Could not load your offers'),
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
