import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/offer.dart';
import '../providers/offers_providers.dart';
import '../widgets/offer_card.dart';
import '../widgets/offer_filter_sheet.dart';
import '../widgets/offer_skeleton.dart';

class OffersListScreen extends ConsumerStatefulWidget {
  const OffersListScreen({super.key});

  @override
  ConsumerState<OffersListScreen> createState() => _OffersListScreenState();
}

class _OffersListScreenState extends ConsumerState<OffersListScreen> {
  final _scrollController = ScrollController();

  // GoRouter listener — refreshes the list whenever the user navigates back
  // to this tab. Required because ShellRoute keeps all tab screens alive, so
  // initState only fires once.
  late final GoRouter _router;
  late String _lastPath;
  bool _routerListenerAdded = false;

  static const _offerPaths = {
    '/student/offers',
    '/company/offers',
    '/teacher/offers',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routerListenerAdded) return;
    _routerListenerAdded = true;
    _router = GoRouter.of(context);
    _lastPath = GoRouterState.of(context).uri.path;
    _router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    if (_routerListenerAdded) _router.routerDelegate.removeListener(_onRouteChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRouteChanged() {
    final current = _router.routerDelegate.currentConfiguration.uri.path;
    // Refresh when user navigates TO an offers tab FROM somewhere else.
    if (_offerPaths.contains(current) && !_offerPaths.contains(_lastPath)) {
      ref.read(offersListProvider.notifier).refresh();
    }
    _lastPath = current;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(offersListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(offersListProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(offersListProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Header + filter bar ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.totalCount > 0
                            ? '${state.totalCount} offer${state.totalCount == 1 ? '' : 's'}'
                            : 'Offers',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    // Active filter indicator
                    if (state.filters.hasActiveFilters)
                      TextButton.icon(
                        icon: const Icon(Icons.filter_list_off, size: 18),
                        label: const Text('Clear'),
                        onPressed: () => ref
                            .read(offersListProvider.notifier)
                            .applyFilters(const OfferFilters()),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: state.isLoading
                          ? null
                          : () => ref
                              .read(offersListProvider.notifier)
                              .refresh(),
                    ),
                    IconButton(
                      icon: Badge(
                        isLabelVisible: state.filters.hasActiveFilters,
                        child: const Icon(Icons.tune_outlined),
                      ),
                      tooltip: 'Filter',
                      onPressed: () => OfferFilterSheet.show(
                        context,
                        current: state.filters,
                        onApply: (f) => ref
                            .read(offersListProvider.notifier)
                            .applyFilters(f),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Loading skeleton ─────────────────────────────────────────
            if (state.isLoading)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: OfferSkeletonList()),
              ),

            // ── Error ────────────────────────────────────────────────────
            if (!state.isLoading && state.error != null)
              SliverFillRemaining(
                child: _ErrorState(
                  onRetry: () =>
                      ref.read(offersListProvider.notifier).refresh(),
                ),
              ),

            // ── Empty ────────────────────────────────────────────────────
            if (!state.isLoading &&
                state.error == null &&
                state.offers.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(
                  hasFilters: state.filters.hasActiveFilters,
                  onClear: () => ref
                      .read(offersListProvider.notifier)
                      .applyFilters(const OfferFilters()),
                ),
              ),

            // ── Offer list ───────────────────────────────────────────────
            if (!state.isLoading && state.offers.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverList.separated(
                  itemCount: state.offers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final offer = state.offers[i];
                    return OfferCard(
                      offer: offer,
                      onTap: () => context.push('/offers/${offer.id}'),
                    );
                  },
                ),
              ),

            // ── Load-more indicator ──────────────────────────────────────
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
              ),

            // ── End of list ──────────────────────────────────────────────
            if (!state.isLoadingMore && !state.hasMore && state.offers.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No more offers',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        ),
      ),
      // Company gets a FAB to jump to their My Offers screen
      floatingActionButton: user?.role == 'company'
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/company/offers/manage'),
              icon: const Icon(Icons.business_center_outlined),
              label: const Text('My offers'),
            )
          : null,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
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
            Icon(Icons.wifi_off_outlined,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Could not load offers',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters, required this.onClear});
  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_off_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No results' : 'No offers yet',
              style: theme.textTheme.titleMedium,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              Text(
                'Try adjusting or clearing your filters.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                  onPressed: onClear, child: const Text('Clear filters')),
            ],
          ],
        ),
      ),
    );
  }
}
