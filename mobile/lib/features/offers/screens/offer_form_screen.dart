import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/models/offer.dart';
import '../data/offers_repository.dart';
import '../providers/offers_providers.dart';

/// Used for both create (offerId == null) and edit (offerId != null).
class OfferFormScreen extends ConsumerStatefulWidget {
  const OfferFormScreen({super.key, this.offerId});

  final int? offerId;

  @override
  ConsumerState<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends ConsumerState<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _skills;
  late final TextEditingController _location;
  late final TextEditingController _duration;
  late final TextEditingController _positions;

  DateTime? _startDate;
  bool _submitting = false;
  String? _serverError;

  bool get _isEdit => widget.offerId != null;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _description = TextEditingController();
    _skills = TextEditingController();
    _location = TextEditingController();
    _duration = TextEditingController();
    _positions = TextEditingController(text: '1');

    if (_isEdit) {
      // Prefill from the cached detail provider if already loaded.
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _skills.dispose();
    _location.dispose();
    _duration.dispose();
    _positions.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    final existing =
        ref.read(offerDetailProvider(widget.offerId!)).valueOrNull;
    if (existing != null) {
      _applyOffer(existing);
    } else {
      try {
        final fetched =
            await ref.read(offersRepositoryProvider).getOffer(widget.offerId!);
        _applyOffer(fetched);
      } catch (_) {}
    }
  }

  void _applyOffer(Offer o) {
    _title.text = o.title;
    _description.text = o.description;
    _skills.text = o.skills;
    _location.text = o.location;
    _duration.text = o.durationWeeks.toString();
    _positions.text = o.positions.toString();
    try {
      setState(() => _startDate = DateTime.parse(o.startDate));
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      setState(() => _serverError = 'Please select a start date.');
      return;
    }
    setState(() {
      _submitting = true;
      _serverError = null;
    });

    final input = OfferInput(
      title: _title.text.trim(),
      description: _description.text.trim(),
      skills: _skills.text.trim(),
      location: _location.text.trim(),
      durationWeeks: int.parse(_duration.text.trim()),
      startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      positions: int.parse(_positions.text.trim()),
    );

    try {
      final repo = ref.read(offersRepositoryProvider);
      if (_isEdit) {
        await repo.updateOffer(widget.offerId!, input);
        ref.invalidate(offerDetailProvider(widget.offerId!));
      } else {
        await repo.createOffer(input);
      }
      ref.invalidate(myOffersProvider);

      if (mounted) context.pop();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit offer' : 'New offer'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Create offer'),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (_serverError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _serverError!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _FormField(
              label: 'Title',
              child: TextFormField(
                controller: _title,
                enabled: !_submitting,
                decoration: const InputDecoration(hintText: 'e.g. Software Engineering Intern'),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
            ),
            const SizedBox(height: 16),

            _FormField(
              label: 'Description',
              child: TextFormField(
                controller: _description,
                enabled: !_submitting,
                decoration:
                    const InputDecoration(hintText: 'Describe the role and responsibilities'),
                minLines: 4,
                maxLines: 8,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            _FormField(
              label: 'Required skills',
              child: TextFormField(
                controller: _skills,
                enabled: !_submitting,
                decoration:
                    const InputDecoration(hintText: 'e.g. Python, Django, REST APIs'),
                minLines: 2,
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Skills are required'
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            _FormField(
              label: 'Location',
              child: TextFormField(
                controller: _location,
                enabled: !_submitting,
                decoration:
                    const InputDecoration(hintText: 'City, Country'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Location is required'
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FormField(
                    label: 'Duration (weeks)',
                    child: TextFormField(
                      controller: _duration,
                      enabled: !_submitting,
                      decoration:
                          const InputDecoration(hintText: 'e.g. 8'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) {
                          return 'Min 1 week';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(
                    label: 'Positions',
                    child: TextFormField(
                      controller: _positions,
                      enabled: !_submitting,
                      decoration:
                          const InputDecoration(hintText: 'e.g. 1'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _FormField(
              label: 'Start date',
              child: InkWell(
                onTap: _submitting ? null : _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _startDate != null
                            ? DateFormat('MMMM d, y').format(_startDate!)
                            : 'Select a date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _startDate == null
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
