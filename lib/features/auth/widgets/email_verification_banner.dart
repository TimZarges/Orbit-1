/// Datei-Header: `lib/features/auth/widgets/email_verification_banner.dart`
/// Zweck: Kompakter, zweisprachiger (DE & EN) Hinweis-Banner für angemeldete
/// Nutzer mit noch unbestätigter E-Mail-Adresse (`emailVerified == false`)
/// inklusive automatischem Lifecycle-Refresh (`AppLifecycleState.resumed`),
/// Stream-Anbindung (`userChanges`/`idTokenChanges`) und Sofort-Prüfen-Button.
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

/// Zeigt bei unbestätigter E-Mail-Adresse ein reaktives Verifizierungs-Banner an.
///
/// Was:
/// - Überwacht `authStateChangesProvider`, `userChangesProvider`, `idTokenChangesProvider`
///   sowie `emailVerificationControllerProvider` und reagiert zusätzlich auf
///   `AppLifecycleState.resumed` (Rückkehr aus E-Mail-App oder Browser-Tab).
/// - Bietet direkt im Banner den Button **„Bereits bestätigt? Status prüfen“**
///   (DE) / **„Already verified? Check status“** (EN), der sofort `reload()`
///   ausführt und das Banner bei `emailVerified == true` unverzüglich ausblendet.
/// - Ermöglicht zudem „Erneut senden“ und optionalen Sprung auf `/verify-email`.
/// Warum: Vermeidet das bisherige Hängenbleiben des Banners bis zu einem manuellen
/// Relogin und bleibt dank Overrides vollständig widget-testbar.
class EmailVerificationBanner extends ConsumerStatefulWidget {
  /// Optionaler Test-Override für den aktuellen Auth-Nutzer.
  final User? userOverride;

  /// Optionaler Test-Override beim Öffnen der Verifizierungsansicht.
  final VoidCallback? onTapVerifyOverride;

  /// Optionaler Test-Override beim erneuten Versenden des Links.
  final Future<void> Function(User user)? onResendOverride;

  /// Optionaler Test-Override für „Bereits bestätigt? Status prüfen“ (`reload()`).
  final Future<bool> Function(User user)? onCheckStatusOverride;

  /// Erstellt ein [EmailVerificationBanner].
  const EmailVerificationBanner({
    super.key,
    this.userOverride,
    this.onTapVerifyOverride,
    this.onResendOverride,
    this.onCheckStatusOverride,
  });

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner> with WidgetsBindingObserver {
  bool _isCheckingLocal = false;
  bool _verifiedInOverride = false;
  DateTime? _lastAutoRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Einmaliger stiller Abgleich beim Erscheinen im Dashboard (nur im Live-Betrieb)
    if (widget.userOverride == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerSilentRefresh();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant EmailVerificationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userOverride != oldWidget.userOverride) {
      _verifiedInOverride = widget.userOverride?.emailVerified ?? false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Beim Zurückkehren aus dem E-Mail-Postfach oder Browser-Tab sofort neu laden
    if (state == AppLifecycleState.resumed && mounted) {
      _triggerSilentRefresh();
    }
  }

  /// Prüft den Status still im Hintergrund (mit 2-Sekunden-Entprellung).
  Future<void> _triggerSilentRefresh() async {
    final now = DateTime.now();
    if (_lastAutoRefreshAt != null &&
        now.difference(_lastAutoRefreshAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastAutoRefreshAt = now;

    if (widget.userOverride != null) {
      if (widget.onCheckStatusOverride != null &&
          !(widget.userOverride!.emailVerified || _verifiedInOverride)) {
        final verified =
            await widget.onCheckStatusOverride!(widget.userOverride!);
        if (mounted && verified) {
          setState(() => _verifiedInOverride = true);
        }
      }
      return;
    }

    await ref
        .read(emailVerificationControllerProvider.notifier)
        .reloadAndRefreshEmailVerification();
  }

  /// Führt die manuelle Statusprüfung auf Knopfdruck („Bereits bestätigt? Status prüfen“) aus.
  Future<void> _handleCheckStatusPressed(
    User user, {
    required bool isEn,
  }) async {
    if (_isCheckingLocal) return;
    setState(() => _isCheckingLocal = true);
    try {
      final bool verified;
      if (widget.onCheckStatusOverride != null) {
        verified = await widget.onCheckStatusOverride!(user);
      } else if (widget.userOverride != null) {
        await user.reload();
        verified = user.emailVerified;
      } else {
        verified = await ref
            .read(emailVerificationControllerProvider.notifier)
            .reloadAndRefreshEmailVerification();
      }

      if (!mounted) return;
      if (verified) {
        setState(() {
          _verifiedInOverride = true;
          _isCheckingLocal = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn
                  ? 'Email verified! Your account is now confirmed.'
                  : 'E-Mail bestätigt! Dein Konto ist jetzt vollständig aktiviert.',
            ),
            backgroundColor: AppColors.emerald,
          ),
        );
      } else {
        setState(() => _isCheckingLocal = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn
                  ? 'Not verified yet. Please open the link in your inbox (or spam folder) first.'
                  : 'Noch nicht bestätigt. Bitte klicke zuerst auf den Link in deinem Postfach (ggf. Spam prüfen).',
            ),
            backgroundColor: AppColors.amber,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingLocal = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn ? 'Check failed: $e' : 'Statusprüfung fehlgeschlagen: $e',
          ),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = widget.userOverride ??
        ref.watch(userChangesProvider.select((s) => s.valueOrNull)) ??
        ref.watch(authStateChangesProvider.select((s) => s.valueOrNull));

    final bool controllerVerified = widget.userOverride == null
        ? ref.watch(
            emailVerificationControllerProvider.select((s) => s.isVerified),
          )
        : false;
    final bool controllerChecking = widget.userOverride == null
        ? ref.watch(
            emailVerificationControllerProvider.select((s) => s.isChecking),
          )
        : false;
    // Auch idTokenChanges reaktiv beobachten, damit Token-Updates sofort greifen
    final bool tokenUserVerified = widget.userOverride == null
        ? (ref.watch(
            idTokenChangesProvider
                .select((s) => s.valueOrNull?.emailVerified ?? false),
          ))
        : false;

    final bool isVerified = (user?.emailVerified ?? false) ||
        _verifiedInOverride ||
        (widget.userOverride == null &&
            (controllerVerified || tokenUserVerified));

    // Bestätigte Accounts und abgemeldete Zustände benötigen keinen Hinweis.
    if (user == null || isVerified) {
      return const SizedBox.shrink();
    }

    final isChecking = _isCheckingLocal || controllerChecking;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
              IconButton(
                key: const Key('unverified_email_open_button'),
                tooltip:
                    isEn ? 'Verification details' : 'Verifizierungs-Ansicht',
                onPressed: () {
                  if (widget.onTapVerifyOverride != null) {
                    widget.onTapVerifyOverride!();
                  } else {
                    context.go('/verify-email');
                  }
                },
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                key: const Key('unverified_email_check_status_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                ),
                onPressed: isChecking
                    ? null
                    : () => _handleCheckStatusPressed(user, isEn: isEn),
                icon: isChecking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  isEn
                      ? 'Already verified? Check status'
                      : 'Bereits bestätigt? Status prüfen',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                key: const Key('unverified_email_resend_button'),
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                ),
                onPressed: () async {
                  if (widget.onResendOverride != null) {
                    await widget.onResendOverride!(user);
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
                  isEn ? 'Resend' : 'Erneut senden',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
