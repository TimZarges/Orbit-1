import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/metrics/load_preview.dart';

void main() {
  test('Power metrics tests from JSON', () {
    final file = File('testvectors/power_metrics.json');
    if (!file.existsSync()) return;
    
    final content = file.readAsStringSync();
    final List<dynamic> tests = json.decode(content);
    
    for (var t in tests) {
      final ftp = (t['input']['ftp'] as num).toDouble();
      final expectedTss = (t['expected']['tss'] as num).toDouble();
      final expectedNp = (t['expected']['np'] as num).toDouble();
      final tolerance = (t['tolerance'] as num).toDouble();
      
      // Für die Vorschau brauchen wir Dauer und NP.
      // Die Dauer können wir aus dem Array berechnen
      final powerArrayStr = t['input']['powerArray'] as String;
      double duration = 0;
      final parts = powerArrayStr.split(',');
      for (var p in parts) {
        final pp = p.split(':');
        if (pp.length == 3) {
          duration += int.parse(pp[2]);
        }
      }
      
      final tss = LoadPreview.calculateTss(
        durationSeconds: duration,
        normalizedPower: expectedNp,
        ftp: ftp,
      );
      
      expect((tss - expectedTss).abs() <= tolerance, isTrue, reason: 'Failed test ${t['id']}');
    }
  });
}
