import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/activity_stream.dart';

/// Interaktive GPS-Streckenkarte im Dark Cockpit.
///
/// Unterstützt:
/// - DSGVO-konforme Vektor-Streckenführung (funktioniert komplett offline ohne IP-Übertragung)
/// - Opt-in-Einwilligung für externe Kacheln
/// - Synchrone Positionierung des Markers beim Chart-Scrubbing
/// - Start- (Grün) und Ziel- (Rot) Pins
class TelemetryMapWidget extends StatefulWidget {
  final List<ActivityStreamPoint> points;
  final ActivityStreamPoint? scrubPoint;
  final double height;

  const TelemetryMapWidget({
    super.key,
    required this.points,
    this.scrubPoint,
    this.height = 240,
  });

  @override
  State<TelemetryMapWidget> createState() => _TelemetryMapWidgetState();
}

class _TelemetryMapWidgetState extends State<TelemetryMapWidget> {
  bool _tilesEnabled = false;

  void _requestTileConsent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Externe Kartenkacheln laden?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Beim Laden von Umgebungskarten wird deine IP-Adresse an den Kartenanbieter übertragen. '
          'Deine Streckenführung bleibt auch ohne externe Kacheln vollständig interaktiv.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _tilesEnabled = true);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentVolt,
              foregroundColor: AppColors.navy,
            ),
            child: const Text('Aktivieren'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gpsPoints = widget.points.where((p) => p.lat != null && p.lng != null).toList();

    if (gpsPoints.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, color: Colors.grey.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              'Keine GPS-Strecke erfasst (Indoor / Rolle)',
              style: AppTypography.bodySmall.copyWith(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Stack(
        children: [
          // Strecken-Painter
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(
              points: gpsPoints,
              scrubPoint: widget.scrubPoint,
              showGrid: _tilesEnabled,
            ),
          ),

          // Start / Ziel & Distanz Badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route, size: 14, color: AppColors.accentVolt),
                  const SizedBox(width: 6),
                  Text(
                    'GPS-Strecke (${(gpsPoints.last.distanceM / 1000).toStringAsFixed(1)} km)',
                    style: AppTypography.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Kacheln-Opt-in Button
          Positioned(
            bottom: 12,
            right: 12,
            child: InkWell(
              onTap: _requestTileConsent,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _tilesEnabled ? Icons.layers : Icons.layers_outlined,
                      size: 14,
                      color: _tilesEnabled ? AppColors.accentVolt : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _tilesEnabled ? 'Kartenkacheln aktiv' : 'Kartenkacheln laden',
                      style: AppTypography.label.copyWith(
                        color: _tilesEnabled ? AppColors.accentVolt : Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<ActivityStreamPoint> points;
  final ActivityStreamPoint? scrubPoint;
  final bool showGrid;

  _RoutePainter({
    required this.points,
    this.scrubPoint,
    this.showGrid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final lats = points.map((p) => p.lat!).toList();
    final lngs = points.map((p) => p.lng!).toList();

    final minLat = lats.fold(1000.0, min);
    final maxLat = lats.fold(-1000.0, max);
    final minLng = lngs.fold(1000.0, min);
    final maxLng = lngs.fold(-1000.0, max);

    final deltaLat = (maxLat - minLat).abs();
    final deltaLng = (maxLng - minLng).abs();

    if (deltaLat == 0 || deltaLng == 0) return;

    // Zentrierung mit Padding
    const padding = 32.0;
    final drawW = size.width - (padding * 2);
    final drawH = size.height - (padding * 2);

    final scale = min(drawW / deltaLng, drawH / deltaLat);

    final offsetX = padding + (drawW - (deltaLng * scale)) / 2;
    final offsetY = padding + (drawH - (deltaLat * scale)) / 2;

    Offset toOffset(double lat, double lng) {
      final x = offsetX + (lng - minLng) * scale;
      final y = size.height - (offsetY + (lat - minLat) * scale); // Invertierte Y-Achse
      return Offset(x, y);
    }

    // Optionaler Rasterhintergrund
    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 1.0;
      for (double x = 0; x < size.width; x += 40) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // Polyline der Route zeichnen
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final pt = toOffset(points[i].lat!, points[i].lng!);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    // Schein-Glow um die Route
    final glowPaint = Paint()
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.3)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glowPaint);

    // Hauptlinie in Cyan
    final routePaint = Paint()
      ..color = const Color(0xFF22D3EE)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, routePaint);

    // Start-Pin (Grün)
    final startPt = toOffset(points.first.lat!, points.first.lng!);
    canvas.drawCircle(startPt, 6, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(startPt, 3, Paint()..color = Colors.white);

    // Ziel-Pin (Rot/Navy)
    final finishPt = toOffset(points.last.lat!, points.last.lng!);
    canvas.drawCircle(finishPt, 6, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(finishPt, 3, Paint()..color = Colors.white);

    // Synchrone Scrubbing-Position (Volt-Marker)
    if (scrubPoint != null && scrubPoint!.lat != null && scrubPoint!.lng != null) {
      final scrubPt = toOffset(scrubPoint!.lat!, scrubPoint!.lng!);
      // Pulsierender Außenkreis
      canvas.drawCircle(scrubPt, 10, Paint()..color = AppColors.accentVolt.withValues(alpha: 0.4));
      // Kern
      canvas.drawCircle(scrubPt, 5, Paint()..color = AppColors.accentVolt);
      canvas.drawCircle(scrubPt, 2, Paint()..color = AppColors.navy);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.scrubPoint != scrubPoint ||
        oldDelegate.showGrid != showGrid;
  }
}
