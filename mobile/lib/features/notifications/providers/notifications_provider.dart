import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_notification.dart';
import '../data/notifications_repository.dart';

// ---------------------------------------------------------------------------
// Notifications list state
// ---------------------------------------------------------------------------

class NotificationsState {
  const NotificationsState({
    required this.items,
    required this.count,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
  });

  final List<AppNotification> items;
  final int count;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentPage;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? count,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        count: count ?? this.count,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        currentPage: currentPage ?? this.currentPage,
      );
}

class NotificationsNotifier
    extends StateNotifier<AsyncValue<NotificationsState>> {
  NotificationsNotifier(this._repo) : super(const AsyncValue.loading());

  static const _pageSize = 20;
  final NotificationsRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final page = await _repo.listNotifications(page: 1, pageSize: _pageSize);
      state = AsyncValue.data(NotificationsState(
        items: page.results,
        count: page.count,
        hasMore: page.next != null,
        currentPage: 1,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final page = await _repo.listNotifications(
          page: nextPage, pageSize: _pageSize);
      final cd = state.valueOrNull!;
      state = AsyncValue.data(cd.copyWith(
        items: [...cd.items, ...page.results],
        count: page.count,
        hasMore: page.next != null,
        isLoadingMore: false,
        currentPage: nextPage,
      ));
    } catch (_) {
      final cd = state.valueOrNull;
      if (cd != null) {
        state = AsyncValue.data(cd.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _repo.markRead(id);
      final current = state.valueOrNull;
      if (current == null) return;
      final updated = current.items.map((n) {
        return n.id == id
            ? AppNotification(
                id: n.id,
                type: n.type,
                payload: n.payload,
                isRead: true,
                createdAt: n.createdAt,
              )
            : n;
      }).toList();
      state = AsyncValue.data(current.copyWith(items: updated));
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markAllRead();
      final current = state.valueOrNull;
      if (current == null) return;
      final updated = current.items.map((n) {
        return AppNotification(
          id: n.id,
          type: n.type,
          payload: n.payload,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      state = AsyncValue.data(current.copyWith(items: updated));
    } catch (_) {}
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<NotificationsState>>(
  (ref) => NotificationsNotifier(ref.read(notificationsRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Unread count — polled every 30 s
// ---------------------------------------------------------------------------

class UnreadCountNotifier extends StateNotifier<int> {
  UnreadCountNotifier(this._repo) : super(0) {
    _refresh();
    _startPolling();
  }

  final NotificationsRepository _repo;
  Timer? _timer;

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refresh(),
    );
  }

  Future<void> _refresh() async {
    try {
      state = await _repo.fetchUnreadCount();
    } catch (_) {}
  }

  void decrement() {
    if (state > 0) state = state - 1;
  }

  void reset() => state = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, int>(
  (ref) => UnreadCountNotifier(ref.read(notificationsRepositoryProvider)),
);
