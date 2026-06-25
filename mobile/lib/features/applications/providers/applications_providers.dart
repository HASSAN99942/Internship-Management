import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/applications_repository.dart';
import '../data/models/application.dart';

// ---------------------------------------------------------------------------
// Student — my applications
// ---------------------------------------------------------------------------

class MyApplicationsNotifier
    extends StateNotifier<AsyncValue<List<Application>>> {
  MyApplicationsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final ApplicationsRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listApplications());
  }

  Future<void> withdraw(int id) async {
    await _repo.withdraw(id);
    await load();
  }
}

final myApplicationsProvider = StateNotifierProvider<MyApplicationsNotifier,
    AsyncValue<List<Application>>>(
  (ref) => MyApplicationsNotifier(ref.read(applicationsRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Company — received applications
// ---------------------------------------------------------------------------

class ReceivedApplicationsNotifier
    extends StateNotifier<AsyncValue<List<Application>>> {
  ReceivedApplicationsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final ApplicationsRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listApplications());
  }

  Future<void> accept(int id) async {
    await _repo.accept(id);
    await load();
  }

  Future<void> reject(int id) async {
    await _repo.reject(id);
    await load();
  }
}

final receivedApplicationsProvider = StateNotifierProvider<
    ReceivedApplicationsNotifier, AsyncValue<List<Application>>>(
  (ref) =>
      ReceivedApplicationsNotifier(ref.read(applicationsRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Single application detail
// ---------------------------------------------------------------------------

final applicationDetailProvider =
    FutureProvider.family<Application, int>((ref, id) {
  return ref.read(applicationsRepositoryProvider).getApplication(id);
});
