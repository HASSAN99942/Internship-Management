import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/internships_repository.dart';
import '../data/models/task.dart';
import 'internships_providers.dart';

// ---------------------------------------------------------------------------
// Tasks list per internship
// ---------------------------------------------------------------------------

class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TasksNotifier(this._repo, this._ref, this._internshipId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final InternshipsRepository _repo;
  final Ref _ref;
  final int _internshipId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _repo.listTasks(_internshipId));
  }

  Future<void> createTask(TaskInput input) async {
    await _repo.createTask(_internshipId, input);
    await _refreshAll();
  }

  Future<void> submitTask(
    int taskId, {
    required String note,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    await _repo.submitTask(
      taskId,
      note: note,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
    );
    await _refreshAll();
  }

  Future<void> validateTask(int taskId) async {
    await _repo.validateTask(taskId);
    await _refreshAll();
  }

  Future<void> requestChanges(int taskId) async {
    await _repo.requestTaskChanges(taskId);
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    await load();
    // Re-fetch the dashboard aggregate so progress numbers update.
    _ref.invalidate(internshipDetailProvider(_internshipId));
  }
}

final tasksProvider = StateNotifierProvider.family<TasksNotifier,
    AsyncValue<List<Task>>, int>(
  (ref, internshipId) => TasksNotifier(
    ref.read(internshipsRepositoryProvider),
    ref,
    internshipId,
  ),
);
