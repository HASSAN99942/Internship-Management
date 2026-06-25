import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/evaluations_provider.dart';
import 'evaluation_card.dart';
import 'evaluation_form.dart';
import 'evaluation_summary_card.dart';

class EvaluationsSection extends ConsumerWidget {
  const EvaluationsSection({
    super.key,
    required this.internshipId,
    required this.status,
  });

  final int internshipId;
  final String status;

  bool get _isActive =>
      status == 'active' || status == 'completed';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(evaluationsProvider(internshipId));
    final user = ref.watch(currentUserProvider);

    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => _ErrorState(
        onRetry: () => ref.invalidate(evaluationsProvider(internshipId)),
      ),
      data: (payload) {
        final role = user?.role ?? '';
        // Determine which evaluator types this viewer may see/submit.
        final viewerType = switch (role) {
          'company' => 'company',
          'teacher' => 'teacher',
          'student' => 'student',
          _ => null,
        };

        final existing = viewerType != null
            ? payload.evaluationFor(viewerType)
            : null;
        final hasSummary = payload.summary.company != null ||
            payload.summary.teacher != null ||
            payload.summary.combined != null;

        // Evaluations visible to this viewer.
        // Company: see company eval only.
        // Teacher: see teacher eval only.
        // Student: see company + teacher evals (not other students').
        final visibleEvals = payload.evaluations.where((e) {
          if (role == 'student') {
            return e.evaluatorType == 'company' ||
                e.evaluatorType == 'teacher';
          }
          return e.evaluatorType == viewerType;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isActive)
              _InactiveNotice(status: status)
            else ...[
              // Summary card (shown when at least company or teacher has submitted).
              if (hasSummary) ...[
                EvaluationSummaryCard(summary: payload.summary),
                const SizedBox(height: 16),
              ],

              // Submitted evaluations (read-only cards) relevant to viewer.
              if (visibleEvals.isNotEmpty) ...[
                ...visibleEvals.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EvaluationCard(
                      evaluation: e,
                      criteria: payload.criteriaFor(e.evaluatorType),
                    ),
                  ),
                ),
              ],

              // Form for viewer's own type (if not yet submitted).
              if (viewerType != null && existing == null) ...[
                if (visibleEvals.isNotEmpty) const SizedBox(height: 4),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: EvaluationForm(
                      internshipId: internshipId,
                      evaluatorType: viewerType,
                      criteria: payload.criteriaFor(viewerType),
                    ),
                  ),
                ),
              ],

              // Empty state: nothing submitted yet and viewer has no form role.
              if (visibleEvals.isEmpty && viewerType == null)
                const _EmptyState(),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 12),
          const Text('Could not load evaluations'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border_rounded,
                size: 48, color: cs.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              'No evaluations yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InactiveNotice extends StatelessWidget {
  const _InactiveNotice({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_clock_outlined,
                size: 48, color: cs.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              'Evaluations are available\nonce the internship is active.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
