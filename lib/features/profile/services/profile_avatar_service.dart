/// Datei-Header: `lib/features/profile/services/profile_avatar_service.dart`
/// Zweck: Zentraler Service für die komprimierte Profilbild-Auswahl, den echten
/// Cloud-Storage-Upload (`users/{uid}/avatars/profile.jpg`) sowie die konsistente
/// Persistenz von `photoUrl` & `avatarUrl` in Firestore und Firebase Auth.
/// Architektur-Einordnung: Datenhaltungs-/Service-Schicht (`lib/features/profile/services/`),
/// entkoppelt Datei-Auswahl, Bildskalierung und Firebase-Uploads sauber von den UI-Widgets
/// (`AGENTS.md` Regel 10).
library;

import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Callback-Signatur für testbare Storage-Uploads ohne Live-Firebase.
typedef AvatarUploadCallback = Future<String> Function(
  String uid,
  Uint8List bytes,
);

/// Service zur dauerhaften Profilbild-Verwaltung (Android & ORBIT Web).
///
/// Was:
/// - Wählt ein Bild über `FilePicker` (`withData: true` für Android-SAF & Web) aus.
/// - Skaliert zu große Bilder bei Bedarf mithilfe von `dart:ui` auf maximal 512px Breite
///   (vermeidet Speicher- und 1-MB-Firestore-Probleme).
/// - Lädt die Bytes nach `users/{uid}/avatars/profile.jpg` mit `SettableMetadata`
///   (`image/jpeg`, `public,max-age=3600`) in Firebase Cloud Storage hoch.
/// - Speichert die Download-URL konsistent auf `users/{uid}` (`photoUrl` & `avatarUrl`
///   auf Top-Level und im `profile`-Objekt) sowie über `user.updatePhotoURL(...)`.
/// Warum: Base64-Strings direkt in Firestore sprengen schnell das Dokumentlimit und
/// wurden beim nachträglichen Speichern nicht sauber mit der Topbar synchronisiert.
class ProfileAvatarService {
  /// Optionaler Override für isolierte Tests ohne echtes Firebase.
  final AvatarUploadCallback? _uploadOverride;

  /// Erstellt einen [ProfileAvatarService].
  const ProfileAvatarService({AvatarUploadCallback? uploadOverride})
      : _uploadOverride = uploadOverride;

  /// Ermittelt die gespeicherte Profilbild-URL konsistent aus Firestore-Dokument
  /// und Firebase-Auth-Fallback (ignoriert leere Strings).
  static String? resolveAvatarUrl(
    Map<String, dynamic>? userDoc, {
    User? authUser,
  }) {
    final profile = userDoc?['profile'] as Map<String, dynamic>?;
    final candidates = <Object?>[
      userDoc?['photoUrl'],
      userDoc?['avatarUrl'],
      profile?['photoUrl'],
      profile?['avatarUrl'],
      authUser?.photoURL,
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }

  /// Öffnet den plattformübergreifenden Bild-Picker (`FileType.image`) und liefert
  /// kompakte Bild-Bytes zurück (`null`, wenn der Nutzer abbricht).
  Future<Uint8List?> pickAndCompressAvatarBytes() async {
    final file = await FilePicker.pickFile(
      type: FileType.image,
    );
    if (file == null) return null;

    final rawBytes = await file.readAsBytes();
    if (rawBytes.isEmpty) return null;

    // Zu große Kamera-/Galeriefotos (> 450 KB) auf max. 512px Breite skalieren
    if (rawBytes.lengthInBytes > 450 * 1024) {
      return _downscaleImageBytes(rawBytes, targetWidth: 512);
    }
    return rawBytes;
  }

  /// Skaliert Bild-Bytes sicher per nativer Codec-Engine herunter, um Bandbreite
  /// und Speicher in Android/Web zu schonen.
  Future<Uint8List> _downscaleImageBytes(
    Uint8List sourceBytes, {
    int targetWidth = 512,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        sourceBytes,
        targetWidth: targetWidth,
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (byteData != null && byteData.lengthInBytes > 0) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Avatar-Skalierung übersprungen: $e');
    }
    return sourceBytes;
  }

  /// Lädt Profilbild-Bytes in Firebase Cloud Storage hoch und verankert die
  /// Download-URL dauerhaft in Firestore (`photoUrl` & `avatarUrl`) sowie Firebase Auth.
  Future<String> uploadAndPersistAvatar({
    required String uid,
    required Uint8List bytes,
  }) async {
    final override = _uploadOverride;
    if (override != null) {
      return override(uid, bytes);
    }

    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase ist nicht initialisiert.');
    }

    final storageRef =
        FirebaseStorage.instance.ref('users/$uid/avatars/profile.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'public,max-age=3600',
    );

    await storageRef.putData(bytes, metadata);
    final rawUrl = await storageRef.getDownloadURL();
    // Cache-Busting-Parameter stellt sicher, dass ein neu gewähltes Foto sofort
    // in allen NetworkImage-Widgets ohne veralteten Browser-Cache geladen wird.
    final separator = rawUrl.contains('?') ? '&' : '?';
    final downloadUrl =
        '$rawUrl${separator}v=${DateTime.now().millisecondsSinceEpoch}';

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'photoUrl': downloadUrl,
        'avatarUrl': downloadUrl,
        'profile': {
          'photoUrl': downloadUrl,
          'avatarUrl': downloadUrl,
        },
      },
      SetOptions(merge: true),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        await user.updatePhotoURL(downloadUrl);
      }
    } catch (e) {
      // Auth-photoURL ist ein Spiegel-Fallback; Firestore bleibt führende Quelle
      debugPrint('Warnung updatePhotoURL: $e');
    }

    return downloadUrl;
  }
}

/// Riverpod-Provider für den [ProfileAvatarService].
final profileAvatarServiceProvider = Provider<ProfileAvatarService>((ref) {
  return const ProfileAvatarService();
});
