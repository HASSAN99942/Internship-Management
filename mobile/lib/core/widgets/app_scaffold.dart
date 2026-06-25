import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/notifications/providers/notifications_provider.dart';
import '../theme/theme_provider.dart';

// ---------------------------------------------------------------------------
// Tab configuration per role
// ---------------------------------------------------------------------------

class _Tab {
  const _Tab(this.route, this.icon, this.activeIcon, this.label);
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const _studentTabs = [
  _Tab('/student', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  _Tab('/student/offers', Icons.work_outline, Icons.work, 'Offers'),
  _Tab('/student/applications', Icons.description_outlined, Icons.description,
      'Applications'),
  _Tab('/student/internship', Icons.school_outlined, Icons.school,
      'Internship'),
  _Tab('/student/messages', Icons.chat_bubble_outline, Icons.chat_bubble,
      'Messages'),
];

const _companyTabs = [
  _Tab('/company', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  _Tab('/company/offers', Icons.work_outline, Icons.work, 'Offers'),
  _Tab('/company/applications', Icons.inbox_outlined, Icons.inbox,
      'Applications'),
  _Tab('/company/internships', Icons.business_center_outlined,
      Icons.business_center, 'Internships'),
  _Tab('/company/messages', Icons.chat_bubble_outline, Icons.chat_bubble,
      'Messages'),
];

const _teacherTabs = [
  _Tab('/teacher', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  _Tab('/teacher/offers', Icons.work_outline, Icons.work, 'Offers'),
  _Tab('/teacher/agreements', Icons.check_circle_outline,
      Icons.check_circle, 'Agreements'),
  _Tab('/teacher/students', Icons.people_outlined, Icons.people, 'Students'),
  _Tab('/teacher/messages', Icons.chat_bubble_outline, Icons.chat_bubble,
      'Messages'),
];

const _adminTabs = [
  _Tab('/admin', Icons.admin_panel_settings_outlined,
      Icons.admin_panel_settings, 'Admin'),
];

List<_Tab> _tabsForRole(String? role) => switch (role) {
      'student' => _studentTabs,
      'company' => _companyTabs,
      'teacher' => _teacherTabs,
      'admin' => _adminTabs,
      _ => _studentTabs,
    };

// ---------------------------------------------------------------------------
// AppScaffold
// ---------------------------------------------------------------------------

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tabs = _tabsForRole(user?.role);
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForLocation(location, tabs);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForRole(user?.role)),
        actions: [
          const _NotificationBell(),
          // User menu
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: user?.displayName ?? 'Account',
            onSelected: (action) => _handleMenu(context, ref, action),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _MenuAction.toggleTheme,
                child: Row(
                  children: [
                    const Icon(Icons.brightness_6_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(_themeModeLabel(
                        ref.read(themeModeProvider))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _MenuAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(tabs[i].route),
        destinations: tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }

  static int _indexForLocation(String location, List<_Tab> tabs) {
    // Prefer the most specific (longest) matching prefix.
    int best = 0;
    int bestLen = 0;
    for (int i = 0; i < tabs.length; i++) {
      final route = tabs[i].route;
      if (location.startsWith(route) && route.length > bestLen) {
        best = i;
        bestLen = route.length;
      }
    }
    return best;
  }

  static String _titleForRole(String? role) => switch (role) {
        'student' => 'Internship Platform',
        'company' => 'Internship Platform',
        'teacher' => 'Internship Platform',
        'admin' => 'Admin',
        _ => 'Internship Platform',
      };

  static String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'Switch to light',
        ThemeMode.light => 'Switch to dark',
        ThemeMode.system => 'Switch theme',
      };

  Future<void> _handleMenu(
    BuildContext context,
    WidgetRef ref,
    _MenuAction action,
  ) async {
    switch (action) {
      case _MenuAction.toggleTheme:
        await ref.read(themeModeProvider.notifier).toggle();
      case _MenuAction.logout:
        await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

enum _MenuAction { toggleTheme, logout }

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider);

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.push('/notifications'),
      icon: count > 0
          ? Badge(
              label: Text(count > 9 ? '9+' : '$count'),
              child: const Icon(Icons.notifications_outlined),
            )
          : const Icon(Icons.notifications_outlined),
    );
  }
}
