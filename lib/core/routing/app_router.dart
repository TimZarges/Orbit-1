import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../design/widget_gallery.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/user_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userDocState = ref.watch(userDocumentProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Wenn der AuthState noch lädt, bleiben wir erst mal stehen
      if (authState.isLoading) return null;

      final isAuth = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuth) {
        return isLoggingIn ? null : '/login';
      }

      // Wenn eingeloggt, prüfe das Onboarding
      if (isAuth && userDocState.valueOrNull != null) {
        final userData = userDocState.valueOrNull!;
        final hasCompletedOnboarding =
            userData['role'] != null && userData['profile'] != null;

        final isOnboarding = state.matchedLocation == '/onboarding';

        if (!hasCompletedOnboarding) {
          return isOnboarding ? null : '/onboarding';
        } else if (isLoggingIn || isOnboarding) {
          return '/';
        }
      } else if (isAuth &&
          userDocState.valueOrNull == null &&
          !userDocState.isLoading) {
        // Dokument existiert nicht -> Onboarding
        final isOnboarding = state.matchedLocation == '/onboarding';
        return isOnboarding ? null : '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const WidgetGalleryScreen(),
      ),
    ],
  );
});
