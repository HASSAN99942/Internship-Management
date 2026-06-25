import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/evaluation_repository.dart';
import '../data/models/evaluation.dart';

final evaluationsProvider =
    FutureProvider.family<EvaluationsPayload, int>((ref, internshipId) {
  return ref.read(evaluationRepositoryProvider).getEvaluations(internshipId);
});
