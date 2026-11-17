/// Datei-Header: `lib/features/auth/screens/email_verification_waiting_screen.dart`
/// Zweck: Wartebildschirm für die E-Mail-Verifikation nach Registrierung im
/// Clean Professional Design (Hell & Dunkel), mit DE/EN-Lokalisierung, 60s-Spam-
/// Cooldown für „Erneut senden“ und automatischem `user.reload()`-Polling.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/auth/screens/`),
/// nutzt granulare Riverpod-Selektoren (`.select(...)`) (`AGENTS.md` Regel 10).
library;

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_guard_service.dart';

/// Wartebildschirm für die E-Mail-Verifikation (`sendEmailVerification` & `reload`).
///
/// Was:
/// - Pollt alle 3 Sekunden per `user.reload()` auf den Verifikationsstatus.
/// - Leitet bei `emailVerified == true` automatisch in die Hauptanwendung weiter.
/// - Bietet „Ich habe bestätigt – Status prüfen“ (`reload`), „Bestätigungs-E-Mail
///   erneut senden“ (mit 60-Sekunden-Cooldown gegen Spam) und „Abmelden“.
/// Warum: Sicherer, nutzerfreundlicher Verifikations-Flow auf DE & EN im Light/Dark Mode.
class EmailVerificationWaitingScreen extends ConsumerStatefulWidget {
  /// Erstellt den [EmailVerificationWaitingScreen].
  const EmailVerificationWaitingScreen({super.key});

  @override
  ConsumerState<EmailVerificationWaitingScreen> createState() =>
      _EmailVerificationWaitingScreenState();
}

class _EmailVerificationWaitingScreenState
    extends ConsumerState<EmailVerificationWaitingScreen> {
  Timer? _pollingTimer;
  Timer? _cooldownTimer;
  bool _isChecking = false;
  bool _isResending = false;
  int _resendCooldownSec = 0;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Startet das 3-Sekunden-Polling auf `emailVerified`.
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final verified =
            await ref.read(authServiceProvider).reloadAndCheckEmailVerified();
        if (verified && mounted) {
          timer.cancel();
          context.go('/');
        }
      } catch (_) {}
    });
  }

  /// Startet einen 60-Sekunden-Cooldown für den Button „E-Mail erneut senden“.
  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldownSec = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldownSec <= 1) {
        timer.cancel();
        setState(() => _resendCooldownSec = 0);
      } else {
        setState(() => _resendCooldownSec--);
      }
    });
  }

  /// Prüft den Bestätigungsstatus sofort per `user.reload()`.
  Future<void> _checkNow({required bool isEn}) async {
    setState(() => _isChecking = true);
    try {
      final verified =
          await ref.read(authServiceProvider).reloadAndCheckEmailVerified();
      if (verified) {
        if (mounted) context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn
                  ? 'Your email is not verified yet. Please click the link in your inbox (check spam).'
                  : 'Deine E-Mail ist noch nicht bestätigt. Bitte klicke auf den Link im Postfach (ggf. Spam prüfen).',
            ),
            backgroundColor: AppColors.amber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn ? 'Check failed: $e' : 'Prüfung fehlgeschlagen: $e',
            ),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  /// Sendet die Bestätigungs-E-Mail erneut und aktiviert den 60s-Cooldown.
  Future<void> _resendVerification({required bool isEn}) async {
    if (_resendCooldownSec > 0) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      _startResendCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn
                  ? 'Verification email has been sent again.'
                  : 'Bestätigungs-E-Mail wurde erneut versendet.',
            ),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn
                  ? 'Could not send email: $e'
                  : 'Konnte E-Mail nicht senden: $e',
            ),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  /// Meldet den Benutzer ab und leitet auf `/login` zurück.
  Future<void> _signOut() async {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
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

    String email = '';
    try {
      email = FirebaseAuth.instance.currentUser?.email ?? '';
    } catch (_) {}

    final resendLabel = _resendCooldownSec > 0
        ? (isEn
            ? 'Resend email (${_resendCooldownSec}s)'
            : 'E-Mail erneut senden (${_resendCooldownSec}s)')
        : (isEn
            ? 'Resend verification email'
            : 'Bestätigungs-E-Mail erneut senden');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEn ? 'Verify Email' : 'E-Mail bestätigen'),
        actions: [
          IconButton(
            key: const Key('verify_email_signout_button'),
            icon: const Icon(Icons.logout),
            tooltip: isEn ? 'Sign Out' : 'Abmelden',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.anthraciteCard : AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 2),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.mark_email_unread_outlined,
                          size: 48,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isEn ? 'Confirm your email' : 'Bestätige deine E-Mail',
                    key: const Key('verify_email_title'),
                    textAlign: TextAlign.center,
                    style: AppTypography.headline.copyWith(
                      color: primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    email.isNotEmpty
                        ? (isEn
                            ? 'We sent a verification link to\n$email.'
                            : 'Wir haben einen Bestätigungslink an\n$email gesendet.')
                        : (isEn
                            ? 'We sent a verification link to your email address.'
                            : 'Wir haben einen Bestätigungslink an deine E-Mail-Adresse gesendet.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEn
                        ? 'Click the link in the email to activate your ORBIT account.'
                        : 'Klicke auf den Link in der E-Mail, um dein ORBIT-Konto zu aktivieren.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isChecking)
                    Center(
                      child: CircularProgressIndicator(color: accentColor),
                    )
                  else
                    ElevatedButton.icon(
                      key: const Key('verify_email_check_now_button'),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: Text(
                        isEn
                            ? 'I confirmed – Check status'
                            : 'Ich habe bestätigt – Status prüfen',
                      ),
                      onPressed: () => _checkNow(isEn: isEn),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('verify_email_resend_button'),
                    icon: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined, size: 18),
                    label: Text(resendLabel),
                    onPressed: (_isResending || _resendCooldownSec > 0)
                        ? null
                        : () => _resendVerification(isEn: isEn),
                  ),
                  if (AuthGuardService.kBetaAllowUnverifiedEmail) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      key: const Key('verify_email_skip_beta_button'),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(
                        isEn ? 'Skip for now' : 'Vorerst überspringen',
                      ),
                      onPressed: () {
                        _pollingTimer?.cancel();
                        context.go('/');
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
