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

  ActivityUploadState(
      {this.isUploading = false, this.error, this.progress = 0.0});
}

class ActivityUploadNotifier extends StateNotifier<ActivityUploadState> {
  final Ref ref;
  ActivityUploadNotifier(this.ref) : super(ActivityUploadState());

  Future<void> pickAndUpload() async {
    final athleteId = ref.read(viewedAthleteIdProvider);
    if (athleteId == null) {
      state = ActivityUploadState(error: 'Not in athlete context');
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['fit'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        final file = File(result.first.path!);

        // 25MB check
        final size = await file.length();
        if (size > 25 * 1024 * 1024) {
          state = ActivityUploadState(error: 'File too large (max 25MB)');
          return;
        }

        final activityId = const Uuid().v4();
        state = ActivityUploadState(isUploading: true, progress: 0.0);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users/$athleteId/fit/$activityId.fit');

        final uploadTask = storageRef.putFile(file);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          state = ActivityUploadState(isUploading: true, progress: progress);
        });

        await uploadTask;
        state = ActivityUploadState(isUploading: false);
      }
    } catch (e) {
      state = ActivityUploadState(error: e.toString());
    }
  }
}

final activityUploadProvider =
    StateNotifierProvider<ActivityUploadNotifier, ActivityUploadState>((ref) {
  return ActivityUploadNotifier(ref);
});
