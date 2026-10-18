import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/error/orbit_error_handler.dart';
import '../../../core/widgets/info_term.dart';
import '../../activities/providers/activity_upload_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../beta_feedback/models/beta_feedback_report.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../coach_link/providers/coach_link_provider.dart';
import '../../integrations/providers/garmin_provider.dart';
import '../widgets/triathlon_combined_icon.dart';
import '../../auth/widgets/password_criteria_checklist.dart';

/// Datenstruktur für den abgeschlossenen 4-Schritte-Onboarding-Assistenten.
class OnboardingSubmissionData {
  final String role;
  final String displayName;
  final List<String> sports;
  final String experienceLevel;
  final String units;
  final bool autoEstimateThresholds;
  final int? restingHrBpm;
  final int? maxHrBpm;
  final int? ftpW;
  final int? runThresholdPaceSecPerKm;
  final int? swimCssSecPer100m;
  final String selectedDataSource; // 'GARMIN' | 'FILE_UPLOAD' | 'LATER'
  final String? inviteCode;
  final bool healthConsentAccepted;

  // Erweiterte Profilfelder (Phase 29 & 36)
  final int? birthYear;
  final double? weightKg;
  final int? heightCm;
  final String? photoBase64;
  final String? email;
  final String? password;

  // Coach-spezifische Felder (Phase 36.3)
  final String? clubName;
  final String? coachCompanyName;
  final String? coachMode;

  const OnboardingSubmissionData({
    required this.role,
    required this.displayName,
    required this.sports,
    required this.experienceLevel,
    required this.units,
    required this.autoEstimateThresholds,
    this.restingHrBpm,
    this.maxHrBpm,
    this.ftpW,
    this.runThresholdPaceSecPerKm,
    this.swimCssSecPer100m,
    required this.selectedDataSource,
    this.inviteCode,
    required this.healthConsentAccepted,
    this.birthYear,
    this.weightKg,
    this.heightCm,
    this.photoBase64,
    this.email,
    this.password,
    this.clubName,
    this.coachCompanyName,
    this.coachMode,
  });
}

/// Geführter Mobile-First 4-Schritte-Onboarding-Assistent für Athleten und Trainer (Phase 29 Onboarding-First).
class OnboardingScreen extends ConsumerStatefulWidget {
  final Future<void> Function(OnboardingSubmissionData data)?
      onCompleteOverride;

  const OnboardingScreen({
    super.key,
    this.onCompleteOverride,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalSteps = 4;
  int _currentStep = 0;

  // Schritt 1: Rolle & Profil
  String _selectedRole = 'ATHLETE';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final List<String> _selectedSports = ['BIKE', 'RUN'];
  String _experienceLevel = 'ADVANCED';
  String _units = 'metric';
  String? _photoBase64;

  // Schritt 2: Physiologische Basiswerte & Zonen
  bool _autoEstimateThresholds = false;
  final TextEditingController _restingHrController = TextEditingController();
  final TextEditingController _maxHrController = TextEditingController();
  final TextEditingController _ftpController = TextEditingController();
  final TextEditingController _runPaceController = TextEditingController();
  final TextEditingController _swimCssController = TextEditingController();

  // Schritt 3: Datenquelle verbinden
  String _selectedDataSource = 'LATER'; // 'GARMIN' | 'FILE_UPLOAD' | 'LATER'
  bool _garminBackfill90Days = true;

  // Schritt 4: Coach-Link & Datenschutz & Kontoerstellung
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _gdprHealthConsent = false;
  bool _showGdprWarning = false;

  // Coach-spezifische Felder (Phase 36.3)
  final TextEditingController _clubNameController = TextEditingController();
  final TextEditingController _coachCompanyNameController =
      TextEditingController();
  String _coachMode = 'SIMPLE_DOWNLOAD'; // 'SIMPLE_DOWNLOAD' | 'FULL_ANALYSIS'

  bool _isSubmitting = false;
  Object? _submitError;

  static const Map<String, (String, IconData)> _sportOptions = {
    'TRIATHLON': ('Triathlon', Icons.emoji_events_outlined),
    'BIKE': ('Radsport', Icons.directions_bike),
    'RUN': ('Laufen', Icons.directions_run),
    'SWIM': ('Schwimmen', Icons.pool),
    'STRENGTH': ('Kraft & Athletik', Icons.fitness_center),
  };

  @override
  void dispose() {
    _nameController.dispose();
    _birthYearController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _restingHrController.dispose();
    _maxHrController.dispose();
    _ftpController.dispose();
    _runPaceController.dispose();
    _swimCssController.dispose();
    _inviteCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _clubNameController.dispose();
    _coachCompanyNameController.dispose();
    super.dispose();
  }

  int? _parsePaceSeconds(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length == 2) {
        final mins = int.tryParse(parts[0]);
        final secs = int.tryParse(parts[1]);
        if (mins != null &&
            secs != null &&
            mins >= 0 &&
            secs >= 0 &&
            secs < 60) {
          return mins * 60 + secs;
        }
      }
      return null;
    }
    return int.tryParse(trimmed);
  }

