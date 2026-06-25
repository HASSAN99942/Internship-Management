import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/evaluation.dart';

class EvaluationRepository {
  const EvaluationRepository();

  Future<EvaluationsPayload> getEvaluations(int internshipId) async {
    final response =
        await apiClient.get('/internships/$internshipId/evaluations/');
    return EvaluationsPayload.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<Evaluation> submitEvaluation(
    int internshipId, {
    required Map<String, int> scores,
    String? comment,
  }) async {
    final response = await apiClient.post(
      '/internships/$internshipId/evaluations/',
      data: {
        'scores': scores,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    return Evaluation.fromJson(response.data as Map<String, dynamic>);
  }
}

final evaluationRepositoryProvider =
    Provider<EvaluationRepository>((_) => const EvaluationRepository());
