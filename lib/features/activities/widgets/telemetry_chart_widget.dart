import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/activity_stream.dart';
import 'telemetry_channel_chips.dart';

/// Interaktives Telemetrie-Chart im Dark Cockpit (#0F172A).
///
/// Unterstützt:
/// - LTTB-optimierte Mehrkanallinien
/// - Weiches Höhen-Backdrop-Band
/// - Long-Press-to-Scrub mit haptischem Feedback und HUD über dem Finger
/// - Zeit- vs. Distanzachse
/// - Synchrone Positionierung auf der Karte
class TelemetryChartWidget extends StatefulWidget {
  final List<ActivityStreamPoint> points;
  final Set<TelemetryChannel> activeChannels;
  final bool useDistanceAxis;
  final ValueChanged<ActivityStreamPoint?>? onScrub;
  final VoidCallback? onToggleFullscreen;
  final double height;

  const TelemetryChartWidget({
    super.key,
    required this.points,
    required this.activeChannels,
    this.useDistanceAxis = false,
    this.onScrub,
    this.onToggleFullscreen,
    this.height = 240,
  });

  @override
  State<TelemetryChartWidget> createState() => _TelemetryChartWidgetState();
}

class _TelemetryChartWidgetState extends State<TelemetryChartWidget> {
  int? _scrubIndex;
  Offset? _scrubPosition;

  void _handleLongPressStart(
      LongPressStartDetails details, BoxConstraints constraints) {
    HapticFeedback.selectionClick();
    _updateScrub(details.localPosition.dx, constraints.maxWidth);
  }

