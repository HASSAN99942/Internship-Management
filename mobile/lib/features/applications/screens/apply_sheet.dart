import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/applications_repository.dart';
import '../providers/applications_providers.dart';

const _maxCvBytes = 5 * 1024 * 1024; // 5 MB
const _allowedExtensions = ['pdf', 'doc', 'docx'];

/// Call [ApplySheet.show] from the offer detail screen.
class ApplySheet extends ConsumerStatefulWidget {
  const ApplySheet({super.key, required this.offerId, required this.offerTitle});

  final int offerId;
  final String offerTitle;

  static Future<bool> show(
    BuildContext context, {
    required int offerId,
    required String offerTitle,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          ApplySheet(offerId: offerId, offerTitle: offerTitle),
    );
    return result == true;
  }

  @override
  ConsumerState<ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends ConsumerState<ApplySheet> {
  final _formKey = GlobalKey<FormState>();
  final _coverCtrl = TextEditingController();
  PlatformFile? _cvFile;
  String? _cvError;
  bool _submitting = false;
  String? _serverError;

  @override
  void dispose() {
    _coverCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    if (file.size > _maxCvBytes) {
      setState(() => _cvError = 'CV must be 5 MB or smaller.');
      return;
    }
    final ext = file.name.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      setState(() => _cvError = 'Only PDF, DOC, or DOCX files are accepted.');
      return;
    }
    setState(() {
      _cvFile = file;
      _cvError = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _serverError = null;
    });

    try {
      await ref.read(applicationsRepositoryProvider).apply(
            widget.offerId,
            coverMessage: _coverCtrl.text.trim(),
            cvFile: _cvFile,
          );
      // Refresh the student's applications list.
      ref.invalidate(myApplicationsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _submitting = false;
        _serverError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Apply for internship',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.offerTitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Cover message
            Text('Cover message *',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _coverCtrl,
              enabled: !_submitting,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText:
                    'Introduce yourself and explain why you are a good fit…',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Cover message is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // CV picker
            Text('CV (optional)',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _submitting ? null : _pickCv,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _cvError != null
                        ? cs.error
                        : cs.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _cvFile != null
                          ? Icons.insert_drive_file_outlined
                          : Icons.upload_file_outlined,
                      size: 20,
                      color: _cvFile != null ? cs.primary : cs.onSurface,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _cvFile != null
                            ? _cvFile!.name
                            : 'Choose PDF, DOC or DOCX (max 5 MB)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _cvFile != null
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_cvFile != null)
                      GestureDetector(
                        onTap: () => setState(() => _cvFile = null),
                        child: Icon(Icons.close, size: 18,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                  ],
                ),
              ),
            ),
            if (_cvError != null) ...[
              const SizedBox(height: 4),
              Text(_cvError!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.error)),
            ],

            if (_serverError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _serverError!,
                  style:
                      TextStyle(color: cs.onErrorContainer, fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_submitting ? 'Submitting…' : 'Submit application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
