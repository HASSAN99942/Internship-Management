import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/messaging_repository.dart';
import '../data/models/message.dart';
import '../data/models/message_thread.dart';
import 'threads_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class MessagesState {
  const MessagesState({
    required this.messages,
    required this.totalCount,
    this.nextOlderPage,
    this.isLoadingOlder = false,
    this.isSending = false,
  });

  final List<Message> messages; // chronological — oldest at index 0
  final int totalCount;
  final int? nextOlderPage; // null = no more older pages to fetch
  final bool isLoadingOlder;
  final bool isSending;

  MessagesState copyWith({
    List<Message>? messages,
    int? totalCount,
    int? nextOlderPage,
    bool clearNextOlderPage = false,
    bool? isLoadingOlder,
    bool? isSending,
  }) =>
      MessagesState(
        messages: messages ?? this.messages,
        totalCount: totalCount ?? this.totalCount,
        nextOlderPage:
            clearNextOlderPage ? null : (nextOlderPage ?? this.nextOlderPage),
        isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
        isSending: isSending ?? this.isSending,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class MessagesNotifier extends StateNotifier<AsyncValue<MessagesState>> {
  MessagesNotifier(this._repo, this._ref, this._threadId)
      : super(const AsyncValue.loading()) {
    loadInitial();
  }

  static const _pageSize = 20;

  final MessagingRepository _repo;
  final Ref _ref;
  final int _threadId;
  Timer? _pollTimer;

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Initial load ──────────────────────────────────────────────────────────

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    try {
      // Step 1: page 1 gives us the total count.
      final first =
          await _repo.listMessages(_threadId, page: 1, pageSize: _pageSize);
      final total = first.count;

      if (total == 0 || total <= _pageSize) {
        state = AsyncValue.data(MessagesState(
          messages: first.results,
          totalCount: total,
          nextOlderPage: null,
        ));
        return;
      }

      // Step 2: fetch the last page so the user sees newest messages first.
      final lastPage = (total / _pageSize).ceil();
      final last =
          await _repo.listMessages(_threadId, page: lastPage, pageSize: _pageSize);
      state = AsyncValue.data(MessagesState(
        messages: last.results,
        totalCount: total,
        nextOlderPage: lastPage > 1 ? lastPage - 1 : null,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Pagination (load older) ───────────────────────────────────────────────

  Future<void> loadOlderMessages() async {
    final current = state.valueOrNull;
    if (current == null ||
        current.nextOlderPage == null ||
        current.isLoadingOlder) {
      return;
    }

    state = AsyncValue.data(current.copyWith(isLoadingOlder: true));
    try {
      final page = await _repo.listMessages(
        _threadId,
        page: current.nextOlderPage!,
        pageSize: _pageSize,
      );
      final cd = state.valueOrNull!;
      final nextOlder =
          current.nextOlderPage! > 1 ? current.nextOlderPage! - 1 : null;
      state = AsyncValue.data(cd.copyWith(
        messages: [...page.results, ...cd.messages],
        nextOlderPage: nextOlder,
        clearNextOlderPage: nextOlder == null,
        isLoadingOlder: false,
      ));
    } catch (_) {
      final cd = state.valueOrNull;
      if (cd != null) state = AsyncValue.data(cd.copyWith(isLoadingOlder: false));
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> sendMessage(String body) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(isSending: true));
    try {
      final msg = await _repo.sendMessage(_threadId, body);
      final cd = state.valueOrNull!;
      state = AsyncValue.data(cd.copyWith(
        messages: [...cd.messages, msg],
        totalCount: cd.totalCount + 1,
        isSending: false,
      ));
      _ref.invalidate(threadsProvider);
    } catch (_) {
      final cd = state.valueOrNull;
      if (cd != null) {
        state = AsyncValue.data(cd.copyWith(isSending: false));
      }
    }
  }

  // ── Mark read ─────────────────────────────────────────────────────────────

  Future<void> markRead() async {
    try {
      await _repo.markThreadRead(_threadId);
      _ref.invalidate(threadsProvider);
    } catch (_) {}
  }

  // ── Polling ───────────────────────────────────────────────────────────────

  Future<void> _poll() async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      final lastPage = max(1, (current.totalCount / _pageSize).ceil());
      final fresh =
          await _repo.listMessages(_threadId, page: lastPage, pageSize: _pageSize);

      final existingIds = {for (final m in current.messages) m.id};
      var newMsgs = fresh.results
          .where((m) => !existingIds.contains(m.id))
          .toList();

      // If the conversation grew past the old last page, fetch the new last page.
      if (fresh.count > current.totalCount) {
        final newLastPage = (fresh.count / _pageSize).ceil();
        if (newLastPage > lastPage) {
          final extra = await _repo.listMessages(
              _threadId, page: newLastPage, pageSize: _pageSize);
          final seenIds = existingIds..addAll(newMsgs.map((m) => m.id));
          newMsgs += extra.results
              .where((m) => !seenIds.contains(m.id))
              .toList();
        }
      }

      if (newMsgs.isEmpty && fresh.count == current.totalCount) return;

      final cd = state.valueOrNull;
      if (cd != null) {
        state = AsyncValue.data(cd.copyWith(
          messages: [...cd.messages, ...newMsgs],
          totalCount: fresh.count,
        ));
      }
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    AsyncValue<MessagesState>, int>(
  (ref, threadId) => MessagesNotifier(
    ref.read(messagingRepositoryProvider),
    ref,
    threadId,
  ),
);

final threadDetailProvider =
    FutureProvider.family<ThreadDetail, int>((ref, threadId) {
  return ref.read(messagingRepositoryProvider).getThread(threadId);
});
