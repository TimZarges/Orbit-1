/// Datei-Header: `lib/features/profile/widgets/v1_simple_profile_view.dart`
/// Zweck: Modulares „Profil Einfach“ für Athleten & Coaches in ORBIT V1.0.0
/// (Phase 43) im Clean Professional Design (Hell & Dunkel) mit DE/EN-Lokalisierung,
/// Wohnland-Vorschau (`dd.mm.yy • 24h`), Triathlon-Badge sowie Garmin Sync & `.fit`-Upload.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/profile/widgets/`),
/// nutzt granulare Riverpod-Selektoren (`.select(...)`) (`AGENTS.md` Regel 10).
library;

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/country_date_time_formatter.dart';
import '../../activities/providers/activity_upload_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/widgets/two_step_account_deletion_dialog.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../coach_link/models/v1_coach_athlete_link.dart';
import '../../integrations/models/garmin_status.dart';
import '../../integrations/providers/garmin_provider.dart';
import '../../legal/widgets/legal_documents_sheet.dart';
import '../../onboarding/widgets/triathlon_combined_icon.dart';
import '../../settings/providers/settings_provider.dart';
import '../services/profile_avatar_service.dart';
import 'user_avatar_circle.dart';
import 'v1_athlete_coach_connection_card.dart';

/// Modulares V1.0.0-Profil („Profil Einfach“) für Athleten und Coaches.
///
/// Was:
/// - Zeigt und bearbeitet alle Onboarding-Stammdaten (Vor-/Nachname, Rolle,
///   Wohnland inkl. `dd.mm.yy • 24h` Vorschau; bei Athleten zusätzlich Geburtsdatum,
///   Geschlecht, Größe, Gewicht, Hauptsportarten inkl. **Triathlon**-Badge;
///   bei Coaches den Coaching-Schwerpunkt / Kurz-Bio).
/// - Blendet V2/V3-Elemente (Leistungsdiagnostik, Zonen-Tabellen, Saisonziele) aus.
/// - Bietet Athleten eine kompakte Daten-Sektion mit **Garmin Sync**-Status
///   (Verbinden / Verwalten) und direktem **`.fit`-Datei-Upload**.
/// Warum: Entlastet `profile_screen.dart` und liefert ein aufgeräumtes,
/// reaktives V1.0.0-Profil (`AGENTS.md` Regel 10).
class V1SimpleProfileView extends ConsumerStatefulWidget {
  /// Optionale Testdaten (z. B. für isolierte Widget-Tests ohne Firestore).
  final Map<String, dynamic>? initialUserDocOverride;

  /// Optionaler Test-Callback beim Speichern des Profils (ohne Firestore).
  final Future<void> Function(Map<String, dynamic> savedPayload)?
      onSaveOverride;

  /// Optionale Test-Links für die Coach-Verbindungskarte des Athleten.
  final List<V1CoachAthleteLink>? coachLinksOverride;

  /// Erstellt das [V1SimpleProfileView].
  const V1SimpleProfileView({
    super.key,
    this.initialUserDocOverride,
    this.onSaveOverride,
    this.coachLinksOverride,
  });

  @override
  ConsumerState<V1SimpleProfileView> createState() =>
      _V1SimpleProfileViewState();
}

