import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/application.dart';
import '../providers/applications_providers.dart';

class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});
  final int applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(applicationDetailProvider(applicationId));

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              const Text('Could not load application'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(applicationDetailProvider(applicationId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (app) => _ApplicationDetailView(application: app),
    );
  }
}

class _ApplicationDetailView extends ConsumerWidget {
  const _ApplicationDetailView({required this.application});
  final Application application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = ref.watch(currentUserProvider);
    final isCompany = user?.role == 'company';
    final isStudent = user?.role == 'student';
    final isPending = application.status == 'pending';
    final isOwnApplication = isStudent && user?.id == application.student.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application'),
        actions: [StatusBadge(status: application.status)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offer info
            Text(
              application.offer.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${application.student.firstName} ${application.student.lastName}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              application.student.email,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),

            // Dates
            _MetaRow(
              icon: Icons.calendar_today_outlined,
              label: 'Applied',
              value: _fmtDate(application.createdAt),
            ),
            if (application.decidedAt != null)
              _MetaRow(
                icon: Icons.check_circle_outline,
                label: 'Decided',
                value: _fmtDate(application.decidedAt!),
              ),

            const SizedBox(height: 20),

            // Cover message
            _Section(
              title: 'Cover message',
              child: Text(
                application.coverMessage,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),

            // CV
            if (application.cvFile != null) ...[
              const SizedBox(height: 20),
              _Section(
                title: 'Curriculum Vitae',
                child: _CvButton(relativePath: application.cvFile!),
              ),
            ],

            // Action buttons
            if (isPending && (isCompany || (isStudent && isOwnApplication))) ...[
              const Divider(height: 40),
              if (isCompany) _CompanyActions(application: application),
              if (isStudent && isOwnApplication)
                _StudentActions(application: application),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(String iso) {
    try {
      return DateFormat('MMMM d, y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ---------------------------------------------------------------------------
// Company: accept / reject
// ---------------------------------------------------------------------------

class _CompanyActions extends ConsumerWidget {
  const _CompanyActions({required this.application});
  final Application application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _confirm(
              context,
              ref,
              title: 'Accept application?',
              message:
                  'An internship agreement will be created and sent for academic validation.',
              confirmLabel: 'Accept',
              onConfirm: () async {
                await ref
                    .read(receivedApplicationsProvider.notifier)
                    .accept(application.id);
                ref.invalidate(applicationDetailProvider(application.id));
              },
            ),
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                  color: Theme.of(context).colorScheme.error),
            ),
            onPressed: () => _confirm(
              context,
              ref,
              title: 'Reject application?',
              message: 'The student will be notified.',
              confirmLabel: 'Reject',
              destructive: true,
              onConfirm: () async {
                await ref
                    .read(receivedApplicationsProvider.notifier)
                    .reject(application.id);
                ref.invalidate(applicationDetailProvider(application.id));
              },
            ),
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Student: withdraw
// ---------------------------------------------------------------------------

class _StudentActions extends ConsumerWidget {
  const _StudentActions({required this.application});
  final Application application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        onPressed: () => _confirm(
          context,
          ref,
          title: 'Withdraw application?',
          message:
              'You will no longer be considered for this position.',
          confirmLabel: 'Withdraw',
          destructive: true,
          onConfirm: () async {
            await ref
                .read(myApplicationsProvider.notifier)
                .withdraw(application.id);
            ref.invalidate(applicationDetailProvider(application.id));
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        icon: const Icon(Icons.undo_outlined),
        label: const Text('Withdraw application'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CV button — opens in browser
// ---------------------------------------------------------------------------

class _CvButton extends StatelessWidget {
  const _CvButton({required this.relativePath});
  final String relativePath;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final absolute = _buildMediaUrl(relativePath);
        final uri = Uri.tryParse(absolute);
        if (uri == null) return;
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: const Icon(Icons.open_in_new, size: 18),
      label: const Text('Open CV'),
    );
  }

  static String _buildMediaUrl(String path) {
    if (path.startsWith('http')) return path;
    // Strip /api/v1 suffix from base URL to get the server origin.
    final base = dotenv.env['API_BASE_URL'] ?? '';
    final origin = base
        .replaceAll(RegExp(r'/api/v\d+/?$'), '')
        .replaceAll(RegExp(r'/$'), '');
    return '$origin$path';
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

void _confirm(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<void> Function() onConfirm,
  bool destructive = false,
}) {
  showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor:
                      Theme.of(ctx).colorScheme.error,
                  foregroundColor:
                      Theme.of(ctx).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  ).then((confirmed) async {
    if (confirmed == true && context.mounted) {
      try {
        await onConfirm();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  });
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.bodySmall
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
        Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
