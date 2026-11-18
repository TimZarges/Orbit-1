/// Datei-Header: `lib/features/profile/widgets/user_avatar_circle.dart`
/// Zweck: Wiederverwendbares, reaktives Avatar-Widget für Topbar (`AppBar`) und
/// Profil-Ansichten, das `photoUrl`/`avatarUrl` (HTTPS oder Data-URI) sowie
/// optionale lokale Vorschau-Bytes konsistent und absturzfrei darstellt.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/profile/widgets/`),
/// nutzt granulare Riverpod-Selektoren (`.select(...)`) ohne unnötige Rebuilds
/// (`AGENTS.md` Regel 10).
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../services/profile_avatar_service.dart';

/// Stellt ein Benutzer-Profilbild reaktiv über Firestore (`photoUrl` / `avatarUrl`)
/// und Firebase-Auth-Fallback dar.
///
/// Was: Unterstützt lokale Vorschau-Bytes während/vor Upload (`previewBytes`),
/// explizit übergebene URLs (`photoUrlOverride`) sowie automatische Riverpod-Bindung
/// an [userDocumentProvider] und [authStateChangesProvider].
/// Warum: Vermeidet duplizierte Base64-/NetworkImage-Logik in Topbar und Profilbildern
/// und fängt Netzwerkfehler ohne Crash ab (`AGENTS.md` Regel 10).
class UserAvatarCircle extends ConsumerWidget {
  /// Radius des kreisförmigen Avatars.
  final double radius;

  /// Optionale explizite URL (falls vorhanden, überschreibt den Provider-Lookup).
  final String? photoUrlOverride;

  /// Optionale lokale Bild-Bytes (z. B. direkt nach Auswahl im Onboarding/Profil).
  final Uint8List? previewBytes;

  /// Optionale Hintergrundfarbe des Platzhalter-Kreises.
  final Color? backgroundColor;

  /// Optionale Icon-Farbe des Standard-Platzhalters.
  final Color? iconColor;

  /// Erstellt einen [UserAvatarCircle].
  const UserAvatarCircle({
    super.key,
    this.radius = 16,
    this.photoUrlOverride,
    this.previewBytes,
    this.backgroundColor,
    this.iconColor,
  });

  /// Erzeugt sicher den passenden [ImageProvider] für lokale Bytes, Data-URIs oder HTTPS-URLs.
  static ImageProvider? buildImageProvider({
    String? url,
    Uint8List? previewBytes,
  }) {
    if (previewBytes != null && previewBytes.isNotEmpty) {
      return MemoryImage(previewBytes);
    }
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();
    if (clean.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(clean.split(',').last));
      } catch (_) {
        return null;
      }
    }
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return NetworkImage(clean);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String? effectiveUrl;
    if (photoUrlOverride != null) {
      effectiveUrl = photoUrlOverride;
    } else {
      final authUser = ref.watch(
        authStateChangesProvider.select((s) => s.valueOrNull),
      );
      effectiveUrl = ref.watch(
        userDocumentProvider.select(
          (docAsync) => ProfileAvatarService.resolveAvatarUrl(
            docAsync.valueOrNull,
            authUser: authUser,
          ),
        ),
      );
    }

    final ImageProvider? imageProvider = buildImageProvider(
      url: effectiveUrl,
      previewBytes: previewBytes,
    );

    final Color fallbackBg = backgroundColor ??
        (isDark ? AppColors.anthraciteCard : const Color(0xFFE2E8F0));
    final Color fallbackIcon =
        iconColor ?? (isDark ? AppColors.volt : AppColors.navy);

    return CircleAvatar(
      radius: radius,
      backgroundColor: fallbackBg,
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider != null ? (_, __) {} : null,
      child: imageProvider == null
          ? Icon(
              Icons.person,
              size: radius,
              color: fallbackIcon,
            )
          : null,
    );
  }
}
