import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/internship.dart';
import '../data/models/report.dart';
import '../providers/reports_providers.dart';
import 'report_card.dart';
import 'submit_report_sheet.dart';
import 'request_report_changes_sheet.dart';

/// Reports tab body shown inside the internship detail screen.
class ReportsSection extends ConsumerWidget {
  const ReportsSection({super.key, required this.internship});
  final Internship internship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isStudent = user?.id == internship.student.id;
    final isSupervisor = user?.id == internship.company.id ||
        user?.id == internship.teacher?.id;
    final isActive = internship.status == 'active';

    final async = ref.watch(reportsProvider(internship.id));

    return async.when(
      loading: () => const _ReportsSkeleton(),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () =>
            ref.read(reportsProvider(internship.id).notifier).load(),
      ),
      data: (reports) => _ReportsList(
        reports: reports,
        internship: internship,
        isStudent: isStudent,
        isSupervisor: isSupervisor,
        isActive: isActive,
      ),
    );
  }
}

class _ReportsList extends ConsumerWidget {
  const _ReportsList({
    required this.reports,
    required this.internship,
    required this.isStudent,
    required this.isSupervisor,
    required this.isActive,
  });

  final List<Report> reports;
  final Internship internship;
  final bool isStudent;
  final bool isSupervisor;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        if (reports.isEmpty)
          _EmptyState(
            message: isStudent && isActive
                ? 'No reports yet. Tap + to submit one.'
                : 'No reports have been submitted yet.',
          )
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final report = reports[i];
              return ReportCard(
                report: report,
                onValidate: isSupervisor &&
                        isActive &&
                        report.status == 'submitted'
                    ? () => _confirmValidate(context, ref, report)
                    : null,
                onRequestChanges: isSupervisor &&
                        isActive &&
                        report.status == 'submitted'
                    ? () => RequestReportChangesSheet.show(
                        context, internship.id, report)
                    : null,
              );
            },
          ),
        // FAB for student to submit reports
        if (isStudent && isActive)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'submit_report_fab',
              onPressed: () =>
                  SubmitReportSheet.show(context, internship.id),
              icon: const Icon(Icons.add),
              label: const Text('Submit report'),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmValidate(
      BuildContext context, WidgetRef ref, Report report) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validate report?'),
        content: Text('Mark "${report.title}" as validated.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Validate')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref
            .read(reportsProvider(internship.id).notifier)
            .validateReport(report.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())));
        }
      }
    }
  }
}

class _ReportsSkeleton extends StatelessWidget {
  const _ReportsSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ],
      ),
    );
  }
}
