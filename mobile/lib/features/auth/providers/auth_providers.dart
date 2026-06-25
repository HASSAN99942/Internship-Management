import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/token_store.dart';
import '../data/auth_repository.dart';
import '../data/models/user.dart';

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthUnknown()) {
    _init();
  }

  final AuthRepository _repo;

  Future<void> _init() async {
    state = const AuthLoading();
    try {
      final hasTokens = await tokenStore.hasTokens();
      if (!hasTokens) {
        state = const AuthUnauthenticated();
        return;
      }
      final user = await _repo.me();
      state = AuthAuthenticated(user);
    } catch (_) {
      // Storage unavailable (e.g. WebCrypto on HTTP) or /me failed — treat as
      // unauthenticated so the app never gets stuck on the loading screen.
      try {
        await tokenStore.clearTokens();
      } catch (_) {}
      state = const AuthUnauthenticated();
    }
  }

  /// Logs in and sets [AuthAuthenticated]. Throws [DioException] on failure
  /// so the calling screen can display the error — state is NOT set to loading
  /// here because the screen owns its loading indicator.
  Future<void> login(String email, String password) async {
    final tokens = await _repo.login(email, password);
    await tokenStore.saveTokens(
        access: tokens.access, refresh: tokens.refresh);
    final user = await _repo.me();
    state = AuthAuthenticated(user);
  }

  /// Registers then auto-logs in. Throws on failure.
  Future<void> register(Map<String, dynamic> payload) async {
    await _repo.register(payload);
    await login(
      payload['email'] as String,
      payload['password'] as String,
    );
  }

  Future<void> logout() async {
    final refresh = await tokenStore.getRefreshToken();
    if (refresh != null) {
      try {
        await _repo.logout(refresh);
      } catch (_) {}
    }
    await tokenStore.clearTokens();
    state = const AuthUnauthenticated();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);

final currentUserProvider = Provider<User?>((ref) {
  final s = ref.watch(authControllerProvider);
  return switch (s) {
    AuthAuthenticated(:final user) => user,
    _ => null,
  };
});

// ---------------------------------------------------------------------------
// RouterNotifier — bridges Riverpod auth state to GoRouter refreshListenable
// ---------------------------------------------------------------------------

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (_, next) => notifyListeners(),
    );
  }

  final Ref _ref;

  String? redirect(String location) {
    final authState = _ref.read(authControllerProvider);

    return switch (authState) {
      // Still initialising — show loading screen; don't redirect if already there.
      AuthUnknown() || AuthLoading() =>
        location == '/loading' ? null : '/loading',

      // Not logged in — allow only login / register; push everything else to /login.
      AuthUnauthenticated() =>
        (location == '/login' || location == '/register') ? null : '/login',

      // Logged in — leave any "guest" route (including /loading) to the role home.
      AuthAuthenticated(:final user) => switch (location) {
          '/login' || '/register' || '/loading' => _roleHome(user.role),
          _ => null,
        },
    };
  }

  static String _roleHome(String role) => switch (role) {
        'student' => '/student',
        'company' => '/company',
        'teacher' => '/teacher',
        'admin' => '/admin',
        _ => '/login',
      };
}
