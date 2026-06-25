import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_error.dart';
import '../providers/reports_providers.dart';

/// Bottom sheet for a student to submit a new periodic report.
class SubmitReportSheet extends ConsumerStatefulWidget {
  const SubmitReportSheet({super.key, required this.internshipId});
  final int internshipId;

  static Future<void> show(BuildContext context, int internshipId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SubmitReportSheet(internshipId: internshipId),
    );
  }

  @override
  ConsumerState<SubmitReportSheet> createState() =>
      _SubmitReportSheetState();
}

class _SubmitReportSheetState extends ConsumerState<SubmitReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _period = TextEditingController();
  final _content = TextEditingController();
  PlatformFile? _pickedFile;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _period.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      withData: kIsWeb,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
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
          .submitReport(
            title: _title.text.trim(),
            period: _period.text.trim(),
            content: _content.text.trim(),
            filePath: kIsWeb ? null : _pickedFile?.path,
            fileBytes: kIsWeb ? _pickedFile?.bytes : null,
            fileName: _pickedFile?.name,
          );
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
              Text('Submit report',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
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
              _Label('Title *'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _title,
                enabled: !_loading,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _Label('Period *'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _period,
                enabled: !_loading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    hintText: 'e.g. Week 3, Month 1'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _Label('Content *'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _content,
                enabled: !_loading,
                minLines: 4,
                maxLines: 10,
                decoration: const InputDecoration(
                    hintText: 'Describe your work and progress'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _Label('Attachment (optional)'),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickFile,
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(
                  _pickedFile != null ? _pickedFile!.name : 'Choose file',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
