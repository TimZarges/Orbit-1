/// Datei-Header: `lib/features/auth/widgets/email_verification_banner.dart`
/// Zweck: Kompakter, zweisprachiger (DE & EN) Hinweis-Banner für angemeldete
/// Nutzer mit noch unbestätigter E-Mail-Adresse (`emailVerified == false`).
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/auth/widgets/`),
/// nutzt granulare Riverpod-Selektoren (`.select(...)`) ohne unnötige Rebuilds
/// (`AGENTS.md` Regel 10).
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_guard_service.dart';

/// Zeigt bei unbestätigter E-Mail-Adresse ein klares Verifizierungs-Banner an.
///
/// Was: Rendert bei `user != null && !user.emailVerified` eine kompakte
/// Hinweiszeile mit 1-Klick-Sprung zum `EmailVerificationWaitingScreen` (`/verify-email`)
/// sowie direktem „Erneut senden“-Button. Bei bestätigten Nutzern (`emailVerified == true`)
/// oder im Test ohne Auth-Nutzer rendert das Widget `SizedBox.shrink()`.
/// Warum: Verbindet reibungslosen V1.0.0-Zugang mit sichtbarer Konto-Absicherung
/// nach Registrierung (`AGENTS.md` Regel 10).
class EmailVerificationBanner extends ConsumerWidget {
  /// Optionaler Test-Override für den aktuellen Auth-Nutzer.
  final User? userOverride;

  /// Optionaler Test-Callback beim Öffnen der Verifizierungsansicht.
  final VoidCallback? onTapVerifyOverride;

  /// Optionaler Test-Callback beim erneuten Versenden des Links.
  final Future<void> Function(User user)? onResendOverride;

  /// Erstellt ein [EmailVerificationBanner].
  const EmailVerificationBanner({
    super.key,
    this.userOverride,
    this.onTapVerifyOverride,
    this.onResendOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = userOverride ??
        ref.watch(authStateChangesProvider.select((s) => s.valueOrNull));

    // Bestätigte Accounts und abgemeldete Zustände benötigen keinen Hinweis.
    if (user == null || user.emailVerified) {
      return const SizedBox.shrink();
    }

    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final isEn = lang == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2B2312) : const Color(0xFFFFFBEB);
    final borderColor = isDark
        ? AppColors.amber.withValues(alpha: 0.45)
        : const Color(0xFFF59E0B);
    final textColor = isDark ? Colors.white : const Color(0xFF78350F);
    final accentColor = isDark ? AppColors.amber : const Color(0xFFB45309);
    final emailLabel = user.email ?? '';

    return Container(
      key: const Key('unverified_email_banner'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_email_unread_outlined,
            color: accentColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEn
                      ? 'Please verify your email address'
                      : 'Bitte E-Mail-Adresse bestätigen',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (emailLabel.isNotEmpty)
                  Text(
                    emailLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            key: const Key('unverified_email_resend_button'),
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 34),
            ),
            onPressed: () async {
              if (onResendOverride != null) {
                await onResendOverride!(user);
              } else {
                await AuthGuardService.triggerVerificationEmailSafely(user);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEn
                          ? 'Verification link sent. Please check your inbox.'
                          : 'Bestätigungslink gesendet. Bitte Postfach prüfen.',
                    ),
                  ),
                );
              }
            },
            child: Text(
              isEn ? 'Resend' : 'Erneut',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(
            key: const Key('unverified_email_open_button'),
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 34),
            ),
            onPressed: () {
              if (onTapVerifyOverride != null) {
                onTapVerifyOverride!();
              } else {
                context.go('/verify-email');
              }
            },
            child: Text(
              isEn ? 'Verify' : 'Prüfen',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
