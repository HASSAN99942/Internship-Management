import 'package:flutter/material.dart';
import '../data/models/offer.dart';

/// Bottom sheet with keyword / location / duration filters.
/// Returns the new [OfferFilters] via [onApply].
class OfferFilterSheet extends StatefulWidget {
  const OfferFilterSheet({
    super.key,
    required this.current,
    required this.onApply,
  });

  final OfferFilters current;
  final ValueChanged<OfferFilters> onApply;

  static Future<void> show(
    BuildContext context, {
    required OfferFilters current,
    required ValueChanged<OfferFilters> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OfferFilterSheet(current: current, onApply: onApply),
    );
  }

  @override
  State<OfferFilterSheet> createState() => _OfferFilterSheetState();
}

class _OfferFilterSheetState extends State<OfferFilterSheet> {
  late final TextEditingController _q;
  late final TextEditingController _location;
  late final TextEditingController _duration;

  @override
  void initState() {
    super.initState();
    _q = TextEditingController(text: widget.current.q ?? '');
    _location = TextEditingController(text: widget.current.location ?? '');
    _duration = TextEditingController(
      text: widget.current.durationWeeks?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _q.dispose();
    _location.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _apply() {
    final dw = int.tryParse(_duration.text.trim());
    widget.onApply(
      OfferFilters(
        q: _q.text.trim().isEmpty ? null : _q.text.trim(),
        location:
            _location.text.trim().isEmpty ? null : _location.text.trim(),
        durationWeeks: dw,
      ),
    );
    Navigator.of(context).pop();
  }

  void _reset() {
    _q.clear();
    _location.clear();
    _duration.clear();
    widget.onApply(const OfferFilters());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Filter offers', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _q,
            decoration: const InputDecoration(
              labelText: 'Keyword',
              hintText: 'Title, skills, description…',
              prefixIcon: Icon(Icons.search_outlined),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'City or country',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _duration,
            decoration: const InputDecoration(
              labelText: 'Duration (weeks)',
              hintText: 'e.g. 8',
              prefixIcon: Icon(Icons.schedule_outlined),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _apply(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
