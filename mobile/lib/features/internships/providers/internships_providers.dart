import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/internships_repository.dart';
import '../data/models/internship.dart';

// ---------------------------------------------------------------------------
// All-role internships list
// ---------------------------------------------------------------------------

class InternshipsListNotifier
    extends StateNotifier<AsyncValue<List<Internship>>> {
  InternshipsListNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final InternshipsRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listInternships());
  }

  Future<void> validate(int id) async {
    await _repo.validate(id);
    await load();
  }
}

final internshipsListProvider = StateNotifierProvider<InternshipsListNotifier,
    AsyncValue<List<Internship>>>(
  (ref) =>
      InternshipsListNotifier(ref.read(internshipsRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Single internship dashboard detail
// ---------------------------------------------------------------------------

final internshipDetailProvider =
    FutureProvider.family<InternshipDashboard, int>((ref, id) {
  return ref.read(internshipsRepositoryProvider).getInternship(id);
});

// ---------------------------------------------------------------------------
// Teacher — pending academic validations (derived from the list)
// ---------------------------------------------------------------------------

final pendingValidationsProvider =
    Provider<AsyncValue<List<Internship>>>((ref) {
  final listState = ref.watch(internshipsListProvider);
  return listState.whenData(
    (internships) => internships
        .where((i) => i.status == 'pending_academic_validation')
        .toList(),
  );
});
