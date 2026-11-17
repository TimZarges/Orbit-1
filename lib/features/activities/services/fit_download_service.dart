/// Datei-Header: `lib/features/activities/services/fit_download_service.dart`
/// Zweck: Speicherschonender, plattformübergreifender Download- und Export-Service
/// für originale `.FIT`-Dateien aus Firebase Cloud Storage (`users/{uid}/rawActivities/`).
/// Architektur-Einordnung: Service-Schicht (`lib/features/activities/services/`),
/// kapselt Cloud-Storage-Zugriff und `FilePicker.saveFile` (Android SAF, iOS,
/// Desktop & Web) sauber vom UI-Code (`AGENTS.md` Regel 10).
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import 'fit_file_saver_stub.dart'
    if (dart.library.js_interop) 'fit_file_saver_web.dart' as platform_saver;

/// Ergebnisstatus eines `.FIT`-Datei-Downloads.
enum FitDownloadStatus {
  /// Datei wurde erfolgreich geladen und gespeichert/exportiert.
  success,

  /// Der Benutzer hat den Speicher-Dialog abgebrochen.
  cancelled,

  /// Für diese Aktivität existiert keine Original-`.fit`-Datei in Cloud Storage.
  notFound,

  /// Beim Herunterladen oder Speichern ist ein Fehler aufgetreten.
  error,
}

/// Strukturiertes Ergebnis eines `.FIT`-Downloads.
class FitDownloadResult {
  /// Status des Download-Vorgangs.
  final FitDownloadStatus status;

  /// Dateiname der gespeicherten `.FIT`-Datei (bei Erfolg).
  final String? fileName;

  /// Optionale technische Fehlermeldung zur Diagnose.
  final String? errorMessage;

  /// Erstellt ein unveränderliches [FitDownloadResult].
  const FitDownloadResult({
    required this.status,
    this.fileName,
    this.errorMessage,
  });
}

/// Funktionssignatur zum Laden der Binärdaten aus Cloud Storage (ermöglicht Test-Mocks).
typedef StorageBytesLoader = Future<Uint8List?> Function(String storagePath);

/// Funktionssignatur zum Speichern von Binärdaten auf dem Zielgerät (ermöglicht Test-Mocks).
typedef FileSaver = Future<Uri?> Function({
  required String fileName,
  required Uint8List bytes,
  required String dialogTitle,
});

/// Funktionssignatur für einen autorisierten Server-Fallback-Download via Cloud Function.
typedef CallableFitDownloader = Future<({Uint8List? bytes, String? storagePath})>
    Function(String activityId);

/// Service zum Herunterladen und Speichern originaler `.FIT`-Dateien.
///
/// Was: Lädt die Originaldatei über `activity.rawFilePath` oder den kanonischen
/// Pfad `users/{athleteId}/rawActivities/{activityId}.fit` aus Cloud Storage
/// (mit sicherem Cloud-Function-Fallback `downloadActivityFit` bei Cross-Service-
/// oder CORS-Sperren) und exportiert sie über Web-Blob oder `FilePicker.saveFile`.
/// Warum: Begrenzt die maximale Dateigröße auf 25 MB (analog `storage.rules`),
/// vermeidet unnötige Speicherallokationen und kapselt Storage/SAF für Unit-Tests.
class FitDownloadService {
  /// Maximale Dateigröße für Rohdateien (25 MB gemäß `storage.rules`).
  static const int maxRawFileBytes = 25 * 1024 * 1024;

  /// Injizierbarer Loader für Cloud-Storage-Bytes.
  final StorageBytesLoader _loadBytes;

  /// Injizierbarer Saver für den plattformübergreifenden Datei-Export.
  final FileSaver _saveFile;

  /// Injizierbarer Fallback-Loader über `downloadActivityFit` (`europe-west3`).
  final CallableFitDownloader? _callableFallback;

  /// Gibt an, ob ein eigener Storage-Loader im Test injiziert wurde.
  final bool _hasCustomLoader;

  /// Erstellt einen [FitDownloadService].
  ///
  /// [loadBytes]: Optionaler benutzerdefinierter Storage-Loader (Standard: Firebase Storage).
  /// [saveFile]: Optionaler benutzerdefinierter File-Saver (Standard: Web-Blob / SAF).
  /// [callableFallback]: Optionaler Fallback-Aufrufer für Tests.
  FitDownloadService({
    StorageBytesLoader? loadBytes,
    FileSaver? saveFile,
    CallableFitDownloader? callableFallback,
  })  : _hasCustomLoader = loadBytes != null,
        _loadBytes = loadBytes ?? _defaultStorageLoader,
        _saveFile = saveFile ?? _defaultFileSaver,
        _callableFallback = callableFallback;

