import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/offer.dart';
import '../data/offers_repository.dart';

// ---------------------------------------------------------------------------
// Offers list (browse, with filters + infinite scroll)
// ---------------------------------------------------------------------------

class OffersListState {
  final List<Offer> offers;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final OfferFilters filters;
  final int totalCount;

  const OffersListState({
    this.offers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.filters = const OfferFilters(),
    this.totalCount = 0,
  });

  OffersListState copyWith({
    List<Offer>? offers,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    OfferFilters? filters,
    int? totalCount,
    bool clearError = false,
  }) =>
      OffersListState(
        offers: offers ?? this.offers,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : (error ?? this.error),
        hasMore: hasMore ?? this.hasMore,
        filters: filters ?? this.filters,
        totalCount: totalCount ?? this.totalCount,
      );
}

class OffersListNotifier extends StateNotifier<OffersListState> {
  OffersListNotifier(this._repo) : super(const OffersListState()) {
    load();
  }

  final OffersRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final paginated =
          await _repo.listOffers(state.filters.copyWith(page: 1));
      state = state.copyWith(
        offers: paginated.results,
        isLoading: false,
        hasMore: paginated.next != null,
        filters: state.filters.copyWith(page: 1),
        totalCount: paginated.count,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.filters.page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final paginated =
          await _repo.listOffers(state.filters.copyWith(page: nextPage));
      state = state.copyWith(
        offers: [...state.offers, ...paginated.results],
        isLoadingMore: false,
        hasMore: paginated.next != null,
        filters: state.filters.copyWith(page: nextPage),
        totalCount: paginated.count,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> applyFilters(OfferFilters filters) async {
    state = state.copyWith(
      filters: filters.copyWith(page: 1),
      isLoading: true,
      clearError: true,
    );
    try {
      final paginated = await _repo.listOffers(state.filters);
      state = state.copyWith(
        offers: paginated.results,
        isLoading: false,
        hasMore: paginated.next != null,
        totalCount: paginated.count,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => applyFilters(
        state.filters.copyWith(page: 1),
      );
}

final offersListProvider =
    StateNotifierProvider<OffersListNotifier, OffersListState>(
  (ref) => OffersListNotifier(ref.watch(offersRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Single offer detail
// ---------------------------------------------------------------------------

final offerDetailProvider =
    FutureProvider.family<Offer, int>((ref, id) async {
  return ref.watch(offersRepositoryProvider).getOffer(id);
});

// ---------------------------------------------------------------------------
// Company "my offers" list
// ---------------------------------------------------------------------------

class MyOffersNotifier extends StateNotifier<AsyncValue<List<Offer>>> {
  MyOffersNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final OffersRepository _repo;
  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final paginated = await _repo.listMyOffers();
      state = AsyncValue.data(paginated.results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> publish(int id) async {
    await _repo.publishOffer(id);
    await load();
    // Refresh the public browse list so the newly-published offer appears immediately.
    _ref.read(offersListProvider.notifier).refresh();
  }

  Future<void> close(int id) async {
    await _repo.closeOffer(id);
    await load();
    // Refresh so a closed offer is removed from the public list immediately.
    _ref.read(offersListProvider.notifier).refresh();
  }

  Future<void> delete(int id) async {
    await _repo.deleteOffer(id);
    await load();
  }
}

final myOffersProvider =
    StateNotifierProvider<MyOffersNotifier, AsyncValue<List<Offer>>>(
  (ref) => MyOffersNotifier(ref.watch(offersRepositoryProvider), ref),
);
