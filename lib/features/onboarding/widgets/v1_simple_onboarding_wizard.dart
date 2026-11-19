/// Datei-Header: `lib/features/onboarding/widgets/v1_simple_onboarding_wizard.dart`
/// Zweck: Schlanker, modularer 3-Schritte-Onboarding-Assistent für ORBIT V1.0.0
/// (Rolle & Basis-Einstellungen, Persönliche Stammdaten für Athlet/Coach inkl.
/// Triathlon, Datenquellen & verpflichtende DSGVO-Einwilligung).
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/onboarding/widgets/`),
/// entlastet `onboarding_screen.dart`, nutzt `SettingsController`,
/// `CountryDateTimeFormatter` und `PasswordCriteriaChecklist` (`AGENTS.md` Regel 10).
library;

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/country_date_time_formatter.dart';
import '../../activities/providers/activity_upload_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/services/auth_guard_service.dart';
import '../../auth/widgets/password_criteria_checklist.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../integrations/providers/garmin_provider.dart';
import '../../legal/widgets/legal_documents_sheet.dart';
import '../../profile/services/profile_avatar_service.dart';
import '../../profile/widgets/user_avatar_circle.dart';
import '../../settings/providers/settings_provider.dart';
import 'triathlon_combined_icon.dart';

/// Übergabe-Datenstruktur für den Abschluss des V1.0.0-Onboardings.
class V1OnboardingResult {
  /// Gewählte Rolle (`'ATHLETE'` oder `'TRAINER'`).
  final String role;

  /// Vorname des Nutzers.
  final String firstName;

  /// Nachname des Nutzers.
  final String lastName;

  /// Gewähltes Wohnland (ISO-Code, z. B. `'DE'`, `'AT'`, `'CH'`).
  final String countryCode;

  /// Gewählte Sportarten (bei Athleten, inkl. `'TRIATHLON'`).
  final List<String> sports;

  /// Geburtsdatum des Athleten (optional).
  final String? birthDateIso;

  /// Geschlecht des Athleten (`'male'`, `'female'`, `'diverse'`).
  final String? gender;

  /// Körpergröße in cm (Athlet).
  final int? heightCm;

  /// Körpergewicht in kg (Athlet).
  final double? weightKg;

  /// Coaching-Schwerpunkt / Kurz-Bio (Coach).
  final String? coachBio;

  /// Ob die verpflichtende DSGVO Art. 9 Einwilligung erteilt wurde.
  final bool gdprConsentAccepted;

  /// Erstellt ein [V1OnboardingResult].
  const V1OnboardingResult({
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.countryCode,
    required this.sports,
    this.birthDateIso,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.coachBio,
    required this.gdprConsentAccepted,
  });
}

/// Schlanker 3-Schritte-Onboarding-Wizard für ORBIT V1.0.0 (Athlet & Coach).
///
/// Was:
/// - **Schritt 1:** Rolle (Athlet / Coach), Sprache (DE/EN), Design (Hell/Dunkel/System),
///   Wohnland (`CountryDateTimeFormatter` Vorschau `dd.mm.yy • 24h`).
/// - **Schritt 2:** Stammdaten – gemeinsam Vor-/Nachname; Athlet: Geburtsdatum,
///   Geschlecht, Größe, Gewicht, Hauptsportarten inkl. **Triathlon**; Coach:
///   Coaching-Schwerpunkt / Kurz-Bio.
/// - **Schritt 3:** Datenquellen (nur Athlet: Garmin Connect & `.fit`-Upload),
///   Account-Erstellung (falls nicht eingeloggt) mit `sendEmailVerification()` und
///   verpflichtende, nicht vorangekreuzte DSGVO-Einwilligung.
/// Warum: Vermeidet ein Aufblähen von `onboarding_screen.dart` und fokussiert
/// das Onboarding exakt auf die V1.0.0-Anforderungen.
class V1SimpleOnboardingWizard extends ConsumerStatefulWidget {
  /// Optionaler Test-Callback anstelle des echten Backend-Submits.
  final Future<void> Function(V1OnboardingResult data)? onCompleteOverride;

  /// Erstellt den [V1SimpleOnboardingWizard].
  const V1SimpleOnboardingWizard({super.key, this.onCompleteOverride});

  @override
  ConsumerState<V1SimpleOnboardingWizard> createState() =>
      _V1SimpleOnboardingWizardState();
}

class _V1SimpleOnboardingWizardState
    extends ConsumerState<V1SimpleOnboardingWizard> {
  /// Aktueller Schritt (0..2).
  int _step = 0;

  /// Ausgewählte Rolle (`'ATHLETE'` oder `'TRAINER'`).
  String _role = 'ATHLETE';

  /// Ausgewählte Sportarten (Athlet).
  final List<String> _selectedSports = ['BIKE', 'RUN'];

  /// Ausgewähltes Geschlecht (Athlet).
  String _gender = 'male';

  /// Ausgewähltes Geburtsdatum (Athlet).
  DateTime? _birthDate;

  /// Verpflichtende, nicht vorangekreuzte DSGVO-Einwilligung.
  bool _gdprConsent = false;

  /// Zeigt eine visuelle Warnung, falls ohne Einwilligung abgeschlossen wird.
  bool _showGdprWarning = false;

  /// Ladezustand während des Speicherns.
  bool _isSubmitting = false;

  /// Ausgewählte `.fit`-Dateien in Schritt 3.
  List<PlatformFile> _stagedFiles = const [];

  /// Optional im Onboarding ausgewähltes Profilbild (lokale Vorschau-Bytes).
  Uint8List? _pendingAvatarBytes;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _coachBioCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  /// Unterstützte Wohnländer im Onboarding.
  static const List<String> _countries = [
    'DE',
    'AT',
    'CH',
    'LU',
    'NL',
    'BE',
    'FR',
    'IT',
    'ES',
    'GB',
  ];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _coachBioCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  /// Prüft, ob der aktuelle Nutzer bereits bei Firebase Auth angemeldet ist.
  bool get _isAlreadySignedIn {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Prüft, ob alle Pflichtfelder des aktuellen Schritts erfüllt sind.
  bool get _canProceed {
    if (_step == 0) return true;
    if (_step == 1) {
      return _firstNameCtrl.text.trim().isNotEmpty &&
          _lastNameCtrl.text.trim().isNotEmpty;
    }
    // Schritt 3: Wenn nicht eingeloggt (und kein Test-Override), Konto-Daten prüfen
    if (!_isAlreadySignedIn && widget.onCompleteOverride == null) {
      final email = _emailCtrl.text.trim();
      final validPw = PasswordCriteriaChecklist.isPasswordValid(
        _passwordCtrl.text,
        _confirmPasswordCtrl.text,
      );
      if (email.isEmpty || !email.contains('@') || !validPw) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Granulare Selektoren gemäß Effizienz-Gebot (AGENTS.md Regel 10)
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final countryCode = ref.watch(
      settingsControllerProvider.select((s) => s.countryCode),
    );
    final themeMode = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );

    final isEn = lang == 'en';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.anthraciteCard : AppColors.white;
    final borderColor =
        isDark ? AppColors.darkSubtleBorder : AppColors.cardBorder;
    final primaryText = isDark ? AppColors.white : AppColors.lightTextPrimary;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEn
              ? 'ORBIT Setup (Step ${_step + 1}/3)'
              : 'ORBIT Einrichtung (${_step + 1}/3)',
        ),
        actions: [
          const BetaBugReportIconButton(),
          TextButton(
            key: const Key('v1_onboarding_login_shortcut'),
            onPressed: () => context.go('/login'),
            child: Text(
              isEn ? 'Sign In' : 'Anmelden',
              style: TextStyle(
                color: isDark ? AppColors.volt : AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fortschrittsbalken
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              minHeight: 4,
              backgroundColor: borderColor,
              color: isDark ? AppColors.volt : AppColors.navy,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: switch (_step) {
                      0 => _buildStep1RoleAndPrefs(
                          lang: lang,
                          countryCode: countryCode,
                          themeMode: themeMode,
                          isDark: isDark,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                        ),
                      1 => _buildStep2ProfileData(
                          lang: lang,
                          countryCode: countryCode,
                          isDark: isDark,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                        ),
                      _ => _buildStep3SourcesAndGdpr(
                          lang: lang,
                          isDark: isDark,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                        ),
                    },
                  ),
                ),
              ),
            ),
            // Untere Navigationsleiste
            _buildBottomBar(
              isEn: isEn,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Schritt 1: Rolle (Athlet / Coach), Sprache (DE/EN), Design (Hell/Dunkel/System), Wohnland.
  Widget _buildStep1RoleAndPrefs({
    required String lang,
    required String countryCode,
    required ThemeMode themeMode,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final isEn = lang == 'en';
    final previewDateTime = CountryDateTimeFormatter.formatDateTime(
      DateTime(2026, 10, 21, 19, 54),
      countryCode: countryCode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEn ? 'Welcome to ORBIT' : 'Willkommen bei ORBIT',
          style: AppTypography.headline.copyWith(color: primaryText),
        ),
        const SizedBox(height: 6),
        Text(
          isEn
              ? 'Choose your role, language, appearance, and country of residence.'
              : 'Wähle deine Rolle, Sprache, Darstellung und dein Wohnland.',
          style: AppTypography.bodySmall.copyWith(color: secondaryText),
        ),
        const SizedBox(height: 20),

        // Rollenwahl: Athlet vs. Coach
        Row(
          children: [
            Expanded(
              child: _RoleOptionCard(
                key: const Key('v1_onboarding_role_athlete'),
                icon: Icons.directions_run_rounded,
                title: AppStrings.roleLabel('ATHLETE', lang: lang),
                subtitle: isEn
                    ? 'Sync Garmin & manage .FIT files'
                    : 'Garmin Sync & .FIT-Dateien verwalten',
                selected: _role == 'ATHLETE',
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryText: primaryText,
                onTap: () => setState(() => _role = 'ATHLETE'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleOptionCard(
                key: const Key('v1_onboarding_role_trainer'),
                icon: Icons.sports_rounded,
                title: AppStrings.roleLabel('TRAINER', lang: lang),
                subtitle: isEn
                    ? 'View athletes & download .FIT'
                    : 'Athleten betreuen & .FIT laden',
                selected: _role == 'TRAINER',
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryText: primaryText,
                onTap: () => setState(() => _role = 'TRAINER'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Basis-Einstellungen: Sprache, Design & Wohnland
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sprache (DE / EN)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.settingsLanguageTitle(lang: lang),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                  SegmentedButton<String>(
                    key: const Key('v1_onboarding_lang_segmented'),
                    segments: const [
                      ButtonSegment(value: 'de', label: Text('DE')),
                      ButtonSegment(value: 'en', label: Text('EN')),
                    ],
                    selected: {lang},
                    onSelectionChanged: (sel) => ref
                        .read(settingsControllerProvider.notifier)
                        .setLanguage(sel.first),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Design (Hell / Dunkel / System)
              Text(
                AppStrings.settingsThemeTitle(lang: lang),
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                key: const Key('v1_onboarding_theme_segmented'),
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(
                      AppStrings.themeModeLabel(ThemeMode.light, lang: lang),
                    ),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(
                      AppStrings.themeModeLabel(ThemeMode.dark, lang: lang),
                    ),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(isEn ? 'System' : 'System'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (sel) => ref
                    .read(settingsControllerProvider.notifier)
                    .setThemeMode(sel.first),
              ),
              const Divider(height: 24),

              // Wohnland (steuert dd.mm.yy & 24h)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Country of Residence' : 'Wohnland',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                        Text(
                          '${isEn ? "Format" : "Format"}: $previewDateTime',
                          style: AppTypography.bodySmall.copyWith(
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    key: const Key('v1_onboarding_country_dropdown'),
                    value:
                        _countries.contains(countryCode) ? countryCode : 'DE',
                    items: _countries
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              CountryDateTimeFormatter.countryLabel(
                                c,
                                lang: lang,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setCountryCode(val);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Schritt 2: Persönliche Stammdaten (Athlet: Geburtsdatum, Geschlecht, Größe,
  /// Gewicht, Sportarten inkl. Triathlon; Coach: Vor-/Nachname + Coaching-Schwerpunkt).
  Widget _buildStep2ProfileData({
    required String lang,
    required String countryCode,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final isEn = lang == 'en';
    final isAthlete = _role == 'ATHLETE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEn ? 'Personal Details' : 'Persönliche Stammdaten',
          style: AppTypography.headline.copyWith(color: primaryText),
        ),
        const SizedBox(height: 6),
        Text(
          isAthlete
              ? (isEn
                  ? 'Your core athlete profile for V1.0.0.'
                  : 'Deine wichtigsten Athleten-Stammdaten für das Profil Einfach.')
              : (isEn
                  ? 'Your compact coach profile for your athletes.'
                  : 'Dein kompaktes Coach-Profil für deine Athleten.'),
          style: AppTypography.bodySmall.copyWith(color: secondaryText),
        ),
        const SizedBox(height: 20),

        // Profilbild (optional) + Vorname & Nachname
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      key: const Key('v1_onboarding_avatar_picker'),
                      onTap: () async {
                        final bytes = await ref
                            .read(profileAvatarServiceProvider)
                            .pickAndCompressAvatarBytes();
                        if (bytes != null && bytes.isNotEmpty && mounted) {
                          setState(() => _pendingAvatarBytes = bytes);
                        }
                      },
                      child: Stack(
                        children: [
                          UserAvatarCircle(
                            radius: 40,
                            previewBytes: _pendingAvatarBytes,
                            backgroundColor: isDark
                                ? Theme.of(context).scaffoldBackgroundColor
                                : const Color(0xFFF1F5F9),
                            iconColor: isDark ? AppColors.volt : AppColors.navy,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  isDark ? AppColors.volt : AppColors.navy,
                              child: Icon(
                                Icons.camera_alt,
                                size: 14,
                                color:
                                    isDark ? AppColors.navy : AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEn
                          ? 'Profile Photo (optional)'
                          : 'Profilbild (optional)',
                      style: AppTypography.bodySmall.copyWith(
                        color: secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('v1_onboarding_first_name_field'),
                controller: _firstNameCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: isEn ? 'First Name *' : 'Vorname *',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('v1_onboarding_last_name_field'),
                controller: _lastNameCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: isEn ? 'Last Name *' : 'Nachname *',
                ),
              ),
              if (isAthlete) ...[
                const SizedBox(height: 12),
                // Geburtsdatum mit Picker
                InkWell(
                  key: const Key('v1_onboarding_birthdate_button'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _birthDate ?? DateTime(1994, 6, 15),
                      firstDate: DateTime(1930),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && mounted) {
                      setState(() => _birthDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: isEn ? 'Date of Birth' : 'Geburtsdatum',
                      suffixIcon: const Icon(Icons.cake_outlined, size: 18),
                    ),
                    child: Text(
                      _birthDate != null
                          ? CountryDateTimeFormatter.formatDate(
                              _birthDate!,
                              countryCode: countryCode,
                            )
                          : (isEn
                              ? 'Select date (dd.mm.yy)'
                              : 'Datum wählen (dd.mm.yy)'),
                      style: TextStyle(
                        color: _birthDate != null ? primaryText : secondaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Geschlecht
                DropdownButtonFormField<String>(
                  key: const Key('v1_onboarding_gender_dropdown'),
                  initialValue: _gender,
                  decoration: InputDecoration(
                    labelText: isEn ? 'Gender' : 'Geschlecht',
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'male',
                      child: Text(isEn ? 'Male' : 'Männlich'),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text(isEn ? 'Female' : 'Weiblich'),
                    ),
                    DropdownMenuItem(
                      value: 'diverse',
                      child: Text(isEn ? 'Diverse' : 'Divers'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
                const SizedBox(height: 12),

                // Größe & Gewicht
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('v1_onboarding_height_field'),
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isEn ? 'Height (cm)' : 'Größe (cm)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        key: const Key('v1_onboarding_weight_field'),
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: isEn ? 'Weight (kg)' : 'Gewicht (kg)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hauptsportarten inkl. Triathlon
                Text(
                  isEn ? 'Primary Sports' : 'Hauptsportarten',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sportChip('TRIATHLON', 'Triathlon', Icons.bolt, isDark),
                    _sportChip(
                      'BIKE',
                      AppStrings.sportLabel('BIKE', lang: lang),
                      Icons.directions_bike,
                      isDark,
                    ),
                    _sportChip(
                      'RUN',
                      AppStrings.sportLabel('RUN', lang: lang),
                      Icons.directions_run,
                      isDark,
                    ),
                    _sportChip(
                      'SWIM',
                      AppStrings.sportLabel('SWIM', lang: lang),
                      Icons.pool,
                      isDark,
                    ),
                    _sportChip(
                      'STRENGTH',
                      AppStrings.sportLabel('STRENGTH', lang: lang),
                      Icons.fitness_center,
                      isDark,
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                // Coach: Schwerpunkt / Kurz-Bio
                TextField(
                  key: const Key('v1_onboarding_coach_bio_field'),
                  controller: _coachBioCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isEn
                        ? 'Coaching Focus / Short Bio (e.g. Triathlon, Cycling)'
                        : 'Coaching-Schwerpunkt / Kurz-Bio (z. B. Triathlon, Radsport)',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Schritt 3: Datenquellen (nur Athlet) + Konto + verpflichtende DSGVO-Einwilligung.
  Widget _buildStep3SourcesAndGdpr({
    required String lang,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final isEn = lang == 'en';
    final isAthlete = _role == 'ATHLETE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEn ? 'Data Sources & Privacy' : 'Datenquellen & Datenschutz',
          style: AppTypography.headline.copyWith(color: primaryText),
        ),
        const SizedBox(height: 6),
        Text(
          isEn
              ? 'Connect your training source and confirm GDPR data protection.'
              : 'Verbinde deine Trainingsquelle und bestätige den Datenschutz.',
          style: AppTypography.bodySmall.copyWith(color: secondaryText),
        ),
        const SizedBox(height: 20),

        // Nur Athlet: Garmin Connect & .FIT-Datei-Upload
        if (isAthlete) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEn
                      ? 'Training Data (optional)'
                      : 'Trainingsdaten (optional)',
                  style: AppTypography.title.copyWith(
                    fontSize: 16,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('v1_onboarding_garmin_button'),
                  onPressed: () async {
                    if (_isAlreadySignedIn) {
                      await ref.read(garminServiceProvider).startGarminAuth();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEn
                                ? 'Garmin Connect can be linked right after account creation.'
                                : 'Garmin Connect kann direkt nach Kontoerstellung verknüpft werden.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(
                    isEn
                        ? 'Connect Garmin Connect'
                        : 'Mit Garmin Connect verbinden',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  key: const Key('v1_onboarding_fit_upload_button'),
                  onPressed: () async {
                    final files =
                        await FilePicker.pickFiles(type: FileType.any);
                    if (files.isEmpty) return;
                    final valid = files.where((f) {
                      final n = f.name.toLowerCase();
                      return n.endsWith('.fit') || n.endsWith('.fit.gz');
                    }).toList();
                    if (valid.isEmpty) return;
                    setState(() => _stagedFiles = valid);
                  },
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    _stagedFiles.isEmpty
                        ? (isEn ? 'Upload .FIT file' : '.FIT-Datei hochladen')
                        : (isEn
                            ? '${_stagedFiles.length} .FIT file(s) selected'
                            : '${_stagedFiles.length} .FIT-Datei(en) gewählt'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Account-Erstellung (falls noch nicht eingeloggt & kein Test-Override)
        if (!_isAlreadySignedIn && widget.onCompleteOverride == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Create ORBIT Account' : 'ORBIT-Konto erstellen',
                  style: AppTypography.title.copyWith(
                    fontSize: 16,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('v1_onboarding_email_field'),
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: isEn ? 'Email Address' : 'E-Mail-Adresse',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('v1_onboarding_password_field'),
                  controller: _passwordCtrl,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: isEn ? 'Password' : 'Passwort',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('v1_onboarding_confirm_password_field'),
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText:
                        isEn ? 'Confirm Password' : 'Passwort wiederholen',
                  ),
                ),
                const SizedBox(height: 12),
                PasswordCriteriaChecklist(
                  password: _passwordCtrl.text,
                  confirmPassword: _confirmPasswordCtrl.text,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Verpflichtende, nicht vorangekreuzte DSGVO Art. 9 Einwilligung
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (_showGdprWarning && !_gdprConsent)
                  ? AppColors.coral
                  : borderColor,
              width: (_showGdprWarning && !_gdprConsent) ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEn
                    ? 'Data Protection & Consent'
                    : 'Datenschutz & Einwilligung',
                style: AppTypography.title.copyWith(
                  fontSize: 16,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEn
                    ? 'Your training and health data are stored exclusively on German servers and processed only with your consent.'
                    : 'Sicherer Serverstandort Deutschland – Geschützt nach deutschen & europäischen Datenschutzgesetzen.',
                style: AppTypography.bodySmall.copyWith(color: secondaryText),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const Key('v1_onboarding_gdpr_checkbox'),
                contentPadding: EdgeInsets.zero,
                value: _gdprConsent,
                activeColor: isDark ? AppColors.volt : AppColors.navy,
                checkColor: isDark ? AppColors.navy : AppColors.white,
                title: Text(
                  isEn
                      ? 'I consent to the protected processing of my health and training data and accept the privacy policy.'
                      : 'Ich willige in die geschützte Verarbeitung meiner Gesundheits- und Trainingsdaten ein und akzeptiere die Datenschutzerklärung.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _gdprConsent = val ?? false;
                    if (_gdprConsent) _showGdprWarning = false;
                  });
                },
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    key: const Key('v1_onboarding_privacy_link'),
                    onPressed: () => LegalDocumentsSheet.show(
                      context,
                      initialTab: LegalDocumentTab.privacy,
                      lang: lang,
                    ),
                    icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                    label: Text(
                      isEn ? 'Privacy Policy (GDPR)' : 'Datenschutzerklärung',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('v1_onboarding_imprint_link'),
                    onPressed: () => LegalDocumentsSheet.show(
                      context,
                      initialTab: LegalDocumentTab.imprint,
                      lang: lang,
                    ),
                    icon: const Icon(Icons.business_outlined, size: 16),
                    label: Text(
                      isEn ? 'Legal Notice' : 'Impressum',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (_showGdprWarning && !_gdprConsent)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    isEn
                        ? 'Please accept the privacy and health data consent first.'
                        : 'Bitte bestätige zuerst die Datenschutz- und Gesundheitsdaten-Einwilligung.',
                    style: const TextStyle(
                      color: AppColors.coral,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Baut die untere Navigationsleiste (Zurück / Weiter / Abschließen).
  Widget _buildBottomBar({
    required bool isEn,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    final isLast = _step == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: OutlinedButton(
                key: const Key('v1_onboarding_back_button'),
                onPressed: _isSubmitting ? null : () => setState(() => _step--),
                child: Text(isEn ? 'Back' : 'Zurück'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              key: Key(
                isLast
                    ? 'v1_onboarding_finish_button'
                    : 'v1_onboarding_next_button',
              ),
              onPressed: _isSubmitting || !_canProceed
                  ? null
                  : () {
                      if (!isLast) {
                        setState(() => _step++);
                        return;
                      }
                      if (!_gdprConsent) {
                        setState(() => _showGdprWarning = true);
                        return;
                      }
                      _submit();
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isLast
                          ? (isEn
                              ? 'Complete Setup'
                              : 'Einrichtung abschließen')
                          : (isEn ? 'Continue' : 'Weiter'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Baut einen Sportart-Chip (inkl. Triathlon mit [TriathlonCombinedIcon]).
  Widget _sportChip(
    String code,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final selected = _selectedSports.contains(code);
    return FilterChip(
      key: Key('v1_onboarding_sport_$code'),
      showCheckmark: false,
      avatar: code == 'TRIATHLON'
          ? TriathlonCombinedIcon(
              size: 16,
              color: selected
                  ? (isDark ? AppColors.navy : AppColors.white)
                  : (isDark ? AppColors.volt : AppColors.navy),
            )
          : Icon(
              icon,
              size: 18,
              color: selected
                  ? (isDark ? AppColors.navy : AppColors.white)
                  : (isDark ? AppColors.volt : AppColors.navy),
            ),
      label: Text(label),
      selected: selected,
      selectedColor: isDark ? AppColors.volt : AppColors.navy,
      labelStyle: TextStyle(
        color: selected
            ? (isDark ? AppColors.navy : AppColors.white)
            : (isDark ? AppColors.white : AppColors.lightTextPrimary),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        setState(() {
          if (val) {
            _selectedSports.add(code);
          } else if (_selectedSports.length > 1) {
            _selectedSports.remove(code);
          }
        });
      },
    );
  }

  /// Speichert das V1.0.0-Onboarding-Profil und legt bei Bedarf das Firebase-Konto an.
  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final settings = ref.read(settingsControllerProvider);
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final displayName = '$firstName $lastName'.trim();

    final result = V1OnboardingResult(
      role: _role,
      firstName: firstName,
      lastName: lastName,
      countryCode: settings.countryCode,
      sports: List<String>.unmodifiable(_selectedSports),
      birthDateIso: _birthDate != null
          ? '${_birthDate!.year.toString().padLeft(4, '0')}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
          : null,
      gender: _role == 'ATHLETE' ? _gender : null,
      heightCm: int.tryParse(_heightCtrl.text.trim()),
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      coachBio: _role == 'TRAINER' ? _coachBioCtrl.text.trim() : null,
      gdprConsentAccepted: _gdprConsent,
    );

    try {
      if (widget.onCompleteOverride != null) {
        await widget.onCompleteOverride!(result);
        return;
      }

      // Konto in Firebase Auth erstellen (signUpWithEmail stößt die Bestätigungs-E-Mail
      // bereits sicher über AuthGuardService.triggerVerificationEmailSafely an).
      var verificationTriggeredOnSignup = false;
      if (FirebaseAuth.instance.currentUser == null) {
        await ref
            .read(authServiceProvider)
            .signUpWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
        verificationTriggeredOnSignup = true;
      }

      final activeAuthUser = FirebaseAuth.instance.currentUser;
      if (activeAuthUser != null &&
          !verificationTriggeredOnSignup &&
          !activeAuthUser.emailVerified) {
        await AuthGuardService.triggerVerificationEmailSafely(activeAuthUser);
      }

      final uid = activeAuthUser?.uid;
      final profilePayload = <String, dynamic>{
        'displayName': displayName,
        'firstName': result.firstName,
        'lastName': result.lastName,
        'countryCode': result.countryCode,
        if (result.role == 'ATHLETE') ...{
          'sports': result.sports,
          'sportTypes': result.sports,
          if (result.birthDateIso != null) 'birthDate': result.birthDateIso,
          if (result.gender != null) 'gender': result.gender,
          if (result.heightCm != null) 'heightCm': result.heightCm,
          if (result.weightKg != null) 'weightKg': result.weightKg,
        } else if (result.coachBio != null && result.coachBio!.isNotEmpty) ...{
          'coachBio': result.coachBio,
        },
      };

      // Rolle + Profil in Cloud Function setInitialRole (europe-west3) setzen
      try {
        await FirebaseFunctions.instanceFor(region: 'europe-west3')
            .httpsCallable('setInitialRole')
            .call({
          'role': result.role,
          'profile': profilePayload,
          'settings': {
            'language': settings.languageCode,
            'countryCode': result.countryCode,
            'themeMode': settings.themeMode.name,
            'experienceLevel': 'beginner',
          },
          'consents': {
            'healthData': {
              'at': DateTime.now().toUtc().toIso8601String(),
              'version': 'v1',
            },
            'privacyVersion': 'v1',
          },
        });
      } catch (_) {}

      // Direkte Firestore-Persistenz für sofortige UI-Verfügbarkeit
      if (uid != null) {
        final normalizedEmail =
            (activeAuthUser?.email ?? _emailCtrl.text).trim().toLowerCase();
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {
            'uid': uid,
            if (normalizedEmail.isNotEmpty) 'email': normalizedEmail,
            'role': result.role,
            'onboardingCompleted': true,
            'profile': profilePayload,
            'settings': {
              'language': settings.languageCode,
              'countryCode': result.countryCode,
              'themeMode': settings.themeMode.name,
            },
          },
          SetOptions(merge: true),
        );

        // Optionales Profilbild dauerhaft in Cloud Storage, Firestore & Auth speichern
        if (_pendingAvatarBytes != null) {
          await ref.read(profileAvatarServiceProvider).uploadAndPersistAvatar(
                uid: uid,
                bytes: _pendingAvatarBytes!,
              );
          ref.invalidate(userDocumentProvider);
        }

        // Optionale .FIT-Dateien direkt hochladen
        if (_stagedFiles.isNotEmpty) {
          await ref.read(activityUploadProvider.notifier).uploadFiles(
                targetAthleteId: uid,
                files: _stagedFiles,
              );
        }
      }

      if (!mounted) return;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !currentUser.emailVerified) {
        context.go('/verify-email');
      } else {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

/// Auswahlkarte für die Rolle (Athlet vs. Coach) in Schritt 1.
class _RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color primaryText;
  final VoidCallback onTap;

  const _RoleOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.primaryText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.volt : AppColors.navy;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? activeColor : borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: activeColor, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.title.copyWith(
                fontSize: 15,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