  bool get _canProceedFromCurrentStep {
    switch (_currentStep) {
      case 0:
        return _selectedSports.isNotEmpty;
      case 1:
        return true;
      case 2:
        return _selectedDataSource.isNotEmpty;
      case 3:
        bool isAuth = false;
        try {
          isAuth = FirebaseAuth.instance.currentUser != null;
        } catch (_) {
          isAuth = true;
        }
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final confirmPassword = _confirmPasswordController.text;
        final hasCreds = isAuth ||
            (email.isNotEmpty &&
                PasswordCriteriaChecklist.isPasswordValid(
                    password, confirmPassword));
        return _gdprHealthConsent && hasCreds && !_isSubmitting;
      default:
        return false;
    }
  }

  bool get _isBottomBarButtonEnabled {
    if (_isSubmitting) return false;
    switch (_currentStep) {
      case 0:
        return _selectedSports.isNotEmpty;
      case 1:
        return true;
      case 2:
        return _selectedDataSource.isNotEmpty;
      case 3:
        bool isAuth = false;
        try {
          isAuth = FirebaseAuth.instance.currentUser != null;
        } catch (_) {
          isAuth = true;
        }
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final confirmPassword = _confirmPasswordController.text;
        final hasCreds = isAuth ||
            (email.isNotEmpty &&
                PasswordCriteriaChecklist.isPasswordValid(
                    password, confirmPassword));
        return hasCreds;
      default:
        return false;
    }
  }

  void _onBottomBarPressed() {
    if (_currentStep == _totalSteps - 1) {
      if (!_gdprHealthConsent) {
        setState(() => _showGdprWarning = true);
        return;
      }
    }
    if (_canProceedFromCurrentStep) {
      _goNext();
    }
  }

