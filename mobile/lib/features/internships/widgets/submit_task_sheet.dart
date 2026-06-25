import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_error.dart';
import '../data/models/task.dart';
import '../providers/tasks_providers.dart';

/// Bottom sheet for a student to submit (or resubmit) a task.
class SubmitTaskSheet extends ConsumerStatefulWidget {
  const SubmitTaskSheet({
    super.key,
    required this.internshipId,
    required this.task,
  });
  final int internshipId;
  final Task task;

  static Future<void> show(
      BuildContext context, int internshipId, Task task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          SubmitTaskSheet(internshipId: internshipId, task: task),
    );
  }

  @override
  ConsumerState<SubmitTaskSheet> createState() => _SubmitTaskSheetState();
}

class _SubmitTaskSheetState extends ConsumerState<SubmitTaskSheet> {
  final _noteCtrl = TextEditingController();
  PlatformFile? _pickedFile;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _noteCtrl.dispose();
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(tasksProvider(widget.internshipId).notifier)
          .submitTask(
            widget.task.id,
            note: _noteCtrl.text.trim(),
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
    final isResubmit = widget.task.status == 'changes_requested';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isResubmit ? 'Resubmit task' : 'Submit task',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.task.title,
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
            _Label('Note'),
            const SizedBox(height: 4),
            TextField(
              controller: _noteCtrl,
              enabled: !_loading,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                  hintText: 'Describe what you did (optional)'),
            ),
            const SizedBox(height: 14),
            _Label('Attachment (optional)'),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(
                _pickedFile != null
                    ? _pickedFile!.name
                    : 'Choose file',
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
                    : Text(isResubmit ? 'Resubmit' : 'Submit'),
              ),
            ),
          ],
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
