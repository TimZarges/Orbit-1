import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/profile/screens/thresholds_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/integrations/screens/garmin_connection_screen.dart';
import '../../features/beta_feedback/screens/admin_feedback_screen.dart';
import '../design/widget_gallery.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/user_provider.dart';
import '../../features/workout_builder/screens/workout_builder_screen.dart';
import '../../features/workout_builder/screens/workout_template_library_screen.dart';
import '../../features/analysis/screens/analysis_tab_screen.dart';
import '../../features/diagnostics/screens/diagnostics_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/health/screens/health_cockpit_screen.dart';
import '../../features/activities/screens/activity_detail_loader.dart';
import '../../features/coach_link/screens/trainer_athletes_tab_screen.dart';
import '../../features/auth/screens/email_verification_waiting_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Zentraler Router-Provider der ORBIT-Applikation auf Basis von GoRouter.
///
/// Verwaltet die Navigation, Deep-Link-Normalisierung (z. B. `orbit://oauth/garmin`),
/// Authentifizierungs-Guards und den automatischen Onboarding-First-Flow für Neunutzer.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userDocState = ref.watch(userDocumentProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // 1. Eigene Scheme-Deep-Links (z. B. orbit://oauth/garmin?oauth_token=...&oauth_verifier=...) normalisieren
      if (state.uri.scheme == 'orbit') {
        final host = state.uri.host;
        final path = state.uri.path;
        final cleanPath = host.isNotEmpty ? '/$host$path' : path;
        final query = state.uri.hasQuery ? '?${state.uri.query}' : '';
        return '$cleanPath$query';
      }

      // Wenn der AuthState noch lädt, bleiben wir erst mal stehen
      if (authState.isLoading) return null;

      final isAuth = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuth) {
        final isOnboarding = state.matchedLocation == '/onboarding';
        return (isLoggingIn || isOnboarding) ? null : '/login';
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
    errorBuilder: (context, state) {
      // Fallback für ungematchte Garmin-OAuth-Callbacks
      final uri = state.uri;
      final uriStr = uri.toString();
      if (uri.scheme == 'orbit' ||
          uri.path.contains('garmin') ||
          uriStr.contains('oauth_verifier')) {
        return GarminConnectionScreen(
          initialVerifier: uri.queryParameters['oauth_verifier'],
          initialToken: uri.queryParameters['oauth_token'],
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Seite nicht gefunden')),
        body: Center(
          child: Text(state.error?.toString() ?? 'Fehler beim Laden'),
        ),
      );
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
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationWaitingScreen(),
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
            path: 'diagnostics',
            builder: (context, state) {
              final athleteId = state.uri.queryParameters['athleteId'] ??
                  FirebaseAuth.instance.currentUser?.uid ??
                  '';
              return DiagnosticsScreen(athleteId: athleteId);
            },
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
            path: 'health',
            builder: (context, state) => HealthCockpitScreen(
              athleteId: state.uri.queryParameters['athleteId'],
              athleteName: state.uri.queryParameters['athleteName'],
            ),
          ),
          GoRoute(
            path: 'activities/:id',
            builder: (context, state) {
              final activityId = state.pathParameters['id'] ?? '';
              return ActivityDetailLoader(activityId: activityId);
            },
          ),
          GoRoute(
            path: 'workout-builder',
            builder: (context, state) => WorkoutBuilderScreen(
              sport: state.uri.queryParameters['sport'] ?? 'BIKE',
              targetLocalDate: state.uri.queryParameters['date'],
            ),
          ),
          GoRoute(
            path: 'chat/:chatId',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId'] ?? '';
              final athleteId = state.uri.queryParameters['athleteId'];
              final name = state.uri.queryParameters['name'] ?? 'Coach';
              return ChatScreen(
                chatId: chatId,
                athleteId: athleteId,
                otherUserName: name,
              );
            },
          ),
          GoRoute(
            path: 'chats',
            builder: (context, state) => const ChatListScreen(),
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
        ],
      ),
      GoRoute(
        path: '/oauth/garmin',
        builder: (context, state) => GarminConnectionScreen(
          initialVerifier: state.uri.queryParameters['oauth_verifier'],
          initialToken: state.uri.queryParameters['oauth_token'],
        ),
      ),
      GoRoute(
        path: '/callback/garmin',
        builder: (context, state) => GarminConnectionScreen(
          initialVerifier: state.uri.queryParameters['oauth_verifier'],
          initialToken: state.uri.queryParameters['oauth_token'],
        ),
      ),
      GoRoute(
        path: '/admin/feedback',
        builder: (context, state) => const AdminFeedbackScreen(),
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const WidgetGalleryScreen(),
      ),
      GoRoute(
        path: '/trainer',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Trainer Dashboard')),
          body: const TrainerAthletesTabScreen(),
        ),
      ),
    ],
  );
});
