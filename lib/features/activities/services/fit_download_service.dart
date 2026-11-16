/// Datei-Header: `lib/features/activities/services/fit_download_service.dart`
/// Zweck: Speicherschonender, plattformübergreifender Download- und Export-Service
/// für originale `.FIT`-Dateien aus Firebase Cloud Storage (`users/{uid}/rawActivities/`).
/// Architektur-Einordnung: Service-Schicht (`lib/features/activities/services/`),
/// kapselt Cloud-Storage-Zugriff und `FilePicker.saveFile` (Android SAF, iOS,
/// Desktop & Web) sauber vom UI-Code (`AGENTS.md` Regel 10).
library;

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';

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

/// Service zum Herunterladen und Speichern originaler `.FIT`-Dateien.
///
/// Was: Lädt die Originaldatei über `activity.rawFilePath` oder den kanonischen
/// Pfad `users/{athleteId}/rawActivities/{activityId}.fit` aus Cloud Storage
/// und exportiert sie über `FilePicker.saveFile`.
/// Warum: Begrenzt die maximale Dateigröße auf 25 MB (analog `storage.rules`),
/// vermeidet unnötige Speicherallokationen und kapselt Storage/SAF für Unit-Tests.
class FitDownloadService {
  /// Maximale Dateigröße für Rohdateien (25 MB gemäß `storage.rules`).
  static const int maxRawFileBytes = 25 * 1024 * 1024;

  /// Injizierbarer Loader für Cloud-Storage-Bytes.
  final StorageBytesLoader _loadBytes;

  /// Injizierbarer Saver für den plattformübergreifenden Datei-Export.
  final FileSaver _saveFile;

  /// Erstellt einen [FitDownloadService].
  ///
  /// [loadBytes]: Optionaler benutzerdefinierter Storage-Loader (Standard: Firebase Storage).
  /// [saveFile]: Optionaler benutzerdefinierter File-Saver (Standard: `FilePicker.saveFile`).
  FitDownloadService({
    StorageBytesLoader? loadBytes,
    FileSaver? saveFile,
  })  : _loadBytes = loadBytes ?? _defaultStorageLoader,
        _saveFile = saveFile ?? _defaultFileSaver;

  /// Standard-Loader über Firebase Cloud Storage (`getData` mit 25 MB Limit).
  static Future<Uint8List?> _defaultStorageLoader(String storagePath) async {
    return FirebaseStorage.instance
        .ref(storagePath)
        .getData(maxRawFileBytes);
  }

  /// Standard-Saver über `FilePicker.saveFile` (unterstützt Android SAF, iOS, Desktop & Web).
  static Future<Uri?> _defaultFileSaver({
    required String fileName,
    required Uint8List bytes,
    required String dialogTitle,
  }) {
    return FilePicker.saveFile(
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
    if (rawPath != null && rawPath.isNotEmpty) {
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

    // Kandidaten-Pfade der Reihe nach prüfen (zuerst rawFilePath, dann kanonischer Pfad)
    for (final path in candidates) {
      try {
        final bytes = await _loadBytes(path);
        if (bytes != null && bytes.isNotEmpty) {
          downloadedBytes = bytes;
          matchedPath = path;
          break;
        }
      } on FirebaseException catch (e) {
        // Bei 'object-not-found' nächsten Kandidaten prüfen, andere Fehler direkt melden
        if (e.code != 'object-not-found') {
          return FitDownloadResult(
            status: FitDownloadStatus.error,
            errorMessage: e.message ?? e.code,
          );
        }
      } catch (e) {
        return FitDownloadResult(
          status: FitDownloadStatus.error,
          errorMessage: e.toString(),
        );
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