  void _goNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _submitError = null;
        _currentStep++;
      });
    } else {
      _finishOnboarding();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _submitError = null;
        _currentStep--;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (_) {}
  }

  Future<void> _finishOnboarding() async {
    if (!_gdprHealthConsent) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final displayName = _nameController.text.trim().isEmpty
        ? (_selectedRole == 'TRAINER' ? 'ORBIT Coach' : 'ORBIT Athlet')
        : _nameController.text.trim();

    final nameParts = displayName.split(RegExp(r'\s+'));
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final code = _inviteCodeController.text.trim().toUpperCase();

    final submission = OnboardingSubmissionData(
      role: _selectedRole,
      displayName: displayName,
      sports: List<String>.unmodifiable(_selectedSports),
      experienceLevel: _experienceLevel,
      units: _units,
      autoEstimateThresholds: _autoEstimateThresholds,
      restingHrBpm: int.tryParse(_restingHrController.text.trim()),
      maxHrBpm: int.tryParse(_maxHrController.text.trim()),
      ftpW: int.tryParse(_ftpController.text.trim()),
      runThresholdPaceSecPerKm: _parsePaceSeconds(_runPaceController.text),
      swimCssSecPer100m: _parsePaceSeconds(_swimCssController.text),
      selectedDataSource: _selectedDataSource,
      inviteCode: code.isNotEmpty ? code : null,
      healthConsentAccepted: _gdprHealthConsent,
      birthYear: int.tryParse(_birthYearController.text.trim()),
      weightKg: double.tryParse(_weightController.text.trim()),
      heightCm: int.tryParse(_heightController.text.trim()),
      photoBase64: _photoBase64,
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      clubName: _selectedRole == 'TRAINER' ? _clubNameController.text.trim() : null,
      coachCompanyName: _selectedRole == 'TRAINER'
          ? _coachCompanyNameController.text.trim()
          : null,
      coachMode: _selectedRole == 'TRAINER' ? _coachMode : null,
    );

    try {
      if (widget.onCompleteOverride != null) {
        await widget.onCompleteOverride!(submission);
      } else {
        // Falls noch nicht eingeloggt: Neues Konto in Firebase Auth anlegen
        if (FirebaseAuth.instance.currentUser == null) {
          final email = _emailController.text.trim();
          final password = _passwordController.text.trim();
          if (email.isNotEmpty && password.isNotEmpty) {
            await ref
                .read(authServiceProvider)
                .signUpWithEmail(email, password);
          }
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;

        // Cloud Function setInitialRole aufrufen (Frankfurt europe-west3)
        final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
        await functions.httpsCallable('setInitialRole').call({
          'role': submission.role,
          'profile': {
            'displayName': submission.displayName,
            'firstName': firstName,
            'lastName': lastName,
            'sportTypes': submission.sports,
            'sports': submission.sports,
            'experienceLevel': submission.experienceLevel,
            'autoEstimateThresholds': submission.autoEstimateThresholds,
            if (submission.birthYear != null) 'birthYear': submission.birthYear,
            if (submission.weightKg != null) 'weightKg': submission.weightKg,
            if (submission.heightCm != null) 'heightCm': submission.heightCm,
            if (submission.photoBase64 != null)
              'photoUrl': submission.photoBase64,
            if (submission.restingHrBpm != null)
              'restingHrBpm': submission.restingHrBpm,
            if (submission.maxHrBpm != null) 'maxHrBpm': submission.maxHrBpm,
            'timezone': 'Europe/Berlin',
          },
          'settings': {
            'units': submission.units,
            'language': 'de',
            'experienceLevel': submission.experienceLevel.toLowerCase(),
          },
          'thresholds': {
            'autoEstimate': submission.autoEstimateThresholds,
            if (submission.restingHrBpm != null)
              'restingHrBpm': submission.restingHrBpm,
            if (submission.maxHrBpm != null) 'maxHrBpm': submission.maxHrBpm,
            if (submission.ftpW != null) 'ftpW': submission.ftpW,
            if (submission.runThresholdPaceSecPerKm != null)
              'runThresholdPaceSecPerKm': submission.runThresholdPaceSecPerKm,
            if (submission.swimCssSecPer100m != null)
              'swimCssSecPer100m': submission.swimCssSecPer100m,
          },
          'consents': {
            'healthData': {
              'at': DateTime.now().toUtc().toIso8601String(),
              'version': 'v1',
            },
            'privacyVersion': 'v1',
          },
        });

        // Zusätzlicher Merge-Write in Firestore users/{uid}
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'role': submission.role,
            if (submission.role == 'TRAINER') ...{
              if (submission.clubName != null && submission.clubName!.isNotEmpty)
                'clubName': submission.clubName,
              if (submission.coachCompanyName != null &&
                  submission.coachCompanyName!.isNotEmpty)
                'companyName': submission.coachCompanyName,
              if (submission.coachMode != null)
                'coachMode': submission.coachMode,
            },
            'profile': {
              'displayName': submission.displayName,
              'firstName': firstName,
              'lastName': lastName,
              if (submission.birthYear != null)
                'birthYear': submission.birthYear,
              if (submission.weightKg != null) 'weightKg': submission.weightKg,
              if (submission.heightCm != null) 'heightCm': submission.heightCm,
              if (submission.photoBase64 != null)
                'photoUrl': submission.photoBase64,
              'sports': submission.sports,
              'sportTypes': submission.sports,
              'experienceLevel': submission.experienceLevel,
              if (submission.role == 'TRAINER') ...{
                if (submission.clubName != null &&
                    submission.clubName!.isNotEmpty)
                  'clubName': submission.clubName,
                if (submission.coachCompanyName != null &&
                    submission.coachCompanyName!.isNotEmpty)
                  'companyName': submission.coachCompanyName,
                if (submission.coachMode != null)
                  'coachMode': submission.coachMode,
              },
            },
          }, SetOptions(merge: true)).catchError((_) {});
        }

        // Trainer-Einladungscode einlösen falls vorhanden
        if (submission.inviteCode != null &&
            submission.inviteCode!.isNotEmpty) {
          try {
            await ref
                .read(coachLinkServiceProvider)
                .redeemInvite(submission.inviteCode!);
          } catch (_) {}
        }

        // Datenquelle anstoßen
        if (submission.selectedDataSource == 'GARMIN') {
          await ref.read(garminServiceProvider).startGarminAuth();
        } else if (submission.selectedDataSource == 'FILE_UPLOAD') {
          await ref.read(activityUploadProvider.notifier).pickAndUpload();
        }

        ref.invalidate(userDocumentProvider);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          try {
            await user.sendEmailVerification();
          } catch (_) {}
          if (mounted) {
            context.go('/verify-email');
          }
        } else {
          if (mounted) {
            context.go('/');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = e;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = [
      'Rolle & Profil',
      'Basiswerte & Zonen',
      'Datenquelle verbinden',
      'Konto & Datenschutz',
    ];

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                key: const Key('onboarding_back_button'),
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: _goBack,
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schritt ${_currentStep + 1} von $_totalSteps',
              style: AppTypography.label.copyWith(color: AppColors.volt),
            ),
            Text(
              stepTitles[_currentStep],
              style: AppTypography.title
                  .copyWith(color: AppColors.white, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'Anmelden',
              style: TextStyle(
                color: AppColors.volt,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const BetaBugReportIconButton(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: const Color(0xFF003D82),
            color: AppColors.volt,
            minHeight: 6,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_submitError != null) ...[
                          OrbitErrorBanner(
                            error: _submitError!,
                            contextHint: 'Onboarding',
                            onRetry: _finishOnboarding,
                            onReportIssue: () => showBetaBugReporterSheet(
                              context,
                              initialCategory: BetaFeedbackCategory.bugCrash,
                              routeOverride: '/onboarding',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildStepContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1RoleAndProfile();
      case 1:
        return _buildStep2Thresholds();
      case 2:
        return _buildStep3DataSource();
      case 3:
        return _buildStep4CoachAndGdpr();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Schritt 1: Rolle (Athlet / Trainer), Profilbild, Name, Alter, Gewicht, Größe, Sportarten & Erfahrungsstufe.
  Widget _buildStep1RoleAndProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Willkommen bei ORBIT',
          style: AppTypography.headline
              .copyWith(color: AppColors.white, fontSize: 24),
        ),
        const SizedBox(height: 6),
        Text(
          'Richte dein Profil für sportwissenschaftliche Leistungsdiagnostik und Trainingssteuerung ein.',
          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 20),

        // Profilbild & Foto-Upload
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFF002A5C),
                backgroundImage: _photoBase64 != null
                    ? MemoryImage(base64Decode(_photoBase64!.split(',').last))
                    : null,
                child: _photoBase64 == null
                    ? const Icon(Icons.person, size: 48, color: AppColors.volt)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.volt,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.camera_alt,
                        size: 16, color: AppColors.navy),
                    onPressed: _pickImage,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_photo_alternate_outlined,
                size: 16, color: AppColors.volt),
            label: const Text(
              'Profilbild hinzufügen (optional)',
              style: TextStyle(color: AppColors.volt, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Deine Rolle',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleOptionCard(
                key: const Key('onboarding_role_athlete'),
                title: 'Athlet',
                subtitle: 'Training, Telemetrie & Recovery steuern',
                icon: Icons.directions_run,
                selected: _selectedRole == 'ATHLETE',
                onTap: () => setState(() => _selectedRole = 'ATHLETE'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleOptionCard(
                key: const Key('onboarding_role_trainer'),
                title: 'Trainer / Coach',
                subtitle: 'Athleten betreuen & Pläne erstellen',
                icon: Icons.groups_outlined,
                selected: _selectedRole == 'TRAINER',
                onTap: () => setState(() => _selectedRole = 'TRAINER'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        TextField(
          key: const Key('onboarding_name_field'),
          controller: _nameController,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            labelText: 'Dein Name (Vor- und Nachname)',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'z. B. Lukas Bergmann',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.volt),
            filled: true,
            fillColor: const Color(0xFF002A5C),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF003D82)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.volt, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (_selectedRole == 'ATHLETE') ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('onboarding_birth_year_field'),
                  controller: _birthYearController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Geburtsjahr',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: '1995',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF002A5C),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF003D82)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.volt, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('onboarding_weight_field'),
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Gewicht (kg)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: '75.0',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF002A5C),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF003D82)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.volt, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('onboarding_height_field'),
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Größe (cm)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: '180',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF002A5C),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF003D82)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.volt, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          TextField(
            key: const Key('onboarding_coach_club_field'),
            controller: _clubNameController,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Verein / Team / Verband',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'z. B. Tri-Team Hamburg oder Radsport-Club',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.shield_outlined, color: AppColors.volt),
              filled: true,
              fillColor: const Color(0xFF002A5C),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF003D82)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.volt, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('onboarding_coach_company_field'),
            controller: _coachCompanyNameController,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Gewerbe / Firma / Coaching-Name (optional)',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'z. B. Performance Coaching Schmidt',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.business_center_outlined,
                  color: AppColors.volt),
              filled: true,
              fillColor: const Color(0xFF002A5C),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF003D82)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.volt, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Coach-Modus & Funktionsumfang',
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  key: const Key('onboarding_coach_mode_simple'),
                  label: const Text('Download & Analyse',
                      textAlign: TextAlign.center),
                  selected: _coachMode == 'SIMPLE_DOWNLOAD',
                  showCheckmark: false,
                  selectedColor: AppColors.volt,
                  backgroundColor: const Color(0xFF002A5C),
                  labelStyle: TextStyle(
                    color: _coachMode == 'SIMPLE_DOWNLOAD'
                        ? AppColors.navy
                        : AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _coachMode = 'SIMPLE_DOWNLOAD');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  key: const Key('onboarding_coach_mode_full'),
                  label: const Text('Vollständiges Coaching',
                      textAlign: TextAlign.center),
                  selected: _coachMode == 'FULL_ANALYSIS',
                  showCheckmark: false,
                  selectedColor: AppColors.volt,
                  backgroundColor: const Color(0xFF002A5C),
                  labelStyle: TextStyle(
                    color: _coachMode == 'FULL_ANALYSIS'
                        ? AppColors.navy
                        : AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _coachMode = 'FULL_ANALYSIS');
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),

        Text(
          'Hauptsportart(en)',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sportOptions.entries.map((entry) {
            final code = entry.key;
            final label = entry.value.$1;
            final icon = entry.value.$2;
            final isSelected = _selectedSports.contains(code);

            return FilterChip(
              key: Key('onboarding_sport_$code'),
              showCheckmark: false,
              avatar: code == 'TRIATHLON'
                  ? TriathlonCombinedIcon(
                      size: 16,
                      color: isSelected ? AppColors.navy : AppColors.volt,
                    )
                  : Icon(
                      icon,
                      size: 18,
                      color: isSelected ? AppColors.navy : AppColors.volt,
                    ),
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.volt,
              backgroundColor: const Color(0xFF002A5C),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.navy : AppColors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.volt : const Color(0xFF003D82),
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
          }).toList(),
        ),
        const SizedBox(height: 20),

        Text(
          'Erfahrungsstufe (Datendichte)',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),

        // Robuste Auswahl-Karten ohne Wortumbruch-Fehler
        Column(
          children: [
            _ExperienceCard(
              title: 'Einfach',
              description:
                  'Fokus auf Grundwerte: 3 Ringe, Dauer, Distanz, Ø Puls & Watt, Kalorien.',
              selected: _experienceLevel == 'SIMPLE',
              onTap: () => setState(() => _experienceLevel = 'SIMPLE'),
            ),
            const SizedBox(height: 8),
            _ExperienceCard(
              title: 'Fortgeschritten',
              description:
                  'Zusätzlich Trainingszonen (Z1–Z7), Belastungspunkte & Form-Ampel.',
              selected: _experienceLevel == 'ADVANCED',
              onTap: () => setState(() => _experienceLevel = 'ADVANCED'),
            ),
            const SizedBox(height: 8),
            _ExperienceCard(
              title: 'Experte',
              description:
                  'Volle sportwissenschaftliche Telemetrie inkl. CP, W\'bal & Aerobic Decoupling.',
              selected: _experienceLevel == 'EXPERT',
              onTap: () => setState(() => _experienceLevel = 'EXPERT'),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF002A5C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF003D82)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.straighten, color: AppColors.volt, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Einheiten-System',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              DropdownButton<String>(
                key: const Key('onboarding_units_dropdown'),
                value: _units,
                dropdownColor: const Color(0xFF002A5C),
                style: const TextStyle(color: AppColors.white),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(
                    value: 'metric',
                    child: Text('Metrisch (km, kg, °C)',
                        style: TextStyle(color: AppColors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'imperial',
                    child: Text('Imperial (mi, lbs, °F)',
                        style: TextStyle(color: AppColors.white)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _units = val);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Schritt 2: Physiologische Basiswerte & Zonen inkl. automatischer Schätzung.
  Widget _buildStep2Thresholds() {
    if (_selectedRole == 'TRAINER') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Trainer-Modus & Athleten-Steuerung',
            style: AppTypography.headline
                .copyWith(color: AppColors.white, fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text(
            'Als Coach benötigst du keine eigenen physiologischen Schwellenwerte für deine Betreuung.',
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF002A5C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF003D82)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium_outlined,
                        color: AppColors.volt, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Individuelle Athleten-Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Sobald Athleten deinem Verein beitreten oder deinen Einladungscode einlösen, kannst du deren Watt-Schwellen (FTP/CP), Laktatschwellen-Pace und HF-Bereiche direkt in deinem Coach-Cockpit individuell verwalten und Trainingspläne zielgenau zuweisen.',
                  style: AppTypography.bodySmall
                      .copyWith(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF002A5C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF003D82)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.straighten, color: AppColors.volt, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Einheiten-System',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  key: const Key('onboarding_units_dropdown'),
                  value: _units,
                  dropdownColor: const Color(0xFF002A5C),
                  style: const TextStyle(color: AppColors.white),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                      value: 'metric',
                      child: Text('Metrisch (km, kg, °C)',
                          style: TextStyle(color: AppColors.white)),
                    ),
                    DropdownMenuItem(
                      value: 'imperial',
                      child: Text('Imperial (mi, lbs, °F)',
                          style: TextStyle(color: AppColors.white)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _units = val);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Physiologische Basiswerte & Zonen',
          style: AppTypography.headline
              .copyWith(color: AppColors.white, fontSize: 24),
        ),
        const SizedBox(height: 6),
        Text(
          'Deine Schwellenwerte bilden die Grundlage für deine Zonen Z1–Z7 und deine Trainingsbelastung.',
          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        InkWell(
          key: const Key('onboarding_auto_estimate_button'),
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _autoEstimateThresholds = !_autoEstimateThresholds;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF002A5C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _autoEstimateThresholds
                    ? AppColors.volt
                    : const Color(0xFF003D82),
                width: _autoEstimateThresholds ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _autoEstimateThresholds
                      ? Icons.check_circle
                      : Icons.auto_fix_high_outlined,
                  color: AppColors.volt,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ich kenne meine Werte noch nicht – automatisch aus meinen ersten Trainings berechnen',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ORBIT analysiert deine ersten Fahrten, Läufe und Schwimmeinheiten und schlägt dir passende Schwellenwerte vor.',
                        style: AppTypography.bodySmall
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _autoEstimateThresholds ? 0.45 : 1.0,
          child: IgnorePointer(
            ignoring: _autoEstimateThresholds,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildThresholdInputCard(
                  fieldKey: const Key('onboarding_resting_hr_field'),
                  controller: _restingHrController,
                  label: 'Ruhe-Herzfrequenz (bpm)',
                  hint: 'z. B. 50',
                  infoTitle: 'Ruhe-Herzfrequenz (RHR)',
                  infoDescription:
                      'Dein niedrigster Puls in völliger Ruhe (am besten morgens nach dem Aufwachen gemessen).',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildThresholdInputCard(
                  fieldKey: const Key('onboarding_max_hr_field'),
                  controller: _maxHrController,
                  label: 'Maximale Herzfrequenz (bpm)',
                  hint: 'z. B. 190',
                  infoTitle: 'Maximale Herzfrequenz (HFmax)',
                  infoDescription:
                      'Die höchste Herzfrequenz unter maximaler Ausbelastung. Steuert deine HF-Zonen Z1 bis Z5.',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildThresholdInputCard(
                  fieldKey: const Key('onboarding_ftp_field'),
                  controller: _ftpController,
                  label: 'Rad: Functional Threshold Power (FTP in Watt)',
                  hint: 'z. B. 260',
                  infoTitle: 'FTP (Functional Threshold Power)',
                  infoDescription:
                      'Die höchste durchschnittliche Wattleistung, die du für ca. eine Stunde treten kannst.',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildThresholdInputCard(
                  fieldKey: const Key('onboarding_run_pace_field'),
                  controller: _runPaceController,
                  label: 'Lauf: Schwellen-Pace (min:sek / km)',
                  hint: 'z. B. 4:30',
                  infoTitle: 'Lauf-Schwellen-Pace',
                  infoDescription:
                      'Dein Tempo an der anaeroben Schwelle (ca. 10-km- bis Halbmarathon-Wettkampftempo).',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 12),
                _buildThresholdInputCard(
                  fieldKey: const Key('onboarding_swim_css_field'),
                  controller: _swimCssController,
                  label:
                      'Schwimmen: Critical Swim Speed (CSS in min:sek / 100m)',
                  hint: 'z. B. 1:35',
                  infoTitle: 'CSS (Critical Swim Speed)',
                  infoDescription:
                      'Deine aerobe Schwellengeschwindigkeit im Wasser pro 100 Meter.',
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdInputCard({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required String hint,
    required String infoTitle,
    required String infoDescription,
    required TextInputType keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF002A5C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF003D82)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
              InfoTerm(
                title: infoTitle,
                description: infoDescription,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38),
              isDense: true,
              filled: true,
              fillColor: AppColors.navy,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF003D82)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.volt, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Schritt 3: Datenquelle verbinden.
  Widget _buildStep3DataSource() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Datenquelle verbinden',
          style: AppTypography.headline
              .copyWith(color: AppColors.white, fontSize: 24),
        ),
        const SizedBox(height: 6),
        Text(
          'Verbinde dein Garmin-Konto für automatischen Sync inkl. 90-Tage-Historie oder lade deine erste Trainingsdatei hoch.',
          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        _DataSourceCard(
          key: const Key('onboarding_source_garmin'),
          title: 'Garmin Connect verbinden',
          subtitle:
              'Automatischer Live-Sync für Aktivitäten, Schlaf & HRV inklusive 90-Tage-Historie (Backfill).',
          badgeText: 'Empfohlen',
          icon: Icons.watch_outlined,
          selected: _selectedDataSource == 'GARMIN',
          onTap: () => setState(() => _selectedDataSource = 'GARMIN'),
          footer: _selectedDataSource == 'GARMIN'
              ? CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _garminBackfill90Days,
                  activeColor: AppColors.volt,
                  checkColor: AppColors.navy,
                  title: const Text(
                    'Letzte 90 Tage direkt nach dem Verbinden importieren',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white),
                  ),
                  onChanged: (v) =>
                      setState(() => _garminBackfill90Days = v ?? true),
                )
              : null,
        ),
        const SizedBox(height: 12),
        _DataSourceCard(
          key: const Key('onboarding_source_upload'),
          title: 'Erste Trainingsdatei (.fit / .tcx / .gpx) hochladen',
          subtitle:
              'Ideal für Wahoo, SRM, Zwift oder zum direkten Ausprobieren (Einzel- oder Batch-Upload).',
          icon: Icons.upload_file_outlined,
          selected: _selectedDataSource == 'FILE_UPLOAD',
          onTap: () => setState(() => _selectedDataSource = 'FILE_UPLOAD'),
          footer: _selectedDataSource == 'FILE_UPLOAD'
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton.icon(
                    key: const Key('onboarding_pick_file_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.volt,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                    ),
                    onPressed: () async {
                      final ids = await ref
                          .read(activityUploadProvider.notifier)
                          .pickAndUpload();
                      if (ids.isNotEmpty && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text(
                                '${ids.length} Datei(en) erfolgreich für dein Profil vorgemerkt!'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_upload),
                    label: const Text(
                      'Datei jetzt auswählen & testen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        _DataSourceCard(
          key: const Key('onboarding_source_later'),
          title: 'Später verbinden',
          subtitle:
              'Du kannst Garmin Connect oder Datei-Uploads jederzeit in den Einstellungen oder auf dem Dashboard starten.',
          icon: Icons.schedule_outlined,
          selected: _selectedDataSource == 'LATER',
          onTap: () => setState(() => _selectedDataSource = 'LATER'),
        ),
      ],
    );
  }

  /// Schritt 4: Konto-Erstellung, optionaler Trainer-Code & transparente deutsche Datenschutz-Garantie.
  Widget _buildStep4CoachAndGdpr() {
    bool isAuth = false;
    try {
      isAuth = FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      isAuth = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Trainer-Kopplung & Datenschutz',
          style: AppTypography.headline
              .copyWith(color: AppColors.white, fontSize: 24),
        ),
        const SizedBox(height: 6),
        Text(
          'Deine Daten werden sicher in Deutschland gespeichert und geschützt.',
          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        if (!isAuth) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF002A5C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF003D82)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppColors.volt),
                    const SizedBox(width: 8),
                    Text(
                      'Dein ORBIT-Konto',
                      style: AppTypography.title
                          .copyWith(color: AppColors.white, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Erstelle deine Zugangsdaten, um dein Profil und deine Trainingsdaten jederzeit auf allen Geräten sicher abzurufen.',
                  style:
                      AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('onboarding_email_field'),
                  controller: _emailController,
                  style: const TextStyle(color: AppColors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-Mail-Adresse',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.email_outlined, color: AppColors.volt),
                    filled: true,
                    fillColor: AppColors.navy,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF003D82)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.volt, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('onboarding_password_field'),
                  controller: _passwordController,
                  style: const TextStyle(color: AppColors.white),
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Passwort',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: AppColors.volt),
                    filled: true,
                    fillColor: AppColors.navy,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF003D82)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.volt, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('onboarding_confirm_password_field'),
                  controller: _confirmPasswordController,
                  style: const TextStyle(color: AppColors.white),
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Passwort wiederholen',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.lock_reset, color: AppColors.volt),
                    filled: true,
                    fillColor: AppColors.navy,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF003D82)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.volt, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                PasswordCriteriaChecklist(
                  password: _passwordController.text,
                  confirmPassword: _confirmPasswordController.text,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_selectedRole == 'ATHLETE') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF002A5C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF003D82)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link, color: AppColors.volt),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Einladungscode vom Trainer (optional)',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Hast du einen 6-stelligen Code von deinem Vereinstrainer? Du kannst ihn auch später im Tab „Coach“ eingeben.',
                  style:
                      AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('onboarding_invite_code_field'),
                  controller: _inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: const TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: '6-stelliger Code (z. B. 4A8F2C)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.navy,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF003D82)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.volt, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF002A5C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (_showGdprWarning && !_gdprHealthConsent)
                  ? AppColors.coral
                  : const Color(0xFF003D82),
              width: (_showGdprWarning && !_gdprHealthConsent) ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: AppColors.volt),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Datenschutz & Sicherheit',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• Sicherer Serverstandort Deutschland – Geschützt nach strengen deutschen und europäischen Datenschutzgesetzen.\n'
                '• Deine Trainings- und Gesundheitsdaten (Herzfrequenz, HRV, Schlaf, Wattwerte) dienen ausschließlich deiner persönlichen Leistungs- und Erholungsanalyse.\n'
                '• Dein Vereinstrainer sieht deine Daten nur, wenn du ihn ausdrücklich freischaltest; bei einer Trennung endet der Zugriff sofort.\n'
                '• Du behältst die volle Kontrolle: Du kannst alle deine Daten jederzeit exportieren oder dein Konto rückstandslos löschen.',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const Divider(height: 24, color: Color(0xFF003D82)),
              CheckboxListTile(
                key: const Key('onboarding_gdpr_consent_checkbox'),
                contentPadding: EdgeInsets.zero,
                value: _gdprHealthConsent,
                activeColor: AppColors.volt,
                checkColor: AppColors.navy,
                title: const Text(
                  'Ich willige in die geschützte Verarbeitung meiner Trainings- und Gesundheitsdaten zur Analyse ein.',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.white),
                ),
                onChanged: (val) {
                  setState(() {
                    _gdprHealthConsent = val ?? false;
                    if (_gdprHealthConsent) {
                      _showGdprWarning = false;
                    }
                  });
                },
              ),
              if (_showGdprWarning && !_gdprHealthConsent) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.coral, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Bitte willige in die geschützte Datenverarbeitung ein, um fortzufahren.',
                        style: AppTypography.label.copyWith(
                          color: AppColors.coral,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF002A5C),
        border: Border(top: BorderSide(color: Color(0xFF003D82))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              key: Key(
                isLastStep
                    ? 'onboarding_finish_button'
                    : 'onboarding_next_button',
              ),
              onPressed: _isBottomBarButtonEnabled ? _onBottomBarPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.volt,
                disabledBackgroundColor: AppColors.volt.withValues(alpha: 0.3),
                foregroundColor: AppColors.navy,
                disabledForegroundColor: AppColors.navy.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.navy),
                    )
                  : Text(
                      isLastStep ? 'Konto erstellen & ORBIT starten' : 'Weiter',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.volt : const Color(0xFF002A5C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.volt : const Color(0xFF003D82),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.navy : AppColors.volt,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.title.copyWith(
                color: selected ? AppColors.navy : AppColors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: selected
                    ? AppColors.navy.withValues(alpha: 0.8)
                    : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ExperienceCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.volt : const Color(0xFF002A5C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.volt : const Color(0xFF003D82),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.navy : AppColors.volt,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: selected ? AppColors.navy : AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? AppColors.navy.withValues(alpha: 0.85)
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataSourceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? footer;

  const _DataSourceCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF002A5C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.volt : const Color(0xFF003D82),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.volt : AppColors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.navy : AppColors.volt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (badgeText != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.volt,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      Text(
                        title,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.volt : Colors.white38,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
            if (footer != null) ...[
              const Divider(height: 16, color: Color(0xFF003D82)),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
