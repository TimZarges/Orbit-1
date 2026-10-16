import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../coach_link/providers/athlete_context_provider.dart';

class ActivityUploadState {
  final bool isUploading;
  final String? error;
  final double progress;
  final int totalFiles;
  final int currentFileIndex;
  final int successfulUploads;
  final String? statusMessage;

  ActivityUploadState({
    this.isUploading = false,
    this.error,
    this.progress = 0.0,
    this.totalFiles = 0,
    this.currentFileIndex = 0,
    this.successfulUploads = 0,
    this.statusMessage,
  });

  ActivityUploadState copyWith({
    bool? isUploading,
    String? error,
    double? progress,
    int? totalFiles,
    int? currentFileIndex,
    int? successfulUploads,
    String? statusMessage,
  }) {
    return ActivityUploadState(
      isUploading: isUploading ?? this.isUploading,
      error: error,
      progress: progress ?? this.progress,
      totalFiles: totalFiles ?? this.totalFiles,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      successfulUploads: successfulUploads ?? this.successfulUploads,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class ActivityUploadNotifier extends StateNotifier<ActivityUploadState> {
  final Ref ref;
  ActivityUploadNotifier(this.ref) : super(ActivityUploadState());

  /// Öffnet den Datei-Picker für .fit, .tcx und .gpx (inkl. .gz) und lädt bis zu 50 Dateien als Batch hoch.
  Future<void> pickAndUpload() async {
    final athleteId = ref.read(viewedAthleteIdProvider);
    if (athleteId == null) {
      state = ActivityUploadState(error: 'Kein aktiver Athleten-Kontext');
      return;
    }

    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['fit', 'tcx', 'gpx', 'gz'],
      );

      if (pickedFiles.isEmpty) {
        return;
      }

      // Begrenzung auf maximal 50 Dateien gemäß Spezifikation 18.2
      final filesToUpload = pickedFiles.take(50).toList();
      final total = filesToUpload.length;

      state = ActivityUploadState(
        isUploading: true,
        progress: 0.0,
        totalFiles: total,
        currentFileIndex: 0,
        successfulUploads: 0,
        statusMessage: 'Starte Upload von $total Datei(en)...',
      );

      int successCount = 0;

      for (int i = 0; i < total; i++) {
        final platformFile = filesToUpload[i];

        state = state.copyWith(
          currentFileIndex: i + 1,
          progress: i / total,
          statusMessage:
              'Lade Datei ${i + 1} von $total hoch (${platformFile.name})...',
        );

        // 25MB Check je Datei
        final fileSize =
            platformFile.lengthSync() ?? await platformFile.length() ?? 0;
        if (fileSize > 25 * 1024 * 1024) {
          state = state.copyWith(
            error:
                'Datei ${platformFile.name} ist größer als 25 MB und wurde übersprungen.',
          );
          continue;
        }

        // Dateiendung ermitteln
        final fileName = platformFile.name.toLowerCase();
        String ext = 'fit';
        if (fileName.endsWith('.fit.gz')) {
          ext = 'fit.gz';
        } else if (fileName.endsWith('.tcx.gz')) {
          ext = 'tcx.gz';
        } else if (fileName.endsWith('.gpx.gz')) {
          ext = 'gpx.gz';
        } else if (fileName.endsWith('.tcx')) {
          ext = 'tcx';
        } else if (fileName.endsWith('.gpx')) {
          ext = 'gpx';
        }

        final activityId = const Uuid().v4();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users/$athleteId/fit/$activityId.$ext');

        final metadata = SettableMetadata(
          customMetadata: {
            'originalName': platformFile.name,
            'athleteId': athleteId,
          },
        );

        if (platformFile.path != null) {
          final file = File(platformFile.path!);
          await storageRef.putFile(file, metadata);
        } else {
          final bytes = await platformFile.readAsBytes();
          await storageRef.putData(bytes, metadata);
        }

        successCount++;

        state = state.copyWith(
          successfulUploads: successCount,
          progress: (i + 1) / total,
        );
      }

      state = ActivityUploadState(
        isUploading: false,
        successfulUploads: successCount,
        totalFiles: total,
        progress: 1.0,
        statusMessage:
            '$successCount von $total Datei(en) erfolgreich importiert!',
      );
    } catch (e) {
      state = ActivityUploadState(
        isUploading: false,
        error: 'Fehler beim Datei-Upload: $e',
      );
    }
  }
}

final activityUploadProvider =
    StateNotifierProvider<ActivityUploadNotifier, ActivityUploadState>((ref) {
  return ActivityUploadNotifier(ref);
});
