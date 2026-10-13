import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/profile/screens/thresholds_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/integrations/screens/garmin_connection_screen.dart';
import '../design/widget_gallery.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/user_provider.dart';
import '../../features/workout_builder/screens/workout_builder_screen.dart';
import '../../features/workout_builder/screens/workout_template_library_screen.dart';
import '../../features/analysis/screens/analysis_tab_screen.dart';

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
          routes: [
            GoRoute(
              path: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: 'thresholds',
              builder: (context, state) => const ThresholdsScreen(),
            ),
            GoRoute(
              path: 'calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
            GoRoute(
              path: 'templates',
              builder: (context, state) => const WorkoutTemplateLibraryScreen(),
            ),
            GoRoute(
              path: 'analysis',
              builder: (context, state) => AnalysisTabScreen(
                athleteId: state.uri.queryParameters['athleteId'],
                athleteName: state.uri.queryParameters['athleteName'],
              ),
            ),
            GoRoute(
              path: 'workout-builder',
              builder: (context, state) => WorkoutBuilderScreen(
                sport: state.uri.queryParameters['sport'] ?? 'BIKE',
                targetLocalDate: state.uri.queryParameters['date'],
              ),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'garmin',
                  builder: (context, state) => GarminConnectionScreen(
                    initialVerifier: state.uri.queryParameters['oauth_verifier'],
                    initialToken: state.uri.queryParameters['oauth_token'],
                  ),
                ),
              ],
            ),
          ]),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const WidgetGalleryScreen(),
      ),
    ],
  );
});