  /// Standard-Loader über Firebase Cloud Storage (`getData` mit 25 MB Limit).
  static Future<Uint8List?> _defaultStorageLoader(String storagePath) async {
    return FirebaseStorage.instance
        .ref(storagePath)
        .getData(maxRawFileBytes);
  }

  /// Autorisierter Server-Fallback über die Cloud Function `downloadActivityFit`
  /// in `europe-west3` (prüft `coachLinks` und lädt die `.fit`-Datei via Admin SDK).
  static Future<({Uint8List? bytes, String? storagePath})>
      _defaultCallableDownloader(String activityId) async {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
        .httpsCallable('downloadActivityFit');
    final response = await callable.call({'activityId': activityId});
    final data = response.data;
    if (data is Map && data['found'] == true && data['base64'] is String) {
      final decoded = base64Decode(data['base64'] as String);
      return (
        bytes: decoded,
        storagePath: data['storagePath'] as String?,
      );
    }
    return (bytes: null, storagePath: null);
  }

  /// Gibt zurück, ob im aktuellen Build der native Web-Blob-Download aktiv ist.
  static bool get usesWebBlobDownload => kIsWeb;

  /// Standard-Saver über plattformbedingten Adapter (Web Blob-URL vs. FilePicker SAF/Desktop).
  static Future<Uri?> _defaultFileSaver({
    required String fileName,
    required Uint8List bytes,
    required String dialogTitle,
  }) {
    return platform_saver.saveFitBytes(
      fileName: fileName,
      bytes: bytes,
      dialogTitle: dialogTitle,
    );
  }

  /// Ermittelt die zu prüfenden Storage-Pfade für eine [Activity].
  ///
  /// [activity]: Die betroffene Trainingseinheit.
  /// Rückgabewert: Priorisierte Liste möglicher Cloud-Storage-Pfade.
  static List<String> resolveCandidatePaths(Activity activity) {
    final paths = <String>[];
    final rawPath = activity.rawFilePath?.trim();
    // Garmin-Summary-JSON nicht als .FIT-Download bevorzugen
    if (rawPath != null &&
        rawPath.isNotEmpty &&
        !rawPath.toLowerCase().endsWith('.json')) {
      paths.add(rawPath);
    }
    if (activity.athleteId.isNotEmpty && activity.id.isNotEmpty) {
      final defaultFit =
          'users/${activity.athleteId}/rawActivities/${activity.id}.fit';
      if (!paths.contains(defaultFit)) {
        paths.add(defaultFit);
      }
      final defaultFitGz =
          'users/${activity.athleteId}/rawActivities/${activity.id}.fit.gz';
      if (!paths.contains(defaultFitGz)) {
        paths.add(defaultFitGz);
      }
    }
    return paths;
  }