  void _handleLongPressMoveUpdate(
      LongPressMoveUpdateDetails details, BoxConstraints constraints) {
    _updateScrub(details.localPosition.dx, constraints.maxWidth);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _scrubIndex = null;
      _scrubPosition = null;
    });
    widget.onScrub?.call(null);
  }

  void _updateScrub(double dx, double width) {
    if (widget.points.isEmpty || width <= 0) return;
    final fraction = (dx / width).clamp(0.0, 1.0);
    final index = (fraction * (widget.points.length - 1)).round();

    if (_scrubIndex != index) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _scrubIndex = index;
      _scrubPosition = Offset(dx.clamp(0.0, width), 0);
    });

    widget.onScrub?.call(widget.points[index]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return Container(
        height: widget.height,
        color: const Color(0xFF0F172A),
        alignment: Alignment.center,
        child: const Text('Keine Telemetrie-Daten vorhanden',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scrubPoint =
            _scrubIndex != null ? widget.points[_scrubIndex!] : null;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onLongPressStart: (d) => _handleLongPressStart(d, constraints),
              onLongPressMoveUpdate: (d) =>
                  _handleLongPressMoveUpdate(d, constraints),
              onLongPressEnd: _handleLongPressEnd,
              child: Container(
                height: widget.height,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Dark Cockpit Background
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, widget.height),
                  painter: _TelemetryChartPainter(
                    points: widget.points,
                    activeChannels: widget.activeChannels,
                    scrubIndex: _scrubIndex,
                    useDistanceAxis: widget.useDistanceAxis,
                  ),
                ),
              ),
            ),

            // HUD über dem Finger
            if (scrubPoint != null && _scrubPosition != null)
              Positioned(
                left: (_scrubPosition!.dx - 80)
                    .clamp(8.0, constraints.maxWidth - 168.0),
                top: -50,
                child: _buildHud(scrubPoint),
              ),

            // Vollbild-Button oben rechts
            if (widget.onToggleFullscreen != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen,
                      color: Colors.white70, size: 20),
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: widget.onToggleFullscreen,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHud(ActivityStreamPoint point) {
    final timeStr = _formatTime(point.timeSec);
    final distKm = (point.distanceM / 1000).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentVolt.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.useDistanceAxis
                ? '$distKm km ($timeStr)'
                : '$timeStr ($distKm km)',
            style: AppTypography.label.copyWith(
                color: AppColors.accentVolt,
                fontWeight: FontWeight.bold,
                fontSize: 10),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            children: [
              if (widget.activeChannels.contains(TelemetryChannel.power) &&
                  point.power != null)
                Text('${point.power!.round()} W',
                    style: TextStyle(
                        color: TelemetryChannel.power.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              if (widget.activeChannels.contains(TelemetryChannel.heartRate) &&
                  point.hr != null)
                Text('${point.hr!.round()} bpm',
                    style: TextStyle(
                        color: TelemetryChannel.heartRate.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              if (widget.activeChannels.contains(TelemetryChannel.speed) &&
                  point.speedMps != null)
                Text('${(point.speedMps! * 3.6).toStringAsFixed(1)} km/h',
                    style: TextStyle(
                        color: TelemetryChannel.speed.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              if (widget.activeChannels.contains(TelemetryChannel.cadence) &&
                  point.cadence != null)
                Text('${point.cadence!.round()} rpm',
                    style: TextStyle(
                        color: TelemetryChannel.cadence.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              if (widget.activeChannels.contains(TelemetryChannel.altitude) &&
                  point.altitudeM != null)
                Text('${point.altitudeM!.round()} m',
                    style: TextStyle(
                        color: TelemetryChannel.altitude.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0)
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _TelemetryChartPainter extends CustomPainter {
  final List<ActivityStreamPoint> points;
  final Set<TelemetryChannel> activeChannels;
  final int? scrubIndex;
  final bool useDistanceAxis;

  _TelemetryChartPainter({
    required this.points,
    required this.activeChannels,
    this.scrubIndex,
    this.useDistanceAxis = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final n = points.length;
    final w = size.width;
    final h = size.height - 20; // Platz für Zeitachse unten

    // Maxima für Skalierung
    final maxPower = points.map((p) => p.power ?? 0.0).fold(0.0, max);
    final maxHr = points.map((p) => p.hr ?? 0.0).fold(0.0, max);
    final maxSpeed = points.map((p) => p.speedMps ?? 0.0).fold(0.0, max);
    final maxCad = points.map((p) => p.cadence ?? 0.0).fold(0.0, max);
    final minAlt = points.map((p) => p.altitudeM ?? 0.0).fold(10000.0, min);
    final maxAlt = points.map((p) => p.altitudeM ?? 0.0).fold(-1000.0, max);

    final stepX = w / (n - 1);

    // 1. Höhe als weiches Backdrop-Band (DESIGN.md §3.2)
    if (activeChannels.contains(TelemetryChannel.altitude) && maxAlt > minAlt) {
      final altPath = Path();
      altPath.moveTo(0, h);
      for (int i = 0; i < n; i++) {
        final x = i * stepX;
        final a = points[i].altitudeM ?? minAlt;
        final normA = (a - minAlt) / (maxAlt - minAlt);
        final y = h - (normA * (h * 0.45)); // Nimmt untere 45% ein
        altPath.lineTo(x, y);
      }
      altPath.lineTo(w, h);
      altPath.close();

      final altPaint = Paint()
        ..color = TelemetryChannel.altitude.color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawPath(altPath, altPaint);
    }

    // 2. Kanallinien zeichnen
    if (activeChannels.contains(TelemetryChannel.power) && maxPower > 0) {
      _drawLine(canvas, size, h, (p) => p.power, maxPower * 1.1,
          TelemetryChannel.power.color);
    }

    if (activeChannels.contains(TelemetryChannel.heartRate) && maxHr > 0) {
      _drawLine(canvas, size, h, (p) => p.hr, maxHr * 1.05,
          TelemetryChannel.heartRate.color);
    }

    if (activeChannels.contains(TelemetryChannel.speed) && maxSpeed > 0) {
      _drawLine(canvas, size, h, (p) => p.speedMps, maxSpeed * 1.1,
          TelemetryChannel.speed.color);
    }

    if (activeChannels.contains(TelemetryChannel.cadence) && maxCad > 0) {
      _drawLine(canvas, size, h, (p) => p.cadence, maxCad * 1.1,
          TelemetryChannel.cadence.color);
    }

    // 3. Scrubbing Leitlinie
    if (scrubIndex != null && scrubIndex! < n) {
      final scrubX = scrubIndex! * stepX;
      final linePaint = Paint()
        ..color = AppColors.accentVolt
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(scrubX, 0), Offset(scrubX, h), linePaint);

      // Punkt-Marker
      final dotPaint = Paint()
        ..color = AppColors.accentVolt
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(scrubX, h / 2), 4, dotPaint);
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    double h,
    double? Function(ActivityStreamPoint) getter,
    double maxScale,
    Color color,
  ) {
    final path = Path();
    bool started = false;
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final val = getter(points[i]);
      if (val != null && val > 0) {
        final x = i * stepX;
        final y = h - (val / maxScale) * (h - 15);
        if (!started) {
          path.moveTo(x, y.clamp(0.0, h));
          started = true;
        } else {
          path.lineTo(x, y.clamp(0.0, h));
        }
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TelemetryChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.activeChannels != activeChannels ||
        oldDelegate.scrubIndex != scrubIndex ||
        oldDelegate.useDistanceAxis != useDistanceAxis;
  }
}
