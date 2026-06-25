import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_providers.dart';
import '../../applications/providers/applications_providers.dart';
import '../../applications/screens/apply_sheet.dart';
import '../data/models/offer.dart';
import '../providers/offers_providers.dart';

class OfferDetailScreen extends ConsumerWidget {
  const OfferDetailScreen({super.key, required this.offerId});

  final int offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(offerDetailProvider(offerId));

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                const Text('Could not load offer'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(offerDetailProvider(offerId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (offer) => _OfferDetailView(offer: offer),
    );
  }
}

class _OfferDetailView extends ConsumerWidget {
  const _OfferDetailView({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = ref.watch(currentUserProvider);
    final isCompanyOwner =
        user?.role == 'company' && user?.id == offer.company.id;
    final isStudent = user?.role == 'student';

    // Check if this student already has an application for this offer.
    final myApps = isStudent
        ? ref.watch(myApplicationsProvider).valueOrNull
        : null;
    final existingApp = myApps
        ?.where((a) => a.offer.id == offer.id)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          offer.company.companyName,
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          if (isCompanyOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () =>
                  context.push('/company/offers/${offer.id}/edit'),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    offer.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge(status: offer.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              offer.company.companyName,
              style: theme.textTheme.titleSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Meta grid
            _InfoGrid(offer: offer),
            const SizedBox(height: 24),

            // Description
            _Section(
              title: 'About this internship',
              child: Text(
                offer.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),

            // Skills
            if (offer.skills.isNotEmpty) ...[
              const SizedBox(height: 20),
              _Section(
                title: 'Required skills',
                child: Text(
                  offer.skills,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Apply button — students only, published offers
            if (isStudent && offer.isOpen) ...[
              if (existingApp != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Application submitted · ${existingApp.status}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final applied = await ApplySheet.show(
                        context,
                        offerId: offer.id,
                        offerTitle: offer.title,
                      );
                      if (applied) {
                        // Trigger a reload of the applications list so the
                        // "already applied" chip appears on next watch cycle.
                        ref.invalidate(myApplicationsProvider);
                      }
                    },
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Apply for this internship'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String fmtDate(String iso) {
      try {
        return DateFormat('MMMM d, y').format(DateTime.parse(iso));
      } catch (_) {
        return iso;
      }
    }

    final items = [
      (Icons.location_on_outlined, 'Location', offer.location),
      (Icons.schedule_outlined, 'Duration', '${offer.durationWeeks} weeks'),
      (
        Icons.people_outline,
        'Positions',
        '${offer.positions} open position${offer.positions == 1 ? '' : 's'}'
      ),
      (Icons.calendar_today_outlined, 'Start date', fmtDate(offer.startDate)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items
            .map(
              (item) => _InfoRow(
                icon: item.$1,
                label: item.$2,
                value: item.$3,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
