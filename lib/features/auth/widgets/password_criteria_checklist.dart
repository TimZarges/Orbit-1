import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';

/// Reusable Widget zur interaktiven Live-Validierung von Passwort-Kriterien (Phase 36.2).
///
/// Prüft und visualisiert folgende Sicherheitskriterien in Echtzeit:
/// 1. Mindestens 8 Zeichen Länge
/// 2. Mindestens 1 Großbuchstabe (A-Z)
/// 3. Mindestens 1 Kleinbuchstabe (a-z)
/// 4. Mindestens 1 Zahl oder Sonderzeichen (0-9, !@#$%...)
/// 5. Optionale Übereinstimmung von Passwort und Passwort-Bestätigung
class PasswordCriteriaChecklist extends StatelessWidget {
  /// Das aktuell eingegebene Passwort.
  final String password;

  /// Optionales Bestätigungspasswort. Wenn gesetzt, wird die Übereinstimmung geprüft.
  final String? confirmPassword;

  const PasswordCriteriaChecklist({
    super.key,
    required this.password,
    this.confirmPassword,
  });

  /// Prüft, ob ein Passwort alle Mindestsicherheitskriterien erfüllt.
  static bool isPasswordValid(String password, [String? confirmPassword]) {
    final hasMinLength = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigitOrSpecial =
        password.contains(RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]'));

    if (!hasMinLength || !hasUpper || !hasLower || !hasDigitOrSpecial) {
      return false;
    }

    if (confirmPassword != null) {
      return confirmPassword.isNotEmpty && confirmPassword == password;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hasMinLength = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigitOrSpecial =
        password.contains(RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]'));
    final checkMatch = confirmPassword != null;
    final matchesConfirm = checkMatch &&
        confirmPassword!.isNotEmpty &&
        confirmPassword == password;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildItem(
          key: const Key('pwd_rule_min_length'),
          satisfied: hasMinLength,
          text: 'Mindestens 8 Zeichen',
        ),
        _buildItem(
          key: const Key('pwd_rule_uppercase'),
          satisfied: hasUpper,
          text: 'Mindestens 1 Großbuchstabe (A-Z)',
        ),
        _buildItem(
          key: const Key('pwd_rule_lowercase'),
          satisfied: hasLower,
          text: 'Mindestens 1 Kleinbuchstabe (a-z)',
        ),
        _buildItem(
          key: const Key('pwd_rule_digit_special'),
          satisfied: hasDigitOrSpecial,
          text: 'Mindestens 1 Zahl oder Sonderzeichen',
        ),
        if (checkMatch)
          _buildItem(
            key: const Key('pwd_rule_match'),
            satisfied: matchesConfirm,
            text: 'Passwörter stimmen überein',
          ),
      ],
    );
  }

  Widget _buildItem({
    required Key key,
    required bool satisfied,
    required String text,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: satisfied ? AppColors.emerald : Colors.white38,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: satisfied ? Colors.white : Colors.white60,
              fontSize: 11,
              fontWeight: satisfied ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
