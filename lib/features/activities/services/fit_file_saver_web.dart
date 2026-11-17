/// Datei-Header: `lib/features/activities/services/fit_file_saver_web.dart`
/// Zweck: Browser-native Web-Implementierung zum direkten Herunterladen von
/// `.FIT`-Binärdaten via Blob-URL und unsichtbarem `<a download="...fit">`-Anker
/// (`dart:js_interop` & `package:web`).
/// Architektur-Einordnung: Plattform-Adapter (`lib/features/activities/services/`),
/// wird per bedingtem Import (`if (dart.library.js_interop)`) ausschließlich
/// in Flutter Web geladen (`AGENTS.md` Regel 10).
library;

import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Löst im Web-Browser (Safari, Chrome, Firefox) sofort einen nativen Datei-Download
/// für die übergebenen `.FIT`-Bytes über eine temporäre Blob-URL aus und gibt
/// den Speicher direkt danach wieder frei.
///
/// [fileName]: Zieldateiname (z. B. `261021_Ausfahrt.fit`).
/// [bytes]: Die geladenen Binärdaten aus Firebase Cloud Storage.
/// [dialogTitle]: Auf Web nicht verwendet (Browser steuert den Download-Dialog).
/// Rückgabewert: Virtuelle Download-URI als Erfolgsbestätigung.
Future<Uri?> saveFitBytes({
  required String fileName,
  required Uint8List bytes,
  required String dialogTitle,
}) async {
  // Uint8List sicher in ein JS-Uint8Array für den Blob-Konstruktor überführen
  final jsData = bytes.toJS;
  final blob = web.Blob(
    <JSAny>[jsData].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final objectUrl = web.URL.createObjectURL(blob);

  // Unsichtbares <a>-Element erzeugen, Klick auslösen und Objekt-URL sauber freigeben
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = objectUrl;
  anchor.download = fileName;
  anchor.style.display = 'none';

  final body = web.document.body;
  body?.appendChild(anchor);
  anchor.click();
  anchor.remove();

  // Verzögerte Freigabe schützt Safari vor vorzeitigem Abbruch beim Download-Start
  Future<void>.delayed(const Duration(seconds: 2), () {
    web.URL.revokeObjectURL(objectUrl);
  });

  return Uri(scheme: 'web-download', path: fileName);
}
