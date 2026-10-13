import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization Completeness Tests', () {
    test('all ARB keys in app_de.arb exist in app_en.arb and vice versa', () {
      final deFile = File('lib/l10n/app_de.arb');
      final enFile = File('lib/l10n/app_en.arb');

      expect(deFile.existsSync(), isTrue, reason: 'app_de.arb must exist');
      expect(enFile.existsSync(), isTrue, reason: 'app_en.arb must exist');

      final deMap = jsonDecode(deFile.readAsStringSync()) as Map<String, dynamic>;
      final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;

      // Keys ignorieren, die mit @ beginnen (Metadaten)
      final deKeys = deMap.keys.where((k) => !k.startsWith('@')).toSet();
      final enKeys = enMap.keys.where((k) => !k.startsWith('@')).toSet();

      final missingInEn = deKeys.difference(enKeys);
      final missingInDe = enKeys.difference(deKeys);

      expect(missingInEn, isEmpty, reason: 'Keys in de, but missing in en: $missingInEn');
      expect(missingInDe, isEmpty, reason: 'Keys in en, but missing in de: $missingInDe');
    });

    test('no empty translations in de or en', () {
      final deFile = File('lib/l10n/app_de.arb');
      final enFile = File('lib/l10n/app_en.arb');

      final deMap = jsonDecode(deFile.readAsStringSync()) as Map<String, dynamic>;
      final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;

      for (final entry in deMap.entries) {
        if (!entry.key.startsWith('@')) {
          expect(entry.value.toString().trim(), isNotEmpty,
              reason: 'Key ${entry.key} in app_de.arb is empty');
        }
      }

      for (final entry in enMap.entries) {
        if (!entry.key.startsWith('@')) {
          expect(entry.value.toString().trim(), isNotEmpty,
              reason: 'Key ${entry.key} in app_en.arb is empty');
        }
      }
    });
  });
}
