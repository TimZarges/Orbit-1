import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/activities/providers/activity_upload_provider.dart';

void main() {
  group('Phase 35.2 - SAF Android 16 Upload & Isolate Byte Inspection', () {
    test('ActivityUploadState initialisiert sauber', () {
      final state = ActivityUploadState();
      expect(state.isUploading, false);
      expect(state.totalFiles, 0);
      expect(state.progress, 0.0);
      expect(state.uploadedActivityIds, isEmpty);
    });

    test('ActivityUploadState copyWith aktualisiert Felder korrekt', () {
      final state = ActivityUploadState().copyWith(
        isUploading: true,
        progress: 0.5,
        totalFiles: 2,
        currentFileIndex: 1,
        uploadedActivityIds: ['act_1'],
        statusMessage: 'Lade Datei 1 von 2 hoch...',
      );

      expect(state.isUploading, true);
      expect(state.progress, 0.5);
      expect(state.totalFiles, 2);
      expect(state.currentFileIndex, 1);
      expect(state.uploadedActivityIds, contains('act_1'));
      expect(state.statusMessage, contains('Lade Datei 1'));
    });

    test('FileValidationResult erfasst Sportarten und Dateiformate sauber', () {
      final resFit = FileValidationResult(
        isValid: true,
        sport: 'BIKE',
        extension: 'fit',
        estimatedDurationSec: 3600,
        estimatedDistanceM: 30000,
      );

      expect(resFit.isValid, true);
      expect(resFit.sport, 'BIKE');
      expect(resFit.extension, 'fit');
      expect(resFit.estimatedDistanceM, 30000);

      final resTcx = FileValidationResult(
        isValid: true,
        sport: 'RUN',
        extension: 'tcx',
      );
      expect(resTcx.sport, 'RUN');
      expect(resTcx.extension, 'tcx');
    });
  });
}