class _V1SimpleProfileViewState extends ConsumerState<V1SimpleProfileView> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _coachBioCtrl = TextEditingController();

  String _role = 'ATHLETE';
  String _gender = 'male';
  DateTime? _birthDate;
  List<String> _selectedSports = ['BIKE', 'RUN'];
  String? _avatarUrl;
  Uint8List? _pendingAvatarBytes;
  bool _isUploadingAvatar = false;
  bool _isSaving = false;
  bool _initialized = false;

  /// Unterstützte Wohnländer im Profil.
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
  void initState() {
    super.initState();
    if (widget.initialUserDocOverride != null) {
      _applyUserDoc(widget.initialUserDocOverride!);
    } else {
      _loadFromFirestore();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _coachBioCtrl.dispose();
    super.dispose();
  }

  /// Lädt das Benutzerprofil sicher aus Firestore (`users/{uid}`).
  Future<void> _loadFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null && widget.onSaveOverride == null) return;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        _applyUserDoc(doc.data() ?? const {});
        setState(() {});
      }
    } catch (_) {
      // In Tests ohne Firebase-Initialisierung still ignorieren
    }
  }

  /// Überträgt ein Firestore-Benutzerdokument in die lokalen Eingabe-Controller.
  void _applyUserDoc(Map<String, dynamic> userDoc) {
    if (_initialized) return;
    _initialized = true;

    _role = (userDoc['role'] as String? ?? 'ATHLETE').toUpperCase();
    final profile = userDoc['profile'] as Map<String, dynamic>? ?? const {};
    final settings = userDoc['settings'] as Map<String, dynamic>? ?? const {};

    final displayName = (profile['displayName'] as String? ?? '').trim();
    final fallbackParts =
        displayName.isNotEmpty ? displayName.split(RegExp(r'\s+')) : <String>[];

    _firstNameCtrl.text = (profile['firstName'] as String?)?.trim() ??
        (fallbackParts.isNotEmpty ? fallbackParts.first : '');
    _lastNameCtrl.text = (profile['lastName'] as String?)?.trim() ??
        (fallbackParts.length > 1 ? fallbackParts.sublist(1).join(' ') : '');

    _heightCtrl.text = (profile['heightCm'] ?? '').toString();
    _weightCtrl.text = (profile['weightKg'] ?? '').toString();
    _coachBioCtrl.text = (profile['coachBio'] as String? ?? '').trim();
    User? authUser;
    try {
      if (Firebase.apps.isNotEmpty) {
        authUser = FirebaseAuth.instance.currentUser;
      }
    } catch (_) {}

    _gender = (profile['gender'] as String? ?? 'male');
    _avatarUrl = ProfileAvatarService.resolveAvatarUrl(
      userDoc,
      authUser: authUser,
    );

    final birthDateRaw = profile['birthDate'] as String?;
    if (birthDateRaw != null && birthDateRaw.isNotEmpty) {
      _birthDate = DateTime.tryParse(birthDateRaw);
    }

    final rawSports = profile['sports'] ?? profile['sportTypes'];
    if (rawSports is List && rawSports.isNotEmpty) {
      _selectedSports =
          rawSports.map((e) => e.toString().toUpperCase()).toList();
    }

    final country =
        (profile['countryCode'] ?? settings['countryCode']) as String?;
    if (country != null && country.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(settingsControllerProvider.notifier).setCountryCode(country);
        }
      });
    }
  }

  /// Wählt ein neues Profilbild aus, komprimiert es und lädt es direkt in Cloud Storage hoch.
  Future<void> _pickImage(String lang) async {
    try {
      final avatarService = ref.read(profileAvatarServiceProvider);
      final bytes = await avatarService.pickAndCompressAvatarBytes();
      if (bytes == null || bytes.isEmpty || !mounted) return;

      setState(() {
        _pendingAvatarBytes = bytes;
        _isUploadingAvatar = true;
      });

      String? uid;
      try {
        if (Firebase.apps.isNotEmpty) {
          uid = FirebaseAuth.instance.currentUser?.uid;
        }
      } catch (_) {}

      if (uid != null && Firebase.apps.isNotEmpty) {
        final downloadUrl = await avatarService.uploadAndPersistAvatar(
          uid: uid,
          bytes: bytes,
        );
        ref.invalidate(userDocumentProvider);
        if (mounted) {
          setState(() {
            _avatarUrl = downloadUrl;
            _pendingAvatarBytes = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang == 'en'
                    ? 'Profile photo saved!'
                    : 'Profilbild dauerhaft gespeichert!',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'en'
                  ? 'Photo upload failed: $e'
                  : 'Profilbild-Upload fehlgeschlagen: $e',
            ),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  /// Speichert alle Änderungen im „Profil Einfach“ persistent in Firestore,
  /// ohne ein bestehendes Profilbild jemals mit null oder leerem String zu überschreiben.
  Future<void> _saveProfile(String lang, String countryCode) async {
    String? uid;
    try {
      if (Firebase.apps.isNotEmpty) {
        uid = FirebaseAuth.instance.currentUser?.uid;
      }
    } catch (_) {}
    if (uid == null && widget.onSaveOverride == null) return;

    setState(() => _isSaving = true);
    try {
      // Falls noch lokale Vorschau-Bytes offen sind, zunächst in Cloud Storage sichern
      if (_pendingAvatarBytes != null &&
          uid != null &&
          Firebase.apps.isNotEmpty) {
        final uploadedUrl =
            await ref.read(profileAvatarServiceProvider).uploadAndPersistAvatar(
                  uid: uid,
                  bytes: _pendingAvatarBytes!,
                );
        _avatarUrl = uploadedUrl;
        _pendingAvatarBytes = null;
      }

      final firstName = _firstNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      final displayName = '$firstName $lastName'.trim();
      final heightCm = int.tryParse(_heightCtrl.text.trim());
      final weightKg = double.tryParse(_weightCtrl.text.trim());
      final preservedAvatar =
          (_avatarUrl != null && _avatarUrl!.trim().isNotEmpty)
              ? _avatarUrl!.trim()
              : null;

      final payload = <String, dynamic>{
        if (preservedAvatar != null) 'photoUrl': preservedAvatar,
        if (preservedAvatar != null) 'avatarUrl': preservedAvatar,
        'profile': {
          'displayName': displayName,
          'firstName': firstName,
          'lastName': lastName,
          'countryCode': countryCode,
          if (preservedAvatar != null) 'photoUrl': preservedAvatar,
          if (preservedAvatar != null) 'avatarUrl': preservedAvatar,
          if (_role == 'ATHLETE') ...{
            'sports': _selectedSports,
            'sportTypes': _selectedSports,
            'gender': _gender,
            if (_birthDate != null)
              'birthDate':
                  '${_birthDate!.year.toString().padLeft(4, '0')}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
            if (heightCm != null) 'heightCm': heightCm,
            if (weightKg != null) 'weightKg': weightKg,
          } else ...{
            'coachBio': _coachBioCtrl.text.trim(),
          },
        },
        'settings': {
          'countryCode': countryCode,
        },
      };

      if (widget.onSaveOverride != null) {
        await widget.onSaveOverride!(payload);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(payload, SetOptions(merge: true));
        ref.invalidate(userDocumentProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'en' ? 'Profile saved!' : 'Profil gespeichert!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'en'
                  ? 'Error saving profile: $e'
                  : 'Fehler beim Speichern: $e',
            ),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
    final uploadState = ref.watch(activityUploadProvider);

    final isEn = lang == 'en';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = AppColors.cardBg(isDark: isDark);
    final borderColor = AppColors.cardBorderFor(isDark: isDark);
    final primaryText = AppColors.primaryText(isDark: isDark);
    final secondaryText = AppColors.secondaryText(isDark: isDark);

    String email = '';
    String? uid;
    User? authUser;
    try {
      if (Firebase.apps.isNotEmpty) {
        authUser = FirebaseAuth.instance.currentUser;
        email = authUser?.email ?? '';
        uid = authUser?.uid;
      }
    } catch (_) {}

    // Reaktiver Abgleich mit dem zentralen User-Stream, falls initState noch lädt
    final String? effectiveAvatarUrl = widget.initialUserDocOverride != null
        ? _avatarUrl
        : (_avatarUrl ??
            ref.watch(
              userDocumentProvider.select(
                (docAsync) => ProfileAvatarService.resolveAvatarUrl(
                  docAsync.valueOrNull,
                  authUser: authUser,
                ),
              ),
            ));

    final isAthlete = _role != 'TRAINER';
    final formatPreview = CountryDateTimeFormatter.formatDateTime(
      DateTime(2026, 10, 21, 19, 54),
      countryCode: countryCode,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.navProfile(lang: lang)),
        actions: const [
          BetaBugReportIconButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar & Rollen-Badge
                  Center(
                    child: Stack(
                      children: [
                        UserAvatarCircle(
                          key: const Key('v1_profile_avatar_circle'),
                          radius: 48,
                          photoUrlOverride: effectiveAvatarUrl,
                          previewBytes: _pendingAvatarBytes,
                          backgroundColor: cardBg,
                          iconColor: isDark ? AppColors.volt : AppColors.navy,
                        ),
                        if (_isUploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.volt,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                isDark ? AppColors.volt : AppColors.navy,
                            child: IconButton(
                              key: const Key('v1_profile_pick_avatar_button'),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color:
                                    isDark ? AppColors.navy : AppColors.white,
                              ),
                              onPressed: _isUploadingAvatar
                                  ? null
                                  : () => _pickImage(lang),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      key: const Key('v1_profile_role_badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.volt : AppColors.navy)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        AppStrings.roleLabel(_role, lang: lang),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.volt : AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(color: secondaryText),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // 1. Persönliche Stammdaten & Wohnland
                  _buildSectionCard(
                    title: isEn ? 'Simple Profile' : 'Profil Einfach',
                    cardBg: cardBg,
                    borderColor: borderColor,
                    primaryText: primaryText,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('v1_profile_first_name_field'),
                              controller: _firstNameCtrl,
                              decoration: InputDecoration(
                                labelText: isEn ? 'First Name' : 'Vorname',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              key: const Key('v1_profile_last_name_field'),
                              controller: _lastNameCtrl,
                              decoration: InputDecoration(
                                labelText: isEn ? 'Last Name' : 'Nachname',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Wohnland + Live-Vorschau dd.mm.yy • 24h
                      DropdownButtonFormField<String>(
                        key: const Key('v1_profile_country_dropdown'),
                        initialValue: _countries.contains(countryCode)
                            ? countryCode
                            : 'DE',
                        decoration: InputDecoration(
                          labelText: isEn
                              ? 'Country of Residence ($formatPreview)'
                              : 'Wohnland ($formatPreview)',
                        ),
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

                      if (isAthlete) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                key: const Key('v1_profile_birthdate_button'),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        _birthDate ?? DateTime(1994, 6, 15),
                                    firstDate: DateTime(1930),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null && mounted) {
                                    setState(() => _birthDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText:
                                        isEn ? 'Date of Birth' : 'Geburtsdatum',
                                  ),
                                  child: Text(
                                    _birthDate != null
                                        ? CountryDateTimeFormatter.formatDate(
                                            _birthDate!,
                                            countryCode: countryCode,
                                          )
                                        : 'dd.mm.yy',
                                    style: TextStyle(
                                      color: _birthDate != null
                                          ? primaryText
                                          : secondaryText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: const Key('v1_profile_gender_dropdown'),
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
                                  if (val != null) {
                                    setState(() => _gender = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: const Key('v1_profile_height_field'),
                                controller: _heightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText:
                                      isEn ? 'Height (cm)' : 'Größe (cm)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                key: const Key('v1_profile_weight_field'),
                                controller: _weightCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText:
                                      isEn ? 'Weight (kg)' : 'Gewicht (kg)',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('v1_profile_coach_bio_field'),
                          controller: _coachBioCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: isEn
                                ? 'Coaching Focus / Bio'
                                : 'Coaching-Schwerpunkt / Kurz-Bio',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Sportarten (nur Athlet, inkl. Triathlon-Badge)
                  if (isAthlete) ...[
                    _buildSectionCard(
                      title: isEn ? 'Primary Sports' : 'Sportarten',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryText: primaryText,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _sportChip(
                              'TRIATHLON',
                              'Triathlon',
                              Icons.bolt,
                              isDark,
                              primaryText,
                            ),
                            _sportChip(
                              'BIKE',
                              AppStrings.sportLabel('BIKE', lang: lang),
                              Icons.directions_bike,
                              isDark,
                              primaryText,
                            ),
                            _sportChip(
                              'RUN',
                              AppStrings.sportLabel('RUN', lang: lang),
                              Icons.directions_run,
                              isDark,
                              primaryText,
                            ),
                            _sportChip(
                              'SWIM',
                              AppStrings.sportLabel('SWIM', lang: lang),
                              Icons.pool,
                              isDark,
                              primaryText,
                            ),
                            _sportChip(
                              'STRENGTH',
                              AppStrings.sportLabel('STRENGTH', lang: lang),
                              Icons.fitness_center,
                              isDark,
                              primaryText,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Daten-Sektion für Athleten (Garmin Sync & manueller .fit-Upload)
                    _buildSectionCard(
                      key: const Key('v1_profile_data_section'),
                      title: isEn
                          ? 'Training Data & Sync'
                          : 'Trainingsdaten & Sync',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryText: primaryText,
                      children: [
                        _buildGarminStatusTile(context, ref, lang, isDark),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            key: const Key('v1_profile_fit_upload_button'),
                            onPressed: uploadState.isUploading || uid == null
                                ? null
                                : () => ref
                                    .read(activityUploadProvider.notifier)
                                    .pickAndUpload(targetAthleteId: uid!),
                            icon: uploadState.isUploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file_rounded),
                            label: Text(
                              isEn
                                  ? 'Upload .FIT file'
                                  : '.FIT-Datei manuell hochladen',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Coach-Verbindungs-Sektion für Athleten (Einladungscode / Anfrage / Trennen)
                    V1AthleteCoachConnectionCard(
                      lang: lang,
                      linksOverride: widget.coachLinksOverride,
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // Direkter Einstellungs-Zugang für Coaches in Tab 3 (Profil)
                    OutlinedButton.icon(
                      key: const Key('v1_coach_profile_settings_button'),
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(
                        isEn
                            ? 'Settings (Language, Theme, Password, Logout)'
                            : 'Einstellungen (Sprache, Design, Passwort, Logout)',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Speichern-Button
                  ElevatedButton(
                    key: const Key('v1_profile_save_button'),
                    onPressed: _isSaving
                        ? null
                        : () => _saveProfile(lang, countryCode),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isEn ? 'Save Profile' : 'Profil speichern',
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Sektion: Rechtliches (Datenschutz & Impressum) + Daten & Konto löschen (Art. 17 DSGVO)
                  _buildSectionCard(
                    key: const Key('v1_profile_legal_and_deletion_section'),
                    title: isEn
                        ? 'Privacy, Legal & Account'
                        : 'Datenschutz, Impressum & Konto',
                    cardBg: cardBg,
                    borderColor: borderColor,
                    primaryText: primaryText,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('v1_profile_privacy_button'),
                              onPressed: () => LegalDocumentsSheet.show(
                                context,
                                initialTab: LegalDocumentTab.privacy,
                                lang: lang,
                              ),
                              icon: const Icon(
                                Icons.privacy_tip_outlined,
                                size: 18,
                              ),
                              label: Text(
                                isEn ? 'Privacy' : 'Datenschutz',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('v1_profile_imprint_button'),
                              onPressed: () => LegalDocumentsSheet.show(
                                context,
                                initialTab: LegalDocumentTab.imprint,
                                lang: lang,
                              ),
                              icon: const Icon(
                                Icons.business_outlined,
                                size: 18,
                              ),
                              label: Text(
                                isEn ? 'Legal Notice' : 'Impressum',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('v1_profile_delete_account_button'),
                          onPressed: () =>
                              TwoStepAccountDeletionDialog.show(context),
                          icon: const Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          label: Text(
                            isEn
                                ? 'Delete Data & Account'
                                : 'Daten & Konto löschen',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Offizieller Versions- & Server-Region-Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'ORBIT ${AppInfo.fullVersionString}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Server-Region: ${AppInfo.region}',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryText.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Baut die Garmin-Status-Zeile innerhalb der Daten-Sektion.
  Widget _buildGarminStatusTile(
    BuildContext context,
    WidgetRef ref,
    String lang,
    bool isDark,
  ) {
    final isEn = lang == 'en';
    final garminState = ref.watch(
      garminStatusStreamProvider.select(
        (asyncVal) => asyncVal.valueOrNull?.state,
      ),
    );
    final isConnected = garminState == GarminConnectionState.connected;

    return Row(
      children: [
        Icon(
          isConnected
              ? Icons.check_circle_rounded
              : Icons.sync_disabled_rounded,
          color: isConnected
              ? AppColors.statusSuccess(isDark: isDark)
              : AppColors.secondaryText(isDark: isDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isConnected
                ? (isEn
                    ? 'Garmin Connect: Connected'
                    : 'Garmin Connect: Verbunden')
                : (isEn
                    ? 'Garmin Connect: Not connected'
                    : 'Garmin Connect: Nicht verbunden'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        OutlinedButton(
          key: const Key('v1_profile_garmin_manage_button'),
          onPressed: () => context.push('/settings/garmin'),
          child: Text(
            isConnected
                ? (isEn ? 'Manage' : 'Verwalten')
                : (isEn ? 'Connect' : 'Verbinden'),
          ),
        ),
      ],
    );
  }

  /// Baut eine einheitliche Profil-Karte im Clean Professional Design.
  Widget _buildSectionCard({
    Key? key,
    required String title,
    required Color cardBg,
    required Color borderColor,
    required Color primaryText,
    required List<Widget> children,
  }) {
    return Container(
      key: key,
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
            title,
            style: AppTypography.title.copyWith(
              color: primaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  /// Baut einen Sportart-Chip (inkl. [TriathlonCombinedIcon]).
  Widget _sportChip(
    String code,
    String label,
    IconData icon,
    bool isDark,
    Color primaryText,
  ) {
    final isSelected = _selectedSports.contains(code);
    final sportColor = AppColors.resolveSportColor(code, isDark: isDark);
    final selectedBg = AppColors.primaryAccent(isDark: isDark);
    final selectedFg = isDark ? AppColors.navy : AppColors.lightCardSurface;
    return FilterChip(
      key: Key('v1_profile_sport_$code'),
      showCheckmark: false,
      avatar: code == 'TRIATHLON'
          ? TriathlonCombinedIcon(
              size: 16,
              color: isSelected ? selectedFg : sportColor,
            )
          : Icon(
              icon,
              size: 18,
              color: isSelected ? selectedFg : sportColor,
            ),
      label: Text(label),
      selected: isSelected,
      selectedColor: selectedBg,
      labelStyle: TextStyle(
        color: isSelected ? selectedFg : primaryText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedSports.add(code);
          } else if (_selectedSports.length > 1) {
            _selectedSports.remove(code);
          }
        });
      },
    );
  }
}
