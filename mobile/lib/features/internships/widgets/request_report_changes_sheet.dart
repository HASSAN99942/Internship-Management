import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_error.dart';
import '../data/models/report.dart';
import '../providers/reports_providers.dart';

/// Bottom sheet for company/teacher to request changes on a submitted report,
/// providing a mandatory feedback message.
class RequestReportChangesSheet extends ConsumerStatefulWidget {
  const RequestReportChangesSheet({
    super.key,
    required this.internshipId,
    required this.report,
  });
  final int internshipId;
  final Report report;

  static Future<void> show(
      BuildContext context, int internshipId, Report report) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RequestReportChangesSheet(
          internshipId: internshipId, report: report),
    );
  }

  @override
  ConsumerState<RequestReportChangesSheet> createState() =>
      _RequestReportChangesSheetState();
}

class _RequestReportChangesSheetState
    extends ConsumerState<RequestReportChangesSheet> {
  final _formKey = GlobalKey<FormState>();
  final _feedback = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(reportsProvider(widget.internshipId).notifier)
          .requestChanges(widget.report.id, _feedback.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      final msg = e is ApiError ? e.message : e.toString();
      setState(() {
        _loading = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request changes',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                widget.report.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: cs.onErrorContainer)),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Feedback *',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _feedback,
                enabled: !_loading,
                minLines: 4,
                maxLines: 10,
                decoration: const InputDecoration(
                    hintText: 'Explain what needs to be changed'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Feedback is required' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Request changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
