import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../design/app_colors.dart';
import '../design/app_typography.dart';

/// Statische Metadaten über den aktuellen Client-Build.
class AppInfo {
  static const String version = '1.0.0';
  static const int buildNumber = 1;
  static const String environment = 'Closed Beta';
  static const String region = 'Deutschland (Frankfurt am Main)';

  static String get fullVersionString =>
      'v$version (Build $buildNumber) • $environment';
}

/// Remote-Konfiguration für Force-Updates, Wartungsmodus und Feature-Flags.
class AppConfig {
  final int minRequiredBuild;
  final int latestBuild;
  final String updateUrl;
  final bool maintenanceMode;
  final Map<String, bool> featureFlags;

  const AppConfig({
    this.minRequiredBuild = 1,
    this.latestBuild = 1,
    this.updateUrl = 'https://app.orbit.training/download',
    this.maintenanceMode = false,
    this.featureFlags = const {},
  });

  bool isFeatureEnabled(String flagKey, {bool defaultValue = false}) {
    return featureFlags[flagKey] ?? defaultValue;
  }

  factory AppConfig.fromDocument(DocumentSnapshot doc) {
    if (!doc.exists) return const AppConfig();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppConfig.fromMap(data);
  }

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    final rawFlags = map['featureFlags'];
    final flags = <String, bool>{};
    if (rawFlags is Map) {
      rawFlags.forEach((key, value) {
        if (value is bool) flags[key.toString()] = value;
      });
    }

    return AppConfig(
      minRequiredBuild: (map['minRequiredBuild'] as num?)?.toInt() ?? 1,
      latestBuild: (map['latestBuild'] as num?)?.toInt() ?? 1,
      updateUrl:
          map['updateUrl'] as String? ?? 'https://app.orbit.training/download',
      maintenanceMode: map['maintenanceMode'] as bool? ?? false,
      featureFlags: flags,
    );
  }
}

/// Provider für den kontinuierlichen App-Config Stream aus `/app_config/version_gate`.
final appConfigStreamProvider = StreamProvider<AppConfig>((ref) {
  return FirebaseFirestore.instance
      .collection('app_config')
      .doc('version_gate')
      .snapshots()
      .map((doc) => AppConfig.fromDocument(doc))
      .handleError((_) => const AppConfig());
});

/// Provider zur einfachen Abfrage einzelner Feature-Flags.
final featureFlagProvider = Provider.family<bool, String>((ref, flagKey) {
  final configAsync = ref.watch(appConfigStreamProvider);
  return configAsync.valueOrNull?.isFeatureEnabled(flagKey) ?? false;
});

/// VersionGateWrapper: Prüft, ob der aktuelle Client die Mindest-Build-Version erfüllt.
/// Falls `minRequiredBuild > currentBuild`, wird ein blockierender Fullscreen-Dialog
/// im ORBIT-Navy/Volt-Look angezeigt.
class VersionGateWrapper extends ConsumerWidget {
  final Widget child;

  const VersionGateWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigStreamProvider);
    final config = configAsync.valueOrNull ?? const AppConfig();

    // 1. Wartungsmodus-Prüfung
    if (config.maintenanceMode) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: AppColors.navy,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.volt,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.build_outlined,
                          size: 32, color: AppColors.navy),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Wartungsarbeiten',
                      style: AppTypography.headline.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ORBIT führt derzeit planmäßige Wartungsarbeiten durch. Bitte versuche es in wenigen Minuten erneut.',
                      style: AppTypography.body.copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 2. Force-Update-Prüfung: minRequiredBuild > currentBuild
    if (config.minRequiredBuild > AppInfo.buildNumber) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: AppColors.navy,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ORBIT Update Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.volt.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.volt, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.system_update_alt_rounded,
                            size: 36, color: AppColors.volt),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Neues Beta-Update erforderlich',
                      style: AppTypography.headline.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Deine Version (${AppInfo.fullVersionString}) wird nicht mehr unterstützt.\n'
                      'Bitte installiere das neueste Update (Build ${config.latestBuild}), um weiterhin trainieren und synchronisieren zu können.',
                      style: AppTypography.body.copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (await canLaunchUrlString(config.updateUrl)) {
                            await launchUrlString(config.updateUrl,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.volt,
                          foregroundColor: AppColors.navy,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Jetzt aktualisieren',
                          style: AppTypography.title.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return child;
  }
}
