/// Datei-Header: `lib/features/activities/services/fit_file_saver_stub.dart`
/// Zweck: Native Mobile-/Desktop-Implementierung zum Speichern heruntergeladener
/// `.FIT`-Bytes über `FilePicker.saveFile` (Android SAF, iOS, macOS, Windows, Linux).
/// Architektur-Einordnung: Plattform-Adapter (`lib/features/activities/services/`),
/// wird per bedingtem Import in [FitDownloadService] auf Nicht-Web-Plattformen
/// geladen (`AGENTS.md` Regel 10).
library;

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Speichert `.FIT`-Binärdaten auf nativen Plattformen (Android/iOS/Desktop)
/// über den System-Speicherdialog (`FilePicker.saveFile`).
///
/// [fileName]: Vorgeschlagener Dateiname (z. B. `261021_Ausfahrt.fit`).
/// [bytes]: Die rohen Binärdaten der Trainingsdatei.
/// [dialogTitle]: Lokalisierter Titel für den System-Speicherdialog.
/// Rückgabewert: Ziel-URI bei Erfolg oder `null`, falls abgebrochen.
Future<Uri?> saveFitBytes({
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
