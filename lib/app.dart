import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/realtime_service.dart';

class GxfApp extends ConsumerStatefulWidget {
  const GxfApp({super.key});

  @override
  ConsumerState<GxfApp> createState() => _GxfAppState();
}

class _GxfAppState extends ConsumerState<GxfApp> {
  late final GoRouter _router;
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
      ],
      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        final isLoggedIn = session != null;
        final isLoginPage = state.matchedLocation == '/login';
        final isResetPage = state.matchedLocation == '/reset-password';

        // Si on est en mode récupération de mot de passe
        // on ne redirige jamais ailleurs
        if (_isPasswordRecovery || isResetPage) return '/reset-password';
        if (!isLoggedIn && !isLoginPage) return '/login';
        if (isLoggedIn && isLoginPage) return '/dashboard';
        return null;
      },
      errorBuilder: (context, state) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );

    // Écoute les changements d'authentification
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.passwordRecovery) {
        // Marquer qu'on est en mode récupération
        // et forcer la navigation vers reset
        setState(() => _isPasswordRecovery = true);
        _router.go('/reset-password');
      } else if (event == AuthChangeEvent.userUpdated) {
        // Mot de passe mis à jour avec succès
        setState(() => _isPasswordRecovery = false);
        _router.go('/login');
      } else if (event == AuthChangeEvent.signedIn) {
        // Connexion normale — ignorer si on est en recovery
        if (!_isPasswordRecovery) {
          ref.read(realtimeServiceProvider).initialize();
          _router.go('/dashboard');
        }
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() => _isPasswordRecovery = false);
        _router.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GXF',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