  /// Erstellt einen sicheren, lesbaren Dateinamen für den Export (z. B. `261021_Bonn_Ausfahrt.fit`).
  static String buildExportFileName(Activity activity, {String? sourcePath}) {
    final datePrefix = activity.localDate.replaceAll('-', '');
    final sanitizedTitle = activity.title
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-äöüÄÖÜß]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final baseName =
        sanitizedTitle.isEmpty ? activity.id : '${datePrefix}_$sanitizedTitle';
    final isGzip = sourcePath != null && sourcePath.toLowerCase().endsWith('.gz');
    return isGzip ? '$baseName.fit.gz' : '$baseName.fit';
  }

  /// Lädt die originale `.FIT`-Datei herunter und speichert/exportiert sie auf dem Gerät.
  ///
  /// [activity]: Aktivität, deren `.FIT`-Datei geladen werden soll.
  /// [lang]: Aktive Sprache (`'de'` oder `'en'`) für den Speicherdialog-Titel.
  /// Rückgabewert: [FitDownloadResult] mit Status und Dateiname.
  Future<FitDownloadResult> downloadFitFile(
    Activity activity, {
    String lang = 'de',
  }) async {
    final candidates = resolveCandidatePaths(activity);
    if (candidates.isEmpty) {
      return const FitDownloadResult(status: FitDownloadStatus.notFound);
    }

    Uint8List? downloadedBytes;
    String? matchedPath;
    bool shouldTryCallableFallback = false;

    // Prüfen, ob ein Coach auf die .FIT-Datei eines fremden Athleten zugreift:
    // Nutzt im Produktivbetrieb direkt die autorisierte Cloud Function `downloadActivityFit`
    // (ohne Cross-Service-Storage-Rules-Latenz), bleibt in Tests über _hasCustomLoader unberührt.
    String? currentUid;
    try {
      currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    final bool isCrossUserDownload = !_hasCustomLoader &&
        currentUid != null &&
        activity.athleteId.isNotEmpty &&
        currentUid != activity.athleteId;

    if (isCrossUserDownload) {
      try {
        final fallback = _callableFallback ?? _defaultCallableDownloader;
        final res = await fallback(activity.id);
        if (res.bytes != null && res.bytes!.isNotEmpty) {
          downloadedBytes = res.bytes;
          matchedPath = res.storagePath;
        } else {
          return const FitDownloadResult(status: FitDownloadStatus.notFound);
        }
      } catch (e) {
        return FitDownloadResult(
          status: FitDownloadStatus.error,
          errorMessage: e.toString(),
        );
      }
    } else {
      // 1. Kandidaten-Pfade direkt über Cloud Storage prüfen
      for (final path in candidates) {
        try {
          final bytes = await _loadBytes(path);
          if (bytes != null && bytes.isNotEmpty) {
            downloadedBytes = bytes;
            matchedPath = path;
            break;
          }
        } on FirebaseException catch (e) {
          if (e.code.contains('unauthorized') ||
              e.code.contains('permission-denied') ||
              (e.message?.toLowerCase().contains('not authorized') ?? false)) {
            shouldTryCallableFallback = true;
            break;
          }
          if (!e.code.contains('object-not-found')) {
            return FitDownloadResult(
              status: FitDownloadStatus.error,
              errorMessage: e.message ?? e.code,
            );
          }
        } catch (e) {
          if (!_hasCustomLoader || _callableFallback != null) {
            shouldTryCallableFallback = true;
            break;
          }
          return FitDownloadResult(
            status: FitDownloadStatus.error,
            errorMessage: e.toString(),
          );
        }
      }

      // 2. Autorisierter Server-Fallback bei Cross-Service-/Storage-Rules-Sperre
      if (downloadedBytes == null &&
          shouldTryCallableFallback &&
          (!_hasCustomLoader || _callableFallback != null)) {
        try {
          final fallback = _callableFallback ?? _defaultCallableDownloader;
          final res = await fallback(activity.id);
          if (res.bytes != null && res.bytes!.isNotEmpty) {
            downloadedBytes = res.bytes;
            matchedPath = res.storagePath;
          } else {
            return const FitDownloadResult(status: FitDownloadStatus.notFound);
          }
        } catch (fallbackErr) {
          return FitDownloadResult(
            status: FitDownloadStatus.error,
            errorMessage: fallbackErr.toString(),
          );
        }
      }
    }

    if (downloadedBytes == null) {
      return const FitDownloadResult(status: FitDownloadStatus.notFound);
    }

    // Datei über System-Dialog / Web-Download speichern
    final fileName = buildExportFileName(activity, sourcePath: matchedPath);
    try {
      final savedUri = await _saveFile(
        fileName: fileName,
        bytes: downloadedBytes,
        dialogTitle:
            lang == 'en' ? 'Save .FIT file' : '.FIT-Datei speichern',
      );
      if (savedUri == null) {
        return FitDownloadResult(
          status: FitDownloadStatus.cancelled,
          fileName: fileName,
        );
      }
      return FitDownloadResult(
        status: FitDownloadStatus.success,
        fileName: fileName,
      );
    } catch (e) {
      return FitDownloadResult(
        status: FitDownloadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

/// Riverpod-Provider für den [FitDownloadService].
final fitDownloadServiceProvider = Provider<FitDownloadService>((ref) {
  return FitDownloadService();
});

/// Hält die IDs aller Aktivitäten, deren `.FIT`-Datei aktuell heruntergeladen wird.
///
/// Ermöglicht granulare Selektoren (`select((ids) => ids.contains(activity.id))`),
/// sodass nur die betroffene Vorschaukarte ihren Ladeindikator aktualisiert.
final fitDownloadingIdsProvider = StateProvider<Set<String>>((ref) {
  return const <String>{};
});
