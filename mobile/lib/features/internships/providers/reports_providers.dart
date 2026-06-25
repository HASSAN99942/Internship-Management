import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/internships_repository.dart';
import '../data/models/report.dart';
import 'internships_providers.dart';

// ---------------------------------------------------------------------------
// Reports list per internship
// ---------------------------------------------------------------------------

class ReportsNotifier extends StateNotifier<AsyncValue<List<Report>>> {
  ReportsNotifier(this._repo, this._ref, this._internshipId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final InternshipsRepository _repo;
  final Ref _ref;
  final int _internshipId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _repo.listReports(_internshipId));
  }

  Future<void> submitReport({
    required String title,
    required String period,
    required String content,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    await _repo.submitReport(
      _internshipId,
      title: title,
      period: period,
      content: content,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
    );
    await _refreshAll();
  }

  Future<void> validateReport(int reportId) async {
    await _repo.validateReport(reportId);
    await _refreshAll();
  }

  Future<void> requestChanges(int reportId, String feedback) async {
    await _repo.requestReportChanges(reportId, feedback);
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    await load();
    _ref.invalidate(internshipDetailProvider(_internshipId));
  }
}

final reportsProvider = StateNotifierProvider.family<ReportsNotifier,
    AsyncValue<List<Report>>, int>(
  (ref, internshipId) => ReportsNotifier(
    ref.read(internshipsRepositoryProvider),
    ref,
    internshipId,
  ),
);
