/// Datei-Header: `lib/features/auth/screens/login_screen.dart`
/// Zweck: Anmelde-Bildschirm der ORBIT-Applikation im Clean Professional Design
/// (Hell & Dunkel) mit vollständiger DE/EN-Lokalisierung, „Passwort vergessen /
/// zurücksetzen“-Flow (`sendPasswordResetEmail`) und Einstieg ins Onboarding.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/auth/screens/`),
/// nutzt granulare Riverpod-Selektoren (`.select(...)`) (`AGENTS.md` Regel 10).
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/contact_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../legal/widgets/legal_documents_sheet.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/auth_provider.dart';

/// Anmelde-Bildschirm der ORBIT-Applikation (Login-First, Clean Professional Design).
///
/// Was:
/// - Ermöglicht bestehenden Athleten und Coaches die Anmeldung via E-Mail & Passwort.
/// - Bietet einen lokalisierten (DE/EN) „Passwort vergessen / zurücksetzen“-Flow
///   mit E-Mail-Validierung, Ladezustand und verständlichen Fehlermeldungen.
/// - Bietet den direkten Einstieg in die Registrierung / das Onboarding.
/// Warum: Vollständig an das Hell-/Dunkel-Theme und die DE/EN-Sprachsteuerung
/// von Phase 41–43 angebunden.
class LoginScreen extends ConsumerStatefulWidget {
  /// Erstellt den Anmelde-Bildschirm.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Übersetzt Firebase-Auth-Fehlercodes verständlich auf Deutsch oder Englisch.
  String _localizeAuthError(Object error, {required bool isEn}) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'invalid-credential':
          return isEn
              ? 'Invalid email or password.'
              : 'E-Mail-Adresse oder Passwort ist ungültig.';
        case 'wrong-password':
          return isEn
              ? 'Incorrect password.'
              : 'Das Passwort ist nicht korrekt.';
        case 'invalid-email':
          return isEn
              ? 'Please enter a valid email address.'
              : 'Bitte gib eine gültige E-Mail-Adresse ein.';
        case 'too-many-requests':
          return isEn
              ? 'Too many attempts. Please try again later.'
              : 'Zu viele Versuche. Bitte warte kurz und versuche es erneut.';
        default:
          return error.message ?? error.code;
      }
    }
    return error.toString();
  }

  /// Führt die Anmeldung über [AuthService.signInWithEmail] aus.
  Future<void> _login({required bool isEn}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'Please enter your email and password.'
                : 'Bitte gib E-Mail und Passwort ein.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithEmail(email, password);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn
                  ? 'Sign in failed: ${_localizeAuthError(e, isEn: true)}'
                  : 'Anmeldung fehlgeschlagen: ${_localizeAuthError(e, isEn: false)}',
            ),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Öffnet den lokalisierten „Passwort zurücksetzen“-Dialog mit Ladezustand & Fehlerbehandlung.
  ///
  /// Warum dediziertes [_ForgotPasswordDialog]-Widget statt lokalem Controller:
  /// Ein `StatefulWidget` gibt seinen `TextEditingController` erst in `State.dispose()`
  /// frei, nachdem die 150-ms-Schließanimation der `DialogRoute` vollständig beendet
  /// und das `TextFormField` aus dem Widget-Baum entfernt wurde. Dadurch ist eine
  /// `used after being disposed`-Exception während der Route-Transition ausgeschlossen.
  Future<void> _showForgotPasswordDialog({required bool isEn}) async {
    final initialEmail = _emailController.text.trim();
    await showDialog<void>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        initialEmail: initialEmail,
        isEn: isEn,
        parentContext: context,
        localizeError: (err) => _localizeAuthError(err, isEn: isEn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Granularer Selektor für die aktive Sprache (DE / EN)
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final isEn = lang == 'en';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.white : AppColors.lightTextPrimary;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF475569);
    final accentColor = isDark ? AppColors.volt : AppColors.navy;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEn ? 'Sign In' : 'Anmelden'),
        actions: [
          // Schnellumschaltung DE / EN direkt auf dem Login-Screen
          TextButton(
            key: const Key('login_lang_toggle_button'),
            onPressed: () {
              ref
                  .read(settingsControllerProvider.notifier)
                  .setLanguage(isEn ? 'de' : 'en');
            },
            child: Text(
              isEn ? 'DE' : 'EN',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const BetaBugReportIconButton(),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.anthraciteCard : AppColors.navy,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.volt, width: 2),
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 60,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.bolt,
                              size: 42,
                              color: AppColors.volt,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ORBIT',
                    key: const Key('login_brand_title'),
                    textAlign: TextAlign.center,
                    style: AppTypography.headline.copyWith(
                      color: primaryText,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEn
                        ? 'Endurance Telemetry & Coaching Platform'
                        : 'Ausdauer-Telemetrie & Performance-Plattform',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: secondaryText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    key: const Key('login_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Email Address' : 'E-Mail-Adresse',
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('login_password_field'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Password' : 'Passwort',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('login_forgot_password_button'),
                      onPressed: () => _showForgotPasswordDialog(isEn: isEn),
                      child: Text(
                        isEn ? 'Forgot password?' : 'Passwort vergessen?',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    key: const Key('login_submit_button'),
                    onPressed: _isLoading ? null : () => _login(isEn: isEn),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isEn ? 'Sign In' : 'Anmelden',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    key: const Key('login_register_button'),
                    onPressed: () => context.go('/onboarding'),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: Text(
                      isEn
                          ? 'Create Account / Register'
                          : 'Konto erstellen / Registrieren',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Direkter 1-Klick-Zugang zu Datenschutz, Impressum & Haupt-Webseite
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        key: const Key('login_privacy_button'),
                        onPressed: () => LegalDocumentsSheet.show(
                          context,
                          initialTab: LegalDocumentTab.privacy,
                          lang: lang,
                        ),
                        child: Text(
                          isEn ? 'Privacy Policy' : 'Datenschutz',
                          style: TextStyle(color: secondaryText, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        key: const Key('login_imprint_button'),
                        onPressed: () => LegalDocumentsSheet.show(
                          context,
                          initialTab: LegalDocumentTab.imprint,
                          lang: lang,
                        ),
                        child: Text(
                          isEn ? 'Legal Notice' : 'Impressum',
                          style: TextStyle(color: secondaryText, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        key: const Key('login_website_button'),
                        onPressed: () async {
                          final uri = Uri.tryParse(ContactConfig.websiteUrl);
                          if (uri != null) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Text(
                          isEn ? 'Website' : 'Webseite',
                          style: TextStyle(color: secondaryText, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eigenständiges Dialog-Widget für den „Passwort zurücksetzen“-Flow im [LoginScreen].
///
/// Was: Rendert das E-Mail-Formular zum Anfordern eines Passwort-Reset-Links.
/// Warum: Durch die Kapselung als [ConsumerStatefulWidget] wird der interne
/// [TextEditingController] exakt im `dispose()`-Lebenszyklus des Dialog-Subtrees
/// freigegeben (erst nach Abschluss der Dialog-Schließanimation).
class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  /// Vorausgefüllte E-Mail-Adresse aus dem Login-Feld.
  final String initialEmail;

  /// Gibt an, ob die Oberfläche auf Englisch (`true`) oder Deutsch (`false`) gerendert wird.
  final bool isEn;

  /// Übergeordneter Kontext für die Erfolgs-SnackBar nach dem Schließen.
  final BuildContext parentContext;

  /// Hilfsfunktion zur Übersetzung von Firebase-Auth-Fehlern.
  final String Function(Object error) localizeError;

  const _ForgotPasswordDialog({
    required this.initialEmail,
    required this.isEn,
    required this.parentContext,
    required this.localizeError,
  });

  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  late final TextEditingController _resetEmailController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSending = false;
  String? _dialogError;

  @override
  void initState() {
    super.initState();
    // Initialisiert den E-Mail-Controller mit dem aktuellen Login-Feldwert
    _resetEmailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    // Gibt den Controller erst nach vollständigem Unmount des Dialogs frei
    _resetEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = widget.isEn;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.anthraciteCard : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkSubtleBorder : AppColors.cardBorder,
        ),
      ),
      title: Text(
        isEn ? 'Reset Password' : 'Passwort zurücksetzen',
        style: TextStyle(
          color: isDark ? AppColors.white : AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'Enter your email address. We will send you a secure link to reset your password.'
                  : 'Gib deine E-Mail-Adresse ein. Wir senden dir umgehend einen sicheren Link zum Zurücksetzen deines Passworts.',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF475569),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('forgot_password_email_field'),
              controller: _resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isEn ? 'Email Address' : 'E-Mail-Adresse',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty || !val.contains('@')) {
                  return isEn
                      ? 'Please enter a valid email address'
                      : 'Bitte gib eine gültige E-Mail-Adresse ein';
                }
                return null;
              },
            ),
            if (_dialogError != null) ...[
              const SizedBox(height: 10),
              Text(
                _dialogError!,
                style: const TextStyle(
                  color: AppColors.coral,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: Text(isEn ? 'Cancel' : 'Abbrechen'),
        ),
        ElevatedButton(
          key: const Key('forgot_password_submit_button'),
          onPressed: _isSending
              ? null
              : () async {
                  if (!(_formKey.currentState?.validate() ?? false)) {
                    return;
                  }
                  final targetEmail = _resetEmailController.text.trim();
                  setState(() {
                    _isSending = true;
                    _dialogError = null;
                  });
                  try {
                    await ref
                        .read(authServiceProvider)
                        .resetPassword(targetEmail);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    if (widget.parentContext.mounted) {
                      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEn
                                ? 'We sent a password reset link to $targetEmail.'
                                : 'Wir haben dir einen Link zum Zurücksetzen an $targetEmail gesendet.',
                          ),
                          backgroundColor: AppColors.emerald,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isSending = false;
                        _dialogError = widget.localizeError(e);
                      });
                    }
                  }
                },
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  isEn ? 'Send Link' : 'Link senden',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
