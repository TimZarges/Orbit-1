import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../providers/auth_provider.dart';

/// Anmelde-Bildschirm der ORBIT-Applikation (Phase 36 Login-First).
///
/// Ermöglicht bestehenden Athleten und Trainern den Login via E-Mail und Passwort,
/// bietet einen Passwort-Zurücksetzen-Flow per E-Mail sowie den direkten Einstieg
/// in die Registrierung / das Onboarding für Neukunden.
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

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib E-Mail und Passwort ein.')),
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
            content: Text('Anmeldung fehlgeschlagen: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Öffnet den „Passwort vergessen?“-Dialog und sendet bei Bestätigung eine Reset-E-Mail.
  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    final formKey = GlobalKey<FormState>();

    final targetEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: const Text(
          'Passwort zurücksetzen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gib deine E-Mail-Adresse ein. Wir senden dir umgehend einen sicheren Link zum Zurücksetzen deines Passworts.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('forgot_password_email_field'),
                controller: resetEmailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-Mail-Adresse',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: AppColors.volt),
                  filled: true,
                  fillColor: const Color(0xFF001F47),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.volt, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty || !val.contains('@')) {
                    return 'Bitte gib eine gültige E-Mail-Adresse ein';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            key: const Key('forgot_password_submit_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.volt,
              foregroundColor: AppColors.navy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(resetEmailController.text.trim());
              }
            },
            child: const Text('Link senden',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (targetEmail != null && targetEmail.isNotEmpty) {
      try {
        await ref.read(authServiceProvider).resetPassword(targetEmail);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Wir haben dir einen Link zum Zurücksetzen an $targetEmail gesendet.',
              ),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('E-Mail konnte nicht gesendet werden: $e'),
              backgroundColor: AppColors.coral,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Anmelden', style: TextStyle(color: AppColors.white)),
        actions: const [
          BetaBugReportIconButton(),
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
                        color: const Color(0xFF002A5C),
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
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'High-End Telemetrie & Performance Coaching',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    key: const Key('login_email_field'),
                    controller: _emailController,
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      labelText: 'E-Mail-Adresse',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: AppColors.volt),
                      filled: true,
                      fillColor: const Color(0xFF002A5C),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF003D82)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.volt, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('login_password_field'),
                    controller: _passwordController,
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: AppColors.volt),
                      filled: true,
                      fillColor: const Color(0xFF002A5C),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF003D82)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.volt, width: 2),
                      ),
                    ),
                    obscureText: true,
                  ),
                  // Passwort vergessen Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('login_forgot_password_button'),
                      onPressed: _showForgotPasswordDialog,
                      style:
                          TextButton.styleFrom(foregroundColor: AppColors.volt),
                      child: const Text('Passwort vergessen?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.volt),
                    )
                  else ...[
                    ElevatedButton(
                      key: const Key('login_submit_button'),
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.volt,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Anmelden',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      key: const Key('login_register_button'),
                      onPressed: () {
                        context.go('/onboarding');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.volt,
                        side:
                            const BorderSide(color: AppColors.volt, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Konto erstellen / Registrieren',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
