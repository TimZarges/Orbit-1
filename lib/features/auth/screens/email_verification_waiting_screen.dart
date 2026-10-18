import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../providers/auth_provider.dart';

/// Wartebildschirm für die E-Mail-Verifikation nach der Registrierung (Phase 36.2).
///
/// Features:
/// - Pollt alle 3 Sekunden per `user.reload()` auf den Verifikationsstatus.
/// - Automatische Weiterleitung zur Hauptanwendung, sobald `emailVerified == true`.
/// - Manuelle Aktions-Buttons: „Jetzt prüfen“, „E-Mail erneut senden“ und „Abmelden“.
class EmailVerificationWaitingScreen extends ConsumerStatefulWidget {
  const EmailVerificationWaitingScreen({super.key});

  @override
  ConsumerState<EmailVerificationWaitingScreen> createState() =>
      _EmailVerificationWaitingScreenState();
}

class _EmailVerificationWaitingScreenState
    extends ConsumerState<EmailVerificationWaitingScreen> {
  Timer? _pollingTimer;
  bool _isChecking = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final verified = await ref
            .read(authServiceProvider)
            .reloadAndCheckEmailVerified();
        if (verified && mounted) {
          timer.cancel();
          context.go('/');
        }
      } catch (_) {}
    });
  }

  Future<void> _checkNow() async {
    setState(() => _isChecking = true);
    try {
      final verified =
          await ref.read(authServiceProvider).reloadAndCheckEmailVerified();
      if (verified) {
        if (mounted) context.go('/');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Deine E-Mail ist noch nicht bestätigt. Bitte klicke auf den Link im Postfach (ggf. Spam prüfen).',
              ),
              backgroundColor: AppColors.amber,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prüfung fehlgeschlagen: $e'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bestätigungs-E-Mail wurde erneut versendet.'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konnte E-Mail nicht senden: $e'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _signOut() async {
    _pollingTimer?.cancel();
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    String email = '';
    try {
      email = FirebaseAuth.instance.currentUser?.email ?? '';
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFF001F47),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('E-Mail bestätigen',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            key: const Key('verify_email_signout_button'),
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Abmelden',
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
                        color: const Color(0xFF0F172A),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.volt, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mark_email_unread_outlined,
                          size: 48,
                          color: AppColors.volt,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bestätige deine E-Mail',
                    key: const Key('verify_email_title'),
                    textAlign: TextAlign.center,
                    style: AppTypography.headline.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    email.isNotEmpty
                        ? 'Wir haben einen Bestätigungslink an\n$email gesendet.'
                        : 'Wir haben einen Bestätigungslink an deine E-Mail-Adresse gesendet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Klicke auf den Link in der E-Mail, um dein ORBIT-Konto zu aktivieren. Diese Seite schaltet sich automatisch frei.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isChecking)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.volt),
                    )
                  else
                    ElevatedButton.icon(
                      key: const Key('verify_email_check_now_button'),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Jetzt prüfen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.volt,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _checkNow,
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('verify_email_resend_button'),
                    icon: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.volt),
                          )
                        : const Icon(Icons.send_outlined, size: 18),
                    label: const Text('E-Mail erneut senden'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.volt,
                      side: const BorderSide(color: AppColors.volt),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isResending ? null : _resendVerification,
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
