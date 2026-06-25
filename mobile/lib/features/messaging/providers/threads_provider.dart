import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/messaging_repository.dart';
import '../data/models/message_thread.dart';

class ThreadsNotifier
    extends StateNotifier<AsyncValue<List<MessageThreadRow>>> {
  ThreadsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final MessagingRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.listThreads);
  }
}

final threadsProvider = StateNotifierProvider<ThreadsNotifier,
    AsyncValue<List<MessageThreadRow>>>(
  (ref) => ThreadsNotifier(ref.read(messagingRepositoryProvider)),
);

/// Derives the thread ID for a given internship from the already-loaded threads
/// list. Returns null while loading or if no thread exists for that internship.
final threadIdByInternshipProvider = Provider.family<int?, int>((ref, internshipId) {
  final threads = ref.watch(threadsProvider);
  final list = threads.valueOrNull;
  if (list == null) return null;
  try {
    return list.firstWhere((t) => t.internshipId == internshipId).id;
  } catch (_) {
    return null;
  }
});
