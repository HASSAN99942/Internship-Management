import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../internships/providers/internships_providers.dart';
import '../data/evaluation_repository.dart';
import '../data/models/evaluation.dart';
import '../providers/evaluations_provider.dart';
import 'criterion_rating_row.dart';

class EvaluationForm extends ConsumerStatefulWidget {
  const EvaluationForm({
    super.key,
    required this.internshipId,
    required this.evaluatorType,
    required this.criteria,
  });

  final int internshipId;
  final String evaluatorType;
  final List<Criterion> criteria;

  @override
  ConsumerState<EvaluationForm> createState() => _EvaluationFormState();
}

class _EvaluationFormState extends ConsumerState<EvaluationForm> {
  final Map<String, int> _scores = {};
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _allRated =>
      widget.criteria.every((c) => _scores.containsKey(c.key));

  Future<void> _submit() async {
    if (!_allRated || _loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(evaluationRepositoryProvider).submitEvaluation(
            widget.internshipId,
            scores: _scores,
            comment: _commentController.text.trim(),
          );
      ref.invalidate(evaluationsProvider(widget.internshipId));
      ref.invalidate(internshipDetailProvider(widget.internshipId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluation submitted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _labelFor(widget.evaluatorType),
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...widget.criteria.map(
          (c) => CriterionRatingRow(
            criterion: c,
            value: _scores[c.key],
            onChanged: (v) => setState(() => _scores[c.key] = v),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Comment (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: (_allRated && !_loading) ? _submit : null,
            icon: _loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text('Submit evaluation'),
          ),
        ),
      ],
    );
  }

  static String _labelFor(String type) => switch (type) {
        'company' => 'Company evaluation',
        'teacher' => 'Academic evaluation',
        'student' => 'Rate your internship',
        _ => 'Evaluation',
      };
}
