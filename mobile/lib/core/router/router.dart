import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/applications/screens/application_detail_screen.dart';
import '../../features/applications/screens/my_applications_screen.dart';
import '../../features/applications/screens/received_applications_screen.dart';
import '../../features/internships/screens/agreements_screen.dart';
import '../../features/internships/screens/internship_detail_screen.dart';
import '../../features/internships/screens/internships_list_screen.dart';
import '../../features/offers/screens/offer_detail_screen.dart';
import '../../features/offers/screens/offer_form_screen.dart';
import '../../features/offers/screens/offers_list_screen.dart';
import '../../features/offers/screens/my_offers_screen.dart';
import '../../features/messaging/screens/conversations_screen.dart';
import '../../features/messaging/screens/thread_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../widgets/app_scaffold.dart';
import '../../features/dashboard/screens/student_dashboard_screen.dart';
import '../../features/dashboard/screens/company_dashboard_screen.dart';
import '../../features/dashboard/screens/teacher_dashboard_screen.dart';

// ---------------------------------------------------------------------------
// Router provider — created once; GoRouter holds a reference to the notifier.
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (_, state) => notifier.redirect(state.uri.path),
    routes: [
      // Transient loading splash shown while session is being restored.
      GoRoute(
        path: '/loading',
        builder: (_, _) => const _LoadingScreen(),
      ),

      // ── Unauthenticated ──────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),

      // ── Full-screen push routes (outside shell — no bottom nav) ──────────

      // Offer detail — accessible from every role
      GoRoute(
        path: '/offers/:id',
        builder: (_, state) => OfferDetailScreen(
          offerId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Application detail
      GoRoute(
        path: '/applications/:id',
        builder: (_, state) => ApplicationDetailScreen(
          applicationId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Internship detail
      GoRoute(
        path: '/internships/:id',
        builder: (_, state) => InternshipDetailScreen(
          internshipId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Thread (messaging) — full-screen, outside shell
      GoRoute(
        path: '/threads/:id',
        builder: (_, state) => ThreadScreen(
          threadId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Notifications — full-screen, outside shell
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),

      // Company offer create/edit
      GoRoute(
        path: '/company/offers/new',
        builder: (_, _) => const OfferFormScreen(),
      ),
      GoRoute(
        path: '/company/offers/:id/edit',
        builder: (_, state) => OfferFormScreen(
          offerId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // ── Authenticated — role shell ───────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          // ── Student tabs ─────────────────────────────────────────────────
          GoRoute(
            path: '/student',
            builder: (_, _) => const StudentDashboardScreen(),
          ),
          GoRoute(
            path: '/student/offers',
            builder: (_, _) => const OffersListScreen(),
          ),
          GoRoute(
            path: '/student/applications',
            builder: (_, _) => const MyApplicationsScreen(),
          ),
          GoRoute(
            path: '/student/internship',
            builder: (_, _) => const InternshipsListScreen(),
          ),
          GoRoute(
            path: '/student/messages',
            builder: (_, _) => const ConversationsScreen(),
          ),

          // ── Company tabs ─────────────────────────────────────────────────
          GoRoute(
            path: '/company',
            builder: (_, _) => const CompanyDashboardScreen(),
          ),
          GoRoute(
            path: '/company/offers',
            builder: (_, _) => const OffersListScreen(),
          ),
          GoRoute(
            path: '/company/offers/manage',
            builder: (_, _) => const MyOffersScreen(),
          ),
          GoRoute(
            path: '/company/applications',
            builder: (_, _) => const ReceivedApplicationsScreen(),
          ),
          GoRoute(
            path: '/company/internships',
            builder: (_, _) => const InternshipsListScreen(),
          ),
          GoRoute(
            path: '/company/messages',
            builder: (_, _) => const ConversationsScreen(),
          ),

          // ── Teacher tabs ─────────────────────────────────────────────────
          GoRoute(
            path: '/teacher',
            builder: (_, _) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: '/teacher/offers',
            builder: (_, _) => const OffersListScreen(),
          ),
          GoRoute(
            path: '/teacher/agreements',
            builder: (_, _) => const AgreementsScreen(),
          ),
          GoRoute(
            path: '/teacher/students',
            builder: (_, _) => const InternshipsListScreen(),
          ),
          GoRoute(
            path: '/teacher/messages',
            builder: (_, _) => const ConversationsScreen(),
          ),

          // ── Admin ─────────────────────────────────────────────────────────
          GoRoute(
            path: '/admin',
            builder: (_, _) => const _AdminScreen(),
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Private screens (simple enough to live here)
// ---------------------------------------------------------------------------

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
}

class _AdminScreen extends StatelessWidget {
  const _AdminScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_outlined,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Admin', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Full administration is available via the web interface.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
