import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/error/orbit_error_handler.dart';
import '../models/beta_feedback_report.dart';

/// GlobalKey für das [RepaintBoundary] um die App zur optionalen Screenshot-Aufnahme.
final GlobalKey orbitRepaintBoundaryKey = GlobalKey();

/// Nimmt optional einen PNG-Screenshot des aktuellen Screens über [orbitRepaintBoundaryKey] auf.
Future<Uint8List?> captureOrbitScreenPng() async {
  try {
    final context = orbitRepaintBoundaryKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

/// Kompaktes Bug-Report-Icon für die Top-Bar (App-Bar) in der Beta-Version.
class BetaBugReportIconButton extends StatelessWidget {
  final BetaFeedbackCategory initialCategory;
  final String? initialDescription;
  final Future<void> Function(
    BetaFeedbackReport report,
    Uint8List? screenshotBytes,
  )? onSubmitOverride;

  const BetaBugReportIconButton({
    super.key,
    this.initialCategory = BetaFeedbackCategory.bugCrash,
    this.initialDescription,
    this.onSubmitOverride,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('beta_bug_report_icon_button'),
      icon: const Icon(Icons.bug_report_outlined),
      tooltip: 'Beta-Feedback & Bug melden',
      onPressed: () {
        showBetaBugReporterSheet(
          context,
          initialCategory: initialCategory,
          initialDescription: initialDescription,
          onSubmitOverride: onSubmitOverride,
        );
      },
    );
  }
}

/// Öffnet das Beta-Bug-Reporter Bottom-Sheet.
Future<void> showBetaBugReporterSheet(
  BuildContext context, {
  BetaFeedbackCategory initialCategory = BetaFeedbackCategory.bugCrash,
  String? initialDescription,
  String? routeOverride,
  Future<void> Function(BetaFeedbackReport report, Uint8List? screenshotBytes)?
      onSubmitOverride,
}) async {
  String currentRoute = routeOverride ?? '/';
  if (routeOverride == null) {
    try {
      currentRoute = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
    }
  }

  final capturedPng = await captureOrbitScreenPng();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => BetaBugReporterSheet(
      initialCategory: initialCategory,
      initialDescription: initialDescription,
      currentRoute: currentRoute,
      preCapturedScreenshot: capturedPng,
      onSubmitOverride: onSubmitOverride,
    ),
  );
}

/// Bottom-Sheet zum Melden von Bugs, Berechnungsfehlern, Garmin-/Upload-Problemen oder Vorschlägen.
class BetaBugReporterSheet extends StatefulWidget {
  final BetaFeedbackCategory initialCategory;
  final String? initialDescription;
  final String currentRoute;
  final Uint8List? preCapturedScreenshot;
  final Future<void> Function(
    BetaFeedbackReport report,
    Uint8List? screenshotBytes,
  )? onSubmitOverride;

  const BetaBugReporterSheet({
    super.key,
    this.initialCategory = BetaFeedbackCategory.bugCrash,
    this.initialDescription,
    this.currentRoute = '/',
    this.preCapturedScreenshot,
    this.onSubmitOverride,
  });

  @override
  State<BetaBugReporterSheet> createState() => _BetaBugReporterSheetState();
}

class _BetaBugReporterSheetState extends State<BetaBugReporterSheet> {
  late BetaFeedbackCategory _selectedCategory;
  late final TextEditingController _descriptionController;
  bool _includeDiagnostics = true;
  bool _includeScreenshot = false;
  bool _isSubmitting = false;
  String? _validationError;

  static const String appVersionString = '1.0.0+1 (v0.19.0-beta)';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    _includeScreenshot = widget.preCapturedScreenshot != null;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _resolveDeviceInfo() {
    final platformName = defaultTargetPlatform.name;
    return kIsWeb ? 'Web ($platformName)' : platformName;
  }

  Future<void> _submit() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _validationError = 'Bitte beschreibe kurz, was passiert ist.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationError = null;
    });

    try {
      final reportId = const Uuid().v4();
      String uid = 'anonymous_beta_tester';
      try {
        if (Firebase.apps.isNotEmpty) {
          uid = FirebaseAuth.instance.currentUser?.uid ?? uid;
        }
      } catch (_) {}

      final diagnostics = _includeDiagnostics
          ? BetaDiagnosticsPayload(
              route: widget.currentRoute,
              appVersion: appVersionString,
              deviceInfo: _resolveDeviceInfo(),
              recentLogs: OrbitErrorHandler.recentLogs,
            )
          : null;

      final attachPng = (_includeDiagnostics && _includeScreenshot)
          ? widget.preCapturedScreenshot
          : null;

      final screenshotStoragePath =
          attachPng != null ? 'betaFeedback/$uid/$reportId.png' : null;

      final report = BetaFeedbackReport(
        id: reportId,
        userId: uid,
        category: _selectedCategory,
        description: text,
        includeDiagnostics: _includeDiagnostics,
        diagnostics: diagnostics,
        screenshotPath: screenshotStoragePath,
        createdAt: DateTime.now(),
      );

      if (widget.onSubmitOverride != null) {
        await widget.onSubmitOverride!(report, attachPng);
      } else {
        if (attachPng != null && screenshotStoragePath != null) {
          final storageRef =
              FirebaseStorage.instance.ref().child(screenshotStoragePath);
          await storageRef.putData(
            attachPng,
            SettableMetadata(contentType: 'image/png'),
          );
        }
        await FirebaseFirestore.instance
            .collection('betaFeedback')
            .doc(reportId)
            .set({
          ...report.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Danke! Dein Beta-Feedback wurde erfolgreich übermittelt.',
          ),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final resolved = OrbitErrorHandler.resolve(
        e,
        contextHint: 'BetaBugReporter',
      );
      setState(() {
        _isSubmitting = false;
        _validationError = '${resolved.title}: ${resolved.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final logs = OrbitErrorHandler.recentLogs;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    color: AppColors.volt,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beta Bug- & Feedback-Reporter',
                        style: AppTypography.title.copyWith(
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        'Hilf uns, ORBIT vor dem Release am 31.10. zu perfektionieren.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.techGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Kategorie wählen',
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BetaFeedbackCategory.values.map((cat) {
                final selected = _selectedCategory == cat;
                return ChoiceChip(
                  key: Key('beta_category_${cat.wireValue}'),
                  label: Text(cat.label()),
                  selected: selected,
                  selectedColor: AppColors.navy,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.navy,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('beta_feedback_description_field'),
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Was ist passiert?',
                hintText:
                    'Beschreibe kurz das Problem oder deinen Vorschlag...',
                errorText: _validationError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    key: const Key('beta_diagnostics_optin_checkbox'),
                    value: _includeDiagnostics,
                    activeColor: AppColors.navy,
                    title: const Text(
                      'Diagnose-Metadaten anhängen (Opt-in)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Screen (${widget.currentRoute}), App-Version ($appVersionString), '
                      'Gerät (${_resolveDeviceInfo()}) & letzte ${logs.length} anonymisierte Log-Zeilen (ohne Gesundheitsdaten).',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onChanged: (val) {
                      setState(() => _includeDiagnostics = val ?? false);
                    },
                  ),
                  if (_includeDiagnostics &&
                      widget.preCapturedScreenshot != null)
                    CheckboxListTile(
                      key: const Key('beta_screenshot_optin_checkbox'),
                      value: _includeScreenshot,
                      activeColor: AppColors.navy,
                      title: const Text(
                        'Screenshot des aktuellen Screens beifügen',
                        style: TextStyle(fontSize: 13),
                      ),
                      onChanged: (val) {
                        setState(() => _includeScreenshot = val ?? false);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('beta_feedback_submit_button'),
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(
                  _isSubmitting ? 'Wird gesendet...' : 'Meldung absenden',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
