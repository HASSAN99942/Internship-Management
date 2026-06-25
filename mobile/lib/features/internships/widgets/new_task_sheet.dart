import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_error.dart';
import '../data/models/task.dart';
import '../providers/tasks_providers.dart';

/// Bottom sheet for company/teacher to create a new task.
class NewTaskSheet extends ConsumerStatefulWidget {
  const NewTaskSheet({super.key, required this.internshipId});
  final int internshipId;

  static Future<void> show(
      BuildContext context, int internshipId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => NewTaskSheet(internshipId: internshipId),
    );
  }

  @override
  ConsumerState<NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends ConsumerState<NewTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime? _dueDate;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(tasksProvider(widget.internshipId).notifier).createTask(
            TaskInput(
              title: _title.text.trim(),
              description: _description.text.trim(),
              dueDate: _dueDate != null
                  ? DateFormat('yyyy-MM-dd').format(_dueDate!)
                  : null,
            ),
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
              Text('New task',
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
              _Label('Description'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _description,
                enabled: !_loading,
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 14),
              _Label('Due date'),
              const SizedBox(height: 4),
              InkWell(
                onTap: _loading ? null : _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Text(
                        _dueDate != null
                            ? DateFormat('MMMM d, y').format(_dueDate!)
                            : 'Pick a date (optional)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _dueDate == null
                              ? cs.onSurface.withValues(alpha: 0.4)
                              : null,
                        ),
                      ),
                    ],
                  ),
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
                      : const Text('Create task'),
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
